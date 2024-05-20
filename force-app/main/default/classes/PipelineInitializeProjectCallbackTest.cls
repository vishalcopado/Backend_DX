@IsTest
private class PipelineInitializeProjectCallbackTest {

    private static final String SFDX_GIT_INITIALIZATION = 'SFDX Git Initialization_1';

    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
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
                new PipelineInitializeProjectCallback().execute(job, 'Error');
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY
            Assert.isNotNull(exceptionMessage, 'There is no exception');
            Assert.isTrue(exceptionMessage.contains(String.format(Label.MissingRequiredParameters, new List<String> { Label.PipelineInitializationData })), 'The exception message does not match');
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
            new PipelineInitializeProjectCallback().execute(job, 'Error');

            // VERIFY
            Assert.areEqual(0, [SELECT COUNT() FROM copado__Git_Backup__c], 'Snapshot record is created');

            String initializationDetails = [SELECT Id, Initialization_Data__c FROM copado__Deployment_Flow__c].Initialization_Data__c;
            PipelineInitializationDetails initializationDataWithKeys = getInitializationDataWithKeys(initializationDetails);
            Assert.areEqual(1, initializationDataWithKeys.activityLog.size(), 'The number of log entries do not match');
            Assert.areEqual('Test1', initializationDataWithKeys.activityLog[0].title, 'The log title does not match');
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
            new PipelineInitializeProjectCallback().execute(job, 'Canceled');

            // VERIFY
            Assert.areEqual(0, [SELECT COUNT() FROM copado__Git_Backup__c], 'Snapshot record is created');

