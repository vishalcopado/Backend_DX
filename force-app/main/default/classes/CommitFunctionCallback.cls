public with sharing class CommitFunctionCallback {
    // PUBLIC

    @InvocableMethod(label='Commit Function Callback' category='Commit')
    public static void execute(List<Request> requests) {
        Map<String, Object> resultData = new Map<String, Object>();
        copado__Result__c commitResult = getResult(requests[0].resultId);
        if (isRequestValid(requests)) {
            try {
                resultData = getResultData(commitResult);
                Map<String, Object> dataJson = getJobExecutionDataJson(commitResult);
                if (isCommitResultValid(commitResult, resultData, dataJson)) {
                    updateJobExecutionDataJson(commitResult, dataJson);
                }
            } catch (Exception ex) {
                updateWarningOnJobExecution(commitResult.copado__JobStep__r.copado__JobExecution__c, ex.getMessage() + ex.getStackTraceString());
            }
        }
    }

    // PRIVATE

    private static void updateJobExecutionDataJson(copado__Result__c result, Map<String, Object> dataJson) {
        String jobExecutionId = result.copado__JobStep__r?.copado__JobExecution__c;
        if (String.isNotBlank(jobExecutionId) && !dataJson.isEmpty()) {
            dataJson.put('actionCallback', Settings.NAMESPACE_DOT + 'JobExecutionForTestRecords');
            updateJobExecution(new List<copado__JobExecution__c>{ getJobExecution(jobExecutionId, JSON.serialize(dataJson)) });
        }
    }

    private static copado__JobExecution__c getJobExecution(String jobExecutionId, String dataJson) {
        copado__JobExecution__c result = new copado__JobExecution__c(Id = jobExecutionId, copado__DataJson__c = dataJson);
        return result;
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static void updateJobExecution(List<copado__JobExecution__c> jobExecutions) {
        jobExecutions = Security.stripInaccessible(AccessType.UPDATABLE, jobExecutions).getRecords();
        update jobExecutions;
    }

    private static Boolean isRequestValid(List<Request> requests) {
        return !requests.isEmpty() && String.isNotBlank(requests[0].resultId);
    }

    private static copado__Result__c getResult(String recordId) {
        List<copado__Result__c> result = new ResultsSelector().byIds(new Set<Id>{ recordId });
        return result[0];
    }

    private static Map<String, Object> getResultData(copado__Result__c commitResult) {
        Map<String, Object> result = new Map<String, Object>();
        String resultData = commitResult.copado__Result_Data__c;
        if (String.isNotBlank(resultData)) {
            result = (Map<String, Object>) JSON.deserializeUntyped(resultData);
        }
        return result;
    }

    private static Map<String, Object> getJobExecutionDataJson(copado__Result__c commitResult) {
        Map<String, Object> result = new Map<String, Object>();
        String dataJson = commitResult.copado__JobStep__r?.copado__JobExecution__r?.copado__DataJson__c;
        if (String.isNotBlank(dataJson)) {
            result = (Map<String, Object>) JSON.deserializeUntyped(dataJson);
        }
        return result;
    }

    private static Boolean isCommitResultValid(
        copado__Result__c commitResult,
        Map<String, Object> resultData,
        Map<String, Object> dataJson
    ) {
        String status = resultData.containsKey('status') ? (String) resultData.get('status') : '';
        Boolean recreateFeatureBranch = dataJson.containsKey('recreateFeatureBranch')
            ? (Boolean) dataJson.get('recreateFeatureBranch')
            : false;
        return commitResult.copado__Status__c == 'Success' && (status != 'No Changes' || recreateFeatureBranch);
    }

    private static void updateWarningOnJobExecution(Id jobExecutionId, String infoMessage) {
        if (String.isNotBlank(infoMessage) && Schema.sObjectType.copado__JobExecution__c.fields.copado__ErrorMessage__c.isUpdateable()) {
            update new copado__JobExecution__c(
                Id = jobExecutionId,
                copado__ErrorMessage__c = infoMessage
            );
        }
    }

    // INNER

    public class Request {
        @InvocableVariable(label='Result Id' required=true)
        public String resultId;
    }
}