@IsTest
private class RefreshMetadataCallOutTest {
    private static final String JOB_TEMPLATE = 'SFDX Git Snapshot';
    private static final String JOB_STEP = 'Refresh Metadata';
    private static final String ENVIRONMENT_NAME = 'Dev1';

    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void testRefreshCallWithNoMetadataFile() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            String jsonString = '{"SFDX":{"included":["ApexClass"],"excluded":["ApexPage]}, "Vlocity":{"included":["DataRaptor"],"excluded":["OmniScript"]}}';
            createSnapsot(jsonString);

            JobStep step = getJobStepObj(JOB_STEP);
            Id templateId = TestUtilities.getJobTemplate(JOB_TEMPLATE).Id;
            new JobExecution(getJobTemplateObj(templateId), TestUtilities.getEnvironmentObj(ENVIRONMENT_NAME))
                .add(step)
                .snapshot(getSnapshotObj(ENVIRONMENT_NAME))
                .persist();

            RefreshMetadataCallout.Request request = new RefreshMetadataCallout.Request();
            request.credentialId = getCredentialByEnvName(ENVIRONMENT_NAME).Id;
            request.resultId = getResult(step.Id);

            List<RefreshMetadataCallout.Request> requests = new List<RefreshMetadataCallout.Request>();
            requests.add(request);

            // EXERCISE
            Test.startTest();
            List<RefreshMetadataCallout.Response> response = RefreshMetadataCallout.execute(requests);
            Test.stopTest();

