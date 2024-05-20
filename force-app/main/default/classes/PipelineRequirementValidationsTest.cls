@IsTest
private class PipelineRequirementValidationsTest {

    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        createData();
    }

    @IsTest
    private static void executeWithPipelineAndFunction() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            copado__Git_Repository__c gitRepository = [SELECT Id FROM copado__Git_Repository__c LIMIT 1];
            copado__Deployment_Flow__c pipeline = [SELECT Id, copado__Git_Repository__c FROM copado__Deployment_Flow__c LIMIT 1];

            pipeline.copado__Git_Repository__c = gitRepository.Id;
            update pipeline;

            new Function().apiName('sfdx_git_repository_validation').persist();

            // EXERCISE
            Test.startTest();
            PipelineRequirementValidations.Requirements requirements = PipelineRequirementValidations.getRequirements(pipeline.Id);
            Test.stopTest();

            // VERIFY
            Assert.isTrue(requirements.isActive, 'Pipeline is not active.');
            Assert.isTrue(requirements.hasConnections, 'Pipeline has no connections.');
            Assert.areEqual('main', requirements.mainBranch, 'The main branch name does not match.');
            Assert.areEqual(gitRepository.Id, requirements.gitRepositoryId, 'Git Repository Id does not match.');
            Assert.areEqual('DX', requirements.gitRepositoryName, 'Git repository name does not match.');
            Assert.isTrue(requirements.hasDefaultAuthCredentials, 'The credentials are not default or authenticated.');
            Assert.areEqual([SELECT Id FROM copado__Result__c LIMIT 1].Id, requirements.repositoryFunctionResultId, 'The result Id for repository function does not match.');
        }
    }

    @IsTest
    private static void executeWithPipelineAndNoFunction() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            copado__Deployment_Flow__c pipeline = [SELECT Id FROM copado__Deployment_Flow__c LIMIT 1];

            // EXERCISE
            Test.startTest();
            PipelineRequirementValidations.Requirements requirements = PipelineRequirementValidations.getRequirements(pipeline.Id);
            Test.stopTest();

            // VERIFY
            Assert.isTrue(requirements.isActive, 'Pipeline is not active.');
            Assert.isTrue(requirements.hasConnections, 'Pipeline has no connections.');
            Assert.areEqual('main', requirements.mainBranch, 'The main branch name does not match.');
            Assert.isNull(requirements.gitRepositoryId, 'Git Repository Id is present.');
            Assert.isTrue(String.isBlank(requirements.gitRepositoryName), 'Git repository name is not blank.');
            Assert.isTrue(requirements.hasDefaultAuthCredentials, 'The credentials are not default or authenticated.');
            Assert.isNull(requirements.repositoryFunctionResultId, 'There is a result Id for repository function.');
        }
    }

    @IsTest
    private static void executeResultDetails() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            copado__Result__c resultRecord = (copado__Result__c) new Result().type('Function').status('Not Started').data('Test').persist();

            // EXERCISE
            Test.startTest();
            copado__Result__c result = PipelineRequirementValidations.getResultDetails(resultRecord.Id);
            Test.stopTest();

            // VERIFY
            Assert.isNotNull(result, 'Result is null');
            Assert.areEqual('Test', result.copado__Result_Data__c, 'Result\'s data does not match');
            Assert.areEqual('Not Started', result.copado__Status__c, 'Result\'s status does not match');
        }
    }

    @IsTest
    private static void executeInitializeMain() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            JobTemplate jobTemplate = new JobTemplate().name('SFDX Git Initialization');
            new JobStep(jobTemplate).name('Initialize').type('Function').persist();

            copado__JobTemplate__c template = [SELECT Id, Name, copado__ApiName__c from copado__JobTemplate__c LIMIT 1];
            template.copado__ApiName__c = 'SFDX Git Initialization_1';
            update template;

            copado__Deployment_Flow__c pipeline = [SELECT Id FROM copado__Deployment_Flow__c LIMIT 1];

            // EXERCISE
            Test.startTest();
            PipelineRequirementValidations.initializeMainBranch(pipeline.Id);
            Test.stopTest();

            // VERIFY
            List<copado__JobExecution__c> jobs = [SELECT Id, copado__Pipeline__c FROM copado__JobExecution__c LIMIT 1];
            String initializationDetails = [SELECT Id, Initialization_Data__c FROM copado__Deployment_Flow__c].Initialization_Data__c;
            PipelineInitializationDetails result = getInitializationDataWithKeys(initializationDetails);

            Assert.areEqual(1, jobs.size(), 'The number of jobs do not match.');
            Assert.areEqual('Initializing main', result.status, 'The status does not match.');
            Assert.isNull(result.initializationType, 'The type is not null');
            Assert.isNull(result.completedDate, 'Completed Date is populated.');
            Assert.areEqual(1, result.activityLog.size(), 'The number of logs do not match');
            Assert.areEqual(Label.InitializeProject, result.activityLog[0].title, 'The log title does not match');
        }
    }

    @IsTest
    private static void executeInitializeMainWithException() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            String exceptionMessage;
            copado__Deployment_Flow__c pipeline = [SELECT Id FROM copado__Deployment_Flow__c LIMIT 1];

            // EXERCISE
            Test.startTest();
            try {
                PipelineRequirementValidations.initializeMainBranch(pipeline.Id);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // VERIFY
            List<copado__JobExecution__c> jobs = [SELECT Id, copado__Pipeline__c FROM copado__JobExecution__c LIMIT 1];
            Assert.areEqual(0, jobs.size(), 'There are jobs created');
            Assert.isNotNull(exceptionMessage, 'There is no exception.');
            Assert.isTrue(exceptionMessage.contains('Invalid template name'), 'The exception message does not match.');
        }
    }

    @IsTest
    private static void executeInitializationDataWithException() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            String exceptionMessage;
            String response;

            // EXERCISE
            Test.startTest();
            try {
                response = PipelineRequirementValidations.getInitializationData(null);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // VERIFY
            Assert.isNull(response, 'There is no response.');
            Assert.isNotNull(exceptionMessage, 'There is no exception.');
            Assert.isTrue(exceptionMessage.contains('List index out of bounds'), 'The exception message does not match.');
        }
    }

    @IsTest
    private static void executeInitializationData() {
        System.runAs(TestUtilities.getRunAsUser()) {

        // SETUP
        String response;
        copado__Deployment_Flow__c pipeline = [SELECT Id FROM copado__Deployment_Flow__c LIMIT 1];

        PipelineInitializationDetails initializationDetails = new PipelineInitializationDetails();
        initializationDetails.initializationType = 'Direct Branch Creation';
        initializationDetails.status = 'Branches created';
        initializationDetails.completedDate = String.valueOf(Datetime.now());

        PipelineInitializationDetails.ActivityLog logEntry = new PipelineInitializationDetails.ActivityLog();
        logEntry.status = 'Success';
        logEntry.title = 'Initialize Project in git repository';

        initializationDetails.activityLog = new List<PipelineInitializationDetails.ActivityLog>{ logEntry };
        updatePipeline(pipeline.Id, JSON.serializePretty(initializationDetails));

        // EXERCISE
        Test.startTest();
            response = PipelineRequirementValidations.getInitializationData(pipeline.Id);
        Test.stopTest();

        // VERIFY
        PipelineInitializationDetails parsedResponse = getInitializationDataWithKeys(response);

        Assert.isNotNull(parsedResponse.initializationType, 'The type is null');
        Assert.isNotNull(parsedResponse.completedDate, 'Completed Date is not populated.');
        Assert.areEqual(1, parsedResponse.activityLog.size(), 'The number of logs do not match');
        Assert.areEqual(Label.InitializeProject, parsedResponse.activityLog[0].title, 'The log title does not match');
        }
    }

    // HELPER

    private static void createData() {
        System.runAs(TestUtilities.getRunAsUser()) {
            Project project = new Project();

            new Repository().name('DX');
            Environment dev = new Environment().name('Dev');
            Environment staging = new Environment().name('Staging');
            new Credential(dev).default(true).orgId(fflib_IDGenerator.generate('00D'));
            new Credential(staging).default(true).orgId(fflib_IDGenerator.generate('00D'));

            new Pipeline()
                .name('MyPipeline')
                .mainBranch('main')
                .platform('SFDX')
                .add(project)
                .add(new PipelineConnection().sourceEnvironment(dev).destinationEnvironment(staging).branch('dev').destinationBranch('main'))
                .persist();
        }
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
}