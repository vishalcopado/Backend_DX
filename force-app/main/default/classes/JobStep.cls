@IsTest
public class JobStep extends DomainBuilder {
    public JobStep(JobTemplate template) {
        super(copado__JobStep__c.SObjectType);
        setParent(copado__JobStep__c.copado__JobTemplate__c, template);
    }

    public JobStep() {
        this(new JobTemplate());
    }

    public JobStep type(String value) {
        return (JobStep) set(copado__JobStep__c.copado__Type__c, value);
    }

    public JobStep name(String value) {
        return (JobStep) set(copado__JobStep__c.name, value);
    }

    public JobStep execution(JobExecution execution) {
        setParent(copado__JobStep__c.copado__JobExecution__c, execution);
        return this;
    }

    public JobStep recordId(Id value) {
        return (JobStep) set(copado__JobStep__c.Id, value);
    }

    public JobStep userStory(UserStory story) {
        setParent(copado__JobStep__c.copado__UserStory__c, story);
        return this;
    }

    public JobStep order(Integer value) {
        return (JobStep) set(copado__JobStep__c.copado__Order__c, value);
    }

    public JobStep sequence(String value) {
        return (JobStep) set(copado__JobStep__c.copado__ExecutionSequence__c, value);
    }

    public JobStep result(Id result) {
        return (JobStep) set(copado__JobStep__c.copado__Result__c, result);
    }

    public JobStep configJson(String configJson) {
        return (JobStep) set(copado__JobStep__c.copado__ConfigJson__c, configJson);
    }
}