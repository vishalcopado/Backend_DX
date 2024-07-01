@IsTest
public with sharing class DataTemplate extends DomainBuilder {
    // CONSTRUCTOR

    public DataTemplate() {
        super(copado__Data_Template__c.SObjectType);
    }

    // PUBLIC

    public DataTemplate name(String value) {
        return (DataTemplate) set(copado__Data_Template__c.Name, value);
    }

    public DataTemplate batchSize(Decimal value) {
        return (DataTemplate) set(copado__Data_Template__c.copado__Batch_Size__c, value);
    }

    public DataTemplate templateSourceOrg(Credential value) {
        setParent(copado__Data_Template__c.copado__Template_Source_Org__c, value);
        return this;
    }

    public DataTemplate activate() {
        return (DataTemplate) set(copado__Data_Template__c.copado__Active__c, true);
    }

    public DataTemplate recordId(Id recordId) {
        return (DataTemplate) set(copado__Data_Template__c.Id, recordId);
    }
}