@IsTest
public class PipelineConnection extends DomainBuilder {
    public PipelineConnection(Pipeline pip, Environment source, Environment destination) {
        super(copado__Deployment_Flow_Step__c.SObjectType);
        setParent(copado__Deployment_Flow_Step__c.copado__Deployment_Flow__c, pip);
        setParent(copado__Deployment_Flow_Step__c.copado__Source_Environment__c, source);
        setParent(copado__Deployment_Flow_Step__c.copado__Destination_Environment__c, destination);
    }

    public PipelineConnection() {
        super(copado__Deployment_Flow_Step__c.SObjectType);
    }

    public PipelineConnection pipeline(Pipeline value) {
        setParent(copado__Deployment_Flow_Step__c.copado__Deployment_Flow__c, value);
        return this;
    }

    public PipelineConnection sourceEnvironment(Environment value) {
        setParent(copado__Deployment_Flow_Step__c.copado__Source_Environment__c, value);
        return this;
    }
    public PipelineConnection destinationEnvironment(Environment value) {
        setParent(copado__Deployment_Flow_Step__c.copado__Destination_Environment__c, value);
        return this;
    }

    public PipelineConnection destinationBranch(String value) {
        set(copado__Deployment_Flow_Step__c.copado__Destination_Branch__c, value);
        return this;
    }

    public PipelineConnection branch(String value) {
        set(copado__Deployment_Flow_Step__c.copado__Branch__c, value);
        return this;
    }
}