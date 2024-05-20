@IsTest
public class Artifact extends DomainBuilder {
    public Artifact(Repository rep) {
        super(copado__Artifact__c.SObjectType);
        setParent(copado__Artifact__c.copado__Artifact_Repository__c, rep);
    }

    public Artifact() {
        this(new Repository());
    }

    public Artifact name(String value) {
        return (Artifact) set(copado__Artifact__c.Name, value);
    }

    public Artifact type(String value) {
        return (Artifact) set(copado__Artifact__c.copado__Package_Type__c, value);
    }

    public Artifact packageId(String value) {
        return (Artifact) set(copado__Artifact__c.copado__Package_Id__c, value);
    }

    public Artifact recordTypeId(String value) {
        return (Artifact) recordType(value);
    }

    public Artifact targetDevHub(Credential value) {
        setParent(copado__Artifact__c.copado__Target_Dev_Hub_Org__c, value);
        return this;
    }

    public Artifact branch(String value) {
        return (Artifact) set(copado__Artifact__c.copado__DefaultBranch__c, value);
    }

    public Artifact apiVersion(String value) {
        return (Artifact) set(copado__Artifact__c.Api_Version__c, value);
    }

    public Artifact recordId(Id recordId) {
        return (Artifact) set(copado__Artifact__c.Id, recordId);
    }

    public Artifact pipeline(Pipeline value) {
        setParent(copado__Artifact__c.copado__Pipeline__c, value);
        return this;
    }

    public Artifact noNamespace(Boolean value) {
        return (Artifact) set(copado__Artifact__c.copado__No_Namespace__c, value);
    }

    public Artifact sourceApiVersion(String value) {
        return (Artifact) set(copado__Artifact__c.copado__Source_Api_Version__c, value);
    }
}