@IsTest
public class Project extends DomainBuilder {
    public Project() {
        super(copado__Project__c.SObjectType);
    }

    public Project(Pipeline pip) {
        super(copado__Project__c.SObjectType);
        setParent(copado__Project__c.copado__Deployment_Flow__c, pip);
    }

    public Project name(String name) {
        return (Project) set(copado__Project__c.Name, name);
    }

    public Project recordId(Id recordId) {
        return (Project) set(copado__Project__c.Id, recordId);
    }

    public Project add(Release rel) {
        return (Project) rel.setParent(copado__Release__c.copado__Project__c, this);
    }

     public Project add(UserStory userStory) {
        return (Project) userStory.setParent(copado__User_Story__c.copado__Project__c, this);
    }
}