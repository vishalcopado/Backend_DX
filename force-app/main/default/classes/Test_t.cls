@IsTest
public class Test_t extends DomainBuilder {
    public Test_t() {
        super(copado__Test__c.SObjectType);
    }

    public Test_t extensionConfiguration(ExtensionConfiguration extensionConfiguration) {
        setParent(copado__Test__c.copado__ExtensionConfiguration__c, extensionConfiguration);
        return this;
    }

    public Test_t userStory(UserStory userStory) {
        setParent(copado__Test__c.copado__User_Story__c, userStory);
        return this;
    }
}