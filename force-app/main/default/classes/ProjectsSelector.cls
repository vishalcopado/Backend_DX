public with sharing class ProjectsSelector extends fflib_SObjectSelector {
    // CONSTRUCTOR

    public ProjectsSelector() {
        this(true, true);
    }

    public ProjectsSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(false, enforceCRUD, enforceFLS, false);
    }

    // PUBLIC

    public SObjectType getSObjectType() {
        return copado__Project__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{ copado__Project__c.Name };
    }

    public List<copado__Project__c> byIds(Set<Id> ids) {
        return Database.query(
            newQueryFactory().selectField('copado__Deployment_Flow__r.Name').setCondition(copado__Project__c.Id + ' IN :ids').toSOQL()
        );
    }

    public List<copado__Project__c> byActivePipelineRepoAndPlatform(Set<String> platforms) {
        return Database.query(
            newQueryFactory()
                .selectFields(pipelineFields())
                .setCondition(
                    'copado__Deployment_Flow__r.copado__Active__c = TRUE AND copado__Deployment_Flow__r.copado__Git_Repository__c != null AND copado__Deployment_Flow__r.copado__Platform__c IN: platforms'
                )
                .toSOQL()
        );
    }

    public List<copado__Project__c> byActivePipelineIdsAndName(Set<Id> pipelineIds, Set<String> projectNames) {
        return Database.query(
            newQueryFactory()
                .selectFields(pipelineFields())
                .setCondition(
                    'copado__Deployment_Flow__r.copado__Active__c = TRUE AND copado__Deployment_Flow__c IN: pipelineIds AND Name IN: projectNames'
                )
                .toSOQL()
        );
    }

    // PRIVATE

    private Set<String> pipelineFields() {
        return new Set<String>{
            'copado__Deployment_Flow__r.Name',
            'copado__Deployment_Flow__r.copado__Git_Repository__r.Name',
            'copado__Deployment_Flow__r.copado__Main_Branch__c',
            'copado__Deployment_Flow__r.copado__Enable_Copado_DX__c'
        };
    }
}