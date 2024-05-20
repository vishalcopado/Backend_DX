@IsTest
public with sharing class UserStoryMetadata_t extends DomainBuilder {
    //PUBLIC
    
    public UserStoryMetadata_t() {
        super(copado__User_Story_Metadata__c.SObjectType);
    }

    public UserStoryMetadata_t name(String name) {
        return (UserStoryMetadata_t) set(copado__User_Story_Metadata__c.copado__Metadata_API_Name__c, name);
    }

    public UserStoryMetadata_t type(String type) {
        return (UserStoryMetadata_t) set(copado__User_Story_Metadata__c.copado__Type__c, type);
    }

    public UserStoryMetadata_t action(String action) {
        return (UserStoryMetadata_t) set(copado__User_Story_Metadata__c.copado__Action__c, action);
    }

    public UserStoryMetadata_t userStory(UserStory userStory) {
        setParent(copado__User_Story_Metadata__c.copado__User_Story__c, userStory);
        return this;
    }
}