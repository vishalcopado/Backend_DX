@IsTest
private class PipelineRequirementValidationImplTest {

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
                PipelineInitializer.PreSteps.checkRequirements(null);
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
                PipelineInitializer.PreSteps.checkRequirements(user.Id);
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
    private static void executeWithInactivePipeline() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            copado__Deployment_Flow__c pipeline = [SELECT Id, copado__Active__c FROM copado__Deployment_Flow__c LIMIT 1];
            pipeline.copado__Active__c = false;
            update pipeline;

            String exceptionMessage;

            // EXERCISE
            Test.startTest();
            try {
                PipelineInitializer.PreSteps.checkRequirements(pipeline.Id);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // VERIFY
            Assert.isNotNull(exceptionMessage, 'There is no exception');
            Assert.areEqual(Label.InactivePipelineError, exceptionMessage, 'There is a different exception');
        }
    }


    @IsTest
    private static void executeWithMissingMainBranch() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            copado__Deployment_Flow__c pipeline = [SELECT Id, copado__Main_Branch__c FROM copado__Deployment_Flow__c LIMIT 1];
            pipeline.copado__Main_Branch__c = null;
            update pipeline;
            
            String exceptionMessage;

            // EXERCISE
            Test.startTest();
            try {
                PipelineInitializer.PreSteps.checkRequirements(pipeline.Id);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // VERIFY
            Assert.isNotNull(exceptionMessage, 'There is no exception');
            Assert.areEqual(Label.MainBranchMissingError, exceptionMessage, 'There is a different exception');
        }
    }

    @IsTest
    private static void executeWithMissingRepository() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            copado__Deployment_Flow__c pipeline = [SELECT Id, copado__Git_Repository__c FROM copado__Deployment_Flow__c LIMIT 1];
            
            String exceptionMessage;

            // EXERCISE
            Test.startTest();
            try {
                PipelineInitializer.PreSteps.checkRequirements(pipeline.Id);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // VERIFY
            Assert.isNotNull(exceptionMessage, 'There is no exception');
            Assert.areEqual(Label.GitRepoMissingError, exceptionMessage, 'There is a different exception');
        }
    }

    @IsTest
    private static void executeWithMissingPipelineConnections() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            new Pipeline()
                .name('MissingConnections')
                .mainBranch('main')
                .platform('SFDX')
                .add(new Project())
            .persist();

            copado__Git_Repository__c gitRepository = [SELECT Id FROM copado__Git_Repository__c LIMIT 1];
            copado__Deployment_Flow__c pipeline = [SELECT Id, copado__Git_Repository__c FROM copado__Deployment_Flow__c WHERE Name = 'MissingConnections' LIMIT 1];
            pipeline.copado__Git_Repository__c = gitRepository.Id;
            update pipeline;

            String exceptionMessage;

            // EXERCISE
            Test.startTest();
            try {
                PipelineInitializer.PreSteps.checkRequirements(pipeline.Id);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // VERIFY
            Assert.isNotNull(exceptionMessage, 'There is no exception');
            Assert.areEqual(Label.PipelineConnectionsMissingError, exceptionMessage, 'There is a different exception');
        }
    }

    @IsTest
    private static void executeWithMissingAuthenticatedCredential() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            copado__Git_Repository__c gitRepository = [SELECT Id FROM copado__Git_Repository__c LIMIT 1];
            copado__Deployment_Flow__c pipeline = [SELECT Id, copado__Git_Repository__c FROM copado__Deployment_Flow__c LIMIT 1];
            pipeline.copado__Git_Repository__c = gitRepository.Id;
            update pipeline;

            String exceptionMessage;

            // EXERCISE
            Test.startTest();
            try {
                PipelineInitializer.PreSteps.checkRequirements(pipeline.Id);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // VERIFY
            Assert.isNotNull(exceptionMessage, 'There is no exception');
            Assert.areEqual(Label.MissingAuthenticatedDefaultCredentials, exceptionMessage, 'There is a different exception');
        }
    }

    @IsTest
    private static void executeWithValidPipeline() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Project project = new Project();

            Environment dev1 = new Environment().name('Dev1');
            Environment staging = new Environment().name('Staging');
            new Credential(dev1).default(true).orgId('a00X');
            new Credential(staging).default(true).orgId('a00Y');

            new Pipeline()
                .name('ValidPipeline')
                .mainBranch('main')
                .platform('SFDX')
                .add(project)
                .add(new PipelineConnection().sourceEnvironment(dev1).destinationEnvironment(staging).destinationBranch('staging'))
            .persist();

            copado__Git_Repository__c gitRepository = [SELECT Id FROM copado__Git_Repository__c LIMIT 1];
            copado__Deployment_Flow__c pipeline = [SELECT Id, copado__Git_Repository__c FROM copado__Deployment_Flow__c WHERE Name = 'ValidPipeline' LIMIT 1];
            pipeline.copado__Git_Repository__c = gitRepository.Id;
            update pipeline;

            String exceptionMessage;

            // EXERCISE
            Test.startTest();
            try {
                PipelineInitializer.PreSteps.checkRequirements(pipeline.Id);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // VERIFY
            Assert.isNull(exceptionMessage, 'There is an exception');
            Assert.isTrue(String.isBlank(exceptionMessage), 'There is an exception message');
        }
    }

    // HELPER

    private static void createData() {
        System.runAs(TestUtilities.getRunAsUser()) {
            Project project = new Project();

            new Repository().name('DX');
            Environment dev1 = new Environment().name('Dev1');
            Environment staging = new Environment().name('Staging');
            new Environment().name('UAT');
            new Credential(dev1);
            new Credential(staging);

            new Pipeline()
                .name('MyPipeline')
                .mainBranch('main')
                .platform('SFDX')
                .add(project)
                .add(new PipelineConnection().sourceEnvironment(dev1).destinationEnvironment(staging).destinationBranch('staging'))
            .persist();
        }
    }
}