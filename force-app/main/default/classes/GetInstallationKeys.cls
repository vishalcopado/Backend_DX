@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class GetInstallationKeys implements copado.ParameterExpressionCallable {
    private Request request;

    // GLOBAL

    global String execute(Id contextId) {
        return getPayload(contextId);
    }

    // PRIVATE

    private String getPayload(Id jobStepId) {
        try {
            List<Response> result = new List<Response>();

            List<copado__JobStep__c> jobStep = new JobStepsSelector().byIds(new Set<Id>{ jobStepId });
            List<copado__JobStep__c> prevJobStep = getPreviousJobStep(jobStep[0]);

            request = getRequest(prevJobStep[0]);

            Map<Id, Response> responseByVersionId = createResponseById(request.dependencies);
            result = getKeys(responseByVersionId);

            return JSON.serialize(result);
        } catch (Exception ex) {
            throw new ApplicationException(ex.getMessage() + ' ' + ex.getStackTraceString());
        }
    }

    private List<copado__JobStep__c> getPreviousJobStep(copado__JobStep__c currentJobStep) {
        List<copado__JobStep__c> prevJobStep = new JobStepsSelector()
            .byJobExecutionAndOrder(new Set<Id>{ currentJobStep.copado__JobExecution__c }, Integer.valueOf(currentJobStep.copado__Order__c) - 1);
        if (prevJobStep.size() != 1) {
            throw new ApplicationException(Label.JobStepsNotConfiguredCorrectly);
        }
        return prevJobStep;
    }

    private static Request getRequest(copado__JobStep__c step) {
        Request result = (Request) JSON.deserialize(step.copado__Result__r.copado__Result_Data__c, Request.class);
        result.dependencies.add(result.subscriberVersionId);
        return result;
    }

    private Map<Id, Response> createResponseById(Set<Id> dependenciesIds) {
        Map<Id, Response> result = new Map<Id, Response>();

        for (Id recordId : dependenciesIds) {
            result.put(
                recordId,
                recordId == request.subscriberVersionId
                    ? new Response().id(recordId).versionNumber(request.versionNumber).subscriberPackageId(request.subscriberPackageId)
                    : new Response().id(recordId)
            );
        }
        return result;
    }

    private List<Response> getKeys(Map<Id, Response> dependenciesIds) {
        for (PackageVersionInstallationKey__c key : new PackageVersionInstallationKeySelector().byPackageVersionId(dependenciesIds.keySet())) {
            dependenciesIds.get(key.PackageVersionId__c).key(key.InstallationKey__c);
        }

        return dependenciesIds.values();
    }

    private class Request {
        private Id subscriberVersionId;
        private Set<Id> dependencies;
        private String versionNumber;
        private String subscriberPackageId;
    }

    @TestVisible
    private class Response {
        @TestVisible
        private String id;
        @TestVisible
        private String key;
        @TestVisible
        private String subscriberPackageId;
        @TestVisible
        private String versionNumber;

        public Response id(String id) {
            this.id = id;
            return this;
        }

        public Response key(String key) {
            this.key = key;
            return this;
        }

        public Response subscriberPackageId(String subscriberPackageId) {
            this.subscriberPackageId = subscriberPackageId;
            return this;
        }

        public Response versionNumber(String versionNumber) {
            this.versionNumber = versionNumber;
            return this;
        }
    }
}