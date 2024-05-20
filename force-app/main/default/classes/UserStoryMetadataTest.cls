@IsTest
private class UserStoryMetadataTest {
    private final static String APEX_CLASS = 'ApexClass';
    private final static String APEX_TRIGGER = 'ApexTrigger';
    private static final String APEX_TEST_SUITE = 'ApexTestSuite';
    private static final String CUSTOM_OBJECT = 'CustomObject';
    private final static String ADD = 'Add';
    private final static String SAMPLE_CLASS_1 = 'SampleClass1';
    private final static String SAMPLE_CLASS_2 = 'SampleClass2';
    private final static String SAMPLE_TRIGGER_1 = 'SampleTrigger1';
    private final static String SAMPLE_TRIGGER_2 = 'SampleTrigger2';
    private final static String SAMPLE_TEST_SUITE_1 = 'SampleTestSuite1';
    private final static String SAMPLE_TEST_SUITE_2 = 'SampleTestSuite2';
    private final static String TEST_1 = 'Test1';
    private final static String TEST_2 = 'Test2';

    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void userStoryMetadata() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id userStoryId = getUserStoryId();

            // EXERCISE

            UserStoryMetadata userStoryMetadata = new UserStoryMetadata(getUserStoryMetadata(userStoryId));

            // VERIFY

