@IsTest
private class PackageVersionUpdateJobTest {
    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void execute() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String templateName = 'SFDX Package Version Update';
            JobTemplate template = createJobTemplate(templateName)
                .add(createJobStep('Update Package Version', 'Function'))
                .add(createJobStep('Update Records', 'Flow'));
            template.persist();
            update new copado__JobTemplate__c(Id = template.id, copado__ApiName__c = 'SFDX Package Version Update_1');

            PackageVersionUpdateJob.Version newVersion = new PackageVersionUpdateJob.Version();
            newVersion.installationKey = 'installationKey';
            newVersion.packageVersion = getPackageVersion();

            // EXERCISE

            Test.startTest();
            copado__JobExecution__c job = new PackageVersionUpdateJob(newVersion, 'SFDX Package Version Update_1').execute();
            Test.stopTest();

            // VERIFY

            System.assertEquals(getPackageVersion().copado__LastJobExecutionId__c, job.Id, 'Job execution should be started.');
        }
    }

    @IsTest
    private static void invalidJobTemplate() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            PackageVersionUpdateJob.Version newVersion = new PackageVersionUpdateJob.Version();
            newVersion.installationKey = 'installationKey';
            newVersion.packageVersion = getPackageVersion();

            String exceptionMessage;

            // EXERCISE

            try {
                Test.startTest();
                new PackageVersionUpdateJob(newVersion, 'SFDX Package Version Update_1').execute();
                Test.stopTest();
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY

            String invalidTemplateMsg = Label.InvalidTemplateId.replace('{0}', 'SFDX Package Version Update_1');
            System.assertEquals(invalidTemplateMsg, exceptionMessage, 'Exception should be thrown');
        }
    }

    private static void createData() {
        Repository repo = createRepository();
        Credential cred = createCredential(true);

        createPackageVersion(createPackage(repo, 'Unlocked', cred));
        createPipeline(repo, 'SFDX');
        createEnvironment().add(cred).persist();
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

    private static ArtifactVersion createPackageVersion(Artifact pkg) {
        return new ArtifactVersion(pkg).name('ver 0.1').versionNumber('0.1.0.1');
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
        return [
            SELECT
                Id,
                copado__Artifact__r.copado__Target_Dev_Hub_Org__r.copado__Environment__c,
                copado__Artifact__r.copado__Pipeline__c,
                copado__LastJobExecutionId__c,
                copado__Subscriber_Version_Id__c
            FROM copado__Artifact_Version__c
            LIMIT 1
        ];
    }
}