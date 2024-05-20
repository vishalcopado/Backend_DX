public with sharing class EnvironmentsSelector extends fflib_SObjectSelector {
    // CONSTRUCTOR

    public EnvironmentsSelector() {
        this(true, true);
    }

    public EnvironmentsSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(false, enforceCRUD, enforceFLS, false);
    }

    // PUBLIC

    public SObjectType getSObjectType() {
        return copado__Environment__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{ copado__Environment__c.Name };
    }

    public List<copado__Environment__c> byIds(Set<Id> ids) {
        return Database.query(
            newQueryFactory().selectField(copado__Environment__c.copado__Type__c).setCondition(copado__Environment__c.Id + ' IN :ids').toSOQL()
        );
    }
}