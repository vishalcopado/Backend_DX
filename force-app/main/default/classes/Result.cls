@IsTest
public class Result extends DomainBuilder {
    public Result(JobStep step) {
        super(copado__Result__c.SObjectType);
        setParent(copado__Result__c.copado__JobStep__c, step);
    }
    public Result() {
        super(copado__Result__c.SObjectType);
    }

    public Result type(String value) {
        return (Result) set(copado__Result__c.copado__Job_Type__c, value);
    }

    public Result data(String value) {
        return (Result) set(copado__Result__c.copado__Result_Data__c, value);
    }

    public Result recordId(Id value) {
        return (Result) set(copado__Result__c.Id, value);
    }

    public Result error(String value) {
        return (Result) set(copado__Result__c.copado__Error_Message__c, value);
    }
    public Result status(String value) {
        return (Result) set(copado__Result__c.copado__Status__c, value);
    }

    public Result contextId(String value) {
        return (Result) set(copado__Result__c.copado__ParentId__c, value);
    }

    public Result functionId(String value) {
        return (Result) set(copado__Result__c.copado__Function__c, value);
    }

    public Result function(Function value) {
        setParent(copado__Result__c.copado__Function__c, value);
        return this;
    }

    public Result test(Test_t test) {
        setParent(copado__Result__c.copado__Test__c, test);
        return this;
    }

    public Result setContext(Credential value) {
        setParent(copado__Result__c.copado__ParentId__c, value);
        return this;
    }
}