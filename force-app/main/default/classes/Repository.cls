@IsTest
public class Repository extends DomainBuilder {

    public Repository() {
        super(copado__Git_Repository__c.SObjectType);
    }

    public Repository name(String value) {
        return (Repository) set(copado__Git_Repository__c.Name, value);
    }

    public Repository recordId(Id recordId){
        return (Repository) set(copado__Git_Repository__c.Id, recordId);
    }

    public Repository uri(String value) {
        return (Repository) set(copado__Git_Repository__c.copado__URI__c, value);
    }
}