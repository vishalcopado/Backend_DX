@IsTest
public class DestinationCredential extends DomainBuilder {
    public DestinationCredential(Deployment deployment) {
        super(copado__Destination_Org__c.SObjectType);
        setParent(copado__Destination_Org__c.copado__Deployment__c, deployment);
    }

    public DestinationCredential() {
        this(new Deployment());
    }

    public DestinationCredential destinationOrg(Credential cred) {
        setParent(copado__Destination_Org__c.copado__To_Org__c, cred);
        return this;
    }
}