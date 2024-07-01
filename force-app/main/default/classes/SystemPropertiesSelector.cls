public inherited sharing class SystemPropertiesSelector extends fflib_SObjectSelector {
    // CONSTRUCTOR

    public SystemPropertiesSelector() {
        this(true, true);
    }

    public SystemPropertiesSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(false, enforceCRUD, enforceFLS, false);
    }

    // PUBLIC

    public SObjectType getSObjectType() {
        return copado__System_Property__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            copado__System_Property__c.copado__API_Name__c,
            copado__System_Property__c.copado__Pipeline__c,
            copado__System_Property__c.copado__Value__c,
            copado__System_Property__c.copado__Environment__c,
            copado__System_Property__c.CreatedDate,
            copado__System_Property__c.copado__Is_Global__c
        };
    }

    public List<copado__System_Property__c> byPipelineAndCreatedDateForSFDX(Set<Id> ids, String apiName) {
        return Database.query(
            newQueryFactory()
                .selectField('copado__Value__c')
                .setCondition('copado__Pipeline__c IN :ids AND copado__API_Name__c =:apiName AND copado__Pipeline__r.copado__Platform__c = \'SFDX\'')
                .setOrdering('CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING)
                .toSOQL()
        );
    }

    public List<copado__System_Property__c> byEnvironmentForSFDX(Set<Id> ids, String apiName) {
        return Database.query(
            newQueryFactory()
                .selectField('copado__Value__c')
                .setCondition(
                    'copado__Environment__c IN :ids AND copado__API_Name__c =:apiName AND copado__Environment__r.copado__Platform__c = \'SFDX\''
                )
                .setOrdering('CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING)
                .toSOQL()
        );
    }

    public List<copado__System_Property__c> byPipelineIdAndGlobalForMCDD(Id id, String apiName) {
        return Database.query(
            newQueryFactory()
                .selectFields(new List<String>{ 'copado__Is_Global__c', 'copado__Value__c', 'copado__ParentId__c' })
                .setCondition(
                    '(copado__ParentId__c = :id AND copado__API_Name__c = :apiName) OR (copado__API_Name__c = :apiName AND copado__Is_Global__c = TRUE)'
                )
                .setOrdering('LastModifiedDate', fflib_QueryFactory.SortOrder.DESCENDING)
                .toSOQL()
        );
    }
}