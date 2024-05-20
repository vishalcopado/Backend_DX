@IsTest
public with sharing class UserStoryCommit_t extends DomainBuilder {
    public UserStoryCommit_t(SnapshotCommit snapshotCommit) {
        super(copado__User_Story_Commit__c.SObjectType);
        setParent(copado__User_Story_Commit__c.copado__Snapshot_Commit__c, snapshotCommit);
    }

    public UserStoryCommit_t userStoryId(String userStoryId) {
        return (UserStoryCommit_t) set(copado__User_Story_Commit__c.copado__User_Story__c, userStoryId);
    }
}