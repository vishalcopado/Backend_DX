@IsTest
private class PipelineDifferenceAnalysisCallbackTest {
    
    private static final String DIFFERENCE_METADATA = 'DifferenceMetadata';

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
            Test.startTest();
            try {
                new PipelineDifferenceAnalysisCallback().execute(job, 'Error');
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

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
            Test.startTest();
            new PipelineDifferenceAnalysisCallback().execute(job, 'Error');
            Test.stopTest();

            // VERIFY
            String initializationDetails = getInitializationDetails();

            PipelineInitializationDetails initializationDataWithKeys = getInitializationDataWithKeys(initializationDetails);
            Assert.areEqual('Error', initializationDataWithKeys.diffAnalysisStatus, 'The status does not match.');
            Assert.areEqual(1, initializationDataWithKeys.activityLog.size(), 'The number of log entries do not match');
            Assert.areEqual(Label.CalculatingDifferences, initializationDataWithKeys.activityLog[0].title, 'The log title does not match');
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
            Test.startTest();
            new PipelineDifferenceAnalysisCallback().execute(job, 'Canceled');
            Test.stopTest();

            // VERIFY
            String initializationDetails = getInitializationDetails();

            PipelineInitializationDetails initializationDataWithKeys = getInitializationDataWithKeys(initializationDetails);
            Assert.areEqual('Error', initializationDataWithKeys.diffAnalysisStatus, 'The status does not match.');
            Assert.areEqual(1, initializationDataWithKeys.activityLog.size(), 'The number of log entries do not match');
            Assert.areEqual(Label.CalculatingDifferences, initializationDataWithKeys.activityLog[0].title, 'The log title does not match');
            Assert.areEqual('Cancelled', initializationDataWithKeys.activityLog[0].status, 'The log status does not match');
        }
    }

    @IsTest
    private static void executeCallbackWithSuccessfulJobWithNoFile() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;
            Id sourceEnvId = [SELECT Id FROM copado__Environment__c WHERE Name = 'Staging'].Id;

            Id templateId = [SELECT Id FROM copado__JobTemplate__c].Id;
            copado__JobExecution__c job = new copado__JobExecution__c(
                copado__Status__c = 'Successful',
                copado__Template__c = templateId,
                copado__Pipeline__c = pipelineId,
                copado__Source__c = sourceEnvId
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
            new PipelineDifferenceAnalysisCallback().execute(job, 'Successful');
            Test.stopTest();

            // VERIFY
            String initializationDetails = getInitializationDetails();
            
            PipelineInitializationDetails initializationDataWithKeys = getInitializationDataWithKeys(initializationDetails);
            Assert.areEqual(null, initializationDataWithKeys.diffAnalysisStatus, 'The status does not match.');
            Assert.areEqual(1, initializationDataWithKeys.activityLog.size(), 'The number of log entries do not match');
            Assert.areEqual(Label.CalculatingDifferences, initializationDataWithKeys.activityLog[0].title, 'The log title does not match');
            Assert.areEqual('In Progress', initializationDataWithKeys.activityLog[0].status, 'The log status does not match');
        }
    }

    @IsTest
    private static void executeSuccessCallbackWithOneEnvironmentFile() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;
            Id sourceEnvId = [SELECT Id FROM copado__Environment__c WHERE Name = 'Staging'].Id;
            String fileTitle = pipelineId + '_' + sourceEnvId + '_' + DIFFERENCE_METADATA;
            createFile(fileTitle, sourceEnvId);

            Id templateId = [SELECT Id FROM copado__JobTemplate__c].Id;
            copado__JobExecution__c job = new copado__JobExecution__c(
                copado__Status__c = 'Successful',
                copado__Template__c = templateId,
                copado__Pipeline__c = pipelineId,
                copado__Source__c = sourceEnvId
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
            new PipelineDifferenceAnalysisCallback().execute(job, 'Successful');
            Test.stopTest();

            // VERIFY
            String initializationDetails = getInitializationDetails();
            
            PipelineInitializationDetails initializationDataWithKeys = getInitializationDataWithKeys(initializationDetails);
            Assert.areEqual(null, initializationDataWithKeys.diffAnalysisStatus, 'The status does not match.');
            Assert.areEqual(1, initializationDataWithKeys.activityLog.size(), 'The number of log entries do not match');
            Assert.areEqual(Label.CalculatingDifferences, initializationDataWithKeys.activityLog[0].title, 'The log title does not match');
            Assert.areEqual('In Progress', initializationDataWithKeys.activityLog[0].status, 'The log status does not match');
        }
    }

    @IsTest
    private static void executeSuccessCallbackWithAllEnvironmentFiles() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;
            List<copado__Environment__c> environments = [SELECT Id, Name FROM copado__Environment__c WHERE Name IN ('Staging', 'Production', 'Preprod')];

            Id sourceEnvId;
            for (copado__Environment__c environment : environments) {
                String fileTitle = pipelineId + '_' + environment.Id + '_' + DIFFERENCE_METADATA;
                createFile(fileTitle, environment.Id);
                if (environment.Name == 'Staging') {
                    sourceEnvId = environment.Id;
                }
            }

            Id templateId = [SELECT Id FROM copado__JobTemplate__c].Id;
            copado__JobExecution__c job = new copado__JobExecution__c(
                copado__Status__c = 'Successful',
                copado__Template__c = templateId,
                copado__Pipeline__c = pipelineId,
                copado__Source__c = sourceEnvId
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
            new PipelineDifferenceAnalysisCallback().execute(job, 'Successful');
            Test.stopTest();

            // VERIFY
            String initializationDetails = getInitializationDetails();
            
            PipelineInitializationDetails initializationDataWithKeys = getInitializationDataWithKeys(initializationDetails);
            Assert.areEqual(1, initializationDataWithKeys.activityLog.size(), 'The number of log entries do not match');
            Assert.areEqual(Label.CalculatingDifferences, initializationDataWithKeys.activityLog[0].title, 'The log title does not match');
            Assert.areEqual('Success', initializationDataWithKeys.activityLog[0].status, 'The log status does not match');
            Assert.areEqual('Complete', initializationDataWithKeys.diffAnalysisStatus, 'The status does not match.');
        }
    }

    @IsTest
    private static void executeSuccessCallbackWithOldFile() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;
            Id sourceEnvId = [SELECT Id FROM copado__Environment__c WHERE Name = 'Staging'].Id;
            String fileTitle = pipelineId + '_' + sourceEnvId + '_' + DIFFERENCE_METADATA;
            createFile(fileTitle, sourceEnvId);
            TestUtilities.delay(3);
            createFile(fileTitle, sourceEnvId); // To test when the function has been run more than once

            List<ContentDocumentLink> currentContentDocumentLinks = [SELECT Id, ContentDocument.Title, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :sourceEnvId];
            Assert.areEqual(2, currentContentDocumentLinks.size(), 'The number of files do not match.');

            Id templateId = [SELECT Id FROM copado__JobTemplate__c].Id;
            copado__JobExecution__c job = new copado__JobExecution__c(
                copado__Status__c = 'Successful',
                copado__Template__c = templateId,
                copado__Pipeline__c = pipelineId,
                copado__Source__c = sourceEnvId
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
            new PipelineDifferenceAnalysisCallback().execute(job, 'Successful');
            Test.stopTest();

            // VERIFY
            String initializationDetails = getInitializationDetails();
            
            PipelineInitializationDetails initializationDataWithKeys = getInitializationDataWithKeys(initializationDetails);
            Assert.areEqual(null, initializationDataWithKeys.diffAnalysisStatus, 'The status does not match.');
            Assert.areEqual(1, initializationDataWithKeys.activityLog.size(), 'The number of log entries do not match');
            Assert.areEqual(Label.CalculatingDifferences, initializationDataWithKeys.activityLog[0].title, 'The log title does not match');
            Assert.areEqual('In Progress', initializationDataWithKeys.activityLog[0].status, 'The log status does not match');

            List<ContentDocumentLink> contentDocumentLinks = [SELECT Id, ContentDocument.Title, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :sourceEnvId];
            Assert.areEqual(1, contentDocumentLinks.size(), 'The number of files do not match.');
        }
    }

    // HELPER

    private static void createData() {
        System.runAs(TestUtilities.getRunAsUser()) {
            JobTemplate jobTemplate = new JobTemplate().name('SFDX Diff Analysis');
            new JobStep(jobTemplate).name('Run').type('Function');

            Environment dev1 = new Environment().name('Dev1');
            Environment staging = new Environment().name('Staging');
            Environment preprod = new Environment().name('Preprod');
            Environment prod = new Environment().name('Production');
            new Credential(dev1).default(true).orgId(fflib_IDGenerator.generate('00D'));
            new Credential(staging).default(true).orgId(fflib_IDGenerator.generate('00D'));
            new Credential(preprod).default(true).orgId(fflib_IDGenerator.generate('00D'));
            new Credential(prod).default(true).orgId(fflib_IDGenerator.generate('00D'));

            PipelineInitializationDetails initializationDetails = new PipelineInitializationDetails();
            initializationDetails.initializationType = 'WIP Diff Grid';
            initializationDetails.status = 'Main initialzed';

            PipelineInitializationDetails.ActivityLog logEntry = new PipelineInitializationDetails.ActivityLog();
            logEntry.status = 'In Progress';
            logEntry.title = Label.CalculatingDifferences;

            initializationDetails.activityLog = new List<PipelineInitializationDetails.ActivityLog>{ logEntry };

            new Pipeline()
                .name('MyPipeline')
                .mainBranch('main')
                .platform('SFDX')
                .initializationData(JSON.serializePretty(initializationDetails))
                .add(new Project())
                .add(new PipelineConnection().sourceEnvironment(dev1).destinationEnvironment(staging).destinationBranch('staging').branch('dev1'))
                .add(new PipelineConnection().sourceEnvironment(staging).destinationEnvironment(preprod).destinationBranch('preprod').branch('staging'))
                .add(new PipelineConnection().sourceEnvironment(preprod).destinationEnvironment(prod).destinationBranch('main').branch('preprod'))
            .persist();
        }
    }

    private static PipelineInitializationDetails getInitializationDataWithKeys(String initializationDetails) {
        return (PipelineInitializationDetails) JSON.deserialize(initializationDetails, PipelineInitializationDetails.class);
    }

    private static String getInitializationDetails() {
        return [SELECT Id, Initialization_Data__c FROM copado__Deployment_Flow__c].Initialization_Data__c;
    }

    private static Id createFile(String title, Id recordId) {
        ContentVersion fileVersion = (ContentVersion) new ContentVersion_t()
            .firstPublishLocationId(recordId)
            .title(title)
            .pathOnClient(title)
            .versionData(Blob.valueOf('Test'))
            .persist();
        return fileVersion.ContentDocumentId;
    }
}