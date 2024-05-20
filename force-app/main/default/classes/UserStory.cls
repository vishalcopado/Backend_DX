@IsTest
public class UserStory extends DomainBuilder {
    public UserStory() {
        super(copado__User_Story__c.SObjectType);
    }

    public UserStory title(String title) {
        return (UserStory) set(copado__User_Story__c.copado__User_Story_Title__c, title);
    }

    public UserStory status(String status) {
        return (UserStory) set(copado__User_Story__c.copado__Status__c, status);
    }

    public UserStory credential(Credential credential) {
        setParent(copado__User_Story__c.copado__Org_Credential__c, credential);
        return this;
    }
    
    public UserStory project(Project project) {
        setParent(copado__User_Story__c.copado__Project__c, project);
        return this;
    }

    public UserStory recordId(Id recordId) {
        return (UserStory) set(copado__User_Story__c.Id, recordId);
    }
}