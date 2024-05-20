@SuppressWarnings('PMD.AvoidGlobalModifier')
global class VlocitySettingsDestinationId implements copado.ParameterExpressionCallable {
    public final static String VLOCITY_SETTINGS_YAML_FILE = 'vlocity-settings';

    global String execute(Id contextId) {
        String result = '';
        List<copado__JobStep__c> steps = new JobStepsSelector().byIds(new Set<Id> { contextId });
        if(!steps.isEmpty()) {
            result = ContentDocumentHelper.getContentDocumentIdByLinkedEntinityAndFileName(steps[0]?.copado__Destination_Id__c, VLOCITY_SETTINGS_YAML_FILE);
        }
        return result;
    }
}