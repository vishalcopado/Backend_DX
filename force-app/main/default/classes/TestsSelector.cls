public with sharing class TestsSelector extends fflib_SObjectSelector {
    //PUBLIC

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            copado__Test__c.Id,
            copado__Test__c.Name,
            copado__Test__c.copado__Reference__c,
            copado__Test__c.copado__Type__c,
            copado__Test__c.copado__User_Story__c,
            copado__Test__c.copado__Configuration__c,
            copado__Test__c.copado__ExtensionConfiguration__c,
            copado__Test__c.copado__LatestJobExecution__c,
            copado__Test__c.copado__AcceptanceCriteria__c
        };
    }

    public SObjectType getSObjectType() {
        return copado__Test__c.sObjectType;
    }

    public List<copado__Test__c> byIds(Set<Id> ids) {
        return (List<copado__Test__c>) Database.query(
            newQueryFactory()
                .setEnforceFLS(true)
                .selectField('copado__User_Story__r.copado__Org_Credential__c')
                .setCondition('Id IN :ids')
                .toSOQL()
        );
    }

    public List<copado__Test__c> byUserStoriesAndExtensionTools(Set<Id> userStories, Set<String> extensionTools) {
        return (List<copado__Test__c>) Database.query(
            newQueryFactory()
                .setEnforceFLS(true)
                .setCondition(
                    'copado__User_Story__c IN :userStories AND copado__ExtensionConfiguration__r.copado__ExtensionTool__c IN : extensionTools'
                )
                .addOrdering('LastModifiedDate', fflib_QueryFactory.SortOrder.DESCENDING)
                .toSOQL()
        );
    }

    public List<copado__Test__c> byUserStoryIds(Set<Id> ids) {
        return (List<copado__Test__c>) Database.query(
            newQueryFactory().setEnforceFLS(true).setCondition('copado__User_Story__c IN :ids').toSOQL()
        );
    }
}