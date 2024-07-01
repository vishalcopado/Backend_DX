@IsTest
private class PipelineDistributionCtrlTest {
    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void getFieldsFromFieldSet() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Exercise

            List<String> fields = PipelineDistributionCtrl.getFieldsFromFieldSet('copado__User_Story__c', 'PipelineBasedPackageDistribution');

            // Verify

            System.assert(fields.size() > 0, 'Field set should not be empty');
        }
    }

    @IsTest
    private static void getExistingStoryDetails() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup

            copado__User_Story__c story = getStory();

            // Exercise

            PipelineDistributionCtrl.UserStoryDetails detail = PipelineDistributionCtrl.getExistingStoryDetails(story.Id);

            // Verify

            assertStoryDetails(detail);
            System.assertEquals('US 1', detail.userStoryTitle, 'User Story is incorrect.');
        }
    }

    @IsTest
    private static void getNewStoryDetails() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup

            copado__User_Story__c story = getStory();
            story.copado__User_Story_Title__c = 'US 2';
            copado__User_Story__c newStory = story.clone(false);

            // Exercise

            PipelineDistributionCtrl.UserStoryDetails detail = PipelineDistributionCtrl.getNewStoryDetails(JSON.serialize(newStory));

            // Verify

            assertStoryDetails(detail);
            System.assertEquals('US 2', detail.userStoryTitle, 'User Story is incorrect.');
        }
    }

    @IsTest
    private static void invalidCredentialOnCreatingUserStory() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            copado__Environment__c sEnv = TestDataFactory.createEnvironment('Src Env1', null, 'SFDX');
            insert sEnv;

            copado__Org__c sCred = TestDataFactory.createCredential('Src Cred1', UserInfo.getUserName(), sEnv.Id, null);
            insert sCred;

            copado__User_Story__c story = getStory().clone(false);
            story.copado__Org_Credential__c = sCred.Id;
            upsert story;

            String exceptionMessage;

            // EXERCISE

            try {
                PipelineDistributionCtrl.getExistingStoryDetails(story.Id);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY

            System.assertEquals(Label.Credential_Not_Part_Of_Environment_In_Pipeline, exceptionMessage, 'Exception should be thrown');
        }
    }

    // HELPER

    private static void assertStoryDetails(PipelineDistributionCtrl.UserStoryDetails detail) {
        System.assertEquals('Pipeline 1', detail.pipelineName, 'Pipeline is incorrect.');
        System.assertEquals('Src Env', detail.currentEnvironment, 'Current Environment Name is incorrect.');
        System.assertEquals('Dst Env', detail.nextEnvironment, 'Next Environment is incorrect.');
        System.assertEquals('Project 1', detail.project, 'Project is incorrect.');
        System.assertEquals('R1', detail.release, 'Release is incorrect.');
    }

    private static void createData() {
        copado__Git_Repository__c repo = TestDataFactory.createGitRepository('Repo');
        insert repo;

        copado__Environment__c sEnv = TestDataFactory.createEnvironment('Src Env', null, 'SFDX');
        copado__Environment__c dEnv = TestDataFactory.createEnvironment('Dst Env', null, 'SFDX');
        insert new List<copado__Environment__c>{ sEnv, dEnv };

        copado__Org__c sCred = TestDataFactory.createCredential('Src Cred', UserInfo.getUserName(), sEnv.Id, null);
        copado__Org__c dCred = TestDataFactory.createCredential('Src Cred', UserInfo.getUserName(), dEnv.Id, null);
        insert new List<copado__Org__c>{ sCred, dCred };

        copado__Deployment_Flow__c pipeline = TestDataFactory.createPipeline('Pipeline 1', repo.Id);
        pipeline.copado__Platform__c = 'SFDX';
        insert pipeline;

        copado__Deployment_Flow_Step__c pipelineConnection = TestDataFactory.createPipelineConnection(pipeline.Id, sEnv.Id, dEnv.Id);
        insert pipelineConnection;

        copado__Project__c project = TestDataFactory.createProject('Project 1', pipeline.Id);
        insert project;

        copado__Release__c release = TestDataFactory.createRelease('R1', project.Id);
        insert release;

        copado__User_Story__c story = TestDataFactory.createUserStory('US 1', 'Draft', null, project.Id, release.Id, sCred.Id);
        insert story;
    }

    private static copado__User_Story__c getStory() {
        return [SELECT copado__Project__c, copado__Org_Credential__c, copado__Release__c FROM copado__User_Story__c LIMIT 1];
    }
}