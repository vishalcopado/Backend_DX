@IsTest
public with sharing class UserStoryCommitPageOverrideTest {
    private static final String COMMIT_PAGE_OVERRIDE_SYSTEM_PROPERTY = 'SFDXUserStoryCommitPageOverride';

    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    private static void createData() {
        Repository repo = TestUtilities.createRepository();
        TestUtilities.createCredential(true);
        TestUtilities.createPipeline(repo, 'SFDX').persist();
    }
    
    @IsTest
    private static void commitPageSystemPropertyOverrideSuccessfulWithValueTrue() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Pipeline pipeline = getPipelineObj('My Repo');
            UserStory userStory = new UserStory().title('US 1').status('Draft').credential(TestUtilities.getCredentialObj(true)).project(new Project(pipeline));
            createSystemProperties(pipeline, 'true', COMMIT_PAGE_OVERRIDE_SYSTEM_PROPERTY).persist();

            // EXERCISE

            Boolean hasOverwrite = UserStoryCommitPageOverride.execute(userStory.Id);

            // VERIFY

            Assert.isTrue(hasOverwrite, 'System Property for Commit page Overwrite should be true.');
        }
    }

    @IsTest
    private static void commitPageSystemPropertyOverrideSuccessfulWithValueFalse() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Pipeline pipeline = getPipelineObj('My Repo');
            UserStory userStory = new UserStory().title('US 1').status('Draft').credential(TestUtilities.getCredentialObj(true)).project(new Project(pipeline));
            createSystemProperties(pipeline, 'false', COMMIT_PAGE_OVERRIDE_SYSTEM_PROPERTY).persist();

            // EXERCISE

            Boolean hasOverwrite = UserStoryCommitPageOverride.execute(userStory.Id);

            // VERIFY

            Assert.isFalse(hasOverwrite, 'System Property for Commit page Overwrite should be false.');
        }
    }

    @IsTest
    private static void commitPageSystemPropertyOverrideFailedWhenNoSystemProperty() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Pipeline pipeline = getPipelineObj('My Repo');
            UserStory userStory = new UserStory().title('US 1').status('Draft').credential(TestUtilities.getCredentialObj(true)).project(new Project(pipeline));
            userStory.persist();

            // EXERCISE

            Boolean hasOverwrite = UserStoryCommitPageOverride.execute(userStory.Id);

            // VERIFY

            Assert.isFalse(hasOverwrite, 'System Property for Commit page Overwrite should not be present.');
        }
    }

    @IsTest
    private static void throwExceptionWhenUserStoryNotAssocatedWithPipeline() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String exceptionMessgae = '';
            UserStory userStory = new UserStory().title('US 1').status('Draft').credential(TestUtilities.getCredentialObj(true));
            userStory.persist();

            // EXERCISE

            try {
                UserStoryCommitPageOverride.execute(userStory.Id);
            }
            catch(Exception ex) {
                exceptionMessgae = ex.getMessage();
            }
            

            // VERIFY

            Assert.areEqual(label.UserStory_Not_Associated_With_Pipeline, exceptionMessgae, 'User Story is not associated with project pipeline.');
        }
    }

    private static SystemProperty createSystemProperties(Pipeline pipeline, String value, String apiName) {
        return new SystemProperty(pipeline).apiName(apiName).value(value);
    }

    private static Pipeline getPipelineObj(String repoName) {
        return new Pipeline().recordId(getPipeline(repoName).Id);
    }

    private static copado__Deployment_Flow__c getPipeline(String repositoryName) {
        return [SELECT Id, copado__Git_Repository__r.Name FROM copado__Deployment_Flow__c WHERE copado__Git_Repository__r.Name = :repositoryName LIMIT 1];
    }
}