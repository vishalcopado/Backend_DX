public with sharing class ValidateMetadataSchema {
    private static final String SFDX_VALIDATE_METADATA_SCHEMA = 'sfdx_validate_metadata_schema';
    private static final String PUBLISH_EVENT_FUNCTION_CALLBACK = Settings.NAMESPACE_DOT + 'PublishEventFunctionCallback';

    @TestVisible
    private static Result mockResult;

    // PUBLIC

    @AuraEnabled
    public static Id execute(String metadataFileId, String metadataType) {
        try {
            Id resultId;

            copado.RunCopadoFunction.InvocableVariables request = new copado.RunCopadoFunction.InvocableVariables();
            request.functionApiName = SFDX_VALIDATE_METADATA_SCHEMA;
            request.parameters = getParameters(metadataFileId, metadataType);
            request.showValidationErrors = true;
            request.resultCallback = PUBLISH_EVENT_FUNCTION_CALLBACK;

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

    private static List<copado.Parameter> getParameters(String metadataFileId, String metadataType) {
        List<copado.Parameter> result = new List<copado.Parameter>();

        result.add(new copado.Parameter('metadataFileId', metadataFileId));
        result.add(new copado.Parameter('metadataType', metadataType));

        return result;
    }
}