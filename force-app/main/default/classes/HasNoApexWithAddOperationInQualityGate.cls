@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class HasNoApexWithAddOperationInQualityGate implements copado.ParameterExpressionCallable {

    private final static Set<String> APEX_METADATA_TYPES = new Set<String>{'ApexClass', 'ApexTrigger'};
    private final static String ADD = 'Add';

    // GLOBAL

    global String execute(Id contextId) {
        String result = 'false';
        copado__JobExecution__c jobExecution = getJobExecution(contextId);
        JobExecutionPayload payLoad = getPayload(jobExecution.copado__DataJson__c);

        // we return true if the step is not running as part of a Quality Gate
        if (payLoad.fileWithSelectedChanges != null) {
            List<Change> changes = getChanges(payLoad.fileWithSelectedChanges);
            result = String.valueOf(!hasApexWithAddOperation(changes));
        }
        return result;
    }

    // PRIVATE

    private static copado__JobExecution__c getJobExecution(Id jobStepId) {
        return new JobStepsSelector().byIds(new Set<Id>{ jobStepId })[0].copado__JobExecution__r;
    }

    private static JobExecutionPayload getPayload(String payload) {
        return (JobExecutionPayload) System.JSON.deserialize(payload, JobExecutionPayload.class);
    }

    private static List<Change> getChanges(Id contentVersionId) {
        List<Change> result = new List<Change>();
        List<ContentVersion> contentVersion = new ContentVersionsSelector().byIds(new Set<Id>{ contentVersionId });
        if (!contentVersion?.isEmpty()) {
            String fileContent = contentVersion[0]?.VersionData?.toString();
            result = (List<Change>) JSON.deserialize(fileContent, List<Change>.class);
        }
        return result;
    }

    private static Boolean hasApexWithAddOperation(List<Change> changes) {
        Boolean result = false;
        for (Change change : changes) {
            if (change.a == ADD && APEX_METADATA_TYPES.contains(change.t)) {
                result = true;
                break;
            }
        }
        return result;
    }

    // INNER CLASS

    private with sharing class JobExecutionPayload {
        private Id fileWithSelectedChanges;
    }

    private class Change {
        public String t;
        public String a;
    }
}