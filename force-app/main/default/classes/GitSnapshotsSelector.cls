public with sharing class GitSnapshotsSelector extends fflib_SObjectSelector {
    // CONSTRUCTOR

    public GitSnapshotsSelector() {
        this(true, true);
    }

    public GitSnapshotsSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(false, enforceCRUD, enforceFLS, false);
    }

    // PUBLIC

    public SObjectType getSObjectType() {
        return copado__Git_Backup__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            copado__Git_Backup__c.Id,
            copado__Git_Backup__c.Name
        };
    }

    @SuppressWarnings('PMD.UnusedLocalVariable')
    public List<copado__Git_Backup__c> byPipelineBranchRepoAndCredential(copado__Deployment_Flow__c pipeline, Id credentialId) {
        Id pipelineId = pipeline.Id;
        String branch = pipeline.copado__Main_Branch__c;
        Id repositoryId = pipeline.copado__Git_Repository__c;

        return Database.query(
            newQueryFactory()
                .selectField('Id')
                .setCondition('copado__Pipeline__c =: pipelineId AND copado__Branch__c =: branch AND copado__Git_Repository__c =: repositoryId AND copado__Org__c =: credentialId')
                .setOrdering('CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING)
                .toSOQL()
        );
    }
}