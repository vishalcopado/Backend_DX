@IsTest
private class IsRollBackEnabledTest {
    private static final String ROLLBACK_ENABLED = 'rollback_enabled';
    private static final String ADMIN_USERNAME = 'username-admin@myemail.com';

    @TestSetup
    private static void setup() {
        TestUtilities.setup();
        TestUtilities.setupAdminUser(ADMIN_USERNAME);
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void testRollBackEnabled() {
        // SETUP
        System.runAs(TestUtilities.getRunAsUser(ADMIN_USERNAME)) {
            Environment staging = getEnvironment('Staging');
            new SystemProperty(staging).apiName(ROLLBACK_ENABLED).value('true').persist();
        }
        System.runAs(TestUtilities.getRunAsUser()) {
            Environment staging = getEnvironment('Staging');
            Environment dev1 = getEnvironment('Dev1');
            Pipeline pipeline = getPipeline('MyPipeline');

            JobTemplate jobTemplate = getJobTemplate('Deploy');
            JobExecution execution = new JobExecution(jobTemplate, staging).pipeline(pipeline).source(dev1);
            JobStep step = new JobStep().execution(execution).name('Deploy').type('Function');
            step.persist();

            // EXERCISE
            Boolean isRollBackEnabled = Boolean.valueOf(new IsRollBackEnabled().execute(step.Id));

            // VERIFY
            Assert.areEqual(true, isRollBackEnabled, 'Rollback should be enabled');
        }
    }

    @IsTest
    private static void testRollBackDisabledWithRollBackEnabledToFalse() {
        // SETUP
        System.runAs(TestUtilities.getRunAsUser(ADMIN_USERNAME)) {
            Environment staging = getEnvironment('Staging');
            new SystemProperty(staging).apiName(ROLLBACK_ENABLED).value('false').persist();
        }
        System.runAs(TestUtilities.getRunAsUser()) {
            Environment staging = getEnvironment('Staging');
            Environment dev1 = getEnvironment('Dev1');
            Pipeline pipeline = getPipeline('MyPipeline');

            JobTemplate jobTemplate = getJobTemplate('Deploy');
            JobExecution execution = new JobExecution(jobTemplate, staging).pipeline(pipeline).source(dev1);
            JobStep step = new JobStep().execution(execution).name('Deploy').type('Function');
            step.persist();

            // EXERCISE
            Boolean isRollBackEnabled = Boolean.valueOf(new IsRollBackEnabled().execute(step.Id));

            // VERIFY
            Assert.areEqual(false, isRollBackEnabled, 'Rollback should NOT be enabled');
        }
    }

    @IsTest
    private static void testRollBackDisabledWithRollBackEnabledToADifferentValue() {
        // SETUP
        System.runAs(TestUtilities.getRunAsUser(ADMIN_USERNAME)) {
            Environment staging = getEnvironment('Staging');
            new SystemProperty(staging).apiName(ROLLBACK_ENABLED).value('Other Value').persist();
        }
        System.runAs(TestUtilities.getRunAsUser()) {
            Environment staging = getEnvironment('Staging');
            Environment dev1 = getEnvironment('Dev1');
            Pipeline pipeline = getPipeline('MyPipeline');

            JobTemplate jobTemplate = getJobTemplate('Deploy');
            JobExecution execution = new JobExecution(jobTemplate, staging).pipeline(pipeline).source(dev1);
            JobStep step = new JobStep().execution(execution).name('Deploy').type('Function');
            step.persist();

            // EXERCISE
            Boolean isRollBackEnabled = Boolean.valueOf(new IsRollBackEnabled().execute(step.Id));

            // VERIFY
            Assert.areEqual(false, isRollBackEnabled, 'Rollback should NOT be enabled');
        }
    }

    @IsTest
    private static void testRollBackDisabledWithoutSystemProperty() {
        // SETUP
        System.runAs(TestUtilities.getRunAsUser()) {
            Environment staging = getEnvironment('Staging');
            Environment dev1 = getEnvironment('Dev1');
            Pipeline pipeline = getPipeline('MyPipeline');

            JobTemplate jobTemplate = getJobTemplate('Deploy');
            JobExecution execution = new JobExecution(jobTemplate, staging).pipeline(pipeline).source(dev1);
            JobStep step = new JobStep().execution(execution).name('Deploy').type('Function');
            step.persist();

            // EXERCISE
            Boolean isRollBackEnabled = Boolean.valueOf(new IsRollBackEnabled().execute(step.Id));

            // VERIFY
            Assert.areEqual(false, isRollBackEnabled, 'Rollback should NOT be enabled');
        }
    }

    // PRIVATE
    private static void createData() {
        Project project = new Project();

        Environment dev1 = new Environment().name('Dev1');
        Environment staging = new Environment().name('Staging');

        new Credential(dev1);
        new Credential(staging);

        Pipeline pipeline = new Pipeline()
            .name('MyPipeline')
            .platform('SFDX')
            .repository(new Repository())
            .add(project)
            .add(new PipelineConnection().sourceEnvironment(dev1).destinationEnvironment(staging));
        pipeline.persist();

        JobTemplate jobTemplate = new JobTemplate().name('Deploy').type('Custom').apiName('Deploy');
        new JobStep(jobTemplate).name('Deploy').type('Function').persist();
    }

    private static Id getJobStep() {
        return [SELECT Id FROM copado__JobStep__c LIMIT 1][0].Id;
    }

    private static Environment getEnvironment(String name) {
        Id environment = [SELECT Id FROM copado__Environment__c WHERE Name = :name LIMIT 1][0].Id;
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