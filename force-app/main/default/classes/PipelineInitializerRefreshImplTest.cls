@IsTest
private class PipelineInitializerRefreshImplTest {

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
                PipelineInitializer.PreSteps.refreshMetadata(new PipelineInitializer.RefreshMetadataRequest(null));
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
                PipelineInitializer.PreSteps.refreshMetadata(new PipelineInitializer.RefreshMetadataRequest(user.Id));
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
                PipelineInitializer.PreSteps.refreshMetadata(new PipelineInitializer.RefreshMetadataRequest(pipelineId));
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
                PipelineInitializer.PreSteps.refreshMetadata(new PipelineInitializer.RefreshMetadataRequest(pipelineId));
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
    private static void executeWithCompleteRequest() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;

            // EXERCISE
            Test.startTest();
            PipelineInitializer.PreSteps.refreshMetadata(new PipelineInitializer.RefreshMetadataRequest(pipelineId));
            Test.stopTest();

            // VERIFY
            List<CronTrigger> cronTriggerAssertion = [
                SELECT Id
                FROM CronTrigger
                WHERE CronJobDetail.Name LIKE 'Poll for Refresh Metadata%'
            ];
            Assert.isTrue(!cronTriggerAssertion.isEmpty(), 'A new job must be enqueued');
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
}