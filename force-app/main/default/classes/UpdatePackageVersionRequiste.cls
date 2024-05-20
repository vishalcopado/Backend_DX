public with sharing class UpdatePackageVersionRequiste {
    @InvocableMethod(label='Update Package Version Requsite' category='Package Version Publish')
    public static List<Response> execute(List<Request> requests) {
        try {
            copado__Result__c resultRecord = new ResultsSelector().byIds(new Set<Id>{ requests[0].resultId })[0];
            copado__Artifact_Version__c packageVersion = new PackageVersionsSelector().byIds(new Set<Id>{ (Id) requests[0].packageVersionId })[0];

            String jobExecutionId = resultRecord.copado__JobStep__r?.copado__JobExecution__c;
            if (String.isBlank(jobExecutionId)) {
                throw new ApplicationException(Label.Result_Record_with_valid_Job_Execution);
            }

            Id destinationId = (Id) packageVersion?.copado__Artifact__r?.copado__Target_Dev_Hub_Org__r?.copado__Environment__c;
            updateJobExecution(new List<copado__JobExecution__c>{ getJobExecution(jobExecutionId, destinationId) });

            Map<String, Object> versionDetails = new Map<String, Object>{
                'subscriberId' => packageVersion.copado__Subscriber_Version_Id__c,
                'apiVersion' => getApiVersion(packageVersion)
            };
            return new List<Response>{ new Response(JSON.serialize(versionDetails, true).escapeEcmaScript()) };
        } catch (Exception ex) {
            throw new ApplicationException(ex.getMessage() + ' ' + ex.getStackTraceString());
        }
    }

    // PRIVATE

    private static copado__JobExecution__c getJobExecution(String jobExecutionId, Id destination) {
        copado__JobExecution__c result = new copado__JobExecution__c(Id = jobExecutionId, copado__Destination__c = destination);
        return result;
    }

    private static void updateJobExecution(List<copado__JobExecution__c> jobExecutions) {
        update Security.stripInaccessible(AccessType.UPDATABLE, jobExecutions).getRecords();
    }

    private static String getApiVersion(copado__Artifact_Version__c version) {
        return String.isNotBlank(version.Api_Version__c) ? version.Api_Version__c : version.copado__Artifact__r.Api_Version__c;
    }

    // INNER

    public class Request {
        @InvocableVariable(label='Result Id' required=true)
        public String resultId;

        @InvocableVariable(label='Package Version Id' required=true)
        public String packageVersionId;
    }

    public class Response {
        @InvocableVariable
        public String versionDetails;

        public Response(String versionDetails) {
            this.versionDetails = versionDetails;
        }
    }
}