@IsTest
private class ApiVersionValidationPackageTest {
    private static final String API_VERSION_VALIDATION_ERROR = 'The API version specified is not valid. It must be in the format, Number.0';

    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void apiVersionFormatAsDecimalFailure() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String exceptionMessage;
            Pipeline pipeline = TestUtilities.createPipeline(TestUtilities.getRepositoryObj(), 'SFDX');
            // EXERCISE

            try {
                Test.startTest();
                createPackage('Package_Artifact', pipeline, '54.1').persist();
                Test.stopTest();
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY

            Assert.isTrue(exceptionMessage.contains(API_VERSION_VALIDATION_ERROR), 'Api Version Format validation should be thrown.');
        }
    }

    @IsTest
    private static void apiVersionFormatAsIntegerFailure() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String exceptionMessage;
            Pipeline pipeline = TestUtilities.createPipeline(TestUtilities.getRepositoryObj(), 'SFDX');

            // EXERCISE

            try {
                Test.startTest();
                createPackage('Package_Artifact', pipeline, '54').persist();
                Test.stopTest();
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY

            Assert.isTrue(exceptionMessage.contains(API_VERSION_VALIDATION_ERROR), 'Api Version Format validation should be thrown.');
        }
    }

    @IsTest
    private static void apiVersionFormatValidatationSuccess() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String exceptionMessage;
            Pipeline pipeline = TestUtilities.createPipeline(TestUtilities.getRepositoryObj(), 'SFDX');
            // EXERCISE

            try {
                Test.startTest();
                createPackage('Package_Artifact', pipeline, '54.0').persist();
                Test.stopTest();
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY
            Assert.isNull(exceptionMessage, 'Api Version Format validation should not trigger.');
        }
    }

    @IsTest
    private static void otherRecordTypeValueSuccess() {
        System.runAs(TestUtilities.getRunAsUser()) {
            //SETUP

            Pipeline pipeline = TestUtilities.createPipeline(TestUtilities.getRepositoryObj(), 'SFDX');

            // EXERCISE

            Test.startTest();
            createPackage('Git_Artifact', pipeline, '54').persist();
            Test.stopTest();

            // VERIFY

            List<copado__Artifact__c> pkgs = TestUtilities.getPackages();
            Assert.areEqual(1, pkgs.size(), 'Package should be created');
            Assert.areEqual('54', pkgs[0].Api_Version__c, 'Package should have correct API Version.');
        }
    }

    @IsTest
    private static void otherPlatformValueSuccess() {
        System.runAs(TestUtilities.getRunAsUser()) {
            //SETUP

            Pipeline pipeline = TestUtilities.createPipeline(TestUtilities.getRepositoryObj(), 'Salesforce');

            // EXERCISE

            Test.startTest();
            createPackage('Package_Artifact', pipeline, '54').persist();
            Test.stopTest();

            // VERIFY

            List<copado__Artifact__c> pkgs = TestUtilities.getPackages();
            Assert.areEqual(1, pkgs.size(), 'Package should be created');
            Assert.areEqual('54', pkgs[0].Api_Version__c, 'Package should have correct API Version.');
        }
    }

    private static void createData() {
        TestUtilities.createRepository();
        Credential cred = TestUtilities.createCredential(true);
        TestUtilities.createEnvironment('Test Environment').add(cred).persist();
    }

    private static Artifact createPackage(String recordType, Pipeline pipeline, String apiVersion) {
        return new Artifact(TestUtilities.getRepositoryObj())
            .name('Testpkg')
            .type('Unlocked')
            .recordTypeId(recordType)
            .targetDevHub(TestUtilities.getCredentialObj(true))
            .apiVersion(apiVersion)
            .sourceApiVersion('1.0')
            .pipeline(pipeline);
    }
}