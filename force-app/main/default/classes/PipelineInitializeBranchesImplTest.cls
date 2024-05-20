@IsTest
private class PipelineInitializeBranchesImplTest {

    private static final String BRANCHES_ONLY = 'Direct Branch Creation';
    private static final String MAIN_INITIALIZED = 'Main Initialized';
    private static final String INITIALIZING_MAIN = 'Initializing main';
    private static final String SFDX_INITIALIZE_BRANCHES_ONLY = 'SFDX_Initialize_Pipeline_Branches_Only_1';

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
                PipelineInitializer.Initialize.execute(null);
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
                PipelineInitializer.Initialize.execute(user.Id);
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
    private static void executeWithNonSfdxPipeline() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            String exceptionMessage;

            new Pipeline()
                .name('OtherPipeline')
                .mainBranch('main')
                .platform('Other')
                .add(new Project())
            .persist();

            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c WHERE Name = 'OtherPipeline' LIMIT 1].Id;

            // EXERCISE
            Test.startTest();
            try {
                PipelineInitializer.Initialize.execute(pipelineId);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // VERIFY
            Assert.isNotNull(exceptionMessage, 'There is no exception');
            Assert.areEqual(Label.PipelineUnavailableForInitializationMessage, exceptionMessage, 'There is a different exception');
        }
    }

    @IsTest
    private static void executeWithoutInitializationData() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            String exceptionMessage;
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;

            // EXERCISE
            Test.startTest();
            try {
                PipelineInitializer.Initialize.execute(pipelineId);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // VERIFY
            Assert.isNotNull(exceptionMessage, 'There is no exception');
            Assert.areEqual(String.format(Label.MissingRequiredParameters, new List<String> { Label.PipelineInitializationData }), exceptionMessage, 'There is a different exception');
        }
    }

    @IsTest
    private static void executeWithCompleteRequest() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;

            PipelineInitializationDetails initializationDetails = new PipelineInitializationDetails();
            initializationDetails.initializationType = BRANCHES_ONLY;
            initializationDetails.status = MAIN_INITIALIZED;

            PipelineInitializationDetails.ActivityLog logEntry = new PipelineInitializationDetails.ActivityLog();
            logEntry.status = 'In Progress';
            logEntry.title = Label.SnapshotComplete;

            initializationDetails.activityLog = new List<PipelineInitializationDetails.ActivityLog>{ logEntry };
            updatePipeline(pipelineId, JSON.serializePretty(initializationDetails));

            // EXERCISE
            Test.startTest();
            PipelineInitializer.ExecuteResult response = PipelineInitializer.Initialize.execute(pipelineId);
            Test.stopTest();

            // VERIFY
            String pipelineInitializationDetails = [SELECT Id, Initialization_Data__c FROM copado__Deployment_Flow__c].Initialization_Data__c;
            PipelineInitializationDetails result = getInitializationDataWithKeys(pipelineInitializationDetails);
            Id jobId = [SELECT Id FROM copado__JobExecution__c LIMIT 1].Id;

            Assert.isNotNull(response, 'Response is null');
            Assert.areEqual(jobId, response.jobExecution.Id, 'The job Id does not match');
            Assert.areEqual(2, result.activityLog.size(), 'The number of log entries do not match');
            Assert.areEqual(Label.SnapshotComplete, result.activityLog[0].title, 'The log title does not match');
            Assert.areEqual('Success', result.activityLog[0].status, 'The log status does not match');
            Assert.areEqual(Label.CreatingBranches, result.activityLog[1].title, 'The log title does not match');
            Assert.areEqual('In Progress', result.activityLog[1].status, 'The log status does not match');
            Assert.areEqual(jobId, result.latestJobExecutionId, 'The job Id does not match');
        }
    }

    @IsTest
    private static void executeBeforeInitializingMain() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;

            PipelineInitializationDetails initializationDetails = new PipelineInitializationDetails();
            initializationDetails.initializationType = BRANCHES_ONLY;
            initializationDetails.status = INITIALIZING_MAIN;

            updatePipeline(pipelineId, JSON.serializePretty(initializationDetails));

            // EXERCISE
            Test.startTest();
            PipelineInitializer.ExecuteResult response = PipelineInitializer.Initialize.execute(pipelineId);
            Test.stopTest();

            // VERIFY
            Assert.isNull(response, 'Response is not null');
        }
    }

    @IsTest
    private static void executeWithRandomContent() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;

            Map<String,String> randomContent = new Map<String,String>();
            randomContent.put('Hello', 'World');
            updatePipeline(pipelineId, JSON.serializePretty(randomContent));

            // EXERCISE
            Test.startTest();
            PipelineInitializer.ExecuteResult response = PipelineInitializer.Initialize.execute(pipelineId);
            Test.stopTest();

            // VERIFY
            Assert.isNull(response, 'Response is not null');
        }
    }

    @IsTest
    private static void executeWithWIPFull() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;

            JobTemplate jobTemplate = new JobTemplate().name('SFDX Initialize Pipeline with Changes').apiName('SFDX_Initialize_Pipeline_with_Changes_1');
            new JobStep(jobTemplate).name('CreateBranch').type('Function').persist();

            PipelineInitializationDetails initializationDetails = new PipelineInitializationDetails();
            initializationDetails.initializationType = 'WIP Full';
            initializationDetails.status = MAIN_INITIALIZED;
            initializationDetails.pendingEnvironmentIds = getEnvironmentIds();
            initializationDetails.currentEnvironmentId = initializationDetails.pendingEnvironmentIds[0];
            initializationDetails.areChangesSelected = true;

            PipelineInitializationDetails.ActivityLog logEntry = new PipelineInitializationDetails.ActivityLog();
            logEntry.status = 'In Progress';
            logEntry.title = Label.SnapshotComplete;

            initializationDetails.activityLog = new List<PipelineInitializationDetails.ActivityLog>{ logEntry };
            updatePipeline(pipelineId, JSON.serializePretty(initializationDetails));

            // EXERCISE
            Test.startTest();
            PipelineInitializer.ExecuteResult response = PipelineInitializer.Initialize.execute(pipelineId);
            Test.stopTest();

            // VERIFY
            String pipelineInitializationDetails = [SELECT Id, Initialization_Data__c FROM copado__Deployment_Flow__c].Initialization_Data__c;
            PipelineInitializationDetails result = getInitializationDataWithKeys(pipelineInitializationDetails);
            Id jobId = [SELECT Id FROM copado__JobExecution__c LIMIT 1].Id;

            Assert.isNotNull(response, 'Response is null');
            Assert.areEqual(jobId, response.jobExecution.Id, 'The job Id does not match');
            Assert.areEqual(1, result.activityLog.size(), 'The number of log entries do not match');
            Assert.areEqual(Label.SnapshotComplete, result.activityLog[0].title, 'The log title does not match');
            Assert.areEqual('In Progress', result.activityLog[0].status, 'The log status does not match');
            Assert.areEqual(jobId, result.latestJobExecutionId, 'The job Id does not match');
        }
    }

    @IsTest
    private static void executeWithWIPFullAndNoCurrentEnvironment() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;

            PipelineInitializationDetails initializationDetails = new PipelineInitializationDetails();
            initializationDetails.initializationType = 'WIP Full';
            initializationDetails.status = MAIN_INITIALIZED;
            initializationDetails.areChangesSelected = false;
            updatePipeline(pipelineId, JSON.serializePretty(initializationDetails));

            // EXERCISE
            Test.startTest();
            PipelineInitializer.ExecuteResult response = PipelineInitializer.Initialize.execute(pipelineId);
            Test.stopTest();

            // VERIFY
            Assert.isNull(response, 'Response is not null');
        }
    }

    @IsTest
    private static void executeWithWIPFullAndChangesSelectionPending() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;

            PipelineInitializationDetails initializationDetails = new PipelineInitializationDetails();
            initializationDetails.initializationType = 'WIP Full';
            initializationDetails.status = MAIN_INITIALIZED;
            initializationDetails.areChangesSelected = false;
            initializationDetails.pendingEnvironmentIds = getEnvironmentIds();
            initializationDetails.currentEnvironmentId = initializationDetails.pendingEnvironmentIds[0];
            
            updatePipeline(pipelineId, JSON.serializePretty(initializationDetails));

            // EXERCISE
            Test.startTest();
            PipelineInitializer.ExecuteResult response = PipelineInitializer.Initialize.execute(pipelineId);
            Test.stopTest();

            // VERIFY
            Assert.isNull(response, 'Response is not null');
        }
    }

    // HELPER

    private static void createData() {
        System.runAs(TestUtilities.getRunAsUser()) {
            JobTemplate jobTemplate = new JobTemplate().name('SFDX Initialize Pipeline - Branches Only').apiName(SFDX_INITIALIZE_BRANCHES_ONLY);
            new JobStep(jobTemplate).name('Initialize').type('Function');

            Project project = new Project();

            new Repository().name('DX');
            Environment dev1 = new Environment().name('Dev1');
            Environment staging = new Environment().name('Staging');
            new Credential(dev1);
            new Credential(staging);

            new Pipeline()
                .name('MyPipeline')
                .mainBranch('main')
                .platform('SFDX')
                .add(project)
                .add(new PipelineConnection().sourceEnvironment(dev1).destinationEnvironment(staging).destinationBranch('staging').branch('dev1'))
            .persist();

            copado__Git_Repository__c gitRepository = [SELECT Id FROM copado__Git_Repository__c LIMIT 1];
            copado__Deployment_Flow__c pipelineRecord = [SELECT Id, copado__Git_Repository__c FROM copado__Deployment_Flow__c LIMIT 1];
            pipelineRecord.copado__Git_Repository__c = gitRepository.Id;
            update pipelineRecord;
        }
    }

    private static void updatePipeline(Id pipelineId, String initializationData) {
        copado__Deployment_Flow__c pipeline = new copado__Deployment_Flow__c(
            Id = pipelineId,
            Initialization_Data__c = initializationData
        );

        update pipeline;
    }

    private static PipelineInitializationDetails getInitializationDataWithKeys(String initializationDetails) {
        return (PipelineInitializationDetails) JSON.deserialize(initializationDetails, PipelineInitializationDetails.class);
    }

    private static List<Id> getEnvironmentIds() {
        return new List<Id>(new Map<Id, copado__Environment__c>([SELECT Id FROM copado__Environment__c]).keySet());
    }
}