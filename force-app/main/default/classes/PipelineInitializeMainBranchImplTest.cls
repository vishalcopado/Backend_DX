@IsTest
private class PipelineInitializeMainBranchImplTest {

    private static final String SFDX_GIT_INITIALIZATION = 'SFDX Git Initialization_1';

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
                PipelineInitializer.PreSteps.initializeMainBranch(new PipelineInitializer.InitializeMainBranchRequest());
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
                PipelineInitializer.InitializeMainBranchRequest request = new PipelineInitializer.InitializeMainBranchRequest();
                request.initializationType = 'Direct Branch Creation';
                request.pipelineId = user.Id;

                PipelineInitializer.PreSteps.initializeMainBranch(request);
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
                PipelineInitializer.InitializeMainBranchRequest request = new PipelineInitializer.InitializeMainBranchRequest();
                request.initializationType = 'Direct Branch Creation';
                request.pipelineId = pipelineId;

                PipelineInitializer.PreSteps.initializeMainBranch(request);
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
    private static void executeWithPipelineWithoutDestinationBranch() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            String exceptionMessage;

            Environment integration = new Environment().name('Int');
            Environment prod = new Environment().name('Prod');
            new Credential(integration).default(true);
            new Credential(prod).default(true);

            new Pipeline()
                .name('TestPipeline')
                .mainBranch('main')
                .platform('SFDX')
                .add(new PipelineConnection().sourceEnvironment(integration).destinationEnvironment(prod).branch('develop'))
            .persist();

            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c WHERE Name = 'TestPipeline' LIMIT 1].Id;

            // EXERCISE
            Test.startTest();
            try {
                PipelineInitializer.InitializeMainBranchRequest request = new PipelineInitializer.InitializeMainBranchRequest();
                request.initializationType = 'Direct Branch Creation';
                request.pipelineId = pipelineId;

                PipelineInitializer.PreSteps.initializeMainBranch(request);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // VERIFY
            Assert.isNotNull(exceptionMessage, 'There is no exception');
            Assert.areEqual(Label.VisitPipelineManager, exceptionMessage, 'There is a different exception');
        }
    }

    @IsTest
    private static void executeWithCompleteRequest() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;

            // EXERCISE
            Test.startTest();
            PipelineInitializer.InitializeMainBranchRequest request = new PipelineInitializer.InitializeMainBranchRequest();
            request.initializationType = 'Direct Branch Creation';
            request.pipelineId = pipelineId;

            PipelineInitializer.InitializeMainBranchResult response = PipelineInitializer.PreSteps.initializeMainBranch(request);
            Test.stopTest();

            // VERIFY
            List<copado__JobExecution__c> jobs = [SELECT Id, copado__DataJson__c, copado__Pipeline__c FROM copado__JobExecution__c LIMIT 1];
            String initializationDetails = [SELECT Id, Initialization_Data__c FROM copado__Deployment_Flow__c].Initialization_Data__c;

            PipelineInitializeMainBranchImpl.ProjectInitializationDetails projectDetails = (PipelineInitializeMainBranchImpl.ProjectInitializationDetails) JSON.deserialize(jobs[0].copado__DataJson__c, PipelineInitializeMainBranchImpl.ProjectInitializationDetails.class);

            Assert.isNotNull(response, 'Response is null');
            Assert.areEqual(jobs[0].Id, response.jobExecution.Id, 'The job Id does not match');

            Assert.isTrue(projectDetails.forceBranchCreation, 'The forceBranchCreation value should be true');
            Assert.isFalse(projectDetails.recreateProject, 'The recreateProject value should be false');
            Assert.areEqual('standard', projectDetails.template, 'The template value does not match');
            Assert.areEqual('force-app', projectDetails.defaultDirectory, 'The default directory value does not match');
            Assert.areEqual('main', projectDetails.branch, 'The branch value does not match');

            PipelineInitializationDetails result = getInitializationDataWithKeys(initializationDetails);
            Assert.areEqual('Initializing main', result.status, 'The status does not match.');
            Assert.areEqual('Direct Branch Creation', result.initializationType, 'The type does not match');
            Assert.isNull(result.completedDate, 'Completed Date is populated.');
            Assert.areEqual(jobs[0].Id, result.latestJobExecutionId, 'The job Id does not match');
            Assert.areEqual(1, result.activityLog.size(), 'The number of logs do not match');
            Assert.areEqual(Label.InitializeProject, result.activityLog[0].title, 'The log title does not match');
        }
    }

    @IsTest
    private static void executeWithoutInitializationType() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;

            // EXERCISE
            Test.startTest();
            PipelineInitializer.InitializeMainBranchRequest request = new PipelineInitializer.InitializeMainBranchRequest();
            request.pipelineId = pipelineId;

            PipelineInitializer.InitializeMainBranchResult response = PipelineInitializer.PreSteps.initializeMainBranch(request);
            Test.stopTest();

            // VERIFY
            List<copado__JobExecution__c> jobs = [SELECT Id, copado__Pipeline__c FROM copado__JobExecution__c LIMIT 1];
            String initializationDetails = [SELECT Id, Initialization_Data__c FROM copado__Deployment_Flow__c].Initialization_Data__c;

            Assert.isNotNull(response, 'Response is null');
            Assert.areEqual(jobs[0].Id, response.jobExecution.Id, 'The job Id does not match');

            PipelineInitializationDetails result = getInitializationDataWithKeys(initializationDetails);
            Assert.areEqual('Initializing main', result.status, 'The status does not match.');
            Assert.isNull(result.initializationType, 'The type is not null');
            Assert.isNull(result.completedDate, 'Completed Date is populated.');
            Assert.areEqual(jobs[0].Id, result.latestJobExecutionId, 'The job Id does not match');
            Assert.areEqual(1, result.activityLog.size(), 'The number of logs do not match');
            Assert.areEqual(Label.InitializeProject, result.activityLog[0].title, 'The log title does not match');
        }
    }

    @IsTest
    private static void executeWithExistingData() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;

            PipelineInitializationDetails initializationDetails = new PipelineInitializationDetails();
            initializationDetails.initializationType = 'WIP Full';
            initializationDetails.status = 'Initializing main';
            updatePipeline(pipelineId, JSON.serializePretty(initializationDetails));

            String currentInitializationDetails = [SELECT Id, Initialization_Data__c FROM copado__Deployment_Flow__c].Initialization_Data__c;
            PipelineInitializationDetails result = getInitializationDataWithKeys(currentInitializationDetails);
            Assert.areEqual('Initializing main', result.status, 'The status does not match.');
            Assert.areEqual('WIP Full', result.initializationType, 'The type does not match.');

            // EXERCISE
            Test.startTest();
            PipelineInitializer.InitializeMainBranchRequest request = new PipelineInitializer.InitializeMainBranchRequest();
            request.initializationType = 'WIP Full';
            request.pipelineId = pipelineId;

            PipelineInitializer.InitializeMainBranchResult response = PipelineInitializer.PreSteps.initializeMainBranch(request);
            Test.stopTest();

            // VERIFY
            List<copado__JobExecution__c> jobs = [SELECT Id, copado__Pipeline__c FROM copado__JobExecution__c LIMIT 1];
            String latestInitializationDetails = [SELECT Id, Initialization_Data__c FROM copado__Deployment_Flow__c].Initialization_Data__c;

            Assert.isNotNull(response, 'Response is null');
            Assert.areEqual(jobs[0].Id, response.jobExecution.Id, 'The job Id does not match');

            PipelineInitializationDetails resultInitializationDetails = getInitializationDataWithKeys(latestInitializationDetails);
            Assert.areEqual('Initializing main', resultInitializationDetails.status, 'The status does not match.');
            Assert.areEqual('WIP Full', resultInitializationDetails.initializationType, 'The type does not match');
            Assert.isNull(resultInitializationDetails.completedDate, 'Completed Date is populated.');
            Assert.areEqual(jobs[0].Id, resultInitializationDetails.latestJobExecutionId, 'The job Id does not match');
            Assert.areEqual(1, resultInitializationDetails.activityLog.size(), 'The number of logs do not match');
            Assert.areEqual(Label.InitializeProject, resultInitializationDetails.activityLog[0].title, 'The log title does not match');
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

            new Pipeline()
                .name('MyPipeline')
                .mainBranch('main')
                .platform('SFDX')
                .add(project)
                .add(new PipelineConnection().sourceEnvironment(dev1).destinationEnvironment(staging).destinationBranch('main').branch('staging'))
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