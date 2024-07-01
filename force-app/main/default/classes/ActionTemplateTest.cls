@IsTest
private class ActionTemplateTest {
    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    private static void createData() {
        JobTemplate template = TestUtilities.createJobTemplate('SFDX Package Distribution').apiName('SFDX Package Distribution_1');
        TestUtilities.createJobStep(template, 'Get Dependencies', 'Function');
        TestUtilities.createJobStep(template, 'Install package', 'Function');
        Repository repo = createRepository('My Repo');
        TestUtilities.createPipeline(repo, 'SFDX');
        Credential cred = TestUtilities.createCredential(false);
        TestUtilities.createEnvironment('Env1').add(cred).persist();
    }

    @IsTest
    private static void getApiNameWithJobTemplate() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            Id pipelineId = getPipelineObj('My Repo').Id;

            // EXERCISE
            Test.startTest();
            String result = new ActionTemplate('PackageDistribution', pipelineId).getApiName();
            Test.stopTest();

            // VERIFY
            Assert.areEqual('SFDX Package Distribution_1', result, 'Template Name should match');
        }
    }

    @IsTest
    private static void getApiNameWithoutJobTemplate() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            String templateName;
            String action = 'DummyAction';
            Exception expectedException;
            String actualException = String.format(Label.Error_No_Action_Template_Defined, new List<Object>{ action });

            // EXERCISE
            Test.startTest();
            try {
                templateName = new ActionTemplate(action, getPipeline('My Repo').Id).getApiName();
            } catch(Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // VERIFY
            Assert.areNotEqual(null, expectedException, 'An exception should be thrown');
            Assert.isTrue(expectedException.getMessage().contains(actualException), 'Exception message should match: ' + expectedException.getMessage());
        }
    }

    public static Repository createRepository(String name) {
        return new Repository().name(name);
    }

    private static copado__Deployment_Flow__c getPipeline(String repositoryName) {
        return [SELECT Id, copado__Git_Repository__r.Name FROM copado__Deployment_Flow__c WHERE copado__Git_Repository__r.Name = :repositoryName LIMIT 1];
    }

    private static Pipeline getPipelineObj(String repoName) {
        return new Pipeline().recordId(getPipeline(repoName).Id);
    }

    private static JobTemplate getJobTemplateObj(String name) {
        return new JobTemplate().recordId(TestUtilities.getJobTemplate(name).Id);
    }
}