@IsTest
private class PreStepsStatusImplTest {

    private static final String SFDX_GIT_SNAPSHOT = 'SFDX_Git_Snapshot_1';

    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void executeWithIncompleteRequest() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            String exceptionMessage;

            // EXERCISE
            Test.startTest();
            try {
                PipelineInitializer.PreSteps.status(null);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // VERIFY
            Assert.isNotNull(exceptionMessage, 'There is no exception');
            Assert.areEqual(String.format(Label.MissingRequiredParameters, new List<String> {'Pipeline Id'}), exceptionMessage, 'There is a different exception');
        }
    }

    @IsTest
    private static void executeWithNonPipelineId() {
        User user = TestUtilities.getRunAsUser();
        System.runAs(user) {

            // SETUP
            String exceptionMessage;

            // EXERCISE
            Test.startTest();
            try {
                PipelineInitializer.PreSteps.status(user.Id);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // VERIFY
            Assert.isNotNull(exceptionMessage, 'There is no exception');
            Assert.areEqual(Label.NoPipelineFound, exceptionMessage, 'There is a different exception');
        }
    }

    @IsTest
    private static void executeWithOnlyFile() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;

            PipelineInitializationDetails initializationDetails = new PipelineInitializationDetails();
            initializationDetails.initializationType = 'Direct Branch Creation';
            initializationDetails.status = 'Initializing main';
            updatePipeline(pipelineId, JSON.serializePretty(initializationDetails));

            // EXERCISE
            Test.startTest();
            PipelineInitializer.StatusResult response = PipelineInitializer.PreSteps.status(pipelineId);
            Test.stopTest();

            // VERIFY
            Assert.isTrue(response != null, 'Response is null');
            Assert.isNull(response.steps, 'There are steps in the response');
            Assert.isTrue(String.isBlank(response.jobStatus), 'Job status is not blank');
            Assert.areEqual('Initializing main', response.pipelineInitializationStatus, 'Initialization status does not match');
        }
    }

    @IsTest
    private static void executeWithFileAndJobInfo() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            
            Id snapshotId = createAndGetSnapshotId();
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;

            PipelineInitializationDetails initializationDetails = new PipelineInitializationDetails();
            initializationDetails.initializationType = 'Direct Branch Creation';
            initializationDetails.status = 'Main Initialized';
            updatePipeline(pipelineId, JSON.serializePretty(initializationDetails));

            JobTemplate jobTemplate = new JobTemplate().name('SFDX Git Snapshot').apiName(SFDX_GIT_SNAPSHOT).type('Custom');
            JobStep jobStep = new JobStep(jobTemplate).name('Take snapshot').type('Function');

            createPipelineAction(getPipelineObj('MyPipeline'), jobTemplate, 'TakeSnapshot');

            new JobExecution(jobTemplate).status('Successful').add(jobStep);
            new Result(jobStep).type('Integration').status('Success').persist();

            copado__JobExecution__c job = [SELECT Id, copado__Pipeline__c, copado__Snapshot__c FROM copado__JobExecution__c LIMIT 1];
            job.copado__Pipeline__c = pipelineId;
            job.copado__Snapshot__c = snapshotId;
            update job;

            // EXERCISE
            Test.startTest();
            PipelineInitializer.StatusResult response = PipelineInitializer.PreSteps.status(pipelineId);
            Test.stopTest();

            // VERIFY
            Assert.isTrue(response != null, 'Response is null');
            Assert.isNotNull(response.steps, 'There are steps in the response');
            Assert.areEqual(1, response.steps.size(), 'Number of steps do not match');
            Assert.areEqual('Successful',response.jobStatus, 'Job status does not match');
            Assert.areEqual('Main Initialized', response.pipelineInitializationStatus, 'Initialization status does not match');
        }
    }

    // HELPER

    private static void createData() {
        System.runAs(TestUtilities.getRunAsUser()) {
            Project project = new Project();

            new Repository().name('DX');
            Environment dev1 = new Environment().name('Dev1');
            Environment staging = new Environment().name('Staging');
            new Environment().name('UAT');
            new Credential(dev1).default(true).orgId(fflib_IDGenerator.generate('00D'));
            new Credential(staging).default(true).orgId(fflib_IDGenerator.generate('00D'));

            Pipeline pipeline = new Pipeline()
                .name('MyPipeline')
                .mainBranch('main')
                .platform('SFDX')
                .add(project)
                .add(new PipelineConnection().sourceEnvironment(dev1).destinationEnvironment(staging).destinationBranch('staging'));
            pipeline.persist();

            copado__Git_Repository__c gitRepository = [SELECT Id FROM copado__Git_Repository__c LIMIT 1];
            copado__Deployment_Flow__c pipelineRecord = [SELECT Id, copado__Git_Repository__c FROM copado__Deployment_Flow__c LIMIT 1];
            pipelineRecord.copado__Git_Repository__c = gitRepository.Id;
            update pipelineRecord;
        }
    }

    private static Id createAndGetSnapshotId() {
        copado__Environment__c environment = [SELECT Id FROM copado__Environment__c WHERE Name = 'Staging' LIMIT 1];
        Environment staging = new Environment().recordId(environment.Id);
        new Credential(staging).default(true).orgId(fflib_IDGenerator.generate('00H')).persist();

        Id credentialId = [SELECT Id FROM copado__Org__c WHERE copado__Environment__r.Name = 'Staging' ORDER BY CreatedDate DESC LIMIT 1].Id;
        Id gitRepositoryId = [SELECT Id FROM copado__Git_Repository__c LIMIT 1].Id;
        Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;

        copado__Git_Backup__c snapshot = new copado__Git_Backup__c(copado__Org__c = credentialId, copado__Git_Repository__c = gitRepositoryId, copado__Pipeline__c = pipelineId, copado__Branch__c = 'main');
        insert snapshot;
        return snapshot.Id;
    }

    private static PipelineAction createPipelineAction(Pipeline pipeline, JobTemplate template, String action) {
        return new PipelineAction(pipeline).template(template).action(action);
    }

    private static copado__Deployment_Flow__c getPipeline(String name) {
        return [SELECT Id FROM copado__Deployment_Flow__c WHERE Name = :name LIMIT 1][0];
    }

    private static Pipeline getPipelineObj(String name) {
        return new Pipeline().recordId(getPipeline(name).Id);
    }

    private static void updatePipeline(Id pipelineId, String initializationData) {
        copado__Deployment_Flow__c pipeline = new copado__Deployment_Flow__c(
            Id = pipelineId,
            Initialization_Data__c = initializationData
        );

        update pipeline;
    }
}