public with sharing class QualityGateRuleConditionsSelector extends fflib_SObjectSelector {
    @TestVisible
    private static List<copado__Quality_Gate_Rule_Condition__c> mock = new List<copado__Quality_Gate_Rule_Condition__c>();

    // CONSTRUCTOR

    public QualityGateRuleConditionsSelector() {
        this(true, true);
    }

    public QualityGateRuleConditionsSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(false, enforceCRUD, enforceFLS, false);
    }

    // PUBLIC

    public SObjectType getSObjectType() {
        return copado__Quality_Gate_Rule_Condition__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            copado__Quality_Gate_Rule_Condition__c.Name,
            copado__Quality_Gate_Rule_Condition__c.copado__AcceptanceCriteria__c
        };
    }

    public List<copado__Quality_Gate_Rule_Condition__c> byIds(Set<Id> ids) {
        return Test.isRunningTest() ? mock : (List<copado__Quality_Gate_Rule_Condition__c>) selectSObjectsById(ids);
    }

    public static void setMock(List<copado__Quality_Gate_Rule_Condition__c> providers) {
        mock = providers;
    }

    public static List<copado__Quality_Gate_Rule_Condition__c> getMock() {
        return mock;
    }
}