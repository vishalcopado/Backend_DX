@IsTest
public class PublishPackageVersionCallbackFlowTest {
    @SuppressWarnings('PMD.AvoidHardcodingId')
    private static final String SUBSCRIBER_ID = '04t09000000G3icAAC';

    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
    }

    @IsTest
    private static void publishPackageVersion() {
        // Setup

        System.runAs(TestUtilities.getRunAsUser()) {
            copado__Git_Repository__c repo = createRepository();
            createPackageVersion(repo, createPackage(repo, createPipeline(repo.Id).Id));

            Map<String, Object> flowParams = getFlowParams(createResult());

            // Exercise

            Test.startTest();
            new Flow.Interview.PublishPackageVersionCallback(flowParams).start();
            Test.stopTest();

            // Verify

            List<copado__Artifact_Version__c> versions = getPackageVersions();
            System.assertEquals(
                versions[0].copado__Is_released__c,
                true,
                'Publish package version failed'
            );
        }

    }

    private static copado__Result__c createResult() {
        copado__Result__c result = new copado__Result__c(copado__Result_Data__c = SUBSCRIBER_ID);
        result.copado__Job_Type__c = 'Integration';

        insert result;
        return result;
    }

    private static copado__Deployment_Flow__c createPipeline(Id repositoryId) {
        copado__Deployment_Flow__c pipeline = new copado__Deployment_Flow__c(
            Name = 'My Pipeline',
            copado__Platform__c = 'Salesforce',
            copado__Git_Repository__c = repositoryId
        );

        insert pipeline;
        return pipeline;
    }

    private static copado__Git_Repository__c createRepository() {
        copado__Git_Repository__c repo = new copado__Git_Repository__c(Name = 'My Repo');

        insert repo;
        return repo;
    }

    @SuppressWarnings('PMD.AvoidHardcodingId')
    private static copado__Artifact__c createPackage(
        Copado__Git_Repository__c repo,
        Id pipelineId
    ) {
        copado__Artifact__c pkg = new copado__Artifact__c();
        pkg.Name = 'Testpkg';
        pkg.copado__Package_Type__c = 'Unlocked';
        pkg.copado__Artifact_Repository__c = repo.Id;
        pkg.copado__Package_Id__c = '0Ho5g00000000VzCAI';
        pkg.copado__Pipeline__c = pipelineId;
        pkg.RecordTypeId = SObjectType.copado__Artifact__c.getRecordTypeInfosByDeveloperName()
            .get('Package_Artifact')
            .getRecordTypeId();

        insert pkg;
        return pkg;
    }

    private static copado__Artifact_Version__c createPackageVersion(
        Copado__Git_Repository__c repo,
        copado__Artifact__c pkg
    ) {
        copado__Artifact_Version__c version = new copado__Artifact_Version__c();
        version.copado__Artifact__c = pkg.Id;
        version.Name = 'ver 0.1';
        version.copado__Version_number__c = '0.1.0.1';
        version.copado__Subscriber_Version_Id__c = SUBSCRIBER_ID;

        insert version;
        return version;
    }

    private static Map<String, Object> getFlowParams(copado__Result__c result) {
        Map<String, Object> flowParams = new Map<String, Object>{
            'result' => result,
            'status' => 'Success'
        };
        return flowParams;
    }

    private static List<copado__Artifact_Version__c> getPackageVersions() {
        return [SELECT copado__Is_released__c FROM copado__Artifact_Version__c];
    }
}