@IsTest
public class DeploymentTask extends DomainBuilder {
    public DeploymentTask() {
        super(copado__Deployment_Task__c.SObjectType);
    }

    public DeploymentTask name(String value) {
        return (DeploymentTask) set(copado__Deployment_Task__c.Name, value);
    }

    public DeploymentTask userStory(UserStory story) {
        setParent(copado__Deployment_Task__c.copado__User_Story__c, story);
        return this;
    }

    public DeploymentTask type(String value) {
        return (DeploymentTask) set(copado__Deployment_Task__c.copado__Type__c, value);
    }

    public DeploymentTask sequence(String value) {
        return (DeploymentTask) set(copado__Deployment_Task__c.copado__Perform_Manual_Task__c, value);
    }

    public DeploymentTask order(Integer value) {
        return (DeploymentTask) set(copado__Deployment_Task__c.copado__Order__c, value);
    }
}