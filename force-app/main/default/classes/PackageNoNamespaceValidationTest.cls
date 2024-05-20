@IsTest
private class PackageNoNamespaceValidationTest {
    private static final String NO_NAMESPACE_VALIDATION_ERROR = 'No Namespace cannot be set to true for a Managed package';

    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            setupData();
        }
    }

    @IsTest
    private static void managedWithoutNamespaceFailure() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String exceptionMessage;
            Pipeline pipeline = TestUtilities.createPipeline(TestUtilities.getRepositoryObj(), 'SFDX');

            // EXERCISE

            try {
                Test.startTest();
                createPackage(pipeline, 'Managed', true, 'Package_Artifact').persist();
                Test.stopTest();
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY

            Assert.isTrue(exceptionMessage.contains(NO_NAMESPACE_VALIDATION_ERROR), 'No Namespace validation should be thrown.');
        }
    }

    @IsTest
    private static void unlockedWithNamespaceSuccess() {
        System.runAs(TestUtilities.getRunAsUser()) {
            //SETUP

            Pipeline pipeline = TestUtilities.createPipeline(TestUtilities.getRepositoryObj(), 'SFDX');

            // EXERCISE

            Test.startTest();
            createPackage(pipeline, 'Unlocked', true, 'Package_Artifact').persist();
            Test.stopTest();

            // VERIFY

            List<copado__Artifact__c> pkgs = TestUtilities.getPackages();
            Assert.areEqual(1, pkgs.size(), 'Package should be created');
            Assert.areEqual('Unlocked', pkgs[0].copado__Package_Type__c, 'Package should have correct type');
            Assert.areEqual(true, pkgs[0].copado__No_Namespace__c, 'No namespace should be aligned with Package Type');
        }
    }

    @IsTest
    private static void managedWithNamespaceSuccess() {
        System.runAs(TestUtilities.getRunAsUser()) {
            //SETUP

            Pipeline pipeline = TestUtilities.createPipeline(TestUtilities.getRepositoryObj(), 'SFDX');

            // EXERCISE

            Test.startTest();
            createPackage(pipeline, 'Managed', false, 'Package_Artifact').persist();
            Test.stopTest();

            // VERIFY

            List<copado__Artifact__c> pkgs = TestUtilities.getPackages();
            Assert.areEqual(1, pkgs.size(), 'Package should be created');
            Assert.areEqual('Managed', pkgs[0].copado__Package_Type__c, 'Package should have correct type');
            Assert.areEqual(false, pkgs[0].copado__No_Namespace__c, 'No namespace should be aligned with Package Type');
        }
    }

    @IsTest
    private static void otherRecordTypeSuccess() {
        System.runAs(TestUtilities.getRunAsUser()) {
            //SETUP

            Pipeline pipeline = TestUtilities.createPipeline(TestUtilities.getRepositoryObj(), 'SFDX');

            // EXERCISE

            Test.startTest();
            createPackage(pipeline, 'Managed', true, 'Git_Artifact').persist();
            Test.stopTest();

            // VERIFY

            List<copado__Artifact__c> pkgs = TestUtilities.getPackages();
            Assert.areEqual(1, pkgs.size(), 'Package should be created');
            Assert.areEqual('Managed', pkgs[0].copado__Package_Type__c, 'Package should have correct type');
            Assert.areEqual(true, pkgs[0].copado__No_Namespace__c, 'No namespace should be aligned with Package Type');
        }
    }

    @IsTest
    private static void otherPlatformSuccess() {
        System.runAs(TestUtilities.getRunAsUser()) {
            //SETUP

            Pipeline pipeline = TestUtilities.createPipeline(TestUtilities.getRepositoryObj(), 'Salesforce');

            // EXERCISE

            Test.startTest();
            createPackage(pipeline, 'Managed', true, 'Package_Artifact').persist();
            Test.stopTest();

            // VERIFY

            List<copado__Artifact__c> pkgs = TestUtilities.getPackages();
            Assert.areEqual(1, pkgs.size(), 'Package should be created');
            Assert.areEqual('Managed', pkgs[0].copado__Package_Type__c, 'Package should have correct type');
            Assert.areEqual(true, pkgs[0].copado__No_Namespace__c, 'No namespace should be aligned with Package Type');
        }
    }

    private static void setupData() {
        TestUtilities.createRepository();
        Credential cred = TestUtilities.createCredential(true);
        TestUtilities.createEnvironment('Test Environment').add(cred).persist();
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static Artifact createPackage(Pipeline pipeline, String pkgType, Boolean noNamespace, String recordType) {
        return new Artifact(TestUtilities.getRepositoryObj())
            .name('Test Package')
            .pipeline(pipeline)
            .type(pkgType)
            .recordTypeId(recordType)
            .targetDevHub(TestUtilities.getCredentialObj(true))
            .apiVersion('53.0')
            .sourceApiVersion('1.0') // this is only for Git Package Record Type
            .noNamespace(noNamespace);
    }
}