@IsTest
private class VersionFormatValidationTest {
    private static final String VERSION_NUMBER_VALIDATION_ERROR = 'The Package version number specified is not valid. It must be in the format,  {whole number}.{whole number}.{whole number}.{whole number} or {whole number}.{whole number}.{whole number}.NEXT';

    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            setupData();
        }
    }

    @IsTest
    private static void invalidVersionNumbersFailure() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            List<String> exceptionMessages = new List<String>();
            Pipeline pipeline = TestUtilities.createPipeline(TestUtilities.getRepositoryObj(), 'SFDX');
            Artifact pkg = createPackage(pipeline, 'Package_Artifact', TestUtilities.getCredentialObj(true));

            List<String> invalidVersionNumbers = new List<String>{
                '12.3.4.10.1',
                '13.XX.00.NEXT',
                '01.00.NEXT.NEXT',
                '8,9,9.10',
                '10.0.0.next',
                '234.234.234.LATEST'
            };
            // EXERCISE

            try {
                Test.startTest();
                for (String invalidInput : invalidVersionNumbers) {
                    createPackageVersion(pkg, invalidInput).persist();
                }
                Test.stopTest();
            } catch (Exception ex) {
                exceptionMessages.add(ex.getMessage());
            }

            // VERIFY

            for (String ex : exceptionMessages) {
                Assert.isTrue(ex.contains(VERSION_NUMBER_VALIDATION_ERROR), 'Version Number validation should be thrown for input : ' + ex);
            }
        }
    }

    @IsTest
    private static void otherRecordTypeValueSuccess() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Pipeline pipeline = TestUtilities.createPipeline(TestUtilities.getRepositoryObj(), 'SFDX');
            Artifact pkg = createPackage(pipeline, 'Git_Artifact', TestUtilities.getCredentialObj(true));

            // EXERCISE

            Test.startTest();
            createPackageVersion(pkg, '12.0.0.10.ABC.XYZ').persist();
            Test.stopTest();

            // VERIFY

            List<copado__Artifact_Version__c> packageVersions = TestUtilities.getPackageVersions();
            Assert.areEqual(1, packageVersions.size(), 'Package Version should be created');
            Assert.areEqual('12.0.0.10.ABC.XYZ', packageVersions[0].copado__Version_number__c, 'Version Number should be correct');
        }
    }

    @IsTest
    private static void otherPlatformValueSuccess() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Pipeline pipeline = TestUtilities.createPipeline(TestUtilities.getRepositoryObj(), 'Salesforce');
            Artifact pkg = createPackage(pipeline, 'Package_Artifact', TestUtilities.getCredentialObj(true));

            // EXERCISE

            Test.startTest();
            createPackageVersion(pkg, '12.0.0.10.1').persist();
            Test.stopTest();

            // VERIFY

            List<copado__Artifact_Version__c> packageVersions = TestUtilities.getPackageVersions();
            Assert.areEqual(1, packageVersions.size(), 'Package Version should be created');
            Assert.areEqual('12.0.0.10.1', packageVersions[0].copado__Version_number__c, 'Version Number should be correct');
        }
    }

    @IsTest
    private static void validVersionNumberSuccess() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Pipeline pipeline = TestUtilities.createPipeline(TestUtilities.getRepositoryObj(), 'SFDX');
            Artifact pkg = createPackage(pipeline, 'Package_Artifact', TestUtilities.getCredentialObj(true));

            // EXERCISE

            Test.startTest();
            createPackageVersion(pkg, '12.3.4.10').persist();

            Test.stopTest();

            // VERIFY

            List<copado__Artifact_Version__c> packageVersions = TestUtilities.getPackageVersions();
            Assert.areEqual(1, packageVersions.size(), 'Package Version should be created');
            Assert.areEqual('12.3.4.10', packageVersions[0].copado__Version_number__c, 'Version Number should be correct');
        }
    }

    private static void setupData() {
        TestUtilities.createRepository();

        Credential cred = TestUtilities.createCredential(true);
        TestUtilities.createEnvironment('Test Environment').add(cred).persist();
    }

    private static Artifact createPackage(Pipeline pipeline, String recordType, Credential cred) {
        return new Artifact(TestUtilities.getRepositoryObj())
            .name('Test Package')
            .pipeline(pipeline)
            .type('Managed')
            .recordTypeId(recordType)
            .targetDevHub(TestUtilities.getCredentialObj(true)) 
            .apiVersion('53.0')
            .sourceApiVersion('1.0') // this is only for Git Package Record Type
            .noNamespace(false);
    }

    private static ArtifactVersion createPackageVersion(Artifact pkg, String versionNumber) {
        return new ArtifactVersion(pkg)
            .name('ver 0.1')
            .versionNumber(versionNumber)
            .versionId(fflib_IDGenerator.generate(copado__Artifact_Version__c.SObjectType));
    }
}