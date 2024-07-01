public without sharing class CheckVlocityEnabled {
    private static final String SYSTEM_PROPERTY = 'vlocity_enabled';

    @AuraEnabled
    public static Boolean execute(Id pipelineId) {
        try {
            List<copado__System_Property__c> systemProperties = new SystemPropertiesSelector()
                .byPipelineAndCreatedDateForSFDX(new Set<Id>{ pipelineId }, SYSTEM_PROPERTY);

            return !systemProperties.isEmpty() && systemProperties[0]?.copado__Value__c?.toLowerCase() == 'true' ? true : false;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage() + ex.getStackTraceString()); 
        }
    }
}