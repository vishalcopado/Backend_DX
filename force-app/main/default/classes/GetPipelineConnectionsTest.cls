@IsTest
private class GetPipelineConnectionsTest {

    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void executeWithPipeline() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;

            // EXERCISE
            Test.startTest();
            List<copado__Deployment_Flow_Step__c> connections = GetPipelineConnections.getConnections(pipelineId);
            Test.stopTest();

            // VERIFY
            Assert.areEqual(1, connections.size(), 'There are no connections found.');
        }
    }

    @IsTest
    private static void executeWithNoId() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // EXERCISE
            Test.startTest();
            List<copado__Deployment_Flow_Step__c> connections = GetPipelineConnections.getConnections(null);
            Test.stopTest();

            // VERIFY
            Assert.areEqual(0, connections.size(), 'There are connections found.');
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
            new Credential(dev1).default(true).orgId(fflib_IDGenerator.generate('00D'));
            new Credential(staging).default(true).orgId(fflib_IDGenerator.generate('00D'));

            Pipeline pipeline = new Pipeline()
                .name('MyPipeline')
                .mainBranch('main')
                .platform('SFDX')
                .add(project)
                .add(new PipelineConnection().sourceEnvironment(dev1).destinationEnvironment(staging).destinationBranch('staging'));
            pipeline.persist();
        }
    }
}