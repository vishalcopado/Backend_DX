public with sharing class DataSetsSelector extends fflib_SObjectSelector {
    public DataSetsSelector() {
        super(false, true, true);
    }
    public SObjectType getSObjectType() {
        return copado__Data_Set__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{ 
            copado__Data_Set__c.Id, 
            copado__Data_Set__c.Name
        };
    }

    public List<copado__Data_Set__c> byEnabled() {
        return Database.query(
            newQueryFactory()
                .setCondition('copado__MCDD_Enabled__c=true')
                .toSOQL()
        );
    }

    public List<copado__Data_Set__c> byIds(Set<Id> recordIds) {
        fflib_QueryFactory query = newQueryFactory()
            .selectFields(new List<String>{  
                'copado__Source_Org__c',
                'copado__Last_Generated_Date__c',
                'copado__Data_Template__c' })
            .setCondition('Id IN :recordIds');
        return (List<copado__Data_Set__c>) Database.query(query.toSOQL());
    }
}