            // VERIFY
            List<CronTrigger> cronTriggerAssertion = [
                SELECT Id
                FROM CronTrigger
                WHERE Id = :response[0].result
            ];
            Assert.isTrue(!cronTriggerAssertion.isEmpty(), 'A new job must be enqueued');
            Assert.isTrue(String.isNotBlank(response[0].result), 'Result must contain the job id');
            Assert.isTrue(String.isBlank(response[0].message), 'The message must be blank');
        }
    }

    @IsTest
    private static void testRefreshCallWithMetadataFileUpdatedInTheLastMinute() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            Id credentialId = getCredentialByEnvName(ENVIRONMENT_NAME).Id;
            String jsonString = '{"SFDX":{"included":["ApexClass"],"excluded":["ApexPage]}, "Vlocity":{"included":["DataRaptor"],"excluded":["OmniScript"]}}';
            createSnapsot(jsonString);

            JobStep step = getJobStepObj(JOB_STEP);
            Id templateId = TestUtilities.getJobTemplate(JOB_TEMPLATE).Id;
            new JobExecution(getJobTemplateObj(templateId), TestUtilities.getEnvironmentObj(ENVIRONMENT_NAME))
                .add(step)
                .snapshot(getSnapshotObj(ENVIRONMENT_NAME))
                .persist();
            createContentVersion(
                RefreshMetadataCallout.METADATA_FILE_NAME,
                RefreshMetadataCallout.METADATA_FILE_NAME + '.json',
                credentialId,
                getMetaDataFileContent(2)
            );

            RefreshMetadataCallout.Request request = new RefreshMetadataCallout.Request();
            request.credentialId = credentialId;
            request.resultId = getResult(step.Id);

            List<RefreshMetadataCallout.Request> requests = new List<RefreshMetadataCallout.Request>();
            requests.add(request);

            // EXERCISE
            Test.startTest();
            List<RefreshMetadataCallout.Response> response = RefreshMetadataCallout.execute(requests);
            Test.stopTest();

            // VERIFY
            Assert.isTrue(String.isBlank(response[0].result), 'Response must be blank because of no queue job');
            Assert.isTrue(String.isBlank(response[0].message), 'The message must be blank');
        }
    }

    @IsTest
    private static void testRefreshCallOnEmptyScope() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            createSnapsot(null);
            Id templateId = TestUtilities.getJobTemplate(JOB_TEMPLATE).Id;
            JobStep step = getJobStepObj(JOB_STEP);
            new JobExecution(getJobTemplateObj(templateId), TestUtilities.getEnvironmentObj(ENVIRONMENT_NAME))
                .add(step)
                .snapshot(getSnapshotObj(ENVIRONMENT_NAME))
                .persist();

            RefreshMetadataCallout.Request request = new RefreshMetadataCallout.Request();
            request.credentialId = getCredentialByEnvName(ENVIRONMENT_NAME).Id;
            request.resultId = getResult(step.Id);

            List<RefreshMetadataCallout.Request> requests = new List<RefreshMetadataCallout.Request>();
            requests.add(request);

            // EXERCISE
            Test.startTest();
            List<RefreshMetadataCallout.Response> response = RefreshMetadataCallout.execute(requests);
            Test.stopTest();

            // VERIFY
            Assert.isTrue(String.isBlank(response[0].result), 'Result must be blank because of empty scope');
            Assert.areEqual(Label.Snapshot_Empty_Scope_Banner, response[0].message, 'Response must show empty scope message on empty scope.');
        }
    }

    @IsTest
    private static void testRefreshCallWhenSfdxIsNull() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            String jsonString = '{"SFDX":null, "Vlocity":{"included":["DataRaptor"],"excluded":["OmniScript"]}}';
            createSnapsot(jsonString);

            Id templateId = TestUtilities.getJobTemplate(JOB_TEMPLATE).Id;
            JobStep step = getJobStepObj(JOB_STEP);
            new JobExecution(getJobTemplateObj(templateId), TestUtilities.getEnvironmentObj(ENVIRONMENT_NAME))
                .add(step)
                .snapshot(getSnapshotObj(ENVIRONMENT_NAME))
                .persist();

            RefreshMetadataCallout.Request request = new RefreshMetadataCallout.Request();
            request.credentialId = getCredentialByEnvName(ENVIRONMENT_NAME).Id;
            request.resultId = getResult(step.Id);

            List<RefreshMetadataCallout.Request> requests = new List<RefreshMetadataCallout.Request>();
            requests.add(request);

            // EXERCISE
            Test.startTest();
            List<RefreshMetadataCallout.Response> response = RefreshMetadataCallout.execute(requests);
            Test.stopTest();

            // VERIFY
            Assert.isTrue(String.isBlank(response[0].result), 'Result must be blank because of SFDX is null');
            Assert.isTrue(String.isBlank(response[0].message), 'Message must be blank because of SFDX is null');
        }
    }

    private static Id getResult(Id stepId) {
        return [SELECT Id, copado__JobStep__c FROM copado__Result__c WHERE copado__JobStep__c = :stepId LIMIT 1][0].Id;
    }

    private static void createSnapsot(String scope) {
        insert new copado__Git_Backup__c(
            copado__Org__c = getCredentialByEnvName(ENVIRONMENT_NAME).Id,
            copado__Git_Repository__c = getRepository('My Repo').Id,
            copado__Pipeline__c = getPipeline(getRepository('My Repo').Id).Id,
            copado__Scope__c = scope
        );
    }

    private static Credential getCredentialObj(String envName) {
        return new Credential().recordId(getCredentialByEnvName(envName).Id);
    }

    private static copado__Org__c getCredentialByEnvName(String value) {
        return [SELECT Id, copado__Environment__r.Name FROM copado__Org__c WHERE copado__Environment__r.Name = :value LIMIT 1];
    }

    private static copado__Deployment_Flow__c getPipeline(Id repositoryId) {
        return [SELECT Id, copado__Git_Repository__c FROM copado__Deployment_Flow__c WHERE copado__Git_Repository__c = :repositoryId LIMIT 1];
    }

    private static copado__Git_Repository__c getRepository(String name) {
        return [SELECT Id, Name FROM copado__Git_Repository__c WHERE Name = :Name LIMIT 1];
    }

    private static JobStep getJobStepObj(String name) {
        return new JobStep().recordId(getJobStep(name).Id);
    }

    private static copado__JobStep__c getJobStep(String name) {
        return [SELECT Name, Id FROM copado__JobStep__c WHERE Name = :name LIMIT 1];
    }

    private static JobTemplate getJobTemplateObj(Id templateId) {
        return new JobTemplate().recordId(templateId);
    }

    private static Snapshot getSnapshotObj(String envName) {
        return new Snapshot().recordId(getSnapshot(getCredentialByEnvName(envName).Id).Id);
    }

    private static copado__Git_Backup__c getSnapshot(Id credentialId) {
        return [SELECT Id, copado__Org__c FROM copado__Git_Backup__c WHERE copado__Org__c = :credentialId LIMIT 1];
    }

    private static void createData() {
        Repository repo = TestUtilities.createRepository();
        Environment dev1 = new Environment().name(ENVIRONMENT_NAME);
        Environment staging = new Environment().name('staging');
        TestUtilities.createPipeline(repo, 'SFDX').add(new PipelineConnection().sourceEnvironment(dev1).destinationEnvironment(staging));
        JobTemplate template = TestUtilities.createJobTemplate(JOB_TEMPLATE);
        JobStep step = TestUtilities.createJobStep(template, JOB_STEP, 'Function');
        TestUtilities.createResult(step, 'Success').persist();
    }

    private static Blob getMetaDataFileContent(Integer count) {
        List<MetaDataItem> metaDataItems = new List<MetaDataItem>();
        for (Integer i = 0; i < count; i++) {
            metaDataItems.add(TestDataFactory.getMetadataItem('ApexClass', 'SampleClass' + 1, 'Test Test', '1900-01-01'));
        }
        return Blob.valueOf(JSON.serialize(metaDataItems));
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static void createContentVersion(String title, String pathOnClient, Id firstPublishLocationId, Blob data) {
        new ContentVersion_t().title(title).pathOnClient(pathOnClient).firstPublishLocationId(firstPublishLocationId).versionData(data).persist();
    }
}