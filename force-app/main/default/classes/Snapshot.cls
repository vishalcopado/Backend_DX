@IsTest
public class Snapshot extends DomainBuilder {
    public Snapshot(Credential cred, Pipeline pipeline, Repository repo) {
        super(copado__Git_Backup__c.SObjectType);
        setParent(copado__Git_Backup__c.copado__Git_Repository__c, repo);
        setParent(copado__Git_Backup__c.copado__Org__c, cred);
        setParent(copado__Git_Backup__c.copado__Pipeline__c, pipeline);
    }

    public Snapshot() {
        super(copado__Git_Backup__c.SObjectType);
    }

    public Snapshot recordId(Id value) {
        return (Snapshot) set(copado__Git_Backup__c.Id, value);
    }

    public Snapshot scope(String value) {
        return (Snapshot) set(copado__Git_Backup__c.copado__Scope__c, value);
    }

    public Snapshot branch(String value) {
        return (Snapshot) set(copado__Git_Backup__c.copado__Branch__c, value);
    }

    public Snapshot frequency(String value) {
        return (Snapshot) set(copado__Git_Backup__c.copado__Snapshot_Frequency__c, value);
    }
}