@IsTest
public class ExtensionConfiguration extends DomainBuilder {
    public ExtensionConfiguration() {
        super(copado__ExtensionConfiguration__c.SObjectType);
    }

    public ExtensionConfiguration extensionTool(String tool) {
        return (ExtensionConfiguration) set(copado__ExtensionConfiguration__c.copado__ExtensionTool__c, tool);
    }

    public ExtensionConfiguration phase(String phase) {
        return (ExtensionConfiguration) set(copado__ExtensionConfiguration__c.copado__ExtensionApplication__c, phase);
    }

    public ExtensionConfiguration acceptanceCriteria(String acceptanceCriteria) {
        return (ExtensionConfiguration) set(copado__ExtensionConfiguration__c.copado__AcceptanceCriteria__c, acceptanceCriteria);
    }

    public ExtensionConfiguration activate() {
        return (ExtensionConfiguration) set(copado__ExtensionConfiguration__c.copado__Active__c, true);
    }
}