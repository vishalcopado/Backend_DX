@IsTest
private class PackageVersionTagValidationTest {
    private static final String TAG_RESTRICTION_VALIDATION_ERROR = 'The Tag field is used to create a Git tag during package version creation. Ensure there are no spaces or character sequences that are not allowed for the Git tag. For more details, review the Git documentation https://git-scm.com/docs/git-check-ref-format';

    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            setupData();
        }
    }

    @IsTest
    private static void invalidTagFailure() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            List<String> exceptionMessages = new List<String>();

            Pipeline pipeline = TestUtilities.createPipeline(TestUtilities.getRepositoryObj(), 'SFDX');
            createPackage(pipeline, 'Package_Artifact', TestUtilities.getCredentialObj(true)).persist();

            List<String> invalidTags = new List<String>{
                'tag with space',
                'tagwith*',
                'TagWith/',
                'tagWith^',
                'tagWith~',
                'tagWith:',
                'tagwith?',
                'tagWith[',
                'tagwith\\slash',
                'TagWith//notAllowed',
                '/Tag',
                'TagEnding/',
                'TagEndingWith.',
                'Tag..',
                'Tag@{sequence'
            };

            // EXERCISE

            try {
                Test.startTest();
                for (String invalidTag : invalidTags) {
                    createPackageVersion(TestUtilities.getPackageObj(), 'tag here with spaces');
                }
                Test.stopTest();
            } catch (Exception ex) {
                exceptionMessages.add(ex.getMessage());
            }

            // VERIFY

            for (String ex : exceptionMessages) {
                Assert.isTrue(ex.contains(TAG_RESTRICTION_VALIDATION_ERROR), 'Tag restriction validation should be thrown for input : ' + ex);
            }
        }
    }

    @IsTest
    private static void otherPlatformValueSuccess() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Pipeline pipe = TestUtilities.createPipeline(TestUtilities.getRepositoryObj(), 'Salesforce');
            Artifact pkg = createPackage(pipe, 'Package_Artifact', TestUtilities.getCredentialObj(true));

            // EXERCISE

            Test.startTest();
            createPackageVersion(pkg, 'Tag with ? special chars^').persist();
            Test.stopTest();

            // VERIFY

            List<copado__Artifact_Version__c> packageVersions = TestUtilities.getPackageVersions();
            Assert.areEqual(1, packageVersions.size(), 'Package Version should be created');
            Assert.areEqual('Tag with ? special chars^', packageVersions[0].copado__Tag__c, 'Tag should be correct');
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
            createPackageVersion(pkg, 'tag here with spaces').persist();
            Test.stopTest();

            // VERIFY

            List<copado__Artifact_Version__c> packageVersions = TestUtilities.getPackageVersions();
            Assert.areEqual(1, packageVersions.size(), 'Package Version should be created');
            Assert.areEqual('tag here with spaces', packageVersions[0].copado__Tag__c, 'Tag should be correct');
        }
    }

    @IsTest
    private static void validTagSuccess() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Pipeline pipe = TestUtilities.createPipeline(TestUtilities.getRepositoryObj(), 'SFDX');
            Artifact pkg = createPackage(pipe, 'Package_Artifact', TestUtilities.getCredentialObj(true));

            // EXERCISE

            Test.startTest();
            createPackageVersion(pkg, 'PackageName@1.1.1-0-master').persist();
            Test.stopTest();

            // VERIFY

            List<copado__Artifact_Version__c> packageVersions = TestUtilities.getPackageVersions();
            Assert.areEqual(1, packageVersions.size(), 'Package Version should be created');
            Assert.areEqual('PackageName@1.1.1-0-master', packageVersions[0].copado__Tag__c, 'Tag should be correct');
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
            .recordTypeId(recordType)
            .targetDevHub(cred)
            .apiVersion('53.0')
            .sourceApiVersion('1.0'); // this is only for Git Package Record Type
    }

    private static ArtifactVersion createPackageVersion(Artifact pkg, String tag) {
        return new ArtifactVersion(pkg)
            .name('ver 0.1')
            .versionNumber('0.1.0.1')
            .versionId(fflib_IDGenerator.generate(copado__Artifact_Version__c.SObjectType))
            .tag(tag);
    }
}