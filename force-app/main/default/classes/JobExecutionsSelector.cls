public with sharing class JobExecutionsSelector extends fflib_SObjectSelector {
    // CONSTRUCTOR

    public JobExecutionsSelector() {
        this(true, true);
    }

    public JobExecutionsSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(false, enforceCRUD, enforceFLS, false);
    }

    // PUBLIC

    public SObjectType getSObjectType() {
        return copado__JobExecution__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{ copado__JobExecution__c.Name };
    }

    public List<copado__JobExecution__c> byIds(Set<Id> ids) {
        return Database.query(
            newQueryFactory()
                .selectField('copado__Destination__r.Name')
                .selectField('copado__DataJson__c')
                .selectField('copado__Pipeline__c')
                .selectField('copado__Source__c')
                .selectField('copado__Status__c')
                .selectField('copado__ErrorMessage__c')
                .selectField('copado__Template__r.copado__ApiName__c')
                .setCondition(copado__JobExecution__c.Id + ' IN :ids')
                .toSOQL()
        );
    }

    public List<copado__JobExecution__c> byUserStoryTemplateAndStatus(Id userStoryId, String status, String templateApiName) {
        List<copado__JobExecution__c> result = (List<copado__JobExecution__c>) Database.query(
            newQueryFactory()
                .selectField('copado__UserStoryCommit__c')
                .setCondition(
                    'copado__UserStoryCommit__r.copado__User_Story__c = :userStoryId AND copado__Status__c =: status AND copado__Template__r.copado__ApiName__c =: templateApiName'
                )
                .setOrdering('LastModifiedDate', fflib_QueryFactory.SortOrder.DESCENDING)
                .toSOQL()
        );
        return result;
    }

    public List<copado__JobExecution__c> bySourceTemplateAndStatus(Set<Id> sources, Set<String> templateApiNames, Set<String> statuses) {
        return Database.query(
            newQueryFactory()
                .selectField('copado__DataJson__c')
                .setCondition(
                    'copado__Source__c IN :sources AND copado__Template__r.copado__ApiName__c IN :templateApiNames AND copado__Status__c IN :statuses'
                )
                .toSOQL()
        );
    }

    public copado__JobExecution__c byPromotionId(Id promotionId) {
        List<copado__JobExecution__c> result = (List<copado__JobExecution__c>) Database.query(
            newQueryFactory().selectField('copado__Status__c').setCondition('copado__Promotion__c = :promotionId').toSOQL()
        );

        return (result.isEmpty() ? null : result[0]);
    }

    public List<copado__JobExecution__c> byPipelineActionAndSnapshot(Id pipelineId, String action, Id snapshotId) {
        return Database.query(
            newQueryFactory()
                .selectField('Id')
                .setCondition(
                    'copado__Pipeline__c = :pipelineId AND copado__Template__c IN (SELECT copado__Job_Template__c FROM copado__Pipeline_Action__c WHERE copado__Pipeline__c = :pipelineId AND copado__Action__c = :action) AND copado__Snapshot__c = :snapshotId'
                )
                .setOrdering('CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING)
                .toSOQL()
        );
    }

    public List<copado__JobExecution__c> byIdAndStatus(Id id, String status) {
        return Database.query(
            newQueryFactory()
                .selectField('copado__ErrorMessage__c')
                .setCondition('copado__JobExecution__c.Id = :id AND copado__Status__c = :status')
                .toSOQL()
        );
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    public List<copado__JobExecution__c> byTemplateAndPipelineAndSourceAndStatus(String templateName, Id pipelineId, Id sourceId, String status) {
        return Database.query(
            newQueryFactory()
                .selectField('copado__DataJson__c')
                .selectField('copado__Template__r.copado__ApiName__c')
                .selectField('copado__Pipeline__c')
                .selectField('copado__Source__c')
                .setCondition(
                    'copado__Template__r.copado__ApiName__c = :templateName AND copado__Pipeline__c = :pipelineId AND copado__Source__c = :sourceId AND copado__Status__c = :status'
                )
                .toSOQL()
        );
    }
}