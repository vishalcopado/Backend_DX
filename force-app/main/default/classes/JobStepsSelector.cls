public with sharing class JobStepsSelector extends fflib_SObjectSelector {
    // CONSTRUCTOR

    public JobStepsSelector() {
        this(true, true);
    }

    public JobStepsSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(false, enforceCRUD, enforceFLS, false);
    }

    // PUBLIC

    public SObjectType getSObjectType() {
        return copado__JobStep__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{ copado__JobStep__c.Name };
    }

    public List<copado__JobStep__c> promotionByIds(Set<Id> ids) {
        return Database.query(
            newQueryFactory()
                .selectField('copado__JobExecution__r.copado__Deployment__r.copado__Promotion__c')
                .setCondition(copado__JobStep__c.Id + ' IN :ids')
                .toSOQL()
        );
    }

    public List<copado__JobStep__c> byIds(Set<Id> ids) {
        return Database.query(
            newQueryFactory()
                .selectFields(
                    new List<String>{
                        'copado__JobExecution__r.copado__DataJson__c',
                        'copado__JobExecution__r.copado__Pipeline__c',
                        'copado__JobExecution__r.copado__Promotion__c',
                        'copado__JobExecution__r.copado__Destination__c',
                        'copado__JobExecution__r.copado__Template__r.copado__ApiName__c',
                        'copado__Order__c',
                        'copado__ConfigJson__c',
                        'copado__Destination_Id__c',
                        'copado__Source_Id__c'
                    }
                )
                .setCondition(copado__JobStep__c.Id + ' IN :ids')
                .toSOQL()
        );
    }

    public List<copado__JobStep__c> qualityGateRuleConditionByIds(Set<Id> ids) {
        return Database.query(
            newQueryFactory()
                .selectFields(new List<String>{ 'copado__Quality_Gate_Rule_Condition__c' })
                .setCondition(copado__JobStep__c.Id + ' IN :ids')
                .toSOQL()
        );
    }

    public List<copado__JobStep__c> byJobExecutionAndOrder(Set<Id> ids, Integer order) {
        return Database.query(
            newQueryFactory()
                .selectFields(new Set<String>{ 'copado__Result__r.copado__Result_Data__c', 'copado__JobExecution__c', 'copado__Order__c' })
                .setCondition('copado__JobExecution__c IN :ids AND copado__Order__c =:order')
                .toSOQL()
        );
    }

    public List<copado__JobStep__c> jobExecutionbyStepIds(Set<Id> ids) {
        return Database.query(
            newQueryFactory()
                .selectField('copado__JobExecution__r.copado__Pipeline__c')
                .selectField('copado__JobExecution__r.copado__Destination__c')
                .setCondition(copado__JobStep__c.Id + ' IN :ids')
                .toSOQL()
        );
    }

    public List<copado__JobStep__c> byUserStoryIds(Set<Id> userStoryIds) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('copado__UserStory__c IN :userStoryIds')
            .selectFields(
                new List<String>{
                    'copado__ConfigJson__c'
                }
            )
            .setOrdering('copado__Order__c', fflib_QueryFactory.SortOrder.ASCENDING)
            .addOrdering('copado__UserStory__r.Name', fflib_QueryFactory.SortOrder.ASCENDING);

        return Database.query(query.toSOQL());
    }
}