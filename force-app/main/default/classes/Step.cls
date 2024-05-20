@IsTest
public class Step extends DomainBuilder {
    public Step(Deployment deployment) {
        super(copado__Step__c.SObjectType);
        setParent(copado__Step__c.copado__Deployment__c, deployment);
    }

    public Step() {
        this(new Deployment());
    }

    public Step name(String value) {
        return (Step) set(copado__Step__c.Name, value);
    }

    public Step type(String value) {
        return (Step) set(copado__Step__c.copado__Type__c, value);
    }

    public Step order(Integer value) {
        return (Step) set(copado__Step__c.copado__Order__c, value);
    }
}