@IsTest
public class SystemProperty extends DomainBuilder {
    public SystemProperty(Pipeline pipeline) {
        super(copado__System_Property__c.SObjectType);
        setParent(copado__System_Property__c.copado__Pipeline__c, pipeline);
    }

    public SystemProperty(Environment environment) {
        super(copado__System_Property__c.SObjectType);
        setParent(copado__System_Property__c.copado__Environment__c, environment);
    }

    public SystemProperty() {
        this(new Pipeline());
    }

    public SystemProperty apiName(String value) {
        return (SystemProperty) set(copado__System_Property__c.copado__API_Name__c, value);
    }

    public SystemProperty value(String value) {
        return (SystemProperty) set(copado__System_Property__c.copado__Value__c, value);
    }

    public SystemProperty isGlobal(Boolean value) {
        return (SystemProperty) set(copado__System_Property__c.copado__Is_Global__c, value);
    }
}