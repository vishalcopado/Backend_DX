@IsTest
public class JobTemplate extends DomainBuilder {
    public JobTemplate() {
        super(copado__JobTemplate__c.SObjectType);
        set(copado__JobTemplate__c.copado__Version__c, 1);
    }

    public JobTemplate name(String value) {
        return (JobTemplate) set(copado__JobTemplate__c.Name, value);
    }

    public JobTemplate add(JobStep step) {
        return (JobTemplate) step.setParent(copado__JobStep__c.copado__JobTemplate__c, this);
    }

    public JobTemplate recordId(Id recordId) {
        return (JobTemplate) set(copado__JobTemplate__c.Id, recordId);
    }

    public JobTemplate type(String value) {
        return (JobTemplate) set(copado__JobTemplate__c.copado__Type__c, value);
    }

    public JobTemplate apiName(String apiName) {
        return (JobTemplate) set(copado__JobTemplate__c.copado__ApiName__c, apiName);
    }
}