            String initializationDetails = [SELECT Id, Initialization_Data__c FROM copado__Deployment_Flow__c].Initialization_Data__c;
            PipelineInitializationDetails initializationDataWithKeys = getInitializationDataWithKeys(initializationDetails);
            Assert.areEqual(1, initializationDataWithKeys.activityLog.size(), 'The number of log entries do not match');
            Assert.areEqual('Test1', initializationDataWithKeys.activityLog[0].title, 'The log title does not match');
            Assert.areEqual('Cancelled', initializationDataWithKeys.activityLog[0].status, 'The log status does not match');
        }
    }

    @IsTest
    private static void executeCallbackWithErroredJobAndFailedResultData() {
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
                copado__JobStep__c = jobStep.Id,
                copado__Result_Data__c = '{"projectInitialized" : false}'
            );
            insert result;
            jobStep.copado__Result__c = result.Id;
            update jobStep;

            // EXERCISE
            new PipelineInitializeProjectCallback().execute(job, 'Error');

            // VERIFY
            Assert.areEqual(0, [SELECT COUNT() FROM copado__Git_Backup__c], 'Snapshot record is created');
            String initializationDetails = [SELECT Id, Initialization_Data__c FROM copado__Deployment_Flow__c].Initialization_Data__c;
            PipelineInitializationDetails initializationDataWithKeys = getInitializationDataWithKeys(initializationDetails);
            Assert.areEqual(1, initializationDataWithKeys.activityLog.size(), 'The number of log entries do not match');
            Assert.areEqual('Test1', initializationDataWithKeys.activityLog[0].title, 'The log title does not match');
            Assert.areEqual('Error', initializationDataWithKeys.activityLog[0].status, 'The log status does not match');
        }
    }

    @IsTest
    private static void executeCallbackWithErroredJobAndTrueResultData() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            JobTemplate jobTemplate = new JobTemplate().name('SFDX Git Snapshot').type('Custom').apiName('SFDX_Git_Snapshot_1');
            new JobStep(jobTemplate).name('Snapshot').type('Function');
            createPipelineAction(getPipelineObj('MyPipeline'), jobTemplate, 'TakeSnapshot').persist();

            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;
            Id templateId = [SELECT Id FROM copado__JobTemplate__c WHERE Name = 'SFDX Git Initialization'].Id;
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
                copado__JobStep__c = jobStep.Id,
                copado__Result_Data__c = '{"projectInitialized" : true}'
            );
            insert result;
            jobStep.copado__Result__c = result.Id;
            update jobStep;

            // EXERCISE
            Test.startTest();
            new PipelineInitializeProjectCallback().execute(job, 'Error');
            Test.stopTest();

            // VERIFY
            copado__Git_Backup__c snapshot = [SELECT Id, Name, copado__Pipeline__c, copado__Branch__c, copado__Git_Repository__c, copado__Org__c FROM copado__Git_Backup__c];
            Assert.areEqual(0, Limits.getEmailInvocations(), 'No email is sent');
            Assert.isNotNull(snapshot, 'Snapshot record is not created');
            Assert.areEqual(String.format(Label.PipelineInitializerGitSnapshotMessage, new List<String> {'Staging'}), snapshot.Name, 'Snapshot name does not match.');
            Assert.areEqual(pipelineId, snapshot.copado__Pipeline__c, 'Pipeline Id does not match');
            Assert.areEqual('main', snapshot.copado__Branch__c, 'Branch name does not match');
            Assert.areEqual([SELECT Id FROM copado__Git_Repository__c].Id, snapshot.copado__Git_Repository__c, 'Repository does not match');
            Assert.areEqual([SELECT Id FROM copado__Org__c WHERE copado__Environment__r.Name = 'Staging' AND copado__Default_Credential__c = true AND copado__SFDC_Org_ID__c = 'a00Y'].Id, snapshot.copado__Org__c, 'Credential does not match');
            Assert.areEqual(1, [SELECT COUNT() FROM copado__Git_Org_Commit__c], 'Snapshot commit does not exist');
            Assert.areEqual(2, [SELECT COUNT() FROM copado__JobExecution__c], 'Job Execution count does not match');

            String initializationDetails = [SELECT Id, Initialization_Data__c FROM copado__Deployment_Flow__c].Initialization_Data__c;
            PipelineInitializationDetails initializationDataWithKeys = getInitializationDataWithKeys(initializationDetails);
            Assert.areEqual(3, initializationDataWithKeys.activityLog.size(), 'The number of log entries do not match');
            Assert.areEqual('Test1', initializationDataWithKeys.activityLog[0].title, 'The log title does not match');
            Assert.areEqual('Success', initializationDataWithKeys.activityLog[0].status, 'The log status does not match');
            Assert.areEqual(Label.ProjectInitialized, initializationDataWithKeys.activityLog[1].title, 'The log title does not match');
            Assert.areEqual('Success', initializationDataWithKeys.activityLog[1].status, 'The log status does not match');
            Assert.areEqual(Label.SnapshotMessage, initializationDataWithKeys.activityLog[2].title, 'The log title does not match');

            Id jobId = [SELECT Id FROM copado__JobExecution__c WHERE copado__Template__r.copado__ApiName__c = 'SFDX_Git_Snapshot_1'].Id;
            Assert.areEqual(jobId, initializationDataWithKeys.latestJobExecutionId, 'The job Id does not match');
        }
    }

    @IsTest
    private static void executeCallbackWithSuccessfulJob() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            JobTemplate jobTemplate = new JobTemplate().name('SFDX Git Snapshot').type('Custom').apiName('SFDX_Git_Snapshot_1');
            new JobStep(jobTemplate).name('Snapshot').type('Function');
            createPipelineAction(getPipelineObj('MyPipeline'), jobTemplate, 'TakeSnapshot').persist();

            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;
            Id templateId = [SELECT Id FROM copado__JobTemplate__c WHERE Name = 'SFDX Git Initialization'].Id;
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
                copado__JobStep__c = jobStep.Id,
                copado__Result_Data__c = '{"projectInitialized" : true}'
            );
            insert result;
            jobStep.copado__Result__c = result.Id;
            update jobStep;

            // EXERCISE
            Test.startTest();
            new PipelineInitializeProjectCallback().execute(job, 'Successful');
            Test.stopTest();

            // VERIFY
            copado__Git_Backup__c snapshot = [SELECT Id, Name, copado__Pipeline__c, copado__Branch__c, copado__Git_Repository__c, copado__Org__c FROM copado__Git_Backup__c];
            Assert.areEqual(0, Limits.getEmailInvocations(), 'No email is sent');
            Assert.isNotNull(snapshot, 'Snapshot record is not created');
            Assert.areEqual(String.format(Label.PipelineInitializerGitSnapshotMessage, new List<String> {'Staging'}), snapshot.Name, 'Snapshot name does not match.');
            Assert.areEqual(pipelineId, snapshot.copado__Pipeline__c, 'Pipeline Id does not match');
            Assert.areEqual('main', snapshot.copado__Branch__c, 'Branch name does not match');
            Assert.areEqual([SELECT Id FROM copado__Git_Repository__c].Id, snapshot.copado__Git_Repository__c, 'Repository does not match');
            Assert.areEqual([SELECT Id FROM copado__Org__c WHERE copado__Environment__r.Name = 'Staging' AND copado__Default_Credential__c = true AND copado__SFDC_Org_ID__c = 'a00Y'].Id, snapshot.copado__Org__c, 'Credential does not match');
            Assert.areEqual(1, [SELECT Count() FROM copado__Git_Org_Commit__c], 'Snapshot commit does not exist');
            Assert.areEqual(2, [SELECT COUNT() FROM copado__JobExecution__c], 'Job Execution count does not match');

            String initializationDetails = [SELECT Id, Initialization_Data__c FROM copado__Deployment_Flow__c].Initialization_Data__c;
            PipelineInitializationDetails initializationDataWithKeys = getInitializationDataWithKeys(initializationDetails);
            Assert.areEqual(3, initializationDataWithKeys.activityLog.size(), 'The number of log entries do not match');
            Assert.areEqual('Test1', initializationDataWithKeys.activityLog[0].title, 'The log title does not match');
            Assert.areEqual('Success', initializationDataWithKeys.activityLog[0].status, 'The log status does not match');
            Assert.areEqual(Label.ProjectInitialized, initializationDataWithKeys.activityLog[1].title, 'The log title does not match');
            Assert.areEqual('Success', initializationDataWithKeys.activityLog[1].status, 'The log status does not match');
            Assert.areEqual(Label.SnapshotMessage, initializationDataWithKeys.activityLog[2].title, 'The log title does not match');

            Id jobId = [SELECT Id FROM copado__JobExecution__c WHERE copado__Template__r.copado__ApiName__c = 'SFDX_Git_Snapshot_1'].Id;
            Assert.areEqual(jobId, initializationDataWithKeys.latestJobExecutionId, 'The job Id does not match');
        }
    }

    @IsTest
    private static void executeCallbackWithNonSFDXEnvironment() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            JobTemplate jobTemplate = new JobTemplate().name('SFDX Git Snapshot').type('Custom').apiName('SFDX_Git_Snapshot_1');
            new JobStep(jobTemplate).name('Snapshot').type('Function');
            createPipelineAction(getPipelineObj('MyPipeline'), jobTemplate, 'TakeSnapshot').persist();

            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;
            Id templateId = [SELECT Id FROM copado__JobTemplate__c WHERE Name = 'SFDX Git Initialization'].Id;
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
                copado__JobStep__c = jobStep.Id,
                copado__Result_Data__c = '{"projectInitialized" : true}'
            );
            insert result;
            jobStep.copado__Result__c = result.Id;
            update jobStep;

            copado__Environment__c stagingEnvironment = [SELECT Id, copado__Platform__c FROM copado__Environment__c WHERE Name = 'Staging'];
            stagingEnvironment.copado__Platform__c = 'Salesforce';
            update stagingEnvironment;

            // EXERCISE
            Test.startTest();
            new PipelineInitializeProjectCallback().execute(job, 'Successful');
            Test.stopTest();

            // VERIFY
            Assert.areEqual(0, Limits.getEmailInvocations(), 'No email is sent');
            Assert.areEqual(0, [SELECT Count() FROM copado__Git_Org_Commit__c], 'Snapshot commit exists');
            Assert.areEqual(0, [SELECT Count() FROM copado__Git_Backup__c], 'Snapshot record exists');
            Assert.areEqual(1, [SELECT COUNT() FROM copado__JobExecution__c], 'Job Execution count does not match');

            String initializationDetails = [SELECT Id, Initialization_Data__c FROM copado__Deployment_Flow__c].Initialization_Data__c;
            PipelineInitializationDetails initializationDataWithKeys = getInitializationDataWithKeys(initializationDetails);
            Assert.areEqual(2, initializationDataWithKeys.activityLog.size(), 'The number of log entries do not match');
            Assert.areEqual('Test1', initializationDataWithKeys.activityLog[0].title, 'The log title does not match');
            Assert.areEqual('Success', initializationDataWithKeys.activityLog[0].status, 'The log status does not match');
            Assert.areEqual(Label.SnapshotCreationError, initializationDataWithKeys.activityLog[1].title, 'The log title does not match');
            Assert.areEqual('Error', initializationDataWithKeys.activityLog[1].status, 'The log status does not match');
        }
    }

    // HELPER

    private static void createData() {
        System.runAs(TestUtilities.getRunAsUser()) {
            JobTemplate jobTemplate = new JobTemplate().name('SFDX Git Initialization');
            new JobStep(jobTemplate).name('Initialize').type('Function');

            Project project = new Project();

            new Repository().name('DX');
            Environment dev1 = new Environment().name('Dev1');
            Environment staging = new Environment().name('Staging');
            new Credential(dev1).default(true).orgId('a00X');
            new Credential(staging).default(true).orgId('a00Y');

            PipelineInitializationDetails initializationDetails = new PipelineInitializationDetails();
            initializationDetails.initializationType = 'Direct Branch Creation';
            initializationDetails.status = 'Initializing main';

            PipelineInitializationDetails.ActivityLog logEntry = new PipelineInitializationDetails.ActivityLog();
            logEntry.status = 'In Progress';
            logEntry.title = 'Test1';

            initializationDetails.activityLog = new List<PipelineInitializationDetails.ActivityLog>{ logEntry };

            new Pipeline()
                .name('MyPipeline')
                .mainBranch('main')
                .platform('SFDX')
                .initializationData(JSON.serializePretty(initializationDetails))
                .add(project)
                .add(new PipelineConnection().sourceEnvironment(dev1).destinationEnvironment(staging).destinationBranch('staging').branch('dev1'))
            .persist();

            copado__Git_Repository__c gitRepository = [SELECT Id FROM copado__Git_Repository__c LIMIT 1];
            copado__Deployment_Flow__c pipelineRecord = [SELECT Id, copado__Git_Repository__c FROM copado__Deployment_Flow__c LIMIT 1];
            pipelineRecord.copado__Git_Repository__c = gitRepository.Id;
            update pipelineRecord;

            copado__JobTemplate__c template = [SELECT Id, Name, copado__ApiName__c from copado__JobTemplate__c LIMIT 1];
            template.copado__ApiName__c = SFDX_GIT_INITIALIZATION;
            update template;
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

    private static PipelineInitializationDetails getInitializationDataWithKeys(String initializationDetails) {
        return (PipelineInitializationDetails) JSON.deserialize(initializationDetails, PipelineInitializationDetails.class);
    }
}