@IsTest
private class PackageVersionPublishHandlerTest {
    @SuppressWarnings('PMD.AvoidHardcodingId')
    private static final String SUBSCRIBER_ID = '04t09000000G3icAAC';

    @IsTest
    private static void publishPackageVersion() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup
            copado__Git_Repository__c repo = createRepository();
            copado__Deployment_Flow__c pipeline = createPipeline(repo.Id);
            copado__JobTemplate__c template = createJobTemplate('SFDX Package Version Publish', 1);
            createJobStep(template.Id, 'Update Package Version Requisite', 'Flow');
            createJobStep(template.Id, 'Publish Package Version', 'Function');
            createPipelineAction(pipeline.Id, template.Id);
            copado__Artifact_Version__c version = createPackageVersion(repo, createPackage(repo, pipeline.Id));

            // Exercise
            PackageVersionPublishHandler.startPublish(version.Id);

            // Verify
            List<copado__JobExecution__c> jobs = [SELECT copado__DataJson__c FROM copado__JobExecution__c];

            System.assertEquals(1, jobs.size(), 'Package version publish failed.');
        }
    }

    @IsTest
    private static void validatePackageVersion() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup
            String exceptionMessage;
            copado__Git_Repository__c repo = createRepository();
            copado__Deployment_Flow__c pipeline = createPipeline(repo.Id);
            copado__JobTemplate__c template = createJobTemplate('SFDX Package Version Publish', 1);
            createJobStep(template.Id, 'Update Package Version Requisite', 'Flow');
            createJobStep(template.Id, 'Publish Package Version', 'Function');

            createPipelineAction(pipeline.Id, template.Id);
            copado__Artifact_Version__c version = createPackageVersionWithoutSubscriberId(repo, createPackage(repo, pipeline.Id));

            // EXERCISE

            try {
                Test.startTest();
                PackageVersionPublishHandler.validatepackageVersionInfo(version.Id);
                Test.stopTest();
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY

            System.assertEquals(
                Label.Package_Version_Publish_Error,
                exceptionMessage,
                'Subscriber Version Id is missing. Package version can only be published after it has been generated.'
            );
        }
    }

    @IsTest
    private static void publishVersionwithNoJobTemplate() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup
            copado__Git_Repository__c repo = createRepository();
            copado__Deployment_Flow__c pipeline = createPipeline(repo.Id);
            createPipelineAction(pipeline.Id, null);

            copado__Artifact_Version__c version = createPackageVersion(repo, createPackage(repo, pipeline.Id));
            Exception expectedException = null;

            // Exercise
            try {
                PackageVersionPublishHandler.startPublish(version.Id);
            } catch (Exception ex) {
                expectedException = ex;
            }

            // Verify
            System.assertNotEquals(null, expectedException, 'Should an throw Exception');
        }
    }

    private static copado__Deployment_Flow__c createPipeline(Id repositoryId) {
        copado__Deployment_Flow__c pipeline = new copado__Deployment_Flow__c(
            Name = 'My Pipeline',
            copado__Platform__c = 'SFDX',
            copado__Git_Repository__c = repositoryId
        );
        insert pipeline;
        return pipeline;
    }

    private static copado__Pipeline_Action__c createPipelineAction(id pipelineId, Id templateId) {
        copado__Pipeline_Action__c action = TestDataFactory.createPipelineAction('PublishPackageVersion', pipelineId, templateId);
        insert action;
        return action;
    }

    private static copado__Git_Repository__c createRepository() {
        copado__Git_Repository__c repo = new copado__Git_Repository__c(Name = 'My Repo');
        insert repo;
        return repo;
    }

    @SuppressWarnings('PMD.AvoidHardcodingId')
    private static copado__Artifact__c createPackage(Copado__Git_Repository__c repo, Id pipelineId) {
        copado__Artifact__c pkg = new copado__Artifact__c();
        pkg.Name = 'Testpkg';
        pkg.copado__Package_Type__c = 'Unlocked';
        pkg.copado__Artifact_Repository__c = repo.Id;
        pkg.copado__Package_Id__c = '0Ho5g00000000VzCAI';
        pkg.copado__Pipeline__c = pipelineId;
        pkg.RecordTypeId = SObjectType.copado__Artifact__c.getRecordTypeInfosByDeveloperName().get('Package_Artifact').getRecordTypeId();

        insert pkg;
        return pkg;
    }

    private static copado__Artifact_Version__c createPackageVersion(Copado__Git_Repository__c repo, copado__Artifact__c pkg) {
        copado__Artifact_Version__c version = new copado__Artifact_Version__c();
        version.copado__Artifact__c = pkg.Id;
        version.Name = 'ver 0.1';
        version.copado__Version_number__c = '0.1.0.1';
        version.copado__Subscriber_Version_Id__c = SUBSCRIBER_ID;

        insert version;
        return version;
    }

    private static copado__Artifact_Version__c createPackageVersionWithoutSubscriberId(Copado__Git_Repository__c repo, copado__Artifact__c pkg) {
        copado__Artifact_Version__c version = new copado__Artifact_Version__c();
        version.copado__Artifact__c = pkg.Id;
        version.Name = 'ver 0.2';
        version.copado__Version_number__c = '0.1.0.2';

        insert version;
        return version;
    }

    private static copado__JobTemplate__c createJobTemplate(String name, Integer version) {
        copado__JobTemplate__c template = new copado__JobTemplate__c();
        template.Name = name;
        template.copado__Version__c = version;

        insert template;
        return template;
    }

    public static copado__JobStep__c createJobStep(Id jobTemplateId, String name, String type) {
        copado__JobStep__c step = new copado__JobStep__c(Name = name, copado__Type__c = type, copado__JobTemplate__c = jobTemplateId);

        insert step;
        return step;
    }

    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
    }
}