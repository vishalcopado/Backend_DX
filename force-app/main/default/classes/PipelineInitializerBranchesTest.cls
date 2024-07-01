@IsTest
public with sharing class PipelineInitializerBranchesTest {

    private static final String BRANCHES_ONLY = 'Direct Branch Creation';
    private static final String WIP_FULL = 'WIP Full';
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
    private static void executeWithCompleteRequest() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;

            PipelineInitializationDetails initializationDetails = new PipelineInitializationDetails();
            initializationDetails.initializationType = BRANCHES_ONLY;
            initializationDetails.status = MAIN_INITIALIZED;
            updatePipeline(pipelineId, JSON.serializePretty(initializationDetails));

            // EXERCISE
            Test.startTest();
            PipelineInitializerBranches.createBranches(pipelineId, JSON.serialize(initializationDetails));
            Test.stopTest();

            // VERIFY
            String pipelineInitializationDetails = [SELECT Id, Initialization_Data__c FROM copado__Deployment_Flow__c].Initialization_Data__c;
            PipelineInitializationDetails result = getInitializationDataWithKeys(pipelineInitializationDetails);
            Id jobId = [SELECT Id FROM copado__JobExecution__c LIMIT 1].Id;

            Assert.isNotNull(jobId, 'Response is null');
            Assert.areEqual(1, result.activityLog.size(), 'The number of log entries do not match');
            Assert.areEqual(Label.CreatingBranches, result.activityLog[0].title, 'The log title does not match');
            Assert.areEqual('In Progress', result.activityLog[0].status, 'The log status does not match');
            Assert.areEqual(false, result.areChangesSelected, 'The value does not match');
        }
    }

    @IsTest
    private static void executeForWipFull() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;
            List<Id> environmentIds = getEnvironmentIds();

            PipelineInitializationDetails initializationDetails = new PipelineInitializationDetails();
            initializationDetails.initializationType = WIP_FULL;
            initializationDetails.status = MAIN_INITIALIZED;
            initializationDetails.areChangesSelected = false;
            initializationDetails.pendingEnvironmentIds = environmentIds;
            initializationDetails.currentEnvironmentId = initializationDetails.pendingEnvironmentIds[0];

            updatePipeline(pipelineId, JSON.serializePretty(initializationDetails));

            JobTemplate jobTemplate = new JobTemplate().name('SFDX Initialize Pipeline with Changes').apiName('SFDX_Initialize_Pipeline_with_Changes_1');
            new JobStep(jobTemplate).name('Initialize').type('Function').persist();

            // EXERCISE
            Test.startTest();
            PipelineInitializerBranches.createBranches(pipelineId, JSON.serialize(initializationDetails));
            Test.stopTest();

            // VERIFY
            String pipelineInitializationDetails = [SELECT Id, Initialization_Data__c FROM copado__Deployment_Flow__c].Initialization_Data__c;
            PipelineInitializationDetails result = getInitializationDataWithKeys(pipelineInitializationDetails);
            Id jobId = [SELECT Id FROM copado__JobExecution__c LIMIT 1].Id;

            Assert.isNotNull(jobId, 'Response is null');
            Assert.areEqual(true, result.areChangesSelected, 'The value does not match');
        }
    }

    @IsTest
    private static void executeWithIncompleteRequest() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            String exceptionMessage;

            PipelineInitializationDetails initializationDetails = new PipelineInitializationDetails();
            initializationDetails.initializationType = BRANCHES_ONLY;
            initializationDetails.status = MAIN_INITIALIZED;

            // EXERCISE
            Test.startTest();
            try {
                PipelineInitializerBranches.createBranches(null, JSON.serialize(initializationDetails));
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // VERIFY
            Assert.isNotNull(exceptionMessage, 'There is no exception');
            Assert.isTrue(exceptionMessage.contains(String.format(Label.MissingRequiredParameters, new List<String> {'Pipeline Id'})), 'There is a different exception');
        }
    }

    @IsTest
    private static void executeWithExcetoptionOnRunDifferenceAnalysis() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            String exceptionMessage;

            // EXERCISE
            Test.startTest();
            try {
                PipelineInitializerBranches.runDifferenceAnalysis(null);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // VERIFY
            Assert.isNotNull(exceptionMessage, 'There is no exception');
            Assert.isTrue(exceptionMessage.contains(String.format(Label.MissingRequiredParameters, new List<String> {'Pipeline Id'})), 'There is a different exception');
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
}