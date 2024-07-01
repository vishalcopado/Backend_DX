@IsTest
public with sharing class SnapshotCommit extends DomainBuilder {
    public SnapshotCommit() {
        super(copado__Git_Org_Commit__c.SObjectType);
    }

    public SnapshotCommit commitId(String commitId) {
        return (SnapshotCommit) set(copado__Git_Org_Commit__c.copado__Commit_Id__c, commitId);
    }

    public SnapshotCommit commitDate(Date commitDate) {
        return (SnapshotCommit) set(copado__Git_Org_Commit__c.copado__Commit_Date__c, commitDate);
    }

    public SnapshotCommit gitSnapshot(String gitSnapshot) {
        return (SnapshotCommit) set(copado__Git_Org_Commit__c.copado__Git_Backup__c, gitSnapshot);
    }

    public SnapshotCommit status(String status) {
        return (SnapshotCommit) set(copado__Git_Org_Commit__c.copado__Status__c, status);
    }

    public SnapshotCommit credentialId(String credentialId) {
        return (SnapshotCommit) set(copado__Git_Org_Commit__c.copado__Org__c, credentialId);
    }

    public SnapshotCommit gitOperation(string gitOperation) {
        return (SnapshotCommit) set(copado__Git_Org_Commit__c.copado__Git_Operation__c, gitOperation);
    }
}