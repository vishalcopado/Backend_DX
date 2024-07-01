@IsTest
public class Pipeline extends DomainBuilder {
    public Pipeline(Repository rep) {
        super(copado__Deployment_Flow__c.SObjectType);
        set(copado__Deployment_Flow__c.copado__Active__c, true);
        set(copado__Deployment_Flow__c.copado__Main_Branch__c, 'main');
        setParent(copado__Deployment_Flow__c.copado__Git_Repository__c, rep);
    }

    public Pipeline() {
        super(copado__Deployment_Flow__c.SObjectType);
        platform('SFDX');
        active(true);
    }

    public Pipeline platform(String platform) {
        return (Pipeline) set(copado__Deployment_Flow__c.copado__Platform__c, platform);
    }

    public Pipeline add(Project project) {
        return (Pipeline) project.setParent(copado__Project__c.copado__Deployment_Flow__c, this);
    }

    public Pipeline add(PipelineConnection pipelineConnection) {
        return (Pipeline) pipelineConnection.setParent(copado__Deployment_Flow_Step__c.copado__Deployment_Flow__c, this);
    }

    public Pipeline active(Boolean value) {
        return (Pipeline) set(copado__Deployment_Flow__c.copado__Active__c, value);
    }

    public Pipeline repository(Repository value) {
        setParent(copado__Deployment_Flow__c.copado__Git_Repository__c, value);
        return this;
    }

    public Pipeline recordId(Id value) {
        return (Pipeline) set(copado__Deployment_Flow__c.Id, value);
    }

    public Pipeline name(String value) {
        return (Pipeline) set(copado__Deployment_Flow__c.Name, value);
    }

    public Pipeline mainBranch(String value) {
        return (Pipeline) set(copado__Deployment_Flow__c.copado__Main_Branch__c, value);
    }

    public Pipeline initializationData(String value) {
        return (Pipeline) set(copado__Deployment_Flow__c.Initialization_Data__c, value);
    }
}