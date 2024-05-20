@IsTest
private class HasVlocitySnapshotJobTemplateTest {
    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void vlocitySnapshotTemplateNotAssigned() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            Boolean result;

            // EXERCISE

            Test.startTest();
            result = HasVlocitySnapshotJobTemplate.execute(getPipeline('MyPipeline').Id);
            Test.stopTest();

            // VERIFY

            Assert.isFalse(result, 'Vlocity snapshot template should not be assigned to Pipeline Action');

        }
    }

    @IsTest
    private static void vlocitySnapshotTemplateAssigned() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            JobTemplate jobTemplate = new JobTemplate().name('SFDX Vlocity Git Snapshot').type('Custom').apiName('SFDX_Vlocity_Git_Snapshot_1');
            new JobStep(jobTemplate).name('Snapshot').type('Function');
            createPipelineAction(getPipelineObj('MyPipeline'), jobTemplate, 'TakeSnapshot').persist();
            Boolean result;

            // EXERCISE

            Test.startTest();
            result = HasVlocitySnapshotJobTemplate.execute(getPipeline('MyPipeline').Id);
            Test.stopTest();

            // VERIFY

            Assert.isTrue(result, 'Vlocity snapshot template should be assigned to Pipeline Action');

        }
    }

    private static void createData() {
        Project project = new Project();

        Environment dev1 = new Environment().name('Dev1');
        Environment staging = new Environment().name('Staging');

        new Credential(dev1);
        new Credential(staging);

        new Pipeline()
            .name('MyPipeline')
            .platform('SFDX')
            .repository(new Repository())
            .add(project)
            .add(new PipelineConnection().sourceEnvironment(dev1).destinationEnvironment(staging)).persist();
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