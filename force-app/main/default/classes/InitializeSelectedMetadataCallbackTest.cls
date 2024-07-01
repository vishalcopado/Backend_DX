@IsTest
private class InitializeSelectedMetadataCallbackTest {

    private static final String SELECTED_METADATA = 'Selected Metadata';

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

            PipelineInitializationDetails initializationDetails = new PipelineInitializationDetails();
            initializationDetails.initializationType = 'WIP Full';
            initializationDetails.status = 'Main Initialized';

            PipelineInitializationDetails.ActivityLog logEntry = new PipelineInitializationDetails.ActivityLog();
            logEntry.status = 'In Progress';
            logEntry.title = 'Test';

            initializationDetails.activityLog = new List<PipelineInitializationDetails.ActivityLog>{ logEntry };
            updatePipeline(pipelineId, JSON.serializePretty(initializationDetails));

            InitializeWithSelectedMetadataCallback.Branches branches = new InitializeWithSelectedMetadataCallback.Branches();
            branches.source = 'dev1';
            branches.destination = 'staging';
            InitializeWithSelectedMetadataCallback.JobData jobData = new InitializeWithSelectedMetadataCallback.JobData(branches);

            copado__JobExecution__c job = createJobAndRelatedRecords(pipelineId, JSON.serialize(jobData), 'Error');

            // EXERCISE
            new InitializeWithSelectedMetadataCallback().execute(job, 'Error');

            // VERIFY
            String pipelineInitializationDetails = [SELECT Id, Initialization_Data__c FROM copado__Deployment_Flow__c].Initialization_Data__c;
            PipelineInitializationDetails latestInitializationDetails = getInitializationDataWithKeys(pipelineInitializationDetails);

