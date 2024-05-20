@IsTest
public class Deployment extends DomainBuilder {
    public Deployment(Credential cred) {
        super(copado__Deployment__c.SObjectType);
        setParent(copado__Deployment__c.copado__From_Org__c, cred);
    }

    public Deployment() {
        this(new Credential());
    }

    public Deployment name(String value) {
        return (Deployment) set(copado__Deployment__c.Name, value);
    }
}