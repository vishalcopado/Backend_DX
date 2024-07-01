public with sharing class PipelineActionSelector extends fflib_SObjectSelector {
    // CONSTRUCTOR

    public PipelineActionSelector() {
        this(true, true);
    }

    public PipelineActionSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(false, enforceCRUD, enforceFLS, false);
    }

    // PUBLIC

    public SObjectType getSObjectType() {
        return copado__Pipeline_Action__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            copado__Pipeline_Action__c.Name,
            copado__Pipeline_Action__c.copado__Default__c,
            copado__Pipeline_Action__c.copado__Environment__c
        };
    }

    public List<copado__Pipeline_Action__c> byPipelineAndAction(Set<Id> pipelineIds, Set<String> actionApiNames) {
        return Database.query(
            newQueryFactory()
                .selectField('copado__Job_Template__r.copado__ApiName__c')
                .setCondition('copado__Pipeline__c IN :pipelineIds AND copado__Action__c IN :actionApiNames')
                .setOrdering('copado__Default__c', fflib_QueryFactory.SortOrder.ASCENDING)
                .addOrdering('copado__Environment__c', fflib_QueryFactory.SortOrder.ASCENDING, true)
                .toSOQL()
        );
    }
}