@IsTest
public with sharing class Function extends DomainBuilder {
    // CONSTRUCTOR

    public Function() {
        super(copado__Function__c.SObjectType);
    }

    // PUBLIC

    public Function recordId(Id value) {
        return (Function) set(copado__Function__c.Id, value);
    }

    public Function name(String name) {
        return (Function) set(copado__Function__c.Name, name);
    }

    public Function apiName(String apiName) {
        return (Function) set(copado__Function__c.copado__API_Name__c, apiName);
    }

    public Function script(String value) {
        return (Function) set(copado__Function__c.copado__Script__c, value);
    }

    public Function params(String value) {
        return (Function) set(copado__Function__c.copado__Parameters__c, value);
    }
}