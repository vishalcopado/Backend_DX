@IsTest
private class ConfigureVersionFromGitControllerTest {
    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void getGitConfig() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String templateName = 'SFDX Package Version Git Configure';
            JobTemplate template = createJobTemplate(templateName)
                .add(createJobStep('Git Config', 'Function'))
                .add(createJobStep('Update Record', 'Flow'));
            template.persist();
            update new copado__JobTemplate__c(Id = template.id, copado__ApiName__c = 'SFDX Package Version Git Configure_1');

            // EXERCISE

            Test.startTest();
            ConfigureVersionFromGitController.getGitConfig(getPackageVersion().Id);
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
    private static void getGitConfigFailure() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String exceptionMessage;
            String templateName = 'Invalid Template';

            createJobTemplate(templateName).persist();

            // EXERCISE

            try {
                Test.startTest();
                ConfigureVersionFromGitController.getGitConfig(getPackageVersion().Id);
                Test.stopTest();
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY

            String invalidTemplateMsg = Label.InvalidTemplateId.replace('{0}', 'SFDX Package Version Git Configure_1');
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

    private static JobStep createJobStep(String stepName, String stepType) {
        return new JobStep().name(stepName).type(stepType);
    }

    private static copado__Artifact_Version__c getPackageVersion() {
        return [SELECT Id, copado__LastJobExecutionId__c, copado__Subscriber_Version_Id__c FROM copado__Artifact_Version__c LIMIT 1];
    }

    private static copado__JobExecution__c getJobExecution() {
        return [SELECT Id FROM copado__JobExecution__c LIMIT 1];
    }

    private static copado__Environment__c getEnvironment() {
        return [SELECT Id FROM copado__Environment__c LIMIT 1];
    }
}