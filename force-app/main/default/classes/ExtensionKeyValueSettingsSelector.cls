public inherited sharing class ExtensionKeyValueSettingsSelector extends fflib_SObjectSelector {
    // PUBLIC

    public Schema.SObjectType getSObjectType() {
        return copado__ExtensionKeyValueSetting__mdt.SObjectType;
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            copado__ExtensionKeyValueSetting__mdt.copado__Key__c,
            copado__ExtensionKeyValueSetting__mdt.copado__Value__c
        };
    }

    public List<copado__ExtensionKeyValueSetting__mdt> byPlatformAndKey(String platform, String key) {
        return Database.query(
            newQueryFactory().setCondition('copado__Extension__r.copado__Platform__c = :platform AND copado__Key__c = :key').setLimit(1).toSOQL()
        );
    }
}