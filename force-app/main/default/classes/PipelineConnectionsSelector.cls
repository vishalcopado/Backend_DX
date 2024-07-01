public with sharing class PipelineConnectionsSelector extends fflib_SObjectSelector {
    // CONSTRUCTOR

    public PipelineConnectionsSelector() {
        this(true, true);
    }

    public PipelineConnectionsSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(false, enforceCRUD, enforceFLS, false);
    }

    // PUBLIC

    public SObjectType getSObjectType() {
        return copado__Deployment_Flow_Step__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{ copado__Deployment_Flow_Step__c.Name };
    }

    public List<copado__Deployment_Flow_Step__c> byPipelineAndSourceEnv(Set<Id> pipelineIds, Set<Id> sourceEnvIds) {
        return Database.query(
            newQueryFactory()
                .selectField('copado__Destination_Environment__r.Name')
                .setCondition(copado__Deployment_Flow_Step__c.copado__Deployment_Flow__c + ' IN :pipelineIds')
                .setCondition(copado__Deployment_Flow_Step__c.copado__Source_Environment__c + ' IN :sourceEnvIds')
                .toSOQL()
        );
    }

    public List<copado__Deployment_Flow_Step__c> byPipelineAndSourceEnvAndDestinationEnv(
        Set<Id> pipelineIds,
        Set<Id> sourceEnvIds,
        Set<Id> destinationEnvIds
    ) {
        return Database.query(
            newQueryFactory()
                .selectField(copado__Deployment_Flow_Step__c.copado__Destination_Branch__c)
                .selectField(copado__Deployment_Flow_Step__c.copado__Branch__c)
                .setCondition(
                    'copado__Deployment_Flow__c IN :pipelineIds AND copado__Source_Environment__c IN :sourceEnvIds AND copado__Destination_Environment__c IN :destinationEnvIds'
                )
                .toSOQL()
        );
    }

    public List<copado__Deployment_Flow_Step__c> byPipelineAndSourceEnvironment(
        Set<Id> pipelineIds,
        Set<Id> sourceEnvironmentIds
    ) {
        return Database.query(
            newQueryFactory()
                .selectField('copado__Branch__c')
                .selectField('copado__Destination_Branch__c')
                .selectField('copado__Destination_Environment__r.Name')
                .setCondition(
                    'copado__Deployment_Flow__c IN :pipelineIds AND copado__Source_Environment__c IN :sourceEnvironmentIds'
                )
                .toSOQL()
        );
    }

    public List<copado__Deployment_Flow_Step__c> byPipelineIds(Set<Id> pipelineIds) {
        return Database.query(
            newQueryFactory()
                .selectField('copado__Source_Environment__c')
                .setCondition(copado__Deployment_Flow_Step__c.copado__Deployment_Flow__c + ' IN :pipelineIds')
                .toSOQL()
        );
    }

    public List<copado__Deployment_Flow_Step__c> byPipelineId(Id pipelineId) {
        return Database.query(
            newQueryFactory()
                .selectField('copado__Source_Environment__c')
                .selectField('copado__Source_Environment__r.Name')
                .selectField('copado__Destination_Environment__c')
                .selectField('copado__Destination_Environment__r.Name')
                .selectField('copado__Branch__c')
                .selectField('copado__Destination_Branch__c')
                .setCondition(copado__Deployment_Flow_Step__c.copado__Deployment_Flow__c + '= :pipelineId')
                .toSOQL()
        );
    }
}