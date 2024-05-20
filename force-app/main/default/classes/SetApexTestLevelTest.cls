@IsTest
private class SetApexTestLevelTest {
    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void setEmptyValue() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            copado__User_Story__c userStory = getUserStory();
            userStory.copado__Promotion_Test_Level__c = null;

            // EXERCISE

            Test.startTest();
            update userStory;
            Test.stopTest();

            // VERIFY

            userStory = getUserStory();
            System.assertEquals(null, userStory.Apex_Test_Level__c, 'Apex_Test_Level__c should be updated to null');
        }
    }

    @IsTest
    private static void setNoRunTest() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            
            copado__User_Story__c userStory = getUserStory();
            userStory.copado__Promotion_Test_Level__c = 'NoTestRun';

            // EXERCISE

            Test.startTest();
            update userStory;
            Test.stopTest();

            // VERIFY
            
            userStory = getUserStory();
            System.assertEquals('No Test Run', userStory.Apex_Test_Level__c, 'Apex_Test_Level__c should be updated to No Test Run');
        }
    }

    @IsTest
    private static void setRunSpecifiedTest() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            
            copado__User_Story__c userStory = getUserStory();
            userStory.copado__Promotion_Test_Level__c = 'RunSpecifiedTests';

            // EXERCISE

            Test.startTest();
            update userStory;
            Test.stopTest();

            // VERIFY
            
            userStory = getUserStory();
            System.assertEquals('Run Specified Tests', userStory.Apex_Test_Level__c, 'Apex_Test_Level__c should be updated to Run Specified Tests');
        }
    }

    @IsTest
    private static void setRunLocalTest() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            
            copado__User_Story__c userStory = getUserStory();
            userStory.copado__Promotion_Test_Level__c = 'RunLocalTests';

            // EXERCISE

            Test.startTest();
            update userStory;
            Test.stopTest();

            // VERIFY
            
            userStory = getUserStory();
            System.assertEquals('Run Local Tests', userStory.Apex_Test_Level__c, 'Apex_Test_Level__c should be updated to Run Local Tests');
        }
    }

    @IsTest
    private static void setRunAllTest() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            
            copado__User_Story__c userStory = getUserStory();
            userStory.copado__Promotion_Test_Level__c = 'RunAllTestsInOrg';

            // EXERCISE

            Test.startTest();
            update userStory;
            Test.stopTest();

            // VERIFY
            
            userStory = getUserStory();
            System.assertEquals('Run All Tests In Org', userStory.Apex_Test_Level__c, 'Apex_Test_Level__c should be updated to Run All Tests In Org');
        }
    }

    @IsTest
    private static void promotionTestLevelUnaffectedByApexTestLevel() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            copado__User_Story__c userStory = getUserStory();
            userStory.Apex_Test_Level__c = 'Run Specified Tests';

            // EXERCISE

            Test.startTest();
            update userStory;
            Test.stopTest();

            // VERIFY

            userStory = getUserStory();
            System.assertEquals('NoTestRun', userStory.copado__Promotion_Test_Level__c, 'copado__Promotion_Test_Level__c should not be updated to Run Specified Tests');
        }
    }

    private static copado__User_Story__c getUserStory() {
        return [SELECT Id, Apex_Test_Level__c, copado__Promotion_Test_Level__c FROM copado__User_Story__c].get(0);
    }

    private static void createData() {
        copado__User_Story__c story = new copado__User_Story__c(copado__User_Story_Title__c = 'US 1', copado__Status__c = 'Draft');
        insert story;
    }
}