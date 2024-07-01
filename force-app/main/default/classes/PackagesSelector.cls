public with sharing class PackagesSelector extends fflib_SObjectSelector {
    // CONSTRUCTOR

    public PackagesSelector() {
        this(true, true);
    }

    public PackagesSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(false, enforceCRUD, enforceFLS, false);
    }

    // PUBLIC

    public SObjectType getSObjectType() {
        return copado__Artifact__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            copado__Artifact__c.Name,
            copado__Artifact__c.Api_Version__c,
            copado__Artifact__c.copado__Package_Type__c,
            copado__Artifact__c.copado__Package_Namespace__c,
            copado__Artifact__c.copado__No_Namespace__c,
            copado__Artifact__c.IsOrgDependent__c,
            copado__Artifact__c.copado__Target_Dev_Hub_Org__c,
            copado__Artifact__c.copado__DefaultBranch__c
        };
    }

    public List<copado__Artifact__c> byIds(Set<Id> ids) {
        return Database.query(newQueryFactory().setCondition(copado__Artifact__c.Id + ' IN :ids').toSOQL());
    }

    public List<copado__Artifact__c> byPackage2Ids(Set<Id> ids) {
        return Database.query(newQueryFactory().setCondition(copado__Artifact__c.copado__Package_Id__c + ' IN :ids').toSOQL());
    }

    public List<copado__Artifact__c> selectBySubscriberIdWithVersions(Set<Id> ids, Set<String> versionFieldSet) {
        fflib_QueryFactory query = newQueryFactory().setCondition(copado__Artifact__c.copado__Package_Id__c + ' IN :ids');

        return Database.query(query.toSOQL());
    }

    public List<copado__Artifact__c> byRecordType(Set<String> recordTypes, Set<Id> packageIds) {
        return Database.query(
            newQueryFactory().setCondition(copado__Artifact__c.Id + ' IN :packageIds AND RecordType.DeveloperName IN :recordTypes').toSOQL()
        );
    }
}