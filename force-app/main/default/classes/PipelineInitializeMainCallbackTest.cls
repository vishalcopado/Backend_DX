@IsTest
private class PipelineInitializeMainCallbackTest {

    private static final String SFDX_INITIALIZE_BRANCHES_ONLY = 'SFDX_Initialize_Pipeline_Branches_Only_1';

    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void executeCallbackWithErroredJob() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;

            Id templateId = [SELECT Id FROM copado__JobTemplate__c].Id;
            copado__JobExecution__c job = new copado__JobExecution__c(
                copado__Status__c = 'Error',
                copado__Template__c = templateId,
                copado__Pipeline__c = pipelineId
            );
            insert job;
            copado__JobStep__c jobStep = new copado__JobStep__c(
                copado__Type__c = 'Flow',
                copado__ConfigJson__c = '{"flowName" : "MockedFlow"}',
                Name = 'Take logs',
                copado__JobExecution__c = job.Id
            );
            insert jobStep;
            copado__Result__c result = new copado__Result__c(
                copado__Job_Type__c = 'Integration',
                copado__Status__c = 'Failed',
                copado__JobStep__c = jobStep.Id
            );
            insert result;
            jobStep.copado__Result__c = result.Id;
            update jobStep;

            // EXERCISE
            new PipelineInitializeMainCallback().execute(job, 'Error');

            // VERIFY
            Assert.areEqual(1, [SELECT COUNT() FROM copado__JobExecution__c], 'No new job execution is created');
            String initializationDetails = getInitializationDetails();

            PipelineInitializationDetails initializationDataWithKeys = getInitializationDataWithKeys(initializationDetails);
            Assert.areEqual('Error initializing main', initializationDataWithKeys.status, 'The status does not match.');
            Assert.isNull(initializationDataWithKeys.completedDate, 'Completed Date is populated.');
            Assert.areEqual(1, initializationDataWithKeys.activityLog.size(), 'The number of log entries do not match');
            Assert.areEqual(Label.SnapshotMessage, initializationDataWithKeys.activityLog[0].title, 'The log title does not match');
            Assert.areEqual('Error', initializationDataWithKeys.activityLog[0].status, 'The log status does not match');
        }
    }

    @IsTest
    private static void executeCallbackWithCancelledJob() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;

            Id templateId = [SELECT Id FROM copado__JobTemplate__c].Id;
            copado__JobExecution__c job = new copado__JobExecution__c(
                copado__Status__c = 'Canceled',
                copado__Template__c = templateId,
                copado__Pipeline__c = pipelineId
            );
            insert job;
            copado__JobStep__c jobStep = new copado__JobStep__c(
                copado__Type__c = 'Flow',
                copado__ConfigJson__c = '{"flowName" : "MockedFlow"}',
                Name = 'Take logs',
                copado__JobExecution__c = job.Id
            );
            insert jobStep;
            copado__Result__c result = new copado__Result__c(
                copado__Job_Type__c = 'Integration',
                copado__Status__c = 'Cancelled',
                copado__JobStep__c = jobStep.Id
            );
            insert result;
            jobStep.copado__Result__c = result.Id;
            update jobStep;

            // EXERCISE
            new PipelineInitializeMainCallback().execute(job, 'Canceled');

            // VERIFY
            Assert.areEqual(1, [SELECT COUNT() FROM copado__JobExecution__c], 'No new job execution is created');
            String initializationDetails = getInitializationDetails();

            PipelineInitializationDetails initializationDataWithKeys = getInitializationDataWithKeys(initializationDetails);
            Assert.areEqual('Error initializing main', initializationDataWithKeys.status, 'The status does not match.');
            Assert.isNull(initializationDataWithKeys.completedDate, 'Completed Date is populated.');
            Assert.areEqual(1, initializationDataWithKeys.activityLog.size(), 'The number of log entries do not match');
            Assert.areEqual(Label.SnapshotMessage, initializationDataWithKeys.activityLog[0].title, 'The log title does not match');
            Assert.areEqual('Cancelled', initializationDataWithKeys.activityLog[0].status, 'The log status does not match');
        }
    }

    @IsTest
    private static void executeCallbackWithoutInitializationData() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            String exceptionMessage;
            copado__Deployment_Flow__c pipeline = [SELECT Id, Initialization_Data__c FROM copado__Deployment_Flow__c];

            Id templateId = [SELECT Id FROM copado__JobTemplate__c].Id;
            copado__JobExecution__c job = new copado__JobExecution__c(
                copado__Status__c = 'Error',
                copado__Template__c = templateId,
                copado__Pipeline__c = pipeline.Id
            );
            insert job;

            pipeline.Initialization_Data__c = '';
            update pipeline;

            // EXERCISE
            try {
                new PipelineInitializeMainCallback().execute(job, 'Error');
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY
            Assert.isNotNull(exceptionMessage, 'There is no exception');
            Assert.isTrue(exceptionMessage.contains(String.format(Label.MissingRequiredParameters, new List<String> { Label.PipelineInitializationData })), 'The exception message does not match');
        }
    }

    @IsTest
    private static void executeCallbackWithSuccessfulJob() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            JobTemplate jobTemplate = new JobTemplate().name('SFDX Initialize Pipeline - Branches Only').apiName(SFDX_INITIALIZE_BRANCHES_ONLY);
            new JobStep(jobTemplate).name('Initialize').type('Function').persist();

            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;

            Id templateId = [SELECT Id FROM copado__JobTemplate__c WHERE Name = 'SFDX Snapshot'].Id;
            copado__JobExecution__c job = new copado__JobExecution__c(
                copado__Status__c = 'Successful',
                copado__Template__c = templateId,
                copado__Pipeline__c = pipelineId
            );
            insert job;
            copado__JobStep__c jobStep = new copado__JobStep__c(
                copado__Type__c = 'Flow',
                copado__ConfigJson__c = '{"flowName" : "MockedFlow"}',
                Name = 'Take logs',
                copado__JobExecution__c = job.Id
            );
            insert jobStep;
            copado__Result__c result = new copado__Result__c(
                copado__Job_Type__c = 'Integration',
                copado__Status__c = 'Success',
                copado__JobStep__c = jobStep.Id
            );
            insert result;
            jobStep.copado__Result__c = result.Id;
            update jobStep;

            // EXERCISE
            Test.startTest();
            new PipelineInitializeMainCallback().execute(job, 'Successful');
            Test.stopTest();

            // VERIFY
            String initializationDetails = getInitializationDetails();
            
            PipelineInitializationDetails initializationDataWithKeys = getInitializationDataWithKeys(initializationDetails);
            Assert.areEqual('Creating branches', initializationDataWithKeys.status, 'The status does not match.');
            Assert.areEqual('Direct Branch Creation', initializationDataWithKeys.initializationType, 'The status does not match.');
            Assert.areEqual(3, initializationDataWithKeys.activityLog.size(), 'The number of log entries do not match');
            Assert.areEqual(Label.SnapshotMessage, initializationDataWithKeys.activityLog[0].title, 'The log title does not match');
            Assert.areEqual('Success', initializationDataWithKeys.activityLog[0].status, 'The log status does not match');
            Assert.areEqual(Label.SnapshotComplete, initializationDataWithKeys.activityLog[1].title, 'The log title does not match');
            Assert.areEqual('Success', initializationDataWithKeys.activityLog[1].status, 'The log status does not match');
            Assert.areEqual(Label.CreatingBranches, initializationDataWithKeys.activityLog[2].title, 'The log title does not match');
            Assert.areEqual('In Progress', initializationDataWithKeys.activityLog[2].status, 'The log status does not match');

            Assert.areEqual(2, [SELECT COUNT() FROM copado__JobExecution__c], 'Job Execution count does not match');
        }
    }

    // HELPER

    private static void createData() {
        System.runAs(TestUtilities.getRunAsUser()) {
            JobTemplate jobTemplate = new JobTemplate().name('SFDX Snapshot');
            new JobStep(jobTemplate).name('Take Snapshot').type('Function');

            Environment dev1 = new Environment().name('Dev1');
            Environment staging = new Environment().name('Staging');
            new Credential(dev1).default(true).orgId('a00X');
            new Credential(staging).default(true).orgId('a00Y');

            PipelineInitializationDetails initializationDetails = new PipelineInitializationDetails();
            initializationDetails.initializationType = 'Direct Branch Creation';
            initializationDetails.status = 'Initializing main';

            PipelineInitializationDetails.ActivityLog logEntry = new PipelineInitializationDetails.ActivityLog();
            logEntry.status = 'In Progress';
            logEntry.title = Label.SnapshotMessage;

            initializationDetails.activityLog = new List<PipelineInitializationDetails.ActivityLog>{ logEntry };

            new Pipeline()
                .name('MyPipeline')
                .mainBranch('main')
                .platform('SFDX')
                .initializationData(JSON.serializePretty(initializationDetails))
                .add(new Project())
                .add(new PipelineConnection().sourceEnvironment(dev1).destinationEnvironment(staging).destinationBranch('staging').branch('dev1'))
            .persist();
        }
    }

    private static PipelineInitializationDetails getInitializationDataWithKeys(String initializationDetails) {
        return (PipelineInitializationDetails) JSON.deserialize(initializationDetails, PipelineInitializationDetails.class);
    }

    private static String getInitializationDetails() {
        return [SELECT Id, Initialization_Data__c FROM copado__Deployment_Flow__c].Initialization_Data__c;
    }
}