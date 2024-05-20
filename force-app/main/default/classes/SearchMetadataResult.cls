@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class SearchMetadataResult {
    @AuraEnabled
    global String CreatedDate;
    @AuraEnabled
    global LookupUserField CreatedBy;
    @AuraEnabled
    global String LastModifiedDate;
    @AuraEnabled
    global LookupUserField LastModifiedBy;
    @AuraEnabled
    global Boolean IsNameObsolete;
    @AuraEnabled
    global String Name;
    @AuraEnabled
    global String DeveloperName;

    global with sharing class LookupUserField {
        @AuraEnabled
        global String Name;
    }
}