            Assert.areEqual(2, userStoryMetadata.userStoryClasses.size(), 'Number of User story classes should be 2');
            Assert.areEqual(2, userStoryMetadata.userStoryTriggers.size(), 'Number of User story triggers should be 2');
            Assert.areEqual(2, userStoryMetadata.userStoryApexTestSuites.size(), 'Number of User story test suites should be 2');
            Assert.isTrue(
                userStoryMetadata.userStoryClasses.containsAll(new Set<String>{ SAMPLE_CLASS_1, SAMPLE_CLASS_2 }),
                'The user story metadata apex classes list is incorrect'
            );
            Assert.isTrue(
                userStoryMetadata.userStoryTriggers.containsAll(new Set<String>{ SAMPLE_TRIGGER_1, SAMPLE_TRIGGER_2 }),
                'The user story metadata apex triggers list is incorrect'
            );
            Assert.isTrue(
                userStoryMetadata.userStoryApexTestSuites.containsAll(new Set<String>{ SAMPLE_TEST_SUITE_1, SAMPLE_TEST_SUITE_2 }),
                'The user story metadata test suites list is incorrect'
            );
        }
    }

    @IsTest
    private static void toClassesAndTriggers() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            UserStoryMetadata userStoryMetadata = new UserStoryMetadata();

            // EXERCISE

            userStoryMetadata.toClassesAndTriggers(getCommitChanges());

            // VERIFY

            Assert.areEqual(2, userStoryMetadata.userStoryClasses.size(), 'Number of User story classes should be 2');
            Assert.areEqual(2, userStoryMetadata.userStoryTriggers.size(), 'Number of User story triggers should be 2');
            Assert.areEqual(2, userStoryMetadata.userStoryApexTestSuites.size(), 'Number of User story test suites should be 2');
            Assert.isTrue(
                userStoryMetadata.userStoryClasses.containsAll(new Set<String>{ SAMPLE_CLASS_1, SAMPLE_CLASS_2 }),
                'The user story metadata apex classes list is incorrect'
            );
            Assert.isTrue(
                userStoryMetadata.userStoryTriggers.containsAll(new Set<String>{ SAMPLE_TRIGGER_1, SAMPLE_TRIGGER_2 }),
                'The user story metadata apex triggers list is incorrect'
            );
            Assert.isTrue(
                userStoryMetadata.userStoryApexTestSuites.containsAll(new Set<String>{ SAMPLE_TEST_SUITE_1, SAMPLE_TEST_SUITE_2 }),
                'The user story metadata test suites list is incorrect'
            );
        }
    }

    @IsTest
    private static void add() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id userStoryId = getUserStoryId();
            UserStoryMetadata userStoryMetadata = new UserStoryMetadata(getUserStoryMetadata(userStoryId));

            // EXERCISE

            userStoryMetadata.add(TEST_1, APEX_CLASS);
            userStoryMetadata.add(TEST_2, APEX_TRIGGER);
            userStoryMetadata.add('Test3', CUSTOM_OBJECT);

            // VERIFY

            Assert.areEqual(3, userStoryMetadata.userStoryClasses.size(), 'Number of User story classes should be 3');
            Assert.areEqual(3, userStoryMetadata.userStoryTriggers.size(), 'Number of User story triggers should be 3');
            Assert.areEqual(2, userStoryMetadata.userStoryApexTestSuites.size(), 'Number of User story test suites should be 2');
            Assert.isTrue(
                userStoryMetadata.userStoryClasses.containsAll(new Set<String>{ SAMPLE_CLASS_1, SAMPLE_CLASS_2, TEST_1 }),
                'The user story metadata apex classes list is incorrect'
            );
            Assert.isTrue(
                userStoryMetadata.userStoryTriggers.containsAll(new Set<String>{ SAMPLE_TRIGGER_1, SAMPLE_TRIGGER_2, TEST_2 }),
                'The user story metadata apex triggers list is incorrect'
            );
            Assert.isTrue(
                userStoryMetadata.userStoryApexTestSuites.containsAll(new Set<String>{ SAMPLE_TEST_SUITE_1, SAMPLE_TEST_SUITE_2 }),
                'The user story metadata test suites list is incorrect'
            );
        }
    }

    @IsTest
    private static void remove() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id userStoryId = getUserStoryId();
            UserStoryMetadata userStoryMetadata = new UserStoryMetadata(getUserStoryMetadata(userStoryId));

            // EXERCISE

            userStoryMetadata.remove(SAMPLE_CLASS_1, APEX_CLASS);
            userStoryMetadata.remove(SAMPLE_TRIGGER_1, APEX_TRIGGER);
            userStoryMetadata.remove(SAMPLE_TEST_SUITE_1, APEX_TEST_SUITE);
            userStoryMetadata.remove(TEST_1, APEX_CLASS);
            userStoryMetadata.add(TEST_2, CUSTOM_OBJECT);

            // VERIFY

            Assert.areEqual(1, userStoryMetadata.userStoryClasses.size(), 'Number of User story classes should be 1');
            Assert.areEqual(1, userStoryMetadata.userStoryTriggers.size(), 'Number of User story triggers should be 1');
            Assert.areEqual(1, userStoryMetadata.userStoryApexTestSuites.size(), 'Number of User story test suites should be 1');
            Assert.isTrue(
                userStoryMetadata.userStoryClasses.containsAll(new Set<String>{ SAMPLE_CLASS_2 }),
                'The user story metadata apex classes list is incorrect'
            );
            Assert.isTrue(
                userStoryMetadata.userStoryTriggers.containsAll(new Set<String>{ SAMPLE_TRIGGER_2 }),
                'The user story metadata apex triggers list is incorrect'
            );
            Assert.isTrue(
                userStoryMetadata.userStoryApexTestSuites.containsAll(new Set<String>{ SAMPLE_TEST_SUITE_2 }),
                'The user story metadata test suites list is incorrect'
            );
        }
    }

    @IsTest
    private static void removeAll() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id userStoryId = getUserStoryId();
            UserStoryMetadata userStoryMetadata = new UserStoryMetadata(getUserStoryMetadata(userStoryId));

            // EXERCISE

            userStoryMetadata.removeAll(new Set<String>{ SAMPLE_CLASS_1, SAMPLE_CLASS_2 }, APEX_CLASS);
            userStoryMetadata.removeAll(new Set<String>{ SAMPLE_TEST_SUITE_1, SAMPLE_TEST_SUITE_2 }, APEX_TEST_SUITE);
            userStoryMetadata.removeAll(new Set<String>{ SAMPLE_TRIGGER_1 }, APEX_TRIGGER);
            userStoryMetadata.removeAll(new Set<String>{ TEST_1, TEST_2 }, CUSTOM_OBJECT);

            // VERIFY

            Assert.areEqual(0, userStoryMetadata.userStoryClasses.size(), 'Number of User story classes should be 0');
            Assert.areEqual(1, userStoryMetadata.userStoryTriggers.size(), 'Number of User story triggers should be 1');
            Assert.areEqual(0, userStoryMetadata.userStoryApexTestSuites.size(), 'Number of User story test suites should be 0');
            Assert.isTrue(
                userStoryMetadata.userStoryTriggers.containsAll(new Set<String>{ SAMPLE_TRIGGER_2 }),
                'The user story metadata apex triggers list is incorrect'
            );
        }
    }

    @IsTest
    private static void hasApex() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id userStoryId = getUserStoryId();
            UserStoryMetadata userStoryMetadata = new UserStoryMetadata(getUserStoryMetadata(userStoryId));

            // EXERCISE

            userStoryMetadata.removeAll(new Set<String>{ SAMPLE_CLASS_1, SAMPLE_CLASS_2 }, APEX_CLASS);
            userStoryMetadata.removeAll(new Set<String>{ SAMPLE_TEST_SUITE_1, SAMPLE_TEST_SUITE_2 }, APEX_TEST_SUITE);
            userStoryMetadata.removeAll(new Set<String>{ SAMPLE_TRIGGER_1 }, APEX_TRIGGER);
            userStoryMetadata.removeAll(new Set<String>{ TEST_1, TEST_2 }, CUSTOM_OBJECT);
            userStoryMetadata.add(SAMPLE_TEST_SUITE_1, APEX_TEST_SUITE);

            // VERIFY

            Assert.areEqual(0, userStoryMetadata.userStoryClasses.size(), 'Number of User story classes should be 0');
            Assert.areEqual(1, userStoryMetadata.userStoryTriggers.size(), 'Number of User story triggers should be 1');
            Assert.areEqual(1, userStoryMetadata.userStoryApexTestSuites.size(), 'Number of User story test suites should be 1');
            Assert.isTrue(userStoryMetadata.hasApex(), 'The userStoryMetadata should consists of apex');
            Assert.isTrue(
                userStoryMetadata.userStoryTriggers.containsAll(new Set<String>{ SAMPLE_TRIGGER_2 }),
                'The user story metadata apex triggers list is incorrect'
            );
            Assert.isTrue(
                userStoryMetadata.userStoryApexTestSuites.containsAll(new Set<String>{ SAMPLE_TEST_SUITE_1 }),
                'The user story metadata test suites list is incorrect'
            );
        }
    }

    @IsTest
    private static void hasTestSuites() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id userStoryId = getUserStoryId();
            UserStoryMetadata userStoryMetadata = new UserStoryMetadata(getUserStoryMetadata(userStoryId));

            // EXERCISE

            userStoryMetadata.removeAll(new Set<String>{ SAMPLE_CLASS_1, SAMPLE_CLASS_2 }, APEX_CLASS);
            userStoryMetadata.removeAll(new Set<String>{ SAMPLE_TEST_SUITE_1, SAMPLE_TEST_SUITE_2 }, APEX_TEST_SUITE);
            userStoryMetadata.removeAll(new Set<String>{ SAMPLE_TRIGGER_1 }, APEX_TRIGGER);
            userStoryMetadata.removeAll(new Set<String>{ TEST_1, TEST_2 }, CUSTOM_OBJECT);
            userStoryMetadata.add(SAMPLE_TEST_SUITE_1, APEX_TEST_SUITE);

            // VERIFY

            Assert.areEqual(0, userStoryMetadata.userStoryClasses.size(), 'Number of User story classes should be 0');
            Assert.areEqual(1, userStoryMetadata.userStoryTriggers.size(), 'Number of User story triggers should be 1');
            Assert.areEqual(1, userStoryMetadata.userStoryApexTestSuites.size(), 'Number of User story test suites should be 1');
            Assert.isTrue(userStoryMetadata.hasTestSuites(), 'The userStoryMetadata should consists of test suites');
            Assert.isTrue(
                userStoryMetadata.userStoryTriggers.containsAll(new Set<String>{ SAMPLE_TRIGGER_2 }),
                'The user story metadata apex triggers list is incorrect'
            );
            Assert.isTrue(
                userStoryMetadata.userStoryApexTestSuites.containsAll(new Set<String>{ SAMPLE_TEST_SUITE_1 }),
                'The user story metadata test suites list is incorrect'
            );
        }
    }

    @IsTest
    private static void clear() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            
            Id userStoryId = getUserStoryId();
            UserStoryMetadata userStoryMetadata = new UserStoryMetadata(getUserStoryMetadata(userStoryId));

            // EXERCISE

            userStoryMetadata.clear();

            // VERIFY

            Assert.areEqual(0, userStoryMetadata.userStoryClasses.size(), 'Number of User story classes should be 0');
            Assert.areEqual(0, userStoryMetadata.userStoryTriggers.size(), 'Number of User story triggers should be 0');
            Assert.areEqual(0, userStoryMetadata.userStoryApexTestSuites.size(), 'Number of User story test suites should be 0');
            Assert.isFalse(userStoryMetadata.hasApex(), 'The userStoryMetadata should not consists of apex');
        }
    }

    private static void createData() {
        Credential credential = new Credential(new Environment().type('Production/Developer')).type('Production/Developer');
        UserStory userStory = new UserStory().title('US 1').status('Draft').credential(credential);

        new UserStoryMetadata_t().name(SAMPLE_CLASS_1).type(APEX_CLASS).action(ADD).userStory(userStory);
        new UserStoryMetadata_t().name(SAMPLE_CLASS_2).type(APEX_CLASS).action(ADD).userStory(userStory);
        new UserStoryMetadata_t().name(SAMPLE_TRIGGER_1).type(APEX_TRIGGER).action(ADD).userStory(userStory);
        new UserStoryMetadata_t().name(SAMPLE_TRIGGER_2).type(APEX_TRIGGER).action(ADD).userStory(userStory);
        new UserStoryMetadata_t().name(SAMPLE_TEST_SUITE_1).type(APEX_TEST_SUITE).action(ADD).userStory(userStory);
        new UserStoryMetadata_t().name(SAMPLE_TEST_SUITE_2).type(APEX_TEST_SUITE).action(ADD).userStory(userStory).persist();
    }

    private static List<CommitChanges.Change> getCommitChanges() {
        List<CommitChanges.Change> changeList = new List<CommitChanges.Change>();
        changeList.add(getCommitChange(APEX_CLASS, SAMPLE_CLASS_1, 'File path is handled automatically', '', ADD));
        changeList.add(getCommitChange(APEX_TRIGGER, SAMPLE_TRIGGER_1, 'File path is handled automatically', '', ADD));
        changeList.add(getCommitChange(APEX_CLASS, SAMPLE_CLASS_2, 'File path is handled automatically', '', ADD));
        changeList.add(getCommitChange(APEX_TRIGGER, SAMPLE_TRIGGER_2, 'File path is handled automatically', '', ADD));
        changeList.add(getCommitChange(APEX_TEST_SUITE, SAMPLE_TEST_SUITE_1, 'File path is handled automatically', '', ADD));
        changeList.add(getCommitChange(APEX_TEST_SUITE, SAMPLE_TEST_SUITE_2, 'File path is handled automatically', '', ADD));
        return changeList;
    }

    private static List<CommitChanges.Change> getCommitChangesWithAddApexClassOnly() {
        List<CommitChanges.Change> changeList = new List<CommitChanges.Change>();
        changeList.add(getCommitChange(APEX_CLASS, SAMPLE_CLASS_1, 'File path is handled automatically', '', ADD));
        return changeList;
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static CommitChanges.Change getCommitChange(String type, String name, String module, String category, String action) {
        return new CommitChanges.Change(type, name, module, category, action);
    }

    private static Id getContentVersionId() {
        return [SELECT Id FROM ContentVersion LIMIT 1].Id;
    }

    private static Id getUserStoryId() {
        return [SELECT Id FROM copado__User_Story__c LIMIT 1].Id;
    }

    private static List<copado__User_Story_Metadata__c> getUserStoryMetadata(Id userStoryId) {
        return [
            SELECT Id, copado__Metadata_API_Name__c, copado__Type__c
            FROM copado__User_Story_Metadata__c
            WHERE copado__User_Story__c = :userStoryId
        ];
    }
}