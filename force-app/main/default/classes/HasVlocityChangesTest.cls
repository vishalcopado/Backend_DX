@IsTest
private class HasVlocityChangesTest {
    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void withVlocityChangesSuccess() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            String vlocityChangesExist;

            JobExecution jobExecution = TestUtilities.createJobExecution(
                TestUtilities.getTemplateObj('SFDX Vlocity Deploy'),
                TestUtilities.getEnvironmentObj('Test Environment'),
                getDataJson('Copado Deploy Changes.json')
            );
            createJobStep('Salesforce Deploy', 'Function', jobExecution);

            // EXERCISE
            Test.startTest();
            vlocityChangesExist = new HasVlocityChanges().execute(TestUtilities.getJobStep(jobExecution.Id, 'Salesforce Deploy').Id);
            Test.stopTest();

            // VERIFY
            Assert.areEqual('true', vlocityChangesExist, 'Vlocity Changes should exist');
        }
    }

    @IsTest
    private static void withoutVlocityChangesSuccess() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            String vlocityChangesExist;

            JobExecution jobExecution = TestUtilities.createJobExecution(
                TestUtilities.getTemplateObj('SFDX Vlocity Deploy'),
                TestUtilities.getEnvironmentObj('Test Environment'),
                getDataJson('Copado Deploy Changes1.json')
            );
            createJobStep('Salesforce Deploy', 'Function', jobExecution);

            // EXERCISE

            Test.startTest();
            vlocityChangesExist = new HasVlocityChanges().execute(TestUtilities.getJobStep(jobExecution.Id, 'Salesforce Deploy').Id);
            Test.stopTest();

            // VERIFY

            Assert.areEqual('false', vlocityChangesExist, 'Vlocity changes should not exist');
        }
    }

    @IsTest
    private static void noFileChangesFilePresent() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            String vlocityChangesExist;

            JobExecution jobExecution = TestUtilities.createJobExecution(
                TestUtilities.getTemplateObj('SFDX Vlocity Deploy'),
                TestUtilities.getEnvironmentObj('Test Environment'),
                getDataJsonWithoutFileChangesId()
            );
            createJobStep('Salesforce Deploy', 'Function', jobExecution);

            // EXERCISE

            Test.startTest();
            vlocityChangesExist = new HasVlocityChanges().execute(TestUtilities.getJobStep(jobExecution.Id, 'Salesforce Deploy').Id);
            Test.stopTest();

            // VERIFY

            Assert.areEqual('false', vlocityChangesExist, 'Vlocity changes should not exist');
        }
    }

    private static void createData() {
        TestUtilities.createEnvironment('Test Environment');
        TestUtilities.createJobTemplate('SFDX Vlocity Deploy');
        addContentVersion('Copado Deploy Changes.json', getDeploymentChangesDataWithVlocity());
        addContentVersion('Copado Deploy Changes1.json', getDeploymentChangesDataWithoutVlocity());
    }

    private static String getDataJson(String title) {
        DeploymentJsonWrapper jsonObject = new DeploymentJsonWrapper().fileWithSelectedChanges(String.valueOf(getContentVersionId(title)));
        return JSON.serialize(jsonObject);
    }

    private static String getDataJsonWithoutFileChangesId() {
        DeploymentJsonWrapper jsonObject = new DeploymentJsonWrapper().fileWithSelectedChanges('');
        return JSON.serialize(jsonObject);
    }

    private static void createJobStep(String name, String type, JobExecution execution) {
        new JobStep(TestUtilities.getTemplateObj('SFDX Vlocity Deploy')).name(name).type(type).execution(execution).persist();
    }

    private static void addContentVersion(String title, String data) {
        new ContentVersion_t().versionData(Blob.valueOf(data)).title(title).pathOnClient(title).persist();
    }

    private static Id getContentVersionId(String title) {
        return [SELECT Id, Title, VersionData FROM ContentVersion WHERE Title = :title AND isLatest = TRUE][0].Id;
    }

    private static String getDeploymentChangesDataWithVlocity() {
        List<MetaDataItem> result = new List<MetaDataItem>();
        result.add(TestDataFactory.getMetadataItem('ApexClass', 'Vlocity1', 'Test User', '2023-02-17T10:41:48.000+0000'));
        result.add(TestDataFactory.getMetadataItemWithCategory('DataRaptor', 'Vlocity2', 'Test User', '2023-02-17T10:41:48.000+0000', 'Vlocity'));
        return JSON.serialize(result);
    }

    private static String getDeploymentChangesDataWithoutVlocity() {
        List<MetaDataItem> result = new List<MetaDataItem>();
        result.add(TestDataFactory.getMetadataItem('ApexClass', 'VlocityApexClass1', 'Test User', '2023-02-17T10:41:48.000+0000'));
        result.add(TestDataFactory.getMetadataItem('ApexClass', 'VlocityApexClass2', 'Test User', '2023-02-17T10:41:48.000+0000'));
        return JSON.serialize(result);
    }

    //INNER

    private class DeploymentJsonWrapper {
        private List<String> userStoryIds;
        private List<String> userStoryBranches;
        private String transactionId;
        private String promotionId;
        private String promotionBranchName;
        private String fileWithSelectedChanges;
        private String destinationBranchName;
        private String deploymentId;
        private String deploymentDryRun;

        private DeploymentJsonWrapper fileWithSelectedChanges(String fileWithSelectedChanges) {
            this.fileWithSelectedChanges = fileWithSelectedChanges;
            return this;
        }
    }
}