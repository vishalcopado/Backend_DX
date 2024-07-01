public with sharing class JobStepApexCtrl {
    @AuraEnabled(cacheable=true)
    public static copado__Function__c getFunctionByApiName(String apiName) {
        try {
            List<copado__Function__c> functions = new FunctionsSelector().byApiName(new Set<String>{ apiName });
            return !functions.isEmpty() ? functions[0] : null;
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }
}