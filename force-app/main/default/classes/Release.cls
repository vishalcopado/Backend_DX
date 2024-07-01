@IsTest
public class Release extends DomainBuilder {

    public Release() {
        super(copado__Release__c.SObjectType);
    }

    public Release name(String value) {
        return (Release) set(copado__Release__c.Name, value);
    }

    public Release baseBranch(String value) {
        return (Release) set(copado__Release__c.copado__Base_Branch__c, value);
    }

    public Release description(String value) {
        return (Release) set(copado__Release__c.copado__Description__c, value);
    }

    public Release status(String value) {
        return (Release) set(copado__Release__c.copado__Status__c, value);
    }
}