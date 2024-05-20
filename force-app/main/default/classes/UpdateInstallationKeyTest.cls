@IsTest
private class UpdateInstallationKeyTest {
    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void fetchInstallationKeySuccess() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Artifact pkg = createPackage(getRepositoryObj(), 'Unlocked', getCredentialObj());

            createPackageVersion(pkg, createFakeId('04t')).persist();

            copado__Artifact_Version__c version = getPackageVersion();
            createInstallationKey('pwd1', version.copado__Subscriber_Version_Id__c, version.Name);

            // EXERCISE

            Test.startTest();
            String key = UpdateInstallationKey.fetchInstallationKey(version.copado__Subscriber_Version_Id__c);
            Test.stopTest();

            // VERIFY

            System.assertEquals('pwd1', key, 'Installation Key should be returned correctly.');
        }
    }

    @IsTest
    private static void executeJobSuccess() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Artifact pkg = createPackage(getRepositoryObj(), 'Unlocked', getCredentialObj());

            JobTemplate template = createJobTemplate('SFDX Package Version Update')
                .add(createJobStep('Update Package Version', 'Function'))
                .add(createJobStep('Update Records', 'Flow'));
            createPackageVersion(pkg, createFakeId('04t')).persist();
            update new copado__JobTemplate__c(Id = template.id, copado__ApiName__c = 'SFDX Package Version Update_1');

            // EXERCISE

            Test.startTest();
            UpdateInstallationKey.executeJob(getPackageVersion().copado__Subscriber_Version_Id__c, '12345');
            Test.stopTest();

            // VERIFY

            System.assertEquals(
                getJobExecution().Id,
                getPackageVersion().copado__LastJobExecutionId__c,
                'Package Version LastJobExecutionId should be updated'
            );
        }
    }

    @IsTest
    private static void executeJobFailure() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String exceptionMessage;
            createPackageVersion(createPackage(getRepositoryObj(), 'Unlocked', getCredentialObj()), createFakeId('04t')).persist();

            // EXERCISE

            try {
                Test.startTest();
                UpdateInstallationKey.executeJob(getPackageVersion().copado__Subscriber_Version_Id__c, '12345');
                Test.stopTest();
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY

            String invalidTemplateMsg = Label.InvalidTemplateId.replace('{0}', 'SFDX Package Version Update_1');
            System.assertEquals(invalidTemplateMsg, exceptionMessage, 'Exception should be thrown');
        }
    }

    @IsTest
    private static void emptySubscriberId() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String exceptionMessage;
            createPackageVersion(createPackage(getRepositoryObj(), 'Unlocked', getCredentialObj()), null).persist();

            // EXERCISE

            try {
                Test.startTest();
                UpdateInstallationKey.executeJob(getPackageVersion().copado__Subscriber_Version_Id__c, '12345');
                Test.stopTest();
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY

            System.assertEquals(Label.Empty_Subscriber_Version_Id, exceptionMessage, 'Exception should be thrown');
        }
    }

    @IsTest
    private static void invalidSubscriberId() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String exceptionMessage;

            createPackageVersion(createPackage(getRepositoryObj(), 'Unlocked', getCredentialObj()), createFakeId('04t')).persist();

            // EXERCISE

            try {
                Test.startTest();
                UpdateInstallationKey.executeJob(createFakeId('04t'), '12345');
                Test.stopTest();
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY

            System.assertEquals(Label.Invalid_Subscriber_Version_Id, exceptionMessage, 'Exception should be thrown');
        }
    }

    @IsTest
    private static void emptyDevHub() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String exceptionMessage;
            createPackageVersion(createPackage(getRepositoryObj(), 'Unlocked', null), createFakeId('04t')).persist();

            // EXERCISE

            try {
                Test.startTest();
                UpdateInstallationKey.executeJob(getPackageVersion().copado__Subscriber_Version_Id__c, '12345');
                Test.stopTest();
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY

            System.assertEquals(Label.PopulateTargetDevHub, exceptionMessage, 'Exception should be thrown');
        }
    }

    // HELPER

    private static void createData() {
        Repository repo = createRepository();
        Credential cred = createCredential(true);
        createPipeline(repo, 'SFDX');
        createEnvironment().add(cred).persist();
    }

    private static Credential getCredentialObj() {
        return new Credential().recordId(getCredential().Id);
    }

    private static Repository getRepositoryObj() {
        return new Repository().recordId(getRepository().Id);
    }

    private static Repository createRepository() {
        return new Repository().name('My Repo');
    }

    private static Pipeline createPipeline(Repository repo, String platform) {
        return new Pipeline(repo).platform(platform);
    }

    private static Artifact createPackage(Repository repo, String type, Credential cred) {
        return new Artifact(repo).name('Testpkg').type(type).recordTypeId('Package_Artifact').targetDevHub(cred);
    }

    private static ArtifactVersion createPackageVersion(Artifact pkg, Id subscriberVersionId) {
        return new ArtifactVersion(pkg).name('ver 0.1').versionNumber('0.1.0.1').versionId(subscriberVersionId);
    }

    private static Environment createEnvironment() {
        return new Environment().platform('SFDX').type('Production/Developer');
    }

    private static Credential createCredential(Boolean isDevHub) {
        return new Credential().devhub(isDevHub).type('Production/Developer');
    }

    private static JobTemplate createJobTemplate(String name) {
        return new JobTemplate().name(name);
    }

    private static JobStep createJobStep(String name, String type) {
        return new JobStep().name(name).type(type);
    }

    private static copado__Artifact_Version__c getPackageVersion() {
        return [SELECT Id, Name, copado__LastJobExecutionId__c, copado__Subscriber_Version_Id__c FROM copado__Artifact_Version__c LIMIT 1];
    }

    private static copado__JobExecution__c getJobExecution() {
        return [SELECT Id FROM copado__JobExecution__c LIMIT 1];
    }

    private static Id createFakeId(String keyPrefix) {
        return fflib_IDGenerator.generate(keyPrefix);
    }

    private static copado__Environment__c getEnvironment() {
        return [SELECT Id FROM copado__Environment__c LIMIT 1];
    }

    private static copado__Org__c getCredential() {
        return [SELECT Id FROM copado__Org__c WHERE copado__is_Developer_Hub_Org__c = TRUE LIMIT 1];
    }

    private static copado__Git_Repository__c getRepository() {
        return [SELECT Id FROM copado__Git_Repository__c LIMIT 1];
    }

    private static void createInstallationKey(String key, Id subscriberVersionId, String versionName) {
        PackageVersionInstallationKey__c installationKey = new PackageVersionInstallationKey__c(
            PackageVersionId__c = subscriberVersionId,
            InstallationKey__c = key,
            Name = versionName
        );
        insert installationKey;
    }
}