@SuppressWarnings('PMD.AvoidGlobalModifier')
global class GetGitJson implements copado.ParameterExpressionCallable {
    private static final String GIT_REPOSITORY_ID = 'gitRepositoryId';
    private static final String GIT_CREDENTIAL_DYNAMIC_EXPRESSON = '{$Context.Repository.Credential}';

    // GLOBAL

    global String execute(Id contextId) {
        String result = '';
        try {
            String gitRepositoryId = getGitRepositoryId(contextId);
            result = getGitJsonValue(gitRepositoryId);
        } catch (Exception ex) {
            throw new ApplicationException(ex.getMessage() + ' ' + ex.getStackTraceString());
        }
        return result;
    }

    // PRIVATE

    private String getGitRepositoryId(Id jobStepId) {
        Map<String, Object> dataJson = getDataJson(jobStepId);
        if (!dataJson.containsKey(GIT_REPOSITORY_ID)) {
            throw new ApplicationException(Label.GitRepositoryIdNotFound);
        }
        return (String) dataJson.get(GIT_REPOSITORY_ID);
    }

    private Map<String, Object> getDataJson(Id jobStepId) {
        Map<String, Object> result = new Map<String, Object>();
        List<copado__JobStep__c> jobExecutionData = new JobStepsSelector().byIds(new Set<Id>{ jobStepId });
        String dataJsonString = jobExecutionData[0]?.copado__JobExecution__r?.copado__DataJson__c;
        if(String.isNotBlank(dataJsonString)){
            result = (Map<String, Object>) JSON.deserializeUntyped(dataJsonString);
        }
        return result;
    }

    private String getGitJsonValue(Id gitRepositoryId) {
        copado.Jobs.DynamicExpressionEvaluateRequest request = new copado.Jobs.DynamicExpressionEvaluateRequest(
            gitRepositoryId,
            new List<String>{ GIT_CREDENTIAL_DYNAMIC_EXPRESSON }
        );
        List<copado.Jobs.DynamicExpressionEvaluateResult> responses = copado.Jobs.DynamicExpression.evaluate(request);
        return responses[0].value;
    }
}