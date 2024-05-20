public with sharing class ExtensionConfigurationsSelector extends fflib_SObjectSelector {
    //CONSTRUCTOR

    public ExtensionConfigurationsSelector() {
        this(true);
    }

    public ExtensionConfigurationsSelector(Boolean enforceFLS) {
        super(false, true, enforceFLS, false);
    }

    //PUBLIC

    public SObjectType getSObjectType() {
        return copado__ExtensionConfiguration__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{ copado__ExtensionConfiguration__c.copado__AcceptanceCriteria__c };
    }

    public List<copado__ExtensionConfiguration__c> byIds(Set<Id> recordIds) {
        return (List<copado__ExtensionConfiguration__c>) selectSObjectsById(recordIds);
    }

    public List<copado__ExtensionConfiguration__c> byActiveExtensionTools(Set<String> extensionTools) {
        return Database.query(
            newQueryFactory()
                .setCondition('copado__ExtensionTool__c IN :extensionTools AND copado__Active__c = true')
                .setOrdering('LastModifiedDate', fflib_QueryFactory.SortOrder.DESCENDING, true)
                .toSOQL()
        );
    }
}