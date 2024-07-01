@IsTest
public class JobExecution extends DomainBuilder {
    public JobExecution(JobTemplate template, Environment env) {
        super(copado__JobExecution__c.SObjectType);
        setParent(copado__JobExecution__c.copado__Template__c, template);
        setParent(copado__JobExecution__c.copado__Destination__c, env);
    }

    public JobExecution(JobTemplate template) {
        super(copado__JobExecution__c.SObjectType);
        setParent(copado__JobExecution__c.copado__Template__c, template);
    }

    public JobExecution() {
        this(new JobTemplate(), new Environment());
    }

    public JobExecution recordId(Id value) {
        return (JobExecution) set(copado__JobExecution__c.Id, value);
    }

    public JobExecution dataJSON(String value) {
        return (JobExecution) set(copado__JobExecution__c.copado__DataJson__c, value);
    }

    public JobExecution status(String value) {
        return (JobExecution) set(copado__JobExecution__c.copado__Status__c, value);
    }

    public JobExecution errorMessage(String value) {
        return (JobExecution) set(copado__JobExecution__c.copado__ErrorMessage__c, value);
    }

    public JobExecution add(JobStep step) {
        return (JobExecution) step.setParent(copado__JobStep__c.copado__JobExecution__c, this);
    }

    public JobExecution pipeline(Pipeline value) {
        setParent(copado__JobExecution__c.copado__Pipeline__c, value);
        return this;
    }

    public JobExecution source(Environment value) {
        setParent(copado__JobExecution__c.copado__Source__c, value);
        return this;
    }

    public JobExecution destination(Environment value) {
        setParent(copado__JobExecution__c.copado__Destination__c, value);
        return this;
    }

    public JobExecution promotion(Promotion value) {
        setParent(copado__JobExecution__c.copado__Promotion__c, value);
        return this;
    }

    public JobExecution snapshot(Snapshot value) {
        setParent(copado__JobExecution__c.copado__Snapshot__c, value);
        return this;
    }

    public JobExecution userStoryCommit(UserStoryCommit_t value) {
        setParent(copado__JobExecution__c.copado__UserStoryCommit__c, value);
        return this;
    }
}