            Assert.areEqual(1, [SELECT COUNT() FROM copado__JobExecution__c], 'No new job execution is created');
            Assert.areEqual(2, latestInitializationDetails.activityLog.size(), 'The number of log entries do not match');
            Assert.areEqual('Test', latestInitializationDetails.activityLog[0].title, 'The log title does not match');
            Assert.areEqual('In Progress', latestInitializationDetails.activityLog[0].status, 'The log status does not match');
            Assert.areEqual(String.format(Label.NamedBranchCreated, new List<String> { 'dev1' }), latestInitializationDetails.activityLog[1].title, 'The log title does not match');
            Assert.areEqual('Error', latestInitializationDetails.activityLog[1].status, 'The log status does not match');
        }
    }

    @IsTest
    private static void executeCallbackWithCancelledJob() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;

            PipelineInitializationDetails initializationDetails = new PipelineInitializationDetails();
            initializationDetails.initializationType = 'WIP Full';
            initializationDetails.status = 'Main Initialized';

            PipelineInitializationDetails.ActivityLog logEntry = new PipelineInitializationDetails.ActivityLog();
            logEntry.status = 'In Progress';
            logEntry.title = 'Test';

            initializationDetails.activityLog = new List<PipelineInitializationDetails.ActivityLog>{ logEntry };
            updatePipeline(pipelineId, JSON.serializePretty(initializationDetails));

            InitializeWithSelectedMetadataCallback.Branches branches = new InitializeWithSelectedMetadataCallback.Branches();
            branches.source = 'dev1';
            branches.destination = 'staging';
            InitializeWithSelectedMetadataCallback.JobData jobData = new InitializeWithSelectedMetadataCallback.JobData(branches);

            copado__JobExecution__c job = createJobAndRelatedRecords(pipelineId, JSON.serialize(jobData), 'Canceled');

            // EXERCISE
            new InitializeWithSelectedMetadataCallback().execute(job, 'Canceled');

            // VERIFY
            String pipelineInitializationDetails = [SELECT Id, Initialization_Data__c FROM copado__Deployment_Flow__c].Initialization_Data__c;
            PipelineInitializationDetails latestInitializationDetails = getInitializationDataWithKeys(pipelineInitializationDetails);

            Assert.areEqual(1, [SELECT COUNT() FROM copado__JobExecution__c], 'No new job execution is created');
            Assert.areEqual(2, latestInitializationDetails.activityLog.size(), 'The number of log entries do not match');
            Assert.areEqual('Test', latestInitializationDetails.activityLog[0].title, 'The log title does not match');
            Assert.areEqual('In Progress', latestInitializationDetails.activityLog[0].status, 'The log status does not match');
            Assert.areEqual(String.format(Label.NamedBranchCreated, new List<String> { 'dev1' }), latestInitializationDetails.activityLog[1].title, 'The log title does not match');
            Assert.areEqual('Cancelled', latestInitializationDetails.activityLog[1].status, 'The log status does not match');
        }
    }

    @IsTest
    private static void executeWithSuccessfulJobAndNoMetadataFile() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;
            List<Id> environmentIds = getEnvironmentIds();

            PipelineInitializationDetails initializationDetails = new PipelineInitializationDetails();
            initializationDetails.initializationType = 'WIP Full';
            initializationDetails.status = 'Main Initialized';
            initializationDetails.pendingEnvironmentIds = environmentIds;
            initializationDetails.currentEnvironmentId = initializationDetails.pendingEnvironmentIds[0];

            PipelineInitializationDetails.ActivityLog logEntry = new PipelineInitializationDetails.ActivityLog();
            logEntry.status = 'In Progress';
            logEntry.title = 'Test';

            initializationDetails.activityLog = new List<PipelineInitializationDetails.ActivityLog>{ logEntry };
            updatePipeline(pipelineId, JSON.serializePretty(initializationDetails));

            InitializeWithSelectedMetadataCallback.Branches branches = new InitializeWithSelectedMetadataCallback.Branches();
            branches.source = 'staging';
            branches.destination = 'uat';
            InitializeWithSelectedMetadataCallback.JobData jobData = new InitializeWithSelectedMetadataCallback.JobData(branches);

            copado__JobExecution__c job = createJobAndRelatedRecords(pipelineId, JSON.serialize(jobData), 'Successful');

            // EXERCISE
            new InitializeWithSelectedMetadataCallback().execute(job, 'Successful');

            // VERIFY
            String pipelineInitializationDetails = [SELECT Id, Initialization_Data__c FROM copado__Deployment_Flow__c].Initialization_Data__c;
            PipelineInitializationDetails result = getInitializationDataWithKeys(pipelineInitializationDetails);

            copado__JobExecution__c newJob = [SELECT Id, copado__DataJson__c FROM copado__JobExecution__c WHERE copado__Template__r.copado__ApiName__c = 'SFDX_Initialize_Pipeline_with_Changes_1' AND Id != :job.Id];

            Assert.areEqual(2, [SELECT COUNT() FROM copado__JobExecution__c], 'No new job execution is created');
            Assert.areEqual(2, result.activityLog.size(), 'The number of log entries do not match');
            Assert.areEqual('Test', result.activityLog[0].title, 'The log title does not match');
            Assert.areEqual('In Progress', result.activityLog[0].status, 'The log status does not match');
            Assert.areEqual(String.format(Label.NamedBranchCreated, new List<String> { 'staging' }), result.activityLog[1].title, 'The log title does not match');
            Assert.areEqual('Success', result.activityLog[1].status, 'The log status does not match');
            Assert.areEqual('Creating branches', result.status, 'The status does not match.');
            Assert.areEqual('WIP Full', result.initializationType, 'The type does not match.');
            Assert.areNotEqual(initializationDetails.currentEnvironmentId, result.currentEnvironmentId, 'The current environment Id is not updated');
            Assert.areEqual(2, result.pendingEnvironmentIds.size(), 'The pending environment list size does not match');
            Assert.areEqual(newJob.Id, result.latestJobExecutionId, 'The job id does not match');
        }
    }

    @IsTest
    private static void executeWithSuccessfulJobAndNoGroupToProcess() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;
            List<Id> environmentIds = getEnvironmentIds();

            String fileTitle = pipelineId + '_' + environmentIds[0] + '_' + SELECTED_METADATA;
            List<PipelineInitializer.MetadataGroup> metadataGroupsForFileCreation = getMetadataGroups('ExecuteLogs', 'Create new class', 'This new class handles execution logic.', true);
            createFile(fileTitle, environmentIds[0], JSON.serializePretty(new PipelineInitializerSaveSelectionsImpl.MetadataGroups(metadataGroupsForFileCreation)));

            PipelineInitializationDetails initializationDetails = new PipelineInitializationDetails();
            initializationDetails.initializationType = 'WIP Full';
            initializationDetails.status = 'Main Initialized';
            initializationDetails.pendingEnvironmentIds = environmentIds;
            initializationDetails.currentEnvironmentId = initializationDetails.pendingEnvironmentIds[0];

            PipelineInitializationDetails.ActivityLog logEntry = new PipelineInitializationDetails.ActivityLog();
            logEntry.status = 'In Progress';
            logEntry.title = 'Test';

            initializationDetails.activityLog = new List<PipelineInitializationDetails.ActivityLog>{ logEntry };
            updatePipeline(pipelineId, JSON.serializePretty(initializationDetails));

            InitializeWithSelectedMetadataCallback.Branches branches = new InitializeWithSelectedMetadataCallback.Branches();
            branches.source = 'staging';
            branches.destination = 'uat';
            InitializeWithSelectedMetadataCallback.JobData jobData = new InitializeWithSelectedMetadataCallback.JobData(branches);

            copado__JobExecution__c job = createJobAndRelatedRecords(pipelineId, JSON.serialize(jobData), 'Successful');

            // EXERCISE
            new InitializeWithSelectedMetadataCallback().execute(job, 'Successful');

            // VERIFY
            String pipelineInitializationDetails = [SELECT Id, Initialization_Data__c FROM copado__Deployment_Flow__c].Initialization_Data__c;
            PipelineInitializationDetails result = getInitializationDataWithKeys(pipelineInitializationDetails);

            copado__JobExecution__c newJob = [SELECT Id, copado__DataJson__c FROM copado__JobExecution__c WHERE copado__Template__r.copado__ApiName__c = 'SFDX_Initialize_Pipeline_with_Changes_1' AND Id != :job.Id];

            Assert.areEqual(2, [SELECT COUNT() FROM copado__JobExecution__c], 'No new job execution is created');
            Assert.areEqual(2, result.activityLog.size(), 'The number of log entries do not match');
            Assert.areEqual('Test', result.activityLog[0].title, 'The log title does not match');
            Assert.areEqual('In Progress', result.activityLog[0].status, 'The log status does not match');
            Assert.areEqual(String.format(Label.NamedBranchCreated, new List<String> { 'staging' }), result.activityLog[1].title, 'The log title does not match');
            Assert.areEqual('Success', result.activityLog[1].status, 'The log status does not match');
            Assert.areEqual('Creating branches', result.status, 'The status does not match.');
            Assert.areEqual('WIP Full', result.initializationType, 'The type does not match.');
            Assert.areEqual(environmentIds[1], result.currentEnvironmentId, 'The current environment Id is not updated');
            Assert.areEqual(2, result.pendingEnvironmentIds.size(), 'The pending environment list size does not match');
            Assert.areEqual(newJob.Id, result.latestJobExecutionId, 'The job id does not match');
        }
    }

    @IsTest
    private static void executeWithSuccessfulJobAndNoGroupNoNextEnvironment() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;
            List<Id> environmentIds = getEnvironmentIds();

            String fileTitle = pipelineId + '_' + environmentIds[1] + '_' + SELECTED_METADATA;
            List<PipelineInitializer.MetadataGroup> metadataGroupsForFileCreation = getMetadataGroups('ExecuteLogs', 'Create new class', 'This new class handles execution logic.', true);
            createFile(fileTitle, environmentIds[2], JSON.serializePretty(new PipelineInitializerSaveSelectionsImpl.MetadataGroups(metadataGroupsForFileCreation)));

            PipelineInitializationDetails initializationDetails = new PipelineInitializationDetails();
            initializationDetails.pendingEnvironmentIds = new List<Id>{ environmentIds[2] };
            initializationDetails.currentEnvironmentId = environmentIds[2];

            updatePipeline(pipelineId, JSON.serializePretty(initializationDetails));

            InitializeWithSelectedMetadataCallback.Branches branches = new InitializeWithSelectedMetadataCallback.Branches();
            branches.source = 'staging';
            branches.destination = 'uat';
            InitializeWithSelectedMetadataCallback.JobData jobData = new InitializeWithSelectedMetadataCallback.JobData(branches);

            copado__JobExecution__c job = createJobAndRelatedRecords(pipelineId, JSON.serialize(jobData), 'Successful');

            // EXERCISE
            new InitializeWithSelectedMetadataCallback().execute(job, 'Successful');

            // VERIFY
            String pipelineInitializationDetails = [SELECT Id, Initialization_Data__c FROM copado__Deployment_Flow__c].Initialization_Data__c;
            PipelineInitializationDetails result = getInitializationDataWithKeys(pipelineInitializationDetails);

            Assert.areEqual(1, [SELECT COUNT() FROM copado__JobExecution__c], 'No new job execution is created');
            Assert.areEqual(1, result.activityLog.size(), 'The number of log entries do not match');
            Assert.areEqual(String.format(Label.NamedBranchCreated, new List<String> { 'staging' }), result.activityLog[0].title, 'The log title does not match');
            Assert.areEqual('Success', result.activityLog[0].status, 'The log status does not match');
            Assert.areEqual(null, result.currentEnvironmentId, 'The current environment Id is not updated');
            Assert.areEqual(0, result.pendingEnvironmentIds.size(), 'The pending environment list size does not match');
        }
    }

    @IsTest
    private static void executeSuccessfulJobAndMoreMetadataGroupToProcess() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;
            List<Id> environmentIds = getEnvironmentIds();

            String fileTitle = pipelineId + '_' + environmentIds[0] + '_' + SELECTED_METADATA;
            List<PipelineInitializer.MetadataGroup> metadataGroupsForFileCreation = getMetadataGroups('ExecuteLogs', 'Create new class', 'This new class handles execution logic.', true);
            metadataGroupsForFileCreation.addAll(getMetadataGroups('AddTest', 'Write Unit Tests', 'This new class has the unit tests.', false));

            createFile(fileTitle, environmentIds[0], JSON.serializePretty(new PipelineInitializerSaveSelectionsImpl.MetadataGroups(metadataGroupsForFileCreation)));

            PipelineInitializationDetails initializationDetails = new PipelineInitializationDetails();
            initializationDetails.pendingEnvironmentIds = environmentIds;
            initializationDetails.currentEnvironmentId = initializationDetails.pendingEnvironmentIds[0];

            updatePipeline(pipelineId, JSON.serializePretty(initializationDetails));

            InitializeWithSelectedMetadataCallback.Branches branches = new InitializeWithSelectedMetadataCallback.Branches();
            branches.source = 'staging';
            branches.destination = 'uat';
            InitializeWithSelectedMetadataCallback.JobData jobData = new InitializeWithSelectedMetadataCallback.JobData(branches);

            copado__JobExecution__c job = createJobAndRelatedRecords(pipelineId, JSON.serialize(jobData), 'Successful');

            JobTemplate jobTemplate = new JobTemplate().name('SFDX Commit').apiName('sfdx_commit_1');
            new JobStep(jobTemplate).name('CommitMetadat').type('Function');
            createPipelineAction(getPipelineObj('MyPipeline'), jobTemplate, 'Commit').persist();

            // EXERCISE
            Test.startTest();
            new InitializeWithSelectedMetadataCallback().execute(job, 'Successful');
            Test.stopTest();

            // VERIFY
            String finalInitializationDetails = [SELECT Id, Initialization_Data__c FROM copado__Deployment_Flow__c].Initialization_Data__c;
            copado__User_Story__c userStory = [SELECT Id, Name, copado__User_Story_Title__c, copado__Functional_Specifications__c, copado__Project__c, copado__Project__r.Name, copado__Project__r.copado__Description__c FROM copado__User_Story__c];

            PipelineInitializationDetails initializationDataWithKeys = getInitializationDataWithKeys(finalInitializationDetails);
            Assert.areEqual(environmentIds[0], initializationDataWithKeys.currentEnvironmentId, 'The current environment Id is not updated');
            Assert.areEqual(3, initializationDataWithKeys.pendingEnvironmentIds.size(), 'The pending environment list size does not match');
            Assert.areNotEqual(job.Id, initializationDataWithKeys.latestJobExecutionId, 'The job Id does not match');
            Assert.areEqual(2, initializationDataWithKeys.activityLog.size(), 'The number of log entries do not match');
            Assert.areEqual(String.format(Label.NamedBranchCreated, new List<String> { 'staging' }), initializationDataWithKeys.activityLog[0].title, 'The log title does not match');
            Assert.areEqual(String.format(Label.CommittingChanges, new List<String> { userStory.Name }), initializationDataWithKeys.activityLog[1].title, 'The log title does not match');
            Assert.areEqual('In Progress', initializationDataWithKeys.activityLog[1].status, 'The log status does not match');

            Assert.isNotNull(userStory, 'There is a user story record');
            Assert.areEqual('Write Unit Tests', userStory.copado__User_Story_Title__c, 'The US title does not match');
            Assert.areEqual('This new class has the unit tests.', userStory.copado__Functional_Specifications__c, 'The US specifications do not match');
            Assert.isNotNull(userStory.copado__Project__c, 'The US project is null');
            Assert.areEqual(String.format(Label.PipelineInitializerGitSnapshotMessage, new List<String> { 'MyPipeline' }), userStory.copado__Project__r.Name, 'The project name does not match');
            Assert.areEqual(Label.NewProjectDescription, userStory.copado__Project__r.copado__Description__c, 'The project description does not match');

            Assert.isNotNull([SELECT Id FROM copado__JobExecution__c WHERE copado__Template__r.copado__ApiName__c = 'sfdx_commit_1'], 'The commit job is not created');
        }
    }

    @IsTest
    private static void executeProcessMetadataGroup() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;
            copado__Deployment_Flow__c pipeline = new PipelinesSelector().byId(new Set<Id>{ pipelineId })[0];

            List<Id> environmentIds = getEnvironmentIds();

            String fileTitle = pipeline.Id + '_' + environmentIds[0] + '_' + SELECTED_METADATA;
            List<PipelineInitializer.MetadataGroup> metadataGroupsForFileCreation = getMetadataGroups('ExecuteLogs', 'Create new class', 'This new class handles execution logic.', false);
            metadataGroupsForFileCreation.addAll(getMetadataGroups('AddTest', 'Write Unit Tests', 'This new class has the unit tests.', false));

            createFile(fileTitle, environmentIds[0], JSON.serializePretty(new PipelineInitializerSaveSelectionsImpl.MetadataGroups(metadataGroupsForFileCreation)));

            PipelineInitializationDetails initializationDetails = new PipelineInitializationDetails();
            initializationDetails.pendingEnvironmentIds = environmentIds;
            initializationDetails.currentEnvironmentId = initializationDetails.pendingEnvironmentIds[0];

            Pipeline pipelineObject = getPipelineObj('MyPipeline');
            new Project(pipelineObject).name(String.format(Label.PipelineInitializerGitSnapshotMessage, new List<String> { 'MyPipeline' }));
            JobTemplate jobTemplate = new JobTemplate().name('SFDX Commit').apiName('sfdx_commit_1');
            new JobStep(jobTemplate).name('CommitMetadat').type('Function');
            createPipelineAction(getPipelineObj('MyPipeline'), jobTemplate, 'Commit').persist();

            updatePipeline(pipeline.Id, JSON.serializePretty(initializationDetails));

            // EXERCISE
            Test.startTest();
            new InitializeWithSelectedMetadataCallback().processMetadataGroup(metadataGroupsForFileCreation[0], pipeline, environmentIds[0]);
            Test.stopTest();

            // VERIFY
            copado__User_Story__c userStory = [SELECT Id, copado__User_Story_Title__c, copado__Functional_Specifications__c, copado__Project__c, copado__Project__r.Name, copado__Project__r.copado__Description__c FROM copado__User_Story__c];
            Assert.isNotNull(userStory, 'There is a user story record');
            Assert.areEqual('Create new class', userStory.copado__User_Story_Title__c, 'The US title does not match');
            Assert.areEqual('This new class handles execution logic.', userStory.copado__Functional_Specifications__c, 'The US specifications do not match');
            Assert.isNotNull(userStory.copado__Project__c, 'The US project is null');
            Assert.areEqual(String.format(Label.PipelineInitializerGitSnapshotMessage, new List<String> { 'MyPipeline' }), userStory.copado__Project__r.Name, 'The project name does not match');

            Assert.isNotNull([SELECT Id FROM copado__JobExecution__c WHERE copado__Template__r.copado__ApiName__c = 'sfdx_commit_1'], 'The commit job is not created');
        }
    }

    // HELPER

    private static void createData() {
        System.runAs(TestUtilities.getRunAsUser()) {

            JobTemplate jobTemplate = new JobTemplate().name('SFDX Initialize Pipeline with Changes').apiName('SFDX_Initialize_Pipeline_with_Changes_1');
            new JobStep(jobTemplate).name('CreateBranch').type('Function');

            Environment dev1 = new Environment().name('Dev1');
            Environment staging = new Environment().name('Staging');
            Environment uat = new Environment().name('Uat');
            new Credential(dev1).default(true).orgId(fflib_IDGenerator.generate('00D'));
            new Credential(staging).default(true).orgId(fflib_IDGenerator.generate('00D'));
            new Credential(uat).default(true).orgId(fflib_IDGenerator.generate('00D'));

            new Pipeline()
                .name('MyPipeline')
                .mainBranch('main')
                .platform('SFDX')
                .add(new Project())
                .add(new PipelineConnection().sourceEnvironment(dev1).destinationEnvironment(staging).destinationBranch('staging').branch('dev1'))
                .add(new PipelineConnection().sourceEnvironment(staging).destinationEnvironment(uat).destinationBranch('uat').branch('staging'))
                .persist();
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

    private static copado__JobExecution__c createJobAndRelatedRecords(Id pipelineId, String jobData, String status) {
        Id templateId = [SELECT Id FROM copado__JobTemplate__c].Id;

        copado__JobExecution__c job = new copado__JobExecution__c(
            copado__Status__c = status,
            copado__Template__c = templateId,
            copado__Pipeline__c = pipelineId,
            copado__DataJson__c = jobData
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
            copado__Status__c = status == 'Successful' ? 'Success' : status == 'Canceled' ? 'Cancelled' : 'Failed',
            copado__JobStep__c = jobStep.Id
        );
        insert result;
        jobStep.copado__Result__c = result.Id;
        update jobStep;

        return job;
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

    private static PipelineAction createPipelineAction(Pipeline pipeline, JobTemplate template, String action) {
        return new PipelineAction(pipeline).template(template).action(action);
    }

    private static copado__Deployment_Flow__c getPipeline(String name) {
        return [SELECT Id FROM copado__Deployment_Flow__c WHERE Name = :name LIMIT 1][0];
    }

    private static Pipeline getPipelineObj(String name) {
        return new Pipeline().recordId(getPipeline(name).Id);
    }
}