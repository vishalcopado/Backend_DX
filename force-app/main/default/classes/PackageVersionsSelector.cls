public with sharing class PackageVersionsSelector extends FflibExtension {
    // CONSTRUCTOR

    public PackageVersionsSelector() {
        this(true, true);
    }

    public PackageVersionsSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(false, enforceCRUD, enforceFLS, false);
    }

    // PUBLIC

    public SObjectType getSObjectType() {
        return copado__Artifact_Version__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            copado__Artifact_Version__c.Name,
            copado__Artifact_Version__c.copado__Version_number__c,
            copado__Artifact_Version__c.copado__Branch__c,
            copado__Artifact_Version__c.copado__Status__c,
            copado__Artifact_Version__c.copado__Is_released__c,
            copado__Artifact_Version__c.copado__Tag__c,
            copado__Artifact_Version__c.copado__Subscriber_Version_Id__c,
            copado__Artifact_Version__c.copado__Artifact__c,
            copado__Artifact_Version__c.copado__Version_Description__c,
            copado__Artifact_Version__c.copado__Version_Name__c,
            copado__Artifact_Version__c.copado__DefinitionFile__c,
            copado__Artifact_Version__c.Code_Coverage__c,
            copado__Artifact_Version__c.Has_Installation_Key__c,
            copado__Artifact_Version__c.Post_Install_URL__c,
            copado__Artifact_Version__c.Post_Install_Script__c,
            copado__Artifact_Version__c.Skip_Validation__c,
            copado__Artifact_Version__c.Release_Notes_URL__c,
            copado__Artifact_Version__c.Uninstall_Script__c,
            copado__Artifact_Version__c.copado__Data_JSON__c,
            copado__Artifact_Version__c.Api_Version__c
        };
    }

    public Map<String, List<Schema.SObjectField>> getSObjectLookupFieldMap() {
        return new Map<String, List<Schema.SObjectField>>{
            'copado__Artifact__r' => new List<Schema.SObjectField>{
                copado__Artifact__c.Name,
                copado__Artifact__c.copado__Package_Id__c,
                copado__Artifact__c.copado__Pipeline__c,
                copado__Artifact__c.copado__Package_Namespace__c,
                copado__Artifact__c.copado__DefaultBranch__c,
                copado__Artifact__c.Api_Version__c
            },
            'copado__Artifact__r.copado__Target_Dev_Hub_Org__r' => new List<Schema.SObjectField>{ copado__Org__c.copado__Environment__c },
            'copado__Artifact__r.copado__Pipeline__r' => new List<Schema.SObjectField>{ copado__Deployment_Flow__c.copado__Platform__c }
        };
    }

    public List<copado__Artifact_Version__c> byIds(Set<Id> ids) {
        fflib_QueryFactory query = newQueryFactory().setCondition(copado__Artifact_Version__c.Id + ' IN :ids');

        setLookupFields(query, 'copado__Artifact__r');
        setLookupFields(query, 'copado__Artifact__r.copado__Target_Dev_Hub_Org__r');
        setLookupFields(query, 'copado__Artifact__r.copado__Pipeline__r');
        return Database.query(query.toSOQL());
    }

    public List<copado__Artifact_Version__c> byPackageIds(Set<Id> packageIds) {
        return Database.query(newQueryFactory().setCondition(copado__Artifact_Version__c.copado__Artifact__c + ' IN :packageIds').toSOQL());
    }

    public List<copado__Artifact_Version__c> byStatusAndIds(Set<Id> packageIds, Set<String> statuses) {
        return Database.query(
            newQueryFactory()
                .selectField('copado__Release_Status__c')
                .setCondition(copado__Artifact_Version__c.copado__Artifact__c + ' IN :packageIds AND copado__Status__c IN :statuses')
                .toSOQL()
        );
    }

    public List<copado__Artifact_Version__c> bySubscriberIds(Set<Id> ids) {
        fflib_QueryFactory query = newQueryFactory().setCondition(copado__Artifact_Version__c.copado__Subscriber_Version_Id__c + ' IN :ids');

        setLookupFields(query, 'copado__Artifact__r');
        setLookupFields(query, 'copado__Artifact__r.copado__Target_Dev_Hub_Org__r');
        return Database.query(query.toSOQL());
    }
}