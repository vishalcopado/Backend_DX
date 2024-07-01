public with sharing class ReleasesSelector extends fflib_SObjectSelector {
    // CONSTRUCTOR

    public ReleasesSelector() {
        this(true, true);
    }

    public ReleasesSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(false, enforceCRUD, enforceFLS, false);
    }

    // PUBLIC

    public SObjectType getSObjectType() {
        return copado__Release__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{ copado__Release__c.Name };
    }

    public List<copado__Release__c> byIds(Set<Id> ids) {
        return Database.query(
            newQueryFactory().setCondition(copado__Release__c.Id + ' IN :ids').toSOQL()
        );
    }
}