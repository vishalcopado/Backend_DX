@IsTest
public class Promotion extends DomainBuilder {
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public Promotion(Project prj, Credential source, Environment sourceEnv, Credential dest, Environment destEnv) {
        super(copado__Promotion__c.SObjectType);
        setParent(copado__Promotion__c.copado__Project__c, prj);
        setParent(copado__Promotion__c.copado__Source_Org_Credential__c, source);
        setParent(copado__Promotion__c.copado__Source_Environment__c, sourceEnv);
        setParent(copado__Promotion__c.copado__Destination_Org_Credential__c, dest);
        setParent(copado__Promotion__c.copado__Destination_Environment__c, destEnv);

        Pipeline pip = (Pipeline) prj.parentByRelationship.get(copado__Project__c.copado__Deployment_Flow__c);

        new PipelineConnection(pip, sourceEnv, destEnv);
    }

    public Promotion() {
        super(copado__Promotion__c.SObjectType);
    }

    public Promotion recordId(Id value) {
        return (Promotion) set(copado__Promotion__c.Id, value);
    }

    public Promotion testLevel(String value) {
        return (Promotion) set(copado__Promotion__c.Apex_Test_Level__c, value);
    }
}