@IsTest
private class GetGitJsonTest {
    private static final String SFDX_INITIALIZE_PROJECT = 'SFDX Initialize Project';
    private static final String INITIALIZE_GIT_WITH_SFDX_PROJECT = 'Initialize Git with SFDX Project';

    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    public static void returnValidCredentialValue() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            copado__JobExecution__c jobExecution = (copado__JobExecution__c) createJobExecution().dataJSON(getDataJson()).persist();
            Id contextId = TestUtilities.getJobStep(jobExecution.Id, INITIALIZE_GIT_WITH_SFDX_PROJECT).Id;

            // EXERCISE

            String result = new GetGitJson().execute(contextId);

            // VERIFY

            Credential credential = (Credential) JSON.deserialize(result, Credential.class);

            Assert.areEqual('git@github.com:user/repository.git', credential.url, 'The credential url is incorrect');
            Assert.areEqual('ssh', credential.type, 'The credential type is incorrect');
            Assert.areEqual('publicKey', credential.publicKey, 'The credential publicKey is incorrect');
            Assert.areEqual('-----BEGIN PRIVATE KEY-----privateKey', credential.privateKey, 'The credential privateKey is incorrect');
        }
    }

    @IsTest
    public static void executeWithNoJobExecution() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            JobTemplate jobTemplate = TestUtilities.getTemplateObj(SFDX_INITIALIZE_PROJECT);
            copado__JobStep__c jobStep = (copado__JobStep__c) new JobStep(jobTemplate)
                .name(INITIALIZE_GIT_WITH_SFDX_PROJECT)
                .type('Function')
                .persist();
            String exceptionMessage;

            // EXERCISE

            try {
                new GetGitJson().execute(jobStep.Id);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY

            Assert.isTrue(exceptionMessage.contains('Could not find valid Git Repository Id in the DataJson'), 'The error message is incorrect');
        }
    }

    @IsTest
    public static void executeWithEmptyDataJson() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            copado__JobExecution__c jobExecution = (copado__JobExecution__c) createJobExecution().dataJSON('').persist();
            Id contextId = TestUtilities.getJobStep(jobExecution.Id, INITIALIZE_GIT_WITH_SFDX_PROJECT).Id;
            String exceptionMessage;

            // EXERCISE

            try {
                new GetGitJson().execute(contextId);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY

            Assert.isTrue(exceptionMessage.contains('Could not find valid Git Repository Id in the DataJson'), 'The error message is incorrect');
        }
    }

    // PRIVATE

    private static void createData() {
        Repository repository = new Repository().name('SFDX Repo').uri('git@github.com:user/repository.git');

        new Attachment_t().name('id_rsa.pub').body(Blob.valueOf('publicKey')).parent(repository);
        new Attachment_t().name('id_rsa').body(Blob.valueOf('-----BEGIN PRIVATE KEY-----privateKey')).parent(repository);

        new JobTemplate().name(SFDX_INITIALIZE_PROJECT).type('Custom').persist();
    }

    private static String getDataJson() {
        Id repositoryId = [SELECT Id FROM copado__Git_Repository__c WHERE Name = 'SFDX Repo' LIMIT 1].Id;
        return '{ "gitRepositoryId":"' + repositoryId + '"}';
    }

    private static JobExecution createJobExecution() {
        JobTemplate jobTemplate = TestUtilities.getTemplateObj(SFDX_INITIALIZE_PROJECT);
        return (JobExecution) new JobExecution(jobTemplate).add(new JobStep(jobTemplate).name(INITIALIZE_GIT_WITH_SFDX_PROJECT).type('Function'));
    }

    private class Credential {
        public String type;
        public String url;
        public String branch;
        public Boolean gitCache;

        public String publicKey;
        public String privateKey;

        public String username;
        public String password;
        public String extraheaders;
    }
}