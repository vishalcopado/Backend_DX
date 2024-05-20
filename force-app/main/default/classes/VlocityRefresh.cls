public with sharing class VlocityRefresh implements copado.ParameterExpressionCallable {
    private static final String FUNCTION_API_NAME = 'vlocity_refresh_index';

    @TestVisible
    private static Result mockResult;

    // PUBLIC

    @AuraEnabled
    public static Id execute(Id credentialId) {
        try {
            Id resultId;
            validateCredentialId(credentialId);
            List<copado__Org__c> credentials = new CredentialsSelector().byIds(new List<Id>{ credentialId });
            copado.RunCopadoFunction.InvocableVariables request = new copado.RunCopadoFunction.InvocableVariables();

            request.functionApiName = FUNCTION_API_NAME;
            request.contextId = credentials[0].copado__Environment__c;
            request.parameters = getParameters(credentialId);
            request.showValidationErrors = true;
            if (Test.isRunningTest()) {
                resultId = mockResult.Id;
            } else {
                resultId = copado.RunCopadoFunction.execute(new List<copado.RunCopadoFunction.InvocableVariables>{ request })[0];
            }
            return resultId;
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }

    //PRIVATE

    private static List<copado.Parameter> getParameters(Id credentialId) {
        List<copado.Parameter> result = new List<copado.Parameter>();

        result.add(new copado.Parameter('sessionId', '{$Context.Credential.SessionId}'));
        result.add(new copado.Parameter('endpoint', '{$Context.Credential.Endpoint}'));
        result.add(new copado.Parameter('credentialId', credentialId));

        return result;
    }

    private static void validateCredentialId(Id credentialId) {
        if (String.isBlank(credentialId)) {
            throw new ApplicationException(Label.Credential_Not_Found);
        }
    }
}