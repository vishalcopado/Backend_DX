@IsTest
private class PipelineInitializerDiffAnalysisImplTest {

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
                PipelineInitializer.PreSteps.runDifferenceAnalysis(null);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // VERIFY
            Assert.isNotNull(exceptionMessage, 'There is no exception');
            Assert.areEqual(String.format(Label.MissingRequiredParameters, new List<String> {'Pipeline Id'}), exceptionMessage, 'The exception message does not match');
        }
    }

    @IsTest
    private static void executeWithIncorrectId() {
        User user = TestUtilities.getRunAsUser();
        System.runAs(user) {

            // SETUP
            String exceptionMessage;

            // EXERCISE
            Test.startTest();
            try {
                PipelineInitializer.PreSteps.runDifferenceAnalysis(user.Id);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // VERIFY
            Assert.isNotNull(exceptionMessage, 'There is no exception');
            Assert.areEqual(Label.NoPipelineFound, exceptionMessage, 'The exception message does not match');
        }
    }

    @IsTest
    private static void executeWithOnePipelineConnection() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            String exceptionMessage;
            Environment first = new Environment().name('First');
            Environment last = new Environment().name('Last');
            new Credential(first).default(true).orgId(fflib_IDGenerator.generate('00S'));
            new Credential(last).default(true).orgId(fflib_IDGenerator.generate('00S'));

            new Pipeline()
                .name('Test')
                .mainBranch('main')
                .platform('SFDX')
                .add(new PipelineConnection().sourceEnvironment(first).destinationEnvironment(last).destinationBranch('main').branch('first'))
            .persist();

            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c WHERE NAME = 'Test'].Id;

            // EXERCISE
            Test.startTest();
            try {
                PipelineInitializer.PreSteps.runDifferenceAnalysis(pipelineId);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // VERIFY
            Assert.isNotNull(exceptionMessage, 'There is no exception');
            Assert.areEqual(Label.NoEnvironmentsForDifferenceAnalysis, exceptionMessage, 'The exception message does not match');
        }
    }

    @IsTest
    private static void executeWithNonSfdxPipeline() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            String exceptionMessage;

            Environment dev1 = new Environment().name('Dev1').platform('Other');
            Environment staging = new Environment().name('Staging').platform('Other');
            Environment prod = new Environment().name('Production').platform('Other');
            new Credential(dev1).default(true).orgId(fflib_IDGenerator.generate('00X'));
            new Credential(staging).default(true).orgId(fflib_IDGenerator.generate('00X'));
            new Credential(prod).default(true).orgId(fflib_IDGenerator.generate('00X'));

            new Pipeline()
                .name('OtherPipeline')
                .mainBranch('main')
                .platform('Other')
                .add(new Project())
                .add(new PipelineConnection().sourceEnvironment(dev1).destinationEnvironment(staging).destinationBranch('staging').branch('dev1'))
                .add(new PipelineConnection().sourceEnvironment(staging).destinationEnvironment(prod).destinationBranch('main').branch('staging'))
            .persist();

            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c WHERE Name = 'OtherPipeline' LIMIT 1].Id;

            // EXERCISE
            Test.startTest();
            try {
                PipelineInitializer.PreSteps.runDifferenceAnalysis(pipelineId);
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
    private static void executeWithNoContentVersion() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;

            // EXERCISE
            Test.startTest();
            PipelineInitializer.PreSteps.runDifferenceAnalysis(pipelineId);
            Test.stopTest();

            // VERIFY
            List<copado__JobExecution__c> jobs = getJobs();
            Map<String, Object> jsonValue = (Map<String, Object>) JSON.deserializeUntyped(jobs[0].copado__DataJson__c);

            Assert.areEqual(1, jobs.size(), 'The number of jobs do not match.');
            Assert.areEqual([SELECT Id FROM copado__JobTemplate__c].Id, jobs[0].copado__Template__c, 'The template value does not match');
            Assert.isNull((String) jsonValue.get('targetEnvironmentFileId'), 'The targetEnvironmentFileId value does not match');
            Assert.isNull((String) jsonValue.get('sourceEnvironmentFileId'), 'The sourceEnvironmentFileId value does not match');
            Assert.areEqual(pipelineId, jobs[0].copado__Pipeline__c, 'The pipeline does not match');
            Assert.areEqual([SELECT Id FROM copado__Environment__c WHERE Name = 'Staging'].Id, jobs[0].copado__Source__c, 'The environment value does not match');
            Assert.areEqual([SELECT Id FROM copado__Environment__c WHERE Name = 'Production'].Id, jobs[0].copado__Destination__c, 'The environment value does not match');

            String initializationDetails = getInitializationDetails();
            PipelineInitializationDetails initializationDataWithKeys = getInitializationDataWithKeys(initializationDetails);

            Assert.areEqual('In Progress', initializationDataWithKeys.diffAnalysisStatus, 'The status does not match.');
            Assert.areEqual(2, initializationDataWithKeys.activityLog.size(), 'The number of log entries do not match');
            Assert.areEqual(Label.CalculatingDifferences, initializationDataWithKeys.activityLog[1].title, 'The log title does not match');
            Assert.areEqual('In Progress', initializationDataWithKeys.activityLog[1].status, 'The log status does not match');
            Assert.isTrue(initializationDataWithKeys.diffAnalysisJobs.contains(jobs[0].Id), 'The job is not present in the list');
            Assert.areEqual('In Progress', initializationDataWithKeys.diffAnalysisStatus, 'The diff status does not match');
        }
    }

    @IsTest
    private static void executeWithContentVersion() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;

            List<copado__Org__c> credentials = [SELECT Id, Name FROM copado__Org__c WHERE copado__Default_Credential__c = true];

            for (copado__Org__c credential : credentials) {
                createFile('MetaData', credential.Id);
            }

            // EXERCISE
            Test.startTest();
            PipelineInitializer.PreSteps.runDifferenceAnalysis(pipelineId);
            Test.stopTest();

            // VERIFY
            List<copado__JobExecution__c> jobs = getJobs();

            Assert.areEqual(1, jobs.size(), 'The number of jobs do not match.');
            Assert.areEqual([SELECT Id FROM copado__JobTemplate__c].Id, jobs[0].copado__Template__c, 'The template value does not match');
            Assert.areEqual(pipelineId, jobs[0].copado__Pipeline__c, 'The pipeline does not match');
            Assert.areEqual([SELECT Id FROM copado__Environment__c WHERE Name = 'Staging'].Id, jobs[0].copado__Source__c, 'The environment value does not match');
            Assert.areEqual([SELECT Id FROM copado__Environment__c WHERE Name = 'Production'].Id, jobs[0].copado__Destination__c, 'The environment value does not match');

            String initializationDetails = getInitializationDetails();
            PipelineInitializationDetails initializationDataWithKeys = getInitializationDataWithKeys(initializationDetails);

            Assert.areEqual('In Progress', initializationDataWithKeys.diffAnalysisStatus, 'The status does not match.');
            Assert.areEqual(2, initializationDataWithKeys.activityLog.size(), 'The number of log entries do not match');
            Assert.areEqual(Label.CalculatingDifferences, initializationDataWithKeys.activityLog[1].title, 'The log title does not match');
            Assert.areEqual('In Progress', initializationDataWithKeys.activityLog[1].status, 'The log status does not match');
            Assert.isTrue(initializationDataWithKeys.diffAnalysisJobs.contains(jobs[0].Id), 'The job is not present in the list');
            Assert.areEqual('In Progress', initializationDataWithKeys.diffAnalysisStatus, 'The diff status does not match');
        }
    }

    @IsTest
    private static void executeWithNoInitializationData() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            String exceptionMessage;
            copado__Deployment_Flow__c pipeline = [SELECT Id, Initialization_Data__c FROM copado__Deployment_Flow__c];
            pipeline.Initialization_Data__c = '';
            update pipeline;

            // EXERCISE
            Test.startTest();
            try {
                PipelineInitializer.PreSteps.runDifferenceAnalysis(pipeline.Id);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // VERIFY
            Assert.isNotNull(exceptionMessage, 'There is no exception');
            Assert.areEqual(String.format(Label.MissingRequiredParameters, new List<String> {Label.PipelineInitializationData}), exceptionMessage, 'The exception message does not match');
        }
    }

    @IsTest
    private static void executeWithNoActivityLog() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            copado__Deployment_Flow__c pipeline = [SELECT Id, Initialization_Data__c FROM copado__Deployment_Flow__c];
            PipelineInitializationDetails currentInitData = getInitializationDataWithKeys(pipeline.Initialization_Data__c);
            currentInitData.activityLog = new List<PipelineInitializationDetails.ActivityLog>();
            pipeline.Initialization_Data__c = JSON.serialize(currentInitData);
            update pipeline;

            // EXERCISE
            Test.startTest();
            PipelineInitializer.PreSteps.runDifferenceAnalysis(pipeline.Id);
            Test.stopTest();

            // VERIFY
            List<copado__JobExecution__c> jobs = getJobs();
            Map<String, Object> jsonValue = (Map<String, Object>) JSON.deserializeUntyped(jobs[0].copado__DataJson__c);

            Assert.areEqual(1, jobs.size(), 'The number of jobs do not match.');
            Assert.areEqual([SELECT Id FROM copado__JobTemplate__c].Id, jobs[0].copado__Template__c, 'The template value does not match');
            Assert.isNull((String) jsonValue.get('targetEnvironmentFileId'), 'The targetEnvironmentFileId value does not match');
            Assert.isNull((String) jsonValue.get('sourceEnvironmentFileId'), 'The sourceEnvironmentFileId value does not match');
            Assert.areEqual(pipeline.Id, jobs[0].copado__Pipeline__c, 'The pipeline does not match');
            Assert.areEqual([SELECT Id FROM copado__Environment__c WHERE Name = 'Staging'].Id, jobs[0].copado__Source__c, 'The environment value does not match');
            Assert.areEqual([SELECT Id FROM copado__Environment__c WHERE Name = 'Production'].Id, jobs[0].copado__Destination__c, 'The environment value does not match');

            String initializationDetails = getInitializationDetails();
            PipelineInitializationDetails initializationDataWithKeys = getInitializationDataWithKeys(initializationDetails);

            Assert.areEqual('In Progress', initializationDataWithKeys.diffAnalysisStatus, 'The status does not match.');
            Assert.areEqual(1, initializationDataWithKeys.activityLog.size(), 'The number of log entries do not match');
            Assert.areEqual(Label.CalculatingDifferences, initializationDataWithKeys.activityLog[0].title, 'The log title does not match');
            Assert.areEqual('In Progress', initializationDataWithKeys.activityLog[0].status, 'The log status does not match');
            Assert.isTrue(initializationDataWithKeys.diffAnalysisJobs.contains(jobs[0].Id), 'The job is not present in the list');
            Assert.areEqual('In Progress', initializationDataWithKeys.diffAnalysisStatus, 'The diff status does not match');
        }
    }

    @IsTest
    private static void executeWithDiffCalculationActivityLog() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            copado__Deployment_Flow__c pipeline = [SELECT Id, Initialization_Data__c FROM copado__Deployment_Flow__c];
            PipelineInitializationDetails currentInitData = getInitializationDataWithKeys(pipeline.Initialization_Data__c);
            currentInitData.activityLog = new List<PipelineInitializationDetails.ActivityLog>();

            PipelineInitializationDetails.ActivityLog logEntry = new PipelineInitializationDetails.ActivityLog();
            logEntry.status = 'In Progress';
            logEntry.title = Label.CalculatingDifferences;

            currentInitData.activityLog.add(logEntry);
            currentInitData.diffAnalysisStatus = 'In Progress';
            pipeline.Initialization_Data__c = JSON.serialize(currentInitData);
            update pipeline;

            // EXERCISE
            Test.startTest();
            PipelineInitializer.PreSteps.runDifferenceAnalysis(pipeline.Id);
            Test.stopTest();

            // VERIFY
            List<copado__JobExecution__c> jobs = getJobs();
            Map<String, Object> jsonValue = (Map<String, Object>) JSON.deserializeUntyped(jobs[0].copado__DataJson__c);

            Assert.areEqual(1, jobs.size(), 'The number of jobs do not match.');
            Assert.areEqual([SELECT Id FROM copado__JobTemplate__c].Id, jobs[0].copado__Template__c, 'The template value does not match');
            Assert.isNull((String) jsonValue.get('targetEnvironmentFileId'), 'The targetEnvironmentFileId value does not match');
            Assert.isNull((String) jsonValue.get('sourceEnvironmentFileId'), 'The sourceEnvironmentFileId value does not match');
            Assert.areEqual(pipeline.Id, jobs[0].copado__Pipeline__c, 'The pipeline does not match');
            Assert.areEqual([SELECT Id FROM copado__Environment__c WHERE Name = 'Staging'].Id, jobs[0].copado__Source__c, 'The environment value does not match');
            Assert.areEqual([SELECT Id FROM copado__Environment__c WHERE Name = 'Production'].Id, jobs[0].copado__Destination__c, 'The environment value does not match');

            String initializationDetails = getInitializationDetails();
            PipelineInitializationDetails initializationDataWithKeys = getInitializationDataWithKeys(initializationDetails);

            Assert.areEqual('In Progress', initializationDataWithKeys.diffAnalysisStatus, 'The status does not match.');
            Assert.areEqual(1, initializationDataWithKeys.activityLog.size(), 'The number of log entries do not match');
            Assert.areEqual(Label.CalculatingDifferences, initializationDataWithKeys.activityLog[0].title, 'The log title does not match');
            Assert.areEqual('In Progress', initializationDataWithKeys.activityLog[0].status, 'The log status does not match');
            Assert.isTrue(initializationDataWithKeys.diffAnalysisJobs.contains(jobs[0].Id), 'The job is not present in the list');
            Assert.areEqual('In Progress', initializationDataWithKeys.diffAnalysisStatus, 'The diff status does not match');
        }
    }

    // HELPER

    private static void createData() {
        System.runAs(TestUtilities.getRunAsUser()) {
            JobTemplate jobTemplate = new JobTemplate().name('SFDX Difference Analysis');
            new JobStep(jobTemplate).name('Run').type('Function');

            Environment dev1 = new Environment().name('Dev1');
            Environment staging = new Environment().name('Staging');
            Environment prod = new Environment().name('Production');
            new Credential(dev1).default(true).orgId(fflib_IDGenerator.generate('00D'));
            new Credential(staging).default(true).orgId(fflib_IDGenerator.generate('00D'));
            new Credential(staging).default(false).orgId(fflib_IDGenerator.generate('00D'));
            new Credential(prod).default(true).orgId(fflib_IDGenerator.generate('00D'));

            PipelineInitializationDetails initializationDetails = new PipelineInitializationDetails();
            initializationDetails.initializationType = 'WIP Diff Grid';
            initializationDetails.status = 'Main initialzed';

            PipelineInitializationDetails.ActivityLog logEntry = new PipelineInitializationDetails.ActivityLog();
            logEntry.status = 'Success';
            logEntry.title = 'Test';

            initializationDetails.activityLog = new List<PipelineInitializationDetails.ActivityLog>{ logEntry };

            new Pipeline()
                .name('MyPipeline')
                .mainBranch('main')
                .platform('SFDX')
                .initializationData(JSON.serializePretty(initializationDetails))
                .add(new Project())
                .add(new PipelineConnection().sourceEnvironment(dev1).destinationEnvironment(staging).destinationBranch('staging').branch('dev1'))
                .add(new PipelineConnection().sourceEnvironment(staging).destinationEnvironment(prod).destinationBranch('main').branch('staging'))
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

    private static List<copado__JobExecution__c> getJobs() {
        return [SELECT Id, copado__Template__c, copado__DataJson__c, copado__Status__c, copado__Pipeline__c, copado__Source__c, copado__Destination__c FROM copado__JobExecution__c];
    }
}