public with sharing class DeploymentsSelector extends fflib_SObjectSelector {
    // CONSTRUCTOR

    public DeploymentsSelector() {
        this(true, true);
    }

    public DeploymentsSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(false, enforceCRUD, enforceFLS, false);
    }

    // PUBLIC

    public SObjectType getSObjectType() {
        return copado__Deployment__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{ copado__Deployment__c.Name };
    }

    public List<copado__Deployment__c> byIds(Set<Id> ids) {
        return Database.query(
            newQueryFactory()
                .selectField('copado__Promotion__r.copado__Destination_Org_Credential__c')
                .setCondition(copado__Deployment__c.Id + ' IN :ids')
                .toSOQL()
        );
    }
}