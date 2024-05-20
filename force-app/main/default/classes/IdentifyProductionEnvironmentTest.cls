@IsTest
private with sharing class IdentifyProductionEnvironmentTest {
    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void nextEnvironmentIsProductionEnvironment() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            Environment staging = getEnvironment('Staging');
            Environment production = getEnvironment('Production');
            JobTemplate jobTemplate = getJobTemplate('Deploy');
            Pipeline pipeline = getPipeline('MyPipeline');

            JobExecution execution = new JobExecution(jobTemplate, production).pipeline(pipeline).source(staging);
            JobStep step = new JobStep().execution(execution).name('Deploy').type('Function');
            step.persist();

            // EXERCISE

            Boolean isProductionEnvironment = Boolean.valueOf(new IdentifyProductionEnvironment().execute(step.Id));

            // VERIFY

            Assert.isTrue(isProductionEnvironment, 'The target environment should be a Production Environment');
        }
    }

    @IsTest
    private static void nextEnvironmentIsNotProductionEnvironment() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            Environment dev1 = getEnvironment('Dev1');
            Environment staging = getEnvironment('Staging');
            Pipeline pipeline = getPipeline('MyPipeline');

            JobTemplate jobTemplate = getJobTemplate('Deploy');
            JobExecution execution = new JobExecution(jobTemplate, staging).pipeline(pipeline).source(dev1);
            JobStep step = new JobStep().execution(execution).name('Deploy').type('Function');
            step.persist();

            // EXERCISE

            Boolean isProductionEnvironment = Boolean.valueOf(new IdentifyProductionEnvironment().execute(step.Id));

            // VERIFY

            Assert.areEqual(false, isProductionEnvironment, 'The target environment should NOT be a Production Environment');
        }
    }

    @IsTest
    private static void nonExistantStepId() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String stepId = fflib_IDGenerator.generate('a0t');

            // EXERCISE

            Boolean isProductionEnvironment = Boolean.valueOf(new IdentifyProductionEnvironment().execute(stepId));

            // VERIFY

            Assert.areEqual(true, isProductionEnvironment, 'The target environment should NOT be a Production Environment');
        }
    }

    @IsTest
    private static void nextEnvironmentIsSandbox() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            Environment sandbox = getEnvironment('Sandbox').type('Sandbox');
            Environment preStaging = getEnvironment('Pre-Staging').type('Sandbox');
            Pipeline pipeline = getPipeline('MyPipeline');

            JobTemplate jobTemplate = getJobTemplate('Deploy');
            JobExecution execution = new JobExecution(jobTemplate, preStaging).pipeline(pipeline).source(sandbox);
            JobStep step = new JobStep().execution(execution).name('Deploy').type('Function');
            step.persist();

            // EXERCISE

            Boolean isProductionEnvironment = Boolean.valueOf(new IdentifyProductionEnvironment().execute(step.Id));

            // VERIFY

            Assert.areEqual(false, isProductionEnvironment, 'The target environment should NOT be a Production Environment');
        }
    }

    @IsTest
    private static void nextEnvironmentIsScratchOrg() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            Environment sandbox = getEnvironment('Sandbox').type('Scratch Org');
            Environment preStaging = getEnvironment('Pre-Staging').type('Scratch Org');
            Pipeline pipeline = getPipeline('MyPipeline');

            JobTemplate jobTemplate = getJobTemplate('Deploy');
            JobExecution execution = new JobExecution(jobTemplate, preStaging).pipeline(pipeline).source(sandbox);
            JobStep step = new JobStep().execution(execution).name('Deploy').type('Function');
            step.persist();

            // EXERCISE

            Boolean isProductionEnvironment = Boolean.valueOf(new IdentifyProductionEnvironment().execute(step.Id));

            // VERIFY

            Assert.areEqual(false, isProductionEnvironment, 'The target environment should NOT be a Production Environment');
        }
    }

    private static void createData() {
        Project project = new Project();

        Environment dev1 = new Environment().name('Dev1');
        Environment dev2 = new Environment().name('Dev2');
        Environment sandbox = new Environment().name('Sandbox').type('Sandbox');
        Environment staging = new Environment().name('Staging');
        Environment preStaging = new Environment().name('Pre-Staging').type('Sandbox');
        Environment production = new Environment().name('Production');

        new Credential(dev1);
        new Credential(dev2);
        new Credential(staging);
        new Credential(preStaging);
        new Credential(production);

        Pipeline pipeline = new Pipeline()
            .name('MyPipeline')
            .platform('SFDX')
            .repository(new Repository())
            .add(project)
            .add(new PipelineConnection().sourceEnvironment(dev1).destinationEnvironment(staging))
            .add(new PipelineConnection().sourceEnvironment(dev2).destinationEnvironment(staging))
            .add(new PipelineConnection().sourceEnvironment(sandbox).destinationEnvironment(preStaging))
            .add(new PipelineConnection().sourceEnvironment(preStaging).destinationEnvironment(staging))
            .add(new PipelineConnection().sourceEnvironment(staging).destinationEnvironment(production));

        pipeline.persist();

        JobTemplate jobTemplate = new JobTemplate().name('Deploy').type('Custom').apiName('Deploy');
        new JobStep(jobTemplate).name('Deploy Step').type('Function').persist();
    }

    private static Environment getEnvironment(String name) {
        Id environment = [SELECT Id, copado__Type__c FROM copado__Environment__c WHERE Name = :name LIMIT 1][0].Id;
        return new Environment().recordId(environment);
    }

    private static JobTemplate getJobTemplate(String name) {
        Id template = [SELECT Id FROM copado__JobTemplate__c WHERE Name = :name LIMIT 1][0].Id;
        return new JobTemplate().recordId(template);
    }

    private static Pipeline getPipeline(String name) {
        Id template = [SELECT Id FROM copado__Deployment_Flow__c WHERE Name = :name LIMIT 1][0].Id;
        return new Pipeline().recordId(template);
    }
}