@IsTest
private class PipelineInitializerJobInformationTest {

    private static final String WIP_FULL = 'WIP Full';
    private static final String WIP_DIFF = 'WIP Diff';
    private static final String INITIALIZING_MAIN = 'Initializing main';
    private static final String SELECTED_METADATA = 'Selected Metadata';
    private static final String DIRECT_BRANCH_CREATION = 'Direct Branch Creation';
    private static final String SFDX_GIT_INITIALIZATION = 'SFDX Git Initialization_1';
    private static final String SFDX_INITIALIZE_BRANCHES_ONLY = 'SFDX_Initialize_Pipeline_Branches_Only_1';
    private static final String SFDX_INITIALIZE_PIPELINE_WITH_CHANGES = 'SFDX_Initialize_Pipeline_with_Changes_1';

    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void executeWithSuccessfulJob() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            JobTemplate jobTemplate = new JobTemplate().name('Test').apiName('Test').type('Custom');
            new JobExecution(jobTemplate).status('Successful').persist();

            Id jobId = [SELECT Id FROM copado__JobExecution__c].Id;

            // EXERCISE
            Test.startTest();
            String errorMessage = PipelineInitializerJobInformation.getJobExecutionErrorMessage(jobId);
            Test.stopTest();

            // VERIFY
            Assert.isTrue(String.isBlank(errorMessage), 'The error message is blank');
        }
    }

    @IsTest
    private static void executeWithErrorJob() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            JobTemplate jobTemplate = new JobTemplate().name('Test').apiName('Test').type('Custom');
            new JobExecution(jobTemplate).status('Error').errorMessage('Custom message').persist();

            Id jobId = [SELECT Id FROM copado__JobExecution__c].Id;

            // EXERCISE
            Test.startTest();
            String errorMessage = PipelineInitializerJobInformation.getJobExecutionErrorMessage(jobId);
            Test.stopTest();

            // VERIFY
            Assert.areEqual('Custom message', errorMessage, 'The error message matches');
        }
    }

    @IsTest
    private static void executeWithException() {
        User user = TestUtilities.getRunAsUser();
        System.runAs(user) {

            // SETUP
            String exceptionMessage;

            // EXERCISE
            Test.startTest();
            try {
                PipelineInitializerJobInformation.getJobExecutionErrorMessage(user.Id);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // VERIFY
            Assert.isNotNull(exceptionMessage, 'There is no exception');
            Assert.areEqual(Label.JobNotFound, exceptionMessage, 'The exception messages do not match');
        }
    }

    @IsTest
    private static void retryForGitInitialization() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;

            PipelineInitializationDetails initializationDetails = new PipelineInitializationDetails();
            initializationDetails.initializationType = DIRECT_BRANCH_CREATION;
            initializationDetails.status = INITIALIZING_MAIN;
            updatePipeline(pipelineId, JSON.serializePretty(initializationDetails));

            JobTemplate gitInitializationTemplate = new JobTemplate().name('SFDX Git Initialization');
            new JobStep(gitInitializationTemplate).name('Initialize').type('Function').persist();
            copado__JobTemplate__c template = [SELECT Id, Name, copado__ApiName__c from copado__JobTemplate__c LIMIT 1];
            template.copado__ApiName__c = SFDX_GIT_INITIALIZATION;
            update template;

            JobTemplate gitSnapshotTemplate = new JobTemplate().name('SFDX Git Snapshot').type('Custom').apiName('SFDX_Git_Snapshot_1');
            new JobStep(gitSnapshotTemplate).name('Snapshot').type('Function');
            createPipelineAction(getPipelineObj('MyPipeline'), gitSnapshotTemplate, 'TakeSnapshot');

            new JobExecution(gitInitializationTemplate).status('Error').errorMessage('Custom message').persist();

            Id jobId = [SELECT Id FROM copado__JobExecution__c].Id;

            // EXERCISE
            Test.startTest();
            PipelineInitializerJobInformation.retryJob(jobId, pipelineId);
            Test.stopTest();

            // VERIFY
            List<copado__JobExecution__c> jobs = [SELECT Id, copado__DataJson__c, copado__Pipeline__c FROM copado__JobExecution__c ORDER BY CreatedDate DESC];
            String latestInitializationDetails = getInitializationDetails();
            PipelineInitializationDetails result = getInitializationDataWithKeys(latestInitializationDetails);

            Assert.areEqual(2, jobs.size(), 'The number of jobs do not match');
            Assert.areEqual(INITIALIZING_MAIN, result.status, 'The status does not match.');
            Assert.areEqual(DIRECT_BRANCH_CREATION, result.initializationType, 'The type does not match');
            Assert.isNull(result.completedDate, 'Completed Date is populated.');
            Assert.areEqual(1, result.activityLog.size(), 'The number of logs do not match');
            Assert.areEqual(Label.InitializeProject, result.activityLog[0].title, 'The log title does not match');
            Assert.areEqual('In Progress', result.activityLog[0].status, 'The log status does not match');
        }
    }

    @IsTest
    private static void retryForGitSnapshot() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;

            PipelineInitializationDetails initializationDetails = new PipelineInitializationDetails();
            initializationDetails.initializationType = DIRECT_BRANCH_CREATION;
            initializationDetails.status = INITIALIZING_MAIN;
            updatePipeline(pipelineId, JSON.serializePretty(initializationDetails));

            JobTemplate gitInitializationTemplate = new JobTemplate().name('SFDX Git Initialization');
            new JobStep(gitInitializationTemplate).name('Initialize').type('Function').persist();
            copado__JobTemplate__c template = [SELECT Id, Name, copado__ApiName__c from copado__JobTemplate__c LIMIT 1];
            template.copado__ApiName__c = SFDX_GIT_INITIALIZATION;
            update template;

            JobTemplate gitSnapshotTemplate = new JobTemplate().name('SFDX Git Snapshot').type('Custom').apiName('SFDX_Git_Snapshot_1');
            new JobStep(gitSnapshotTemplate).name('Snapshot').type('Function');
            createPipelineAction(getPipelineObj('MyPipeline'), gitSnapshotTemplate, 'TakeSnapshot');

            new JobExecution(gitSnapshotTemplate).status('Error').errorMessage('Custom message').persist();

            Id jobId = [SELECT Id FROM copado__JobExecution__c].Id;

            // EXERCISE
            Test.startTest();
            PipelineInitializerJobInformation.retryJob(jobId, pipelineId);
            Test.stopTest();

            // VERIFY
            List<copado__JobExecution__c> jobs = [SELECT Id, copado__DataJson__c, copado__Pipeline__c FROM copado__JobExecution__c ORDER BY CreatedDate DESC];
            String latestInitializationDetails = getInitializationDetails();
            PipelineInitializationDetails result = getInitializationDataWithKeys(latestInitializationDetails);

            Assert.areEqual(2, jobs.size(), 'The number of jobs do not match');
            Assert.areEqual(INITIALIZING_MAIN, result.status, 'The status does not match.');
            Assert.areEqual(DIRECT_BRANCH_CREATION, result.initializationType, 'The type does not match');
            Assert.isNull(result.completedDate, 'Completed Date is populated.');
            Assert.areEqual(1, result.activityLog.size(), 'The number of logs do not match');
            Assert.areEqual(Label.InitializeProject, result.activityLog[0].title, 'The log title does not match');
            Assert.areEqual('In Progress', result.activityLog[0].status, 'The log status does not match');
        }
    }

    @IsTest
    private static void retryForBranchCreation() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;

            PipelineInitializationDetails initializationDetails = new PipelineInitializationDetails();
            initializationDetails.initializationType = DIRECT_BRANCH_CREATION;
            initializationDetails.status = Label.CreatingBranches;
            PipelineInitializationDetails.ActivityLog logEntry1 = new PipelineInitializationDetails.ActivityLog();
            logEntry1.status = 'Success';
            logEntry1.title = 'Test1';

            PipelineInitializationDetails.ActivityLog logEntry2 = new PipelineInitializationDetails.ActivityLog();
            logEntry2.status = 'Error';
            logEntry2.title = Label.CreatingBranches;

            initializationDetails.activityLog = new List<PipelineInitializationDetails.ActivityLog>{ logEntry1, logEntry2 };

            updatePipeline(pipelineId, JSON.serializePretty(initializationDetails));

            JobTemplate jobTemplate = new JobTemplate().name('SFDX Initialize Pipeline - Branches Only').apiName(SFDX_INITIALIZE_BRANCHES_ONLY);
            new JobStep(jobTemplate).name('Initialize').type('Function');

            JobTemplate gitSnapshotTemplate = new JobTemplate().name('SFDX Git Snapshot').type('Custom').apiName('SFDX_Git_Snapshot_1');
            new JobStep(gitSnapshotTemplate).name('Snapshot').type('Function');
            createPipelineAction(getPipelineObj('MyPipeline'), gitSnapshotTemplate, 'TakeSnapshot');

            new JobExecution(jobTemplate).status('Error').errorMessage('Custom message').persist();

            Id jobId = [SELECT Id FROM copado__JobExecution__c].Id;

            // EXERCISE
            Test.startTest();
            PipelineInitializerJobInformation.retryJob(jobId, pipelineId);
            Test.stopTest();

            // VERIFY
            List<copado__JobExecution__c> jobs = [SELECT Id, copado__DataJson__c, copado__Pipeline__c FROM copado__JobExecution__c ORDER BY CreatedDate DESC];
            String latestInitializationDetails = getInitializationDetails();
            PipelineInitializationDetails result = getInitializationDataWithKeys(latestInitializationDetails);

            Assert.areEqual(2, jobs.size(), 'The number of jobs do not match');
            Assert.areEqual(Label.CreatingBranches, result.status, 'The status does not match.');
            Assert.areEqual(DIRECT_BRANCH_CREATION, result.initializationType, 'The type does not match');
            Assert.isNull(result.completedDate, 'Completed Date is populated.');
            Assert.areEqual(3, result.activityLog.size(), 'The number of logs do not match');
            Assert.areEqual(Label.CreatingBranches, result.activityLog[1].title, 'The log title does not match');
            Assert.areEqual('Retried', result.activityLog[1].status, 'The log status does not match');
            Assert.areEqual(Label.CreatingBranches, result.activityLog[2].title, 'The log title does not match');
            Assert.areEqual('In Progress', result.activityLog[2].status, 'The log status does not match');
        }
    }

    @IsTest
    private static void retryForBranchCreationWithChanges() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;
            List<Id> environmentIds = getEnvironmentIds();

            PipelineInitializationDetails initializationDetails = new PipelineInitializationDetails();
            initializationDetails.initializationType = WIP_FULL;
            initializationDetails.status = Label.CreatingBranches;
            initializationDetails.pendingEnvironmentIds = environmentIds;
            initializationDetails.currentEnvironmentId = initializationDetails.pendingEnvironmentIds[0];
            initializationDetails.areChangesSelected = true;
            updatePipeline(pipelineId, JSON.serializePretty(initializationDetails));

            JobTemplate jobTemplate = new JobTemplate().name('SFDX Initialize Pipeline with Changes').apiName(SFDX_INITIALIZE_PIPELINE_WITH_CHANGES);
            new JobStep(jobTemplate).name('Initialize').type('Function');

            JobTemplate gitSnapshotTemplate = new JobTemplate().name('SFDX Git Snapshot').type('Custom').apiName('SFDX_Git_Snapshot_1');
            new JobStep(gitSnapshotTemplate).name('Snapshot').type('Function');
            createPipelineAction(getPipelineObj('MyPipeline'), gitSnapshotTemplate, 'TakeSnapshot');

            new JobExecution(jobTemplate).status('Error').errorMessage('Custom message').persist();

            Id jobId = [SELECT Id FROM copado__JobExecution__c].Id;

            // EXERCISE
            Test.startTest();
            PipelineInitializerJobInformation.retryJob(jobId, pipelineId);
            Test.stopTest();

            // VERIFY
            List<copado__JobExecution__c> jobs = [SELECT Id, copado__DataJson__c, copado__Pipeline__c FROM copado__JobExecution__c ORDER BY CreatedDate DESC];
            String latestInitializationDetails = getInitializationDetails();
            PipelineInitializationDetails result = getInitializationDataWithKeys(latestInitializationDetails);

            Assert.areEqual(2, jobs.size(), 'The number of jobs do not match');
            Assert.areEqual(Label.CreatingBranches, result.status, 'The status does not match.');
            Assert.areEqual(WIP_FULL, result.initializationType, 'The type does not match');
            Assert.isNull(result.completedDate, 'Completed Date is populated.');
        }
    }

    @IsTest
    private static void retryForCommitJob() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;
            List<Id> environmentIds = getEnvironmentIds();

            String fileTitle = pipelineId + '_' + environmentIds[0] + '_' + SELECTED_METADATA;
            List<PipelineInitializer.MetadataGroup> metadataGroupsForFileCreation = getMetadataGroups('ExecuteLogs', 'Create new class', 'This new class handles execution logic.', true);
            metadataGroupsForFileCreation.addAll(getMetadataGroups('AddTest', 'Write Unit Tests', 'This new class has the unit tests.', false));

            createFile(fileTitle, environmentIds[0], JSON.serializePretty(new PipelineInitializerSaveSelectionsImpl.MetadataGroups(metadataGroupsForFileCreation)));

            JobTemplate gitSnapshotTemplate = new JobTemplate().name('SFDX Git Snapshot').type('Custom').apiName('SFDX_Git_Snapshot_1');
            new JobStep(gitSnapshotTemplate).name('Snapshot').type('Function');
            createPipelineAction(getPipelineObj('MyPipeline'), gitSnapshotTemplate, 'TakeSnapshot');

            JobTemplate jobTemplate = new JobTemplate().name('SFDX Commit').type('Custom').apiName('sfdx_commit_1');
            JobStep jobStep = new JobStep(jobTemplate).name('Commit').type('Function');
            createPipelineAction(getPipelineObj('MyPipeline'), jobTemplate, 'Commit');

            new JobExecution(jobTemplate).status('Error').errorMessage('Custom message').add(jobStep).persist();

            Id jobId = [SELECT Id FROM copado__JobExecution__c].Id;

            PipelineInitializationDetails initializationDetails = new PipelineInitializationDetails();
            initializationDetails.pendingEnvironmentIds = environmentIds;
            initializationDetails.currentEnvironmentId = initializationDetails.pendingEnvironmentIds[0];
            initializationDetails.initializationType = WIP_FULL;
            initializationDetails.status = Label.CreatingBranches;
            initializationDetails.latestJobExecutionId = jobId;
            updatePipeline(pipelineId, JSON.serializePretty(initializationDetails));

            // EXERCISE
            Test.startTest();
            PipelineInitializerJobInformation.retryJob(jobId, pipelineId);
            Test.stopTest();

            // VERIFY
            List<copado__JobExecution__c> jobs = [SELECT Id, copado__DataJson__c, copado__Pipeline__c FROM copado__JobExecution__c ORDER BY CreatedDate DESC];
            String finalInitializationDetails = getInitializationDetails();
            PipelineInitializationDetails initializationDataWithKeys = getInitializationDataWithKeys(finalInitializationDetails);

            Assert.areEqual(1, jobs.size(), 'The number of jobs do not match');
            Assert.areEqual(environmentIds[0], initializationDataWithKeys.currentEnvironmentId, 'The current environment Id is not updated');
            Assert.areEqual(2, initializationDataWithKeys.pendingEnvironmentIds.size(), 'The pending environment list size does not match');
            Assert.areEqual(jobs[0].Id, initializationDataWithKeys.latestJobExecutionId, 'The job Id does not match');
        }
    }

    @IsTest
    private static void executeWithNoPipeline() {
        User user = TestUtilities.getRunAsUser();
        System.runAs(user) {

            // SETUP
            String exceptionMessage;

            // EXERCISE
            Test.startTest();
            try {
                PipelineInitializerJobInformation.retryJob(null, user.Id);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // VERIFY
            Assert.isNotNull(exceptionMessage, 'There is no exception');
            Assert.areEqual(Label.NoPipelineFound, exceptionMessage, 'The exception messages do not match');
        }
    }

    @IsTest
    private static void executeWithNoJob() {
        User user = TestUtilities.getRunAsUser();
        System.runAs(user) {

            // SETUP
            String exceptionMessage;
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;

            // EXERCISE
            Test.startTest();
            try {
                PipelineInitializerJobInformation.retryJob(user.Id, pipelineId);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // VERIFY
            Assert.isNotNull(exceptionMessage, 'There is no exception');
            Assert.areEqual(Label.JobNotFound, exceptionMessage, 'The exception messages do not match');
        }
    }

    // HELPER

    private static void createData() {
        System.runAs(TestUtilities.getRunAsUser()) {
            Environment dev1 = new Environment().name('Dev1');
            Environment staging = new Environment().name('Staging');
            new Credential(dev1).default(true).orgId(fflib_IDGenerator.generate('00D'));
            new Credential(staging).default(true).orgId(fflib_IDGenerator.generate('00D'));

            new Pipeline()
                .name('MyPipeline')
                .mainBranch('main')
                .platform('SFDX')
                .add(new Project())
                .add(new PipelineConnection().sourceEnvironment(dev1).destinationEnvironment(staging).destinationBranch('main').branch('dev1'))
            .persist();
        }
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

    private static String getInitializationDetails() {
        return [SELECT Id, Initialization_Data__c FROM copado__Deployment_Flow__c].Initialization_Data__c;
    }

    private static PipelineInitializationDetails getInitializationDataWithKeys(String initializationDetails) {
        return (PipelineInitializationDetails) JSON.deserialize(initializationDetails, PipelineInitializationDetails.class);
    }

    private static void updatePipeline(Id pipelineId, String initializationData) {
        copado__Deployment_Flow__c pipeline = new copado__Deployment_Flow__c(
            Id = pipelineId,
            Initialization_Data__c = initializationData
        );

        update pipeline;
    }

    private static List<Id> getEnvironmentIds() {
        return new List<Id>(new Map<Id, copado__Environment__c>([SELECT Id FROM copado__Environment__c]).keySet());
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static List<PipelineInitializer.MetadataGroup> getMetadataGroups(String metadataName, String groupName, String groupDescription, Boolean isProcessed) {
        copado.Actions.CommitChange change = new copado.Actions.CommitChange();
        change.t = 'ApexClass';
        change.n = metadataName;
        change.m = 'File path is handled automatically';
        change.c = 'SFDX';
        change.a = 'Add';

        List<copado.Actions.CommitChange> changes = new List<copado.Actions.CommitChange> { change };

        List<PipelineInitializer.MetadataGroup> metadataGroups = new List<PipelineInitializer.MetadataGroup>();

        PipelineInitializer.MetadataGroup group1 = new PipelineInitializer.MetadataGroup();
        group1.groupName = groupName;
        group1.groupDescription = groupDescription;
        group1.selectedMetadata = changes;
        group1.isProcessed = isProcessed;

        metadataGroups.add(group1);

        return metadataGroups;
    }

    private static Id createFile(String title, Id recordId, String body) {
        ContentVersion fileVersion = (ContentVersion) new ContentVersion_t()
            .firstPublishLocationId(recordId)
            .title(title)
            .pathOnClient(title)
            .versionData(Blob.valueOf(body))
            .persist();
        return fileVersion.ContentDocumentId;
    }
}