@IsTest
private with sharing class PackageVersionRecordCreationUpdatesTest {
    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
    }

    @IsTest
    private static void updateBranch() {
        // Setup

        System.runAs(TestUtilities.getRunAsUser()) {
            Artifact pkg = createPackage(createRepository(), 'Unlocked');

            // Exercise
            
            Test.startTest();
            createPackageVersion(pkg).persist();
            Test.stopTest();

            // Verify

            System.assertEquals('master', getPackageVersion().copado__Branch__c, 'Package version branch updation failed');
        }
    }

    private static Repository createRepository() {
        return new Repository().name('My Repo');
    }

    private static Artifact createPackage(Repository repo, String type) {
        return new Artifact(repo).name('Testpkg').type(type).recordTypeId('Package_Artifact').branch('master');
    }

    private static ArtifactVersion createPackageVersion(Artifact pkg) {
        return new ArtifactVersion(pkg).name('ver 0.1').versionNumber('0.1.0.1');
    }

    private static copado__Artifact_Version__c getPackageVersion() {
        copado__Artifact_Version__c version = [SELECT copado__Branch__c FROM copado__Artifact_Version__c LIMIT 1];
        return version;
    }
}