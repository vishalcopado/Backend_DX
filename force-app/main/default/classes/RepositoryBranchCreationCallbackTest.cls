@IsTest
private class RepositoryBranchCreationCallbackTest {

    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void executeWithSuccessStatusAndInitializationDetails() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c LIMIT 1].Id;

            PipelineInitializationDetails initializationDetails = new PipelineInitializationDetails();
            initializationDetails.initializationType = 'Direct Branch Creation';
            initializationDetails.status = 'Main initialized';

            PipelineInitializationDetails.ActivityLog logEntry1 = new PipelineInitializationDetails.ActivityLog();
            logEntry1.status = 'Success';
            logEntry1.title = 'Test1';

            PipelineInitializationDetails.ActivityLog logEntry2 = new PipelineInitializationDetails.ActivityLog();
            logEntry2.status = 'In Progress';
            logEntry2.title = Label.CreatingBranches;

            initializationDetails.activityLog = new List<PipelineInitializationDetails.ActivityLog>{ logEntry1, logEntry2 };

            updatePipeline(pipelineId, JSON.serializePretty(initializationDetails));

            copado__Result__c jobStepResult = [SELECT Id FROM copado__Result__c WHERE copado__Job_Type__c = 'Pipeline Initializer' LIMIT 1];

            // Exercise
            new RepositoryBranchCreationCallback().execute(null, jobStepResult, 'Success');

            // Verify
            String details = [SELECT Id, Initialization_Data__c FROM copado__Deployment_Flow__c].Initialization_Data__c;
            PipelineInitializationDetails result = getInitializationDataWithKeys(details);
            Assert.areEqual('Branches created', result.status, 'The status does not match.');
            Assert.isNotNull(result.completedDate, 'Completed Date is not populated.');
            Assert.areEqual(3, result.activityLog.size(), 'The number of log entries do not match');
            Assert.areEqual(Label.CreatingBranches, result.activityLog[1].title, 'The log title does not match');
            Assert.areEqual('Success', result.activityLog[1].status, 'The log status does not match');
            Assert.areEqual(Label.BranchesCreated, result.activityLog[2].title, 'The log title does not match');
            Assert.areEqual('Success', result.activityLog[2].status, 'The log status does not match');
        }
    }

    @IsTest
    private static void executeWithSuccessStatusAndNoOldActivity() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c LIMIT 1].Id;

            PipelineInitializationDetails initializationDetails = new PipelineInitializationDetails();
            initializationDetails.initializationType = 'Direct Branch Creation';
            initializationDetails.status = 'Main initialized';

            updatePipeline(pipelineId, JSON.serializePretty(initializationDetails));

            copado__Result__c jobStepResult = [SELECT Id FROM copado__Result__c WHERE copado__Job_Type__c = 'Pipeline Initializer' LIMIT 1];

            // Exercise
            new RepositoryBranchCreationCallback().execute(null, jobStepResult, 'Success');

            // Verify
            String details = [SELECT Id, Initialization_Data__c FROM copado__Deployment_Flow__c].Initialization_Data__c;
            PipelineInitializationDetails result = getInitializationDataWithKeys(details);
            Assert.areEqual('Branches created', result.status, 'The status does not match.');
            Assert.isNotNull(result.completedDate, 'Completed Date is not populated.');
            Assert.areEqual(1, result.activityLog.size(), 'The number of log entries do not match');
            Assert.areEqual(Label.BranchesCreated, result.activityLog[0].title, 'The log title does not match');
            Assert.areEqual('Success', result.activityLog[0].status, 'The log status does not match');
        }
    }

    @IsTest
    private static void executeWithSuccessStatusAndNoInitializationDetails() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup
            String exceptionMessage;

            copado__Result__c jobStepResult = [SELECT Id FROM copado__Result__c WHERE copado__Job_Type__c = 'Pipeline Initializer' LIMIT 1];

            // Exercise
            Test.startTest();
            try {
                new RepositoryBranchCreationCallback().execute(null, jobStepResult, 'Success');
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // Verify
            Assert.isNotNull(exceptionMessage, 'There is no exception');
            Assert.isTrue(exceptionMessage.contains(String.format(Label.MissingRequiredParameters, new List<String> { Label.PipelineInitializationData })), 'The exception message does not match');
        }
    }

    @IsTest
    private static void executeWithFailedStatusAndInitializationDetails() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c LIMIT 1].Id;

            PipelineInitializationDetails initializationDetails = new PipelineInitializationDetails();
            initializationDetails.initializationType = 'Direct Branch Creation';
            initializationDetails.status = 'Main initialized';

            PipelineInitializationDetails.ActivityLog logEntry1 = new PipelineInitializationDetails.ActivityLog();
            logEntry1.status = 'Success';
            logEntry1.title = 'Test1';

            PipelineInitializationDetails.ActivityLog logEntry2 = new PipelineInitializationDetails.ActivityLog();
            logEntry2.status = 'In Progress';
            logEntry2.title = Label.CreatingBranches;

            initializationDetails.activityLog = new List<PipelineInitializationDetails.ActivityLog>{ logEntry1, logEntry2 };

            updatePipeline(pipelineId, JSON.serializePretty(initializationDetails));

            copado__Result__c jobStepResult = [SELECT Id FROM copado__Result__c WHERE copado__Job_Type__c = 'Pipeline Initializer' LIMIT 1];

            // Exercise
            new RepositoryBranchCreationCallback().execute(null, jobStepResult, 'Failed');

            // Verify
            String details = [SELECT Id, Initialization_Data__c FROM copado__Deployment_Flow__c].Initialization_Data__c;
            PipelineInitializationDetails result = getInitializationDataWithKeys(details);
            Assert.areEqual('Main initialized', result.status, 'The status does not match.');
            Assert.areEqual('Direct Branch Creation', result.initializationType, 'The initialization type does not match.');
            Assert.areEqual(2, result.activityLog.size(), 'The number of log entries do not match');
            Assert.areEqual(Label.CreatingBranches, result.activityLog[1].title, 'The log title does not match');
            Assert.areEqual('Error', result.activityLog[1].status, 'The log status does not match');
        }
    }

    @IsTest
    private static void executeWithCancelledStatus() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c LIMIT 1].Id;

            PipelineInitializationDetails initializationDetails = new PipelineInitializationDetails();
            initializationDetails.initializationType = 'Direct Branch Creation';
            initializationDetails.status = 'Main initialized';

            PipelineInitializationDetails.ActivityLog logEntry1 = new PipelineInitializationDetails.ActivityLog();
            logEntry1.status = 'Success';
            logEntry1.title = 'Test1';

            PipelineInitializationDetails.ActivityLog logEntry2 = new PipelineInitializationDetails.ActivityLog();
            logEntry2.status = 'In Progress';
            logEntry2.title = Label.CreatingBranches;

            initializationDetails.activityLog = new List<PipelineInitializationDetails.ActivityLog>{ logEntry1, logEntry2 };

            updatePipeline(pipelineId, JSON.serializePretty(initializationDetails));

            copado__Result__c jobStepResult = [SELECT Id FROM copado__Result__c WHERE copado__Job_Type__c = 'Pipeline Initializer' LIMIT 1];

            // Exercise
            new RepositoryBranchCreationCallback().execute(null, jobStepResult, 'Cancelled');

            // Verify
            String details = [SELECT Id, Initialization_Data__c FROM copado__Deployment_Flow__c].Initialization_Data__c;
            PipelineInitializationDetails result = getInitializationDataWithKeys(details);
            Assert.areEqual('Main initialized', result.status, 'The status does not match.');
            Assert.areEqual('Direct Branch Creation', result.initializationType, 'The initialization type does not match.');
            Assert.areEqual(2, result.activityLog.size(), 'The number of log entries do not match');
            Assert.areEqual(Label.CreatingBranches, result.activityLog[1].title, 'The log title does not match');
            Assert.areEqual('Cancelled', result.activityLog[1].status, 'The log status does not match');
        }
    }

    // HELPER

    private static void createData() {
        System.runAs(TestUtilities.getRunAsUser()) {
            Project project = new Project();

            new Repository().name('DX');
            Environment dev1 = new Environment().name('Dev1');
            Environment staging = new Environment().name('Staging');
            new Credential(dev1).default(true).orgId('a00X');
            new Credential(staging).default(true).orgId('a00Y');

            Pipeline pipeline = new Pipeline()
                .name('MyPipeline')
                .mainBranch('main')
                .platform('SFDX')
                .add(project)
                .add(new PipelineConnection().sourceEnvironment(dev1).destinationEnvironment(staging).destinationBranch('staging'));
            pipeline.persist();

            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c LIMIT 1].Id;

            copado__JobTemplate__c template = new copado__JobTemplate__c(Name = 'Test Pipeline', copado__Version__c = 1);
            insert template;

            copado__JobExecution__c execution = new copado__JobExecution__c(
                copado__Template__c = template.Id,
                copado__Pipeline__c = pipelineId
            );
            insert execution;

            copado__JobStep__c jobStep = new copado__JobStep__c(
                Name = 'Process Results',
                copado__JobExecution__c = execution.Id,
                copado__Type__c = 'Function'
            );
            insert jobStep;

            copado__Result__c jobStepResult = new copado__Result__c(
                copado__Job_Type__c = 'Pipeline Initializer',
                copado__JobStep__c = jobStep.Id
            );
            insert jobStepResult;
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
}