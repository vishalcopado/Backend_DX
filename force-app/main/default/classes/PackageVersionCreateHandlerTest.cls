@IsTest
private class PackageVersionCreateHandlerTest {
    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    private static void createData() {
        Repository repo = createRepository();
        Pipeline pipeline = createPipeline(repo, 'SFDX');
        JobTemplate template = createJobTemplate('SFDX Package Version Create').add(createJobStep('Update Package Requisite', 'Flow')).add(createJobStep('Create SFDX Package Version', 'Function')).add(createJobStep('Insert Package Version Information', 'Flow'));
        createPipelineAction(pipeline, template, 'CreatePackageVersion');
        Credential cred = createCredential();
        createEnvironment().add(cred);
        createPackage(repo, cred, pipeline).persist();
    }

    @IsTest
    private static void createPackageVersion() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String installationKey = 'someKey';
            createPackageVersion(getPackageObj(), '').persist();

            // EXERCISE

            Test.startTest();
            PackageVersionCreateHandler.startCreate(getPackageVersion().Id, installationKey);
            Test.stopTest();

            // VERIFY

            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(getJobExecution()[0].copado__DataJson__c);
            Map<String, Object> jsonInformation = (Map<String, Object>) JSON.deserializeUntyped((String) data.get('jsonInformation'));

            System.assertEquals('ver 0.1', data.get('versionName'), 'api version should come from package record');
            System.assertEquals('1.0.1.0', data.get('versionNumber'), 'incorrect version number');
            System.assertEquals('Package Version description', data.get('description'), 'incorrect version description');
            System.assertEquals(false, jsonInformation.get('codecoverage'), 'code coverage should be set to false');
            System.assertEquals(false, jsonInformation.get('installationkeybypass'), 'installationkeybypass should be set to false');
            System.assertEquals('45.0', jsonInformation.get('apiversion'), 'code coverage should be set to true');
        }
    }

    @IsTest
    private static void consumeDataJSON() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            createPackageVersion(getPackageObj(), '46.0').persist();
            copado__Artifact_Version__c record = getPackageVersion();
            record.copado__Data_JSON__c = createDataJSON();
            update record;

            // EXERCISE

            Test.startTest();
            PackageVersionCreateHandler.startCreate(getPackageVersion().Id, null);
            Test.stopTest();

            // VERIFY

            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(getJobExecution()[0].copado__DataJson__c);
            Map<String, Object> jsonInformation = (Map<String, Object>) JSON.deserializeUntyped((String) data.get('jsonInformation'));

            System.assertEquals('ver 0.1', data.get('versionName'), 'incorrect version name');
            System.assertEquals('46.0', jsonInformation.get('apiversion'), 'api version should come from package version record');
            System.assertEquals(true, jsonInformation.get('codecoverage'), 'code coverage should be set to true');
            System.assertEquals(true, jsonInformation.get('installationkeybypass'), 'installationkeybypass should be set to true');
            System.assertEquals('release notes url', jsonInformation.get('releasenotesurl'), 'Release notes URL should be updated');
            System.assertEquals('post intall url', jsonInformation.get('postinstallurl'), 'Post intall url should be updated');
            System.assertEquals('uninstall url', jsonInformation.get('uninstallscript'), 'Uninstall url should be updated with data JSON');
        }
    }

    private static Repository createRepository() {
        return new Repository().name('My Repo');
    }

    private static Pipeline createPipeline(Repository repo, String platform) {
        return new Pipeline(repo).platform(platform);
    }

    private static PipelineAction createPipelineAction(Pipeline pipeline, JobTemplate template, String action) {
        return new PipelineAction(pipeline).template(template).action(action);
    }

    private static Artifact createPackage(Repository repo, Credential cred, Pipeline pipeline) {
        return new Artifact(repo)
            .name('Testpkg')
            .type('Unlocked')
            .recordTypeId('Package_Artifact')
            .targetDevHub(cred)
            .pipeline(pipeline)
            .apiVersion('45.0');
    }

    private static ArtifactVersion createPackageVersion(Artifact pkg, String apiVersion) {
        return new ArtifactVersion(pkg)
            .versionName('ver 0.1')
            .versionNumber('1.0.1.0')
            .description('Package Version description')
            .codeCoverage(false)
            .apiVersion(apiVersion);
    }

    private static Environment createEnvironment() {
        return new Environment().platform('SFDX').type('Production/Developer');
    }

    private static Credential createCredential() {
        return new Credential().devhub(true).type('Production/Developer');
    }

    private static JobTemplate createJobTemplate(String name) {
        return new JobTemplate().name(name);
    }

    private static JobStep createJobStep(String stepName, String stepType) {
        return new JobStep().name(stepName).type(stepType);
    }

    private static String createDataJSON() {
        Map<String, Object> data = new Map<String, Object>{
            'codecoverage' => true,
            'installationkeybypass' => true,
            'releasenotesurl' => 'release notes url',
            'postinstallurl' => 'post intall url',
            'uninstallscript' => 'uninstall url',
            'skipvalidation' => false,
            'postinstallscript' => 'post install script',
            'tag' => 'some tag'
        };

        return JSON.serialize(data);
    }

    private static List<copado__JobExecution__c> getJobExecution() {
        return [SELECT copado__DataJson__c FROM copado__JobExecution__c];
    }

    private static copado__Artifact_Version__c getPackageVersion() {
        return [SELECT Id FROM copado__Artifact_Version__c LIMIT 1];
    }

    private static copado__Artifact__c getPackage() {
        return [SELECT Id FROM copado__Artifact__c LIMIT 1];
    }

    private static Artifact getPackageObj() {
        return new Artifact().recordId(getPackage().Id);
    }
}