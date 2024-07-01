public with sharing class FunctionsSelector extends fflib_SObjectSelector {
    // CONSTRUCTOR

    public FunctionsSelector() {
        this(true, true);
    }

    public FunctionsSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(false, enforceCRUD, enforceFLS, false);
    }

    // PUBLIC

    public SObjectType getSObjectType() {
        return copado__Function__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{ copado__Function__c.Name, copado__Function__c.copado__API_Name__c, copado__Function__c.copado__Parameters__c };
    }

    public List<copado__Function__c> byApiName(Set<String> apiNames) {
        return Database.query(newQueryFactory().setCondition(copado__Function__c.copado__API_Name__c + ' IN :apiNames').toSOQL());
    }
}