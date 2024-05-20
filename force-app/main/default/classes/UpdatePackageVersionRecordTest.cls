@IsTest
private class UpdatePackageVersionRecordTest {
    private static final String PUBLISHED_STATUS = 'Published';
    private static final String PRE_RELEASE_STATUS = 'Pre-Release';
    private static final String DRAFT_STATUS = 'Draft';
    private static final String SALESFORCE_PACKAGE_RECORD_TYPE = 'Package_Artifact';

    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void insertReleasedVersion() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Artifact pkg = createPackage(getRepositoryObj(), 'Unlocked', getCredentialObj(), SALESFORCE_PACKAGE_RECORD_TYPE);

            // EXERCISE

            createPackageVersion(pkg, true, createFakeId('04t')).persist();

            // VERIFY

            System.assertEquals(PUBLISHED_STATUS, getPackageVersion()[0].copado__Status__c, 'Status should be Published.');
        }
    }

    @IsTest
    private static void insertPreReleasedVersion() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Artifact pkg = createPackage(getRepositoryObj(), 'Unlocked', getCredentialObj(), SALESFORCE_PACKAGE_RECORD_TYPE);

            // EXERCISE

            createPackageVersion(pkg, false, createFakeId('04t')).persist();

            // VERIFY

            System.assertEquals(PRE_RELEASE_STATUS, getPackageVersion()[0].copado__Status__c, 'Status should be Pre-Release.');
        }

    }

    @IsTest
    private static void insertVersionWithDefaultValues() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Artifact pkg = createPackage(getRepositoryObj(), 'Unlocked', getCredentialObj(), SALESFORCE_PACKAGE_RECORD_TYPE);

            // EXERCISE

            createPackageVersion(pkg, false, null).persist();

            // VERIFY

            System.assertEquals(DRAFT_STATUS, getPackageVersion()[0].copado__Status__c, 'Default Status should be Draft.');
            System.assertEquals('master', getPackageVersion()[0].copado__Branch__c, 'Branch should be same as Package Branch.');
        }
    }

    @IsTest
    private static void updateVersionStatusToPreRelease() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Artifact pkg = createPackage(getRepositoryObj(), 'Unlocked', getCredentialObj(), SALESFORCE_PACKAGE_RECORD_TYPE);
            createPackageVersion(pkg, false, null).persist();
            copado__Artifact_Version__c version = getPackageVersion()[0];
            version.copado__Is_released__c = false;
            version.copado__Subscriber_Version_Id__c = createFakeId('04t');

            // EXERCISE

            update version;

            // VERIFY

            System.assertEquals(PRE_RELEASE_STATUS, getPackageVersion()[0].copado__Status__c, 'Default Status should be Pre-Release.');
        }
    }

    @IsTest
    private static void updateVersionStatusToPublished() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Artifact pkg = createPackage(getRepositoryObj(), 'Unlocked', getCredentialObj(), SALESFORCE_PACKAGE_RECORD_TYPE);
            createPackageVersion(pkg, false, null).persist();
            copado__Artifact_Version__c version = getPackageVersion()[0];
            version.copado__Is_released__c = true;

            // EXERCISE

            update version;

            // VERIFY

            System.assertEquals(PUBLISHED_STATUS, getPackageVersion()[0].copado__Status__c, 'Default Status should be Published.');
        }
    }

    @IsTest
    private static void beforeInsertNotSalesforcePackageRecordType() {
        System.runAs(TestUtilities.getRunAsUser()) {
            System.runAs(TestUtilities.getRunAsUser()) {
                // SETUP

                Artifact pkg = createPackage(getRepositoryObj(), 'Unlocked', getCredentialObj(), 'User_Story_Bundle');

                // EXERCISE

                createPackageVersion(pkg, false, null).persist();

                // VERIFY

                System.assertNotEquals(
                    DRAFT_STATUS,
                    getPackageVersion()[0].copado__Status__c,
                    'Status will not change to Draft as default for record type User Story Bundle.'
                );
            }
        }
    }

    @IsTest
    private static void consumingBranchFromVersion(){
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Artifact pkg = createPackage(getRepositoryObj(), 'Unlocked', getCredentialObj(), SALESFORCE_PACKAGE_RECORD_TYPE);

            // EXERCISE

            ArtifactVersion version = createPackageVersion(pkg, false, null);
            version.branch('dev').persist();

            // VERIFY

            System.assertEquals('dev', getPackageVersion()[0].copado__Branch__c, 'Branch should not be overriden with the package branch.');
        }
    }


    private static void createData() {
        Repository repo = createRepository();
        Credential cred = createCredential(true);

        createPipeline(repo, 'SFDX');
        createEnvironment().add(cred).persist();
    }

    private static Repository createRepository() {
        return new Repository().name('My Repo');
    }

    private static Pipeline createPipeline(Repository repo, String platform) {
        return new Pipeline(repo).platform(platform);
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static Artifact createPackage(Repository repo, String type, Credential cred, String developerName) {
        return new Artifact(repo).name('Testpkg').type(type).recordTypeId(developerName).targetDevHub(cred).branch('master');
    }

    private static ArtifactVersion createPackageVersion(Artifact pkg, Boolean isReleased, Id subscriberId) {
        return new ArtifactVersion(pkg).name('ver 0.1').versionNumber('0.1.0.1').isReleased(isReleased).subscriberId(subscriberId);
    }

    private static Environment createEnvironment() {
        return new Environment().platform('SFDX').type('Production/Developer');
    }

    private static Credential createCredential(Boolean isDevHub) {
        return new Credential().devhub(isDevHub).type('Production/Developer');
    }

    private static List<copado__Artifact_Version__c> getPackageVersion() {
        List<copado__Artifact_Version__c> versions = [
            SELECT
                Id,
                copado__Artifact__r.copado__Target_Dev_Hub_Org__r.copado__Environment__c,
                copado__Artifact__r.copado__Pipeline__c,
                copado__LastJobExecutionId__c,
                copado__Subscriber_Version_Id__c,
                copado__Is_released__c,
                copado__Status__c,
                copado__Branch__c
            FROM copado__Artifact_Version__c
        ];

        return versions;
    }

    private static Id createFakeId(String keyPrefix) {
        return fflib_IDGenerator.generate(keyPrefix);
    }

    private static Repository getRepositoryObj() {
        return new Repository().recordId(getRepository().Id);
    }

    private static copado__Git_Repository__c getRepository() {
        return [SELECT Id FROM copado__Git_Repository__c LIMIT 1];
    }

    private static copado__Org__c getCredential() {
        return [SELECT Id FROM copado__Org__c WHERE copado__is_Developer_Hub_Org__c = TRUE LIMIT 1];
    }

    private static Credential getCredentialObj() {
        return new Credential().recordId(getCredential().Id);
    }
}