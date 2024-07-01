@IsTest
public class DomainBuilderTest {
    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
    }

    @IsTest
    private static void addChild() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup

            JobStep step = new JobStep().name('Create Package and Version records.').type('Flow');

            //Exercise

            new JobTemplate().name('SFDX Package Import').add(step).persist();

            // Verify

            System.assertEquals(1, [SELECT COUNT() FROM copado__JobTemplate__c], 'Job template should be inserted');
            System.assertEquals(1, [SELECT COUNT() FROM copado__JobStep__c], 'Job step should be inserted');
        }
    }

    @IsTest
    @SuppressWarnings('PMD.AvoidHardcodingId')
    private static void recordType() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup

            Repository repo = new Repository().name('My Repo');
            Artifact pkg = new Artifact(repo).name('Testpkg').type('Unlocked').packageId('0Ho5g00000000VzCAI').recordTypeId('Package_Artifact');

            //Exercise

            new ArtifactVersion(pkg).name('ver 0.1').versionNumber('0.1.0.1').versionId('04t5g000000xwXMAAY').persist();

            // Verify

            System.assertEquals(1, [SELECT COUNT() FROM copado__Git_Repository__c], 'Repository should be inserted');
            System.assertEquals(1, [SELECT COUNT() FROM copado__Artifact__c], 'Package should be inserted');
            System.assertEquals(1, [SELECT COUNT() FROM copado__Artifact_Version__c], 'Package Version should be inserted');
        }
    }

    @IsTest
    private static void syncOnChange() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup

            TestDomainBuilder cred = new TestDomainBuilder(copado__Org__c.SObjectType)
                .setBooleanField(copado__Org__c.copado__is_Developer_Hub_Org__c, true);

            //Exercise

            new TestDomainBuilder(copado__Environment__c.SObjectType)
                .setField('copado__Platform__c', 'SFDX')
                .setField('copado__Type__c', 'Production/Developer')
                .add(copado__Org__c.copado__Environment__c, cred)
                .syncChange(copado__Environment__c.copado__Type__c, copado__Org__c.copado__Org_Type__c)
                .persist();

            // Verify

            System.assertEquals('Production/Developer', getCredentialType(), 'Credential type should be synced from Environment');
        }
    }

    private static String getCredentialType() {
        String type = [SELECT copado__Org_Type__c FROM copado__Org__c LIMIT 1].copado__Org_Type__c;
        return type;
    }

    private class TestDomainBuilder extends DomainBuilder {
        private TestDomainBuilder(SObjectType type) {
            super(type);
        }

        private TestDomainBuilder syncChange(SObjectField sourceField, SObjectField targetField) {
            return (TestDomainBuilder) syncOnChange(sourceField, this, targetField);
        }

        private TestDomainBuilder setBooleanField(SObjectField field, Boolean value) {
            return (TestDomainBuilder) set(field, value);
        }

        private TestDomainBuilder setField(String field, String value) {
            return (TestDomainBuilder) set(field, value);
        }

        private TestDomainBuilder add(SObjectField field, TestDomainBuilder child) {
            return (TestDomainBuilder) child.setParent(field, this);
        }
    }
}