@IsTest
public class Environment extends DomainBuilder {
    public Environment() {
        super(copado__Environment__c.SObjectType);
        type('Production/Developer');
        platform('SFDX');
    }

    public Environment platform(String platform) {
        return (Environment) set(copado__Environment__c.copado__Platform__c, platform);
    }

    public Environment add(Credential cred) {
        return (Environment) cred.setParent(copado__Org__c.copado__Environment__c, this);
    }

    public Environment type(String value) {
        return (Environment) set(copado__Environment__c.copado__Type__c, value);
    }

    public Environment recordId(Id recordId) {
        return (Environment) set(copado__Environment__c.Id, recordId);
    }

    public Environment runAllLocalTests(Boolean value) {
        return (Environment) set(copado__Environment__c.copado__Run_all_tests__c, value);
    }

    public Environment name(String name) {
        return (Environment) set(copado__Environment__c.Name, name);
    }
}