@IsTest
private class ApiVersionValidationPackageVersionTest {
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
            Artifact pkg = createPackage('Package_Artifact', pipeline);

            // EXERCISE

            try {
                Test.startTest();
                createPackageVersion(pkg, '54.1').persist();
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
            Artifact pkg = createPackage('Package_Artifact', pipeline);

            // EXERCISE

            try {
                Test.startTest();
                createPackageVersion(pkg, '54').persist();
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
            Artifact pkg = createPackage('Package_Artifact', pipeline);

            // EXERCISE

            try {
                Test.startTest();
                createPackageVersion(pkg, '54.0').persist();
                Test.stopTest();
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY

            Assert.isNull(exceptionMessage, 'Api Version Format validation should not trigger.');
        }
    }

    @IsTest
    private static void otherPlatformValueSuccess() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String exceptionMessage;

            Pipeline pipeline = TestUtilities.createPipeline(TestUtilities.getRepositoryObj(), 'Salesforce');
            Artifact pkg = createPackage('Package_Artifact', pipeline);

            // EXERCISE

            try {
                Test.startTest();
                createPackageVersion(pkg, '54.1').persist();
                Test.stopTest();
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY

            List<copado__Artifact_Version__c> packageVersions = TestUtilities.getPackageVersions();
            Assert.areEqual(1, packageVersions.size(), 'Package should be created');
            Assert.areEqual('54.1', packageVersions[0].Api_Version__c, 'Version Number should be correct');
        }
    }

    @IsTest
    private static void otherRecordTypeValueSuccess() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Pipeline pipeline = TestUtilities.createPipeline(TestUtilities.getRepositoryObj(), 'SFDX');
            Artifact pkg = createPackage('Git_Artifact', pipeline);

            // EXERCISE
            Test.startTest();
            createPackageVersion(pkg, '54.1').persist();
            Test.stopTest();

            // VERIFY

            List<copado__Artifact_Version__c> packageVersions = TestUtilities.getPackageVersions();
            Assert.areEqual(1, packageVersions.size(), 'Package should be created');
            Assert.areEqual('54.1', packageVersions[0].Api_Version__c, 'Version Number should be correct');
        }
    }

    private static void createData() {
        TestUtilities.createRepository();

        Credential cred = TestUtilities.createCredential(true); 
        TestUtilities.createEnvironment('Test Environment').add(cred).persist();
    }

    private static Artifact createPackage(String recordType, Pipeline pipeline) {
        return new Artifact(TestUtilities.getRepositoryObj())
            .name('Testpkg')
            .type('Unlocked')
            .recordTypeId(recordType)
            .targetDevHub(TestUtilities.getCredentialObj(true))
            .apiVersion('54.0')
            .sourceApiVersion('1.0') //this is for Git Package record type
            .pipeline(pipeline);
    }

    private static ArtifactVersion createPackageVersion(Artifact pkg, String apiVersion) {
        return new ArtifactVersion(pkg)
            .name('ver 0.1')
            .versionNumber('0.1.0.1')
            .versionId(fflib_IDGenerator.generate(copado__Artifact_Version__c.SObjectType))
            .apiVersion(apiVersion);
    }
}