public with sharing class UserStoryDataCommitsSelector extends FflibExtension {
    
    public UserStoryDataCommitsSelector() {
        this(true, true);
    }

    public UserStoryDataCommitsSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(false, enforceCRUD, enforceFLS, false);
    }

    public SObjectType getSObjectType() {
        return copado__User_Story_Data_Commit__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            copado__User_Story_Data_Commit__c.Id,
            copado__User_Story_Data_Commit__c.Name
        };
    }

    public Map<String, List<Schema.SObjectField>> getSObjectLookupFieldMap() {
        return new Map<String, List<Schema.SObjectField>>{
            'copado__Data_Set__r' => new List<Schema.SObjectField>{ 
                copado__Data_Set__c.Id, 
                copado__Data_Set__c.copado__Data_Template__c},
            'copado__Data_Set__r.copado__Data_Template__c' => new List<Schema.SObjectField>{ 
                copado__Data_Template__c.Id 
            }
        }; 
    }
    
    public List<copado__User_Story_Data_Commit__c> byUserStoryIds(Set<Id> userStoryIds) {
        
        fflib_QueryFactory query = newQueryFactory()
            .selectFields(new Set<String>{ 
                'copado__Data_Set__c',
                'copado__User_Story__c',
                'copado__Execution_Job__c',
                'copado__Status__c' })
            .setCondition(copado__User_Story_Data_Commit__c.copado__User_Story__c + ' IN :userStoryIds')
            .setOrdering(copado__User_Story_Data_Commit__c.copado__Commit_Date__c, fflib_QueryFactory.SortOrder.DESCENDING, true);
        setLookupFields(query, 'copado__Data_Set__r');
        setLookupFields(query, 'copado__Data_Set__r.copado__Data_Template__c');

        List<copado__User_Story_Data_Commit__c> result =  Database.query(query.toSOQL());
        return result;
    }

    public List<copado__User_Story_Data_Commit__c> byUserStoryIdAndTemplateId(Id userStoryId, Id dataTemplateId){
        fflib_QueryFactory query = newQueryFactory()
            .selectFields(new Set<String>{ 
                'copado__Data_Set__c',
                'copado__User_Story__c',
                'copado__Execution_Job__c',
                'copado__Status__c' })
            .setCondition('copado__User_Story__c  = :userStoryId AND copado__Data_Set__r.copado__Data_Template__c = :dataTemplateId')
            .setOrdering(copado__User_Story_Data_Commit__c.copado__Commit_Date__c, fflib_QueryFactory.SortOrder.DESCENDING, true);
        setLookupFields(query, 'copado__Data_Set__r');
        setLookupFields(query, 'copado__Data_Set__r.copado__Data_Template__c');

        List<copado__User_Story_Data_Commit__c> result =  Database.query(query.toSOQL());
        return result;
    }
}