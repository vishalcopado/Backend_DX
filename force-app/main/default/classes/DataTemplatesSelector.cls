public with sharing class DataTemplatesSelector extends fflib_SObjectSelector {
    public DataTemplatesSelector() {
        super(false, true, true);
    }
    public SObjectType getSObjectType() {
        return copado__Data_Template__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{ copado__Data_Template__c.Id, copado__Data_Template__c.Name };
    }

    public List<copado__Data_Template__c> allActive() {
        return Database.query(
            newQueryFactory()
                .selectField('copado__Batch_Size__c')
                .selectField('copado__Template_Source_Org__r.Name')
                .setCondition('copado__Active__c=true')
                .toSOQL()
        );
    }

    public List<copado__Data_Template__c> byIdSelectedField(Set<Id> recordIds) {
        return (List<copado__Data_Template__c>)Database.query(
            newQueryFactory()
                .selectFields(
                    new List<String>{
                        'copado__Batch_Size__c',
                        'copado__Template_Source_Org__r.Name'
                    }
                )
                .setCondition('id IN : recordIds')
                .toSOQL()
        );
    }
}