@IsTest
private class UpdatePromotionTestLevelTest {
    @IsTest
    private static void onInsert() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            createData('SFDX');

            // EXERCISE

            List<copado__Promoted_User_Story__c> ps = addStoriesToPromotionWithLevels(
                new Set<String>{ 'Run Local Tests', 'Run Specified Tests', 'No Test Run' }
            );

            // VERIFY

            copado__Promotion__c p = promotion(ps[0].copado__Promotion__c);
            System.assertEquals('Run Local Tests', p.Apex_Test_Level__c, 'Test Levels are incorrect.');
        }
    }

    @IsTest
    private static void onDelete() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            createData('SFDX');

            List<copado__Promoted_User_Story__c> ps = addStoriesToPromotionWithLevels(
                new Set<String>{ 'Run Local Tests', 'Run Specified Tests', 'No Test Run' }
            );

            // EXERCISE

            copado__Promoted_User_Story__c toDelete = byStoryTestLevel('Run Local Tests');
            delete toDelete;

            // VERIFY

            copado__Promotion__c p = promotion(ps[0].copado__Promotion__c);
            System.assertEquals('Run Specified Tests', p.Apex_Test_Level__c, 'Test Levels are incorrect.');
        }
    }

    @IsTest
    private static void updatingPromotedUserStoryToOutdated() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            createData('SFDX');

            List<copado__Promoted_User_Story__c> ps = addStoriesToPromotionWithLevels(
                new Set<String>{ 'Run Local Tests', 'Run Specified Tests', 'No Test Run' }
            );

            // EXERCISE

            updatePromotedUserStoryStatus('Run Local Tests', 'Outdated');

            // VERIFY

            copado__Promotion__c p = promotion(ps[0].copado__Promotion__c);
            System.assertEquals('Run Local Tests', p.Apex_Test_Level__c, 'Test Levels should not change');
        }
    }

    @IsTest
    private static void updatingPromotedUserStoryToActive() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            createData('SFDX');

            List<copado__Promoted_User_Story__c> ps = addStoriesToPromotionWithLevels(
                new Set<String>{ 'Run Local Tests', 'Run Specified Tests', 'No Test Run' }
            );

            // EXERCISE

            updatePromotedUserStoryStatus('Run Local Tests', 'Outdated');
            updatePromotedUserStoryStatus('Run Specified Tests', '');
            updatePromotedUserStoryStatus('Run Specified Tests', 'Active');

            // VERIFY

            copado__Promotion__c p = promotion(ps[0].copado__Promotion__c);
            System.assertEquals('Run Specified Tests', p.Apex_Test_Level__c, 'Test Levels are incorrect.');
        }
    }

    @IsTest
    private static void onInsertWithEnvSetToRunAllTests() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            createData('SFDX');
            setApexTestLevelOnDestinationEnv('Run All Tests In Org');

            // EXERCISE

            List<copado__Promoted_User_Story__c> ps = addStoriesToPromotionWithLevels(
                new Set<String>{ 'Run Specified Tests', 'No Test Run' }
            );

            // VERIFY

            copado__Promotion__c p = promotion(ps[0].copado__Promotion__c);
            System.assertEquals('Run All Tests In Org', p.Apex_Test_Level__c, 'Test Levels are incorrect.');
        }
    }

    @IsTest
    private static void onInsertWithEnvSetToRunLocalTests() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            createData('SFDX');
            setApexTestLevelOnDestinationEnv('Run Local Tests');

            // EXERCISE

            List<copado__Promoted_User_Story__c> ps = addStoriesToPromotionWithLevels(
                new Set<String>{ 'Run Specified Tests', 'No Test Run' }
            );

            // VERIFY

            copado__Promotion__c p = promotion(ps[0].copado__Promotion__c);
            System.assertEquals('Run Local Tests', p.Apex_Test_Level__c, 'Test Levels are incorrect.');
        }
    }

    @IsTest
    private static void onInsertWithEnvSetToNoTestRun() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            createData('SFDX');
            setApexTestLevelOnDestinationEnv('No Test Run');

            // EXERCISE

            List<copado__Promoted_User_Story__c> ps = addStoriesToPromotionWithLevels(
                new Set<String>{ 'Run Specified Tests', 'No Test Run' }
            );

            // VERIFY

            copado__Promotion__c p = promotion(ps[0].copado__Promotion__c);
            System.assertEquals('Run Specified Tests', p.Apex_Test_Level__c, 'Test Levels are incorrect.');
        }
    }

    @IsTest
    private static void onDeleteWithEnvSetToRunAllTests() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            createData('SFDX');
            setApexTestLevelOnDestinationEnv('Run All Tests In Org');

            List<copado__Promoted_User_Story__c> ps = addStoriesToPromotionWithLevels(
                new Set<String>{ 'Run All Tests In Org', 'Run Specified Tests' }
            );

            // EXERCISE

            copado__Promoted_User_Story__c toDelete = byStoryTestLevel('Run All Tests In Org');
            delete toDelete;

            // VERIFY

            copado__Promotion__c p = promotion(ps[0].copado__Promotion__c);
            System.assertEquals('Run All Tests In Org', p.Apex_Test_Level__c, 'Test Levels should not change.');
        }
    }

    @IsTest
    private static void onDeleteWithEnvSetToRunLocalTests() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            createData('SFDX');
            setApexTestLevelOnDestinationEnv('Run Local Tests');

            List<copado__Promoted_User_Story__c> ps = addStoriesToPromotionWithLevels(
                new Set<String>{ 'Run All Tests In Org', 'Run Specified Tests' }
            );

            // EXERCISE

            copado__Promoted_User_Story__c toDelete = byStoryTestLevel('Run All Tests In Org');
            delete toDelete;

            // VERIFY

            copado__Promotion__c p = promotion(ps[0].copado__Promotion__c);
            System.assertEquals('Run Local Tests', p.Apex_Test_Level__c, 'Test Levels are incorrect.');
        }
    }

    @IsTest
    private static void onUpdateWithEnvSetToRunAllTests() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            createData('SFDX');
            setApexTestLevelOnDestinationEnv('Run All Tests In Org');

            List<copado__Promoted_User_Story__c> ps = addStoriesToPromotionWithLevels(
                new Set<String>{ 'Run All Tests In Org', 'No Test Run' }
            );

            // EXERCISE

            updatePromotedUserStoryStatus('Run All Tests In Org', 'Outdated');

            // VERIFY

            copado__Promotion__c p = promotion(ps[0].copado__Promotion__c);
            System.assertEquals('Run All Tests In Org', p.Apex_Test_Level__c, 'Test Levels should not change.');
        }
    }

    @IsTest
    private static void onUpdateWithEnvSetToRunLocalTests() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            createData('SFDX');
            setApexTestLevelOnDestinationEnv('Run Local Tests');

            List<copado__Promoted_User_Story__c> ps = addStoriesToPromotionWithLevels(
                new Set<String>{ 'Run All Tests In Org', 'No Test Run' }
            );

            // EXERCISE

            updatePromotedUserStoryStatus('Run All Tests In Org', 'Outdated');

            // VERIFY

            copado__Promotion__c p = promotion(ps[0].copado__Promotion__c);
            System.assertEquals('Run All Tests In Org', p.Apex_Test_Level__c, 'Test Levels should not change.');
        }
    }

    @IsTest
    private static void onAllUpdateToOutdated() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            createData('SFDX');

            List<copado__Promoted_User_Story__c> ps = addStoriesToPromotionWithLevels(
                new Set<String>{ 'Run All Tests In Org', 'Run Specified Tests', 'No Test Run' }
            );

            // EXERCISE

            ps[0].copado__Status__c = 'Outdated';
            ps[1].copado__Status__c = 'Outdated';
            ps[2].copado__Status__c = 'Outdated';
            update ps;

            // VERIFY

            copado__Promotion__c p = promotion(ps[0].copado__Promotion__c);
            System.assertEquals('Run All Tests In Org', p.Apex_Test_Level__c, 'Test Levels should not change.');
        }
    }

    @IsTest
    private static void forOtherPlatform() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            createData('Salesforce');

            // EXERCISE

            List<copado__Promoted_User_Story__c> ps = addStoriesToPromotionWithLevels(
                new Set<String>{ 'Run All Tests In Org', 'Run Specified Tests', 'No Test Run' }
            );

            // VERIFY

            copado__Promotion__c p = promotion(ps[0].copado__Promotion__c);
            System.assertEquals('No Test Run', p.Apex_Test_Level__c, 'Test Levels should not update.');
        }
    }

    @IsTest
    private static void forOtherPlatformWithEnvSetToRunAllTests() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            createData('Salesforce');
            setApexTestLevelOnDestinationEnv('Run All Tests In Org');

            // EXERCISE

            List<copado__Promoted_User_Story__c> ps = addStoriesToPromotionWithLevels(
                new Set<String>{ 'Run All Tests In Org', 'Run Specified Tests', 'No Test Run' }
            );

            // VERIFY

            copado__Promotion__c p = promotion(ps[0].copado__Promotion__c);
            System.assertEquals('No Test Run', p.Apex_Test_Level__c, 'Test Levels should not update.');
        }
    }

    // HELPER

    @TestSetup
    private static void setup() {
        TestUtilities.setup();
    }

    // PRIVATE

    private static void createData(String platform) {
        copado__Git_Repository__c repo = TestDataFactory.createGitRepository('Repo 1');
        insert repo;

        copado__Environment__c sEnv = TestDataFactory.createEnvironment('Src', 'Production/Developer', platform);
        copado__Environment__c dEnv = TestDataFactory.createEnvironment('Dst', 'Production/Developer', platform);
        insert new List<copado__Environment__c>{ sEnv, dEnv };

        copado__Org__c sCred = TestDataFactory.createCredential('Src', UserInfo.getUserName(), sEnv.Id, null);
        copado__Org__c dCred = TestDataFactory.createCredential('Dst', UserInfo.getUserName(), dEnv.Id, null);
        insert new List<copado__Org__c>{ sCred, dCred };

        copado__JobTemplate__c promotionJob = TestDataFactory.createJobTemplate('Promotion');
        insert promotionJob;

        copado__Deployment_Flow__c pipeline = TestDataFactory.createPipeline('Pipeline1', repo.Id);
        pipeline.copado__Platform__c = platform;
        insert pipeline;

        copado__Pipeline_Action__c action = TestDataFactory.createPipelineAction('Promotion', pipeline.Id, promotionJob.Id);
        insert action;

        copado__Deployment_Flow_Step__c pipelineConnection = TestDataFactory.createPipelineConnection(pipeline.Id, sEnv.Id, dEnv.Id);
        insert pipelineConnection;

        copado__Project__c project = TestDataFactory.createProject('Project 1', pipeline.Id);
        insert project;

        List<copado__User_Story__c> stories = new List<copado__User_Story__c>();

        for (String testLevel : UpdatePromotionTestLevel.TEST_LEVELS_IN_ORDER) {
            stories.add(
                new copado__User_Story__c(
                    copado__Project__c = project.Id,
                    copado__Org_Credential__c = sCred.Id,
                    copado__Promotion_Test_Level__c = testLevel.deleteWhitespace(),
                    Apex_Test_Level__c = testLevel
                )
            );
        }

        insert stories;

        insert new copado__Promotion__c(
            copado__Project__c = project.Id,
            copado__Source_Environment__c = sEnv.Id,
            copado__Source_Org_Credential__c = sCred.Id,
            copado__Destination_Environment__c = dEnv.Id,
            copado__Destination_Org_Credential__c = dCred.Id
        );
    }

    private static List<copado__Promoted_User_Story__c> addStoriesToPromotionWithLevels(Set<String> testLevels) {
        List<copado__Promoted_User_Story__c> ps = new List<copado__Promoted_User_Story__c>();

        copado__Promotion__c promotion = [SELECT Id FROM copado__Promotion__c LIMIT 1];

        for (copado__User_Story__c story : [SELECT Id FROM copado__User_Story__c WHERE Apex_Test_Level__c IN :testLevels]) {
            ps.add(new copado__Promoted_User_Story__c(copado__Promotion__c = promotion.Id, copado__User_Story__c = story.Id));
        }

        insert ps;
        return ps;
    }

    private static copado__Promotion__c promotion(Id pId) {
        return [SELECT Apex_Test_Level__c FROM copado__Promotion__c WHERE Id = :pId LIMIT 1];
    }

    private static copado__Promoted_User_Story__c byStoryTestLevel(String testLevel) {
        return [SELECT Id FROM copado__Promoted_User_Story__c WHERE copado__User_Story__r.Apex_Test_Level__c = :testLevel LIMIT 1];
    }

    private static void setApexTestLevelOnDestinationEnv(String value) {
        copado__Environment__c dEnv = getDestinationEnvironment();
        dEnv.Apex_Test_Level__c = value;
        update dEnv;
    }

    private static copado__Environment__c getDestinationEnvironment() {
        return [SELECT Id FROM copado__Environment__c WHERE Name = 'Dst' LIMIT 1];
    }

    private static void updatePromotedUserStoryStatus(String apexTestLevel, String status) {
        copado__Promoted_User_Story__c promotedUserStory = byStoryTestLevel(apexTestLevel);
        promotedUserStory.copado__Status__c = status;
        update promotedUserStory;
    }
}