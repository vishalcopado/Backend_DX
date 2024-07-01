@IsTest
private class PackageCreateHandlerTest {
    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void succesfullPackageGeneration() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Credential cred = createCredential(true);
            createEnvironment().add(cred);
            createPackage(getRepositoryObj(), 'Unlocked', cred, getPipelineObj(),'master').persist();

            // EXERCISE

            Test.startTest();
            PackageCreateHandler.startCreate(getPackage().Id);
            Test.stopTest();

            // VERIFY
            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(getJobExecution().copado__DataJson__c);
            Map<String, Object> jsonInformation = (Map<String, Object>) JSON.deserializeUntyped((String) data.get('jsonInformation'));

            System.assertEquals(getPackage().Api_Version__c, jsonInformation.get('apiversion'), 'Package apiversion should be updated');
            System.assertEquals(getJobExecution().Id, getPackage().copado__LastJobExecutionId__c, 'Package LastJobExecutionId should be updated');
        }
    }

    @IsTest
    private static void packageGenerationWithNoDevHub() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String exceptionMessage;
            createPackage(getRepositoryObj(), 'Unlocked', null, getPipelineObj(),'master').persist();

            // EXERCISE

            try {
                Test.startTest();
                PackageCreateHandler.startCreate(getPackage().Id);
                Test.stopTest();
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY

            System.assertEquals(
                Label.Target_DevHub_Required_For_Package_Generation,
                exceptionMessage,
                'Package Generation should throw error in case devhub org is not provided. '
            );
        }
    }

    @IsTest
    private static void packageGenerationWithNoBranch() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            Credential cred = createCredential(true);
            createEnvironment().add(cred);
            String exceptionMessage;
            createPackage(getRepositoryObj(), 'Unlocked', cred, getPipelineObj(),null).persist();

            // EXERCISE

            try {
                Test.startTest();
                PackageCreateHandler.startCreate(getPackage().Id);
                Test.stopTest();
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY

            System.assertEquals(
                Label.Branch_Required_For_Package_Generation,
                exceptionMessage,
                'You must specify a default branch to generate a package.'
            );
        }
    }

    private static void createData() {
        Repository repo = createRepository();
        Pipeline pipeline = createPipeline(repo, 'SFDX');
        JobTemplate template = createJobTemplate('SFDX Package Create').add(createJobStep('Update Destination on Job Execution', 'Flow')).add(createJobStep('Create Package on Destination', 'Function')).add(createJobStep('Update Package', 'Flow'));
        createPipelineAction(pipeline, template, 'CreatePackage').persist();
    }

    private static Repository createRepository() {
        return new Repository().name('My Repo');
    }

    private static Pipeline createPipeline(Repository repo, String platform) {
        return new Pipeline(repo).platform(platform);
    }
    
    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static Artifact createPackage(Repository repo, String type, Credential cred, Pipeline pipeline, String branch ) {
        return new Artifact(repo)
            .name('Testpkg')
            .type(type)
            .recordTypeId('Package_Artifact')
            .targetDevHub(cred)
            .pipeline(pipeline)
            .apiVersion('45.0')
            .branch(branch);
    }

    private static PipelineAction createPipelineAction(Pipeline pipeline, JobTemplate template, String action) {
        return new PipelineAction(pipeline).template(template).action(action);
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

    private static copado__Artifact__c getPackage() {
        return [SELECT Id, Api_Version__c, copado__LastJobExecutionId__c FROM copado__Artifact__c LIMIT 1];
    }

    private static copado__JobExecution__c getJobExecution() {
        return [SELECT Id, copado__DataJson__c FROM copado__JobExecution__c LIMIT 1];
    }

    private static Repository getRepositoryObj() {
        return new Repository().recordId(getRepository().Id);
    }

    private static Pipeline getPipelineObj() {
        return new Pipeline().recordId(getPipeline().Id);
    }

    private static copado__Deployment_Flow__c getPipeline() {
        return [SELECT Id FROM copado__Deployment_Flow__c LIMIT 1];
    }

    private static copado__Git_Repository__c getRepository() {
        return [SELECT Id FROM copado__Git_Repository__c LIMIT 1];
    }
}