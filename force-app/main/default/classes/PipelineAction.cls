@IsTest
public class PipelineAction extends DomainBuilder {
    public PipelineAction(Pipeline pipeline) {
        super(copado__Pipeline_Action__c.SObjectType);
        set(copado__Pipeline_Action__c.copado__Default__c, true);
        setParent(copado__Pipeline_Action__c.copado__Pipeline__c, pipeline);
    }

    public PipelineAction() {
        this(new Pipeline());
    }

    public PipelineAction action(String value) {
        return (PipelineAction) set(copado__Pipeline_Action__c.copado__Action__c, value);
    }

    public PipelineAction template(JobTemplate value) {
        setParent(copado__Pipeline_Action__c.copado__Job_Template__c, value);
        return this;
    }
}