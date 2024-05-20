public with sharing class GetVlocityDependencies {
    private static final String FUNCTION_API_NAME = 'vlocity_retrieve';
    public final static String VLOCITY_SETTINGS_YAML_FILE = 'vlocity-settings';
    private static final String PUBLISH_EVENT_FUNCTION_CALLBACK = Settings.NAMESPACE_DOT + 'PublishEventFunctionCallback';

    @TestVisible
    private static Result mockResult;

    // PUBLIC

    @AuraEnabled
    public static Id execute(Id credentialId, String selectedDataPacks) {
        try {
            Id resultId;
            validateCredentialId(credentialId);
            List<copado__Org__c> credentials = new CredentialsSelector().byIds(new List<Id>{ credentialId });

            copado.RunCopadoFunction.InvocableVariables request = new copado.RunCopadoFunction.InvocableVariables();
            request.functionApiName = FUNCTION_API_NAME;
            request.contextId = credentials[0].copado__Environment__c;
            request.parameters = getParameters(credentialId, selectedDataPacks, credentials[0].copado__Environment__c);
            request.resultCallback = Settings.NAMESPACE_DOT + PUBLISH_EVENT_FUNCTION_CALLBACK;
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

    private static List<copado.Parameter> getParameters(Id credentialId, String selectedDataPacks, Id environmentId) {
        List<copado.Parameter> parameterList = new List<copado.Parameter>{
            new copado.Parameter('sourceSessionId', '{$Context.Credential.SessionId}'),
            new copado.Parameter('sourceEndPoint', '{$Context.Credential.Endpoint}'),
            new copado.Parameter('sourceDirectory', 'vlocity'),
            new copado.Parameter('maxDepth', null),
            new copado.Parameter('fileChangesId', null),
            new copado.Parameter('selectedDataPacks', selectedDataPacks),
            new copado.Parameter('vlocitySettingsDocumentId', ContentDocumentHelper.getContentDocumentIdByLinkedEntinityAndFileName(environmentId, VLOCITY_SETTINGS_YAML_FILE)),
            new copado.Parameter('commitId', null)
        };
        return parameterList;
    }

    private static void validateCredentialId(Id credentialId) {
        if (String.isBlank(credentialId)) {
            throw new ApplicationException(Label.Credential_Not_Found);
        }
    }
}