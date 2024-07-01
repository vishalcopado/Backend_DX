public with sharing class ResultsSelector extends FFLIBExtension {
    // CONSTRUCTOR

    public ResultsSelector() {
        this(true, true);
    }

    public ResultsSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(false, enforceCRUD, enforceFLS, false);
    }

    // PUBLIC

    public SObjectType getSObjectType() {
        return copado__Result__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            copado__Result__c.Id,
            copado__Result__c.Name,
            copado__Result__c.copado__JobStep__c,
            copado__Result__c.copado__Progress_Status__c,
            copado__Result__c.copado__Status__c,
            copado__Result__c.copado__Result_Data__c
        };
    }

    public Map<String, List<Schema.SObjectField>> getSObjectLookupFieldMap() {
        return new Map<String, List<Schema.SObjectField>>{
            'copado__JobStep__r.copado__JobExecution__r' => new List<Schema.SObjectField>{
                copado__JobExecution__c.copado__DataJson__c,
                copado__JobExecution__c.copado__Promotion__c,
                copado__JobExecution__c.copado__Destination__c,
                copado__JobExecution__c.copado__Pipeline__c
            },
            'copado__JobStep__r.copado__JobExecution__r.copado__Deployment__r' => new List<Schema.SObjectField>{
                copado__Deployment__c.copado__Promotion__c
            },
            'copado__JobStep__r.copado__JobExecution__r.copado__Pipeline__c' => new List<Schema.SObjectField>{
                copado__Deployment_Flow__c.Name
            }
        };
    }

    public copado__Result__c byId(Id recordId) {
        List<copado__Result__c> result = byIds(new Set<Id>{ recordId });
        return result.isEmpty() ? null : result[0];
    }

    public List<copado__Result__c> byIds(Set<Id> ids) {
        fflib_QueryFactory query = newQueryFactory().selectField('copado__Error_Message__c').setCondition(copado__Result__c.Id + ' IN :ids');

        setLookupFields(query, 'copado__JobStep__r.copado__JobExecution__r');
        setLookupFields(query, 'copado__JobStep__r.copado__JobExecution__c');
        setLookupFields(query, 'copado__JobStep__r.copado__JobExecution__r.copado__Deployment__r');
        setLookupFields(query, 'copado__JobStep__r.copado__JobExecution__r.copado__Pipeline__c');
        setLookupFields(query, 'copado__JobStep__r.copado__JobExecution__r.copado__Pipeline__r.Name');
        return Database.query(query.toSOQL());
    }

    // Let this method remain specific to Snapshot, we're accessing scope field from Snapshot object which is accessible to users with Git Snapshot Admin permission set.
    public List<copado__Result__c> byIdsForSnapshot(Set<Id> ids) {
        return Database.query(
            newQueryFactory()
                .selectField('copado__JobStep__r.copado__JobExecution__r.copado__Snapshot__r.copado__Scope__c')
                .setCondition(copado__Result__c.Id + ' IN :ids')
                .toSOQL()
        );
    }

    public List<copado__Result__c> byJobExecutionId(Id jobExecutionId) {
        return Database.query(
            newQueryFactory()
                .setCondition('copado__JobStep__r.copado__JobExecution__c = :jobExecutionId')
                .setOrdering('CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING)
                .toSOQL()
        );
    }
}