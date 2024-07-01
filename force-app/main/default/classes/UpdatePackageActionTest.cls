@IsTest
private class UpdatePackageActionTest {
    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void updatePackageSuccesfully() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            UpdatePackageAction.Request request = new UpdatePackageAction.Request();
            request.resultData = '{"packageId": "testId", "namespace": "testnamespace"}';
            request.packageRecordId = getPackage().Id;

            // EXERCISE

            Test.startTest();
            UpdatePackageAction.execute(new List<UpdatePackageAction.Request>{ request });
            Test.stopTest();

            // VERIFY
            copado__Artifact__c pkg = getPackage();
            System.assertEquals('testnamespace', pkg.copado__Package_Namespace__c, 'Package namespace should be updated.');
            System.assertEquals('testId', pkg.copado__Package_Id__c, 'Package Id should be updated.');
        }
    }

    private static void createData() {
        Repository repo = createRepository();
        Pipeline pipeline = createPipeline(repo, 'SFDX');
        Credential cred = createCredential();
        createEnvironment().add(cred);
        createPackage(repo, cred, pipeline).persist();
    }

    private static Repository createRepository() {
        return new Repository().name('My Repo');
    }

    private static Pipeline createPipeline(Repository repo, String platform) {
        return new Pipeline(repo).platform(platform);
    }

    private static Artifact createPackage(Repository repo, Credential cred, Pipeline pipeline) {
        return new Artifact(repo).name('Testpkg').type('Unlocked').recordTypeId('Package_Artifact').targetDevHub(cred).pipeline(pipeline);
    }

    private static Environment createEnvironment() {
        return new Environment().platform('SFDX').type('Production/Developer');
    }

    private static Credential createCredential() {
        return new Credential().devhub(true).type('Production/Developer');
    }

    private static copado__Artifact__c getPackage() {
        return [
            SELECT Name, copado__Package_Type__c, copado__Artifact_Repository__c, copado__Package_Namespace__c, copado__Package_Id__c, RecordTypeId
            FROM copado__Artifact__c
            LIMIT 1
        ];
    }
}