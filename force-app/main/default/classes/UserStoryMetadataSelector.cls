public with sharing class UserStoryMetadataSelector extends fflib_SObjectSelector {
    // CONSTRUCTOR

    public UserStoryMetadataSelector() {
        this(true, true);
    }

    public UserStoryMetadataSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(false, enforceCRUD, enforceFLS, false);
    }

    // PUBLIC

    public SObjectType getSObjectType() {
        return copado__User_Story_Metadata__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            copado__User_Story_Metadata__c.copado__User_Story__c,
            copado__User_Story_Metadata__c.copado__Type__c,
            copado__User_Story_Metadata__c.copado__Metadata_API_Name__c
        };
    }

    public List<copado__User_Story_Metadata__c> byUserStoryId(Set<Id> ids) {
        return Database.query(
            newQueryFactory()
                .setCondition(copado__User_Story_Metadata__c.copado__User_Story__c + ' IN :ids')
                .selectFields(
                    new Set<String>{
                        'LastModifiedBy.Name',
                        'LastModifiedDate',
                        'copado__Action__c',
                        'copado__JsonInformation__c',
                        'copado__Category__c'
                    }
                )
                .toSOQL()
        );
    }

    public List<copado__User_Story_Metadata__c> byStoryIdsAndActionAddOrFull(Set<Id> ids) {
        return Database.query(
            newQueryFactory()
                .setCondition(copado__User_Story_Metadata__c.copado__User_Story__c + ' IN :ids AND copado__Action__c IN (\'Add\',\'Full\')')
                .toSOQL()
        );
    }

    public List<copado__User_Story_Metadata__c> byStoryIdsAndTypeApexClass(Set<Id> ids, Set<String> types) {
        return Database.query(
            newQueryFactory().setCondition(copado__User_Story_Metadata__c.copado__User_Story__c + ' IN :ids AND copado__Type__c IN :types').toSOQL()
        );
    }
}