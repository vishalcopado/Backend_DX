@IsTest
public class DeploymentJob extends DomainBuilder {
    public DeploymentJob(Step step, DestinationCredential cred) {
        super(copado__Deployment_Job__c.SObjectType);
        setParent(copado__Deployment_Job__c.copado__Step__c, step);
        setParent(copado__Deployment_Job__c.copado__Destination_Org__c, cred);
    }

    public DeploymentJob() {
        this(new Step(), new DestinationCredential());
    }

    public DeploymentJob lastResult(Result result) {
        setParent(copado__Deployment_Job__c.copado__Last_Result__c, result);
        return this;
    }
}