@IsTest
private class ApexTestsResultTest {
    private static final String MOCK_APEX_TESTS_RESULT = '{"result":{"summary":{"testsRan":3,"passing":2,"failing":1,"skipped":0,"passRate":"67%","failRate":"32%","testRunCoverage":"79%"},"coverage":{"coverage":[{"name":"HelloMars","coveredPercent":75,"totalLines":100,"totalCovered":75},{"name":"HelloWorld","coveredPercent":100,"totalLines":100,"totalCovered":90},{"name":"AccountTrigger","coveredPercent":74,"totalLines":100,"totalCovered":74},{"name":"HelloWorldWrapper","coveredPercent":0,"totalLines":0,"totalCovered":0}]}}}';

    @IsTest
    private static void fromJson() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Exercise
            ApexTestsResult testsResult = new ApexTestsResult().fromJson(MOCK_APEX_TESTS_RESULT);

            // Verify
            Assert.areEqual(3, testsResult.result.summary.testsRan, 'There should be 3 tests ran');
            Assert.areEqual(2, testsResult.result.summary.passing, 'There should be 2 passing test');
            Assert.areEqual(1, testsResult.result.summary.failing, 'There should be 1 failing test');
            Assert.areEqual(0, testsResult.result.summary.skipped, 'There should be 0 skipped test');
            Assert.areEqual('67%', testsResult.result.summary.passRate, 'Pass Rate should be 67%');
            Assert.areEqual('32%', testsResult.result.summary.failRate, 'Fail Rate should be 32%');
            Assert.areEqual('79%', testsResult.result.summary.testRunCoverage, 'Coverage should be 79%');
        }
    }

    @IsTest
    private static void calculateClassesWithoutCoverage() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup
            ApexTestsResult testsResult = new ApexTestsResult().fromJson(MOCK_APEX_TESTS_RESULT);
            Set<String> userStoryClasses = new Set<String>{ 'HelloMars', 'HelloWorld' };

            // Exercise
            Integer classesWithoutCoverage = testsResult.getMetadataWithoutCoverage(85, userStoryClasses).size();

            // Verify
            Assert.areEqual(1, classesWithoutCoverage, 'There should only be one class without coverage');
        }
    }

    @IsTest
    private static void calculateClassesWithoutCoverageWithNoExecutableLogic() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup
            ApexTestsResult testsResult = new ApexTestsResult().fromJson(MOCK_APEX_TESTS_RESULT);
            Set<String> userStoryClasses = new Set<String>{ 'HelloMars', 'HelloWorld', 'HelloWorldWrapper' };

            // Exercise
            Integer classesWithoutCoverage = testsResult.getMetadataWithoutCoverage(85, userStoryClasses).size();

            // Verify
            Assert.areEqual(1, classesWithoutCoverage, 'There should be only one class without coverage');
        }
    }

    @IsTest
    private static void calculateTriggersWithoutCoverage() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup
            ApexTestsResult testsResult = new ApexTestsResult().fromJson(MOCK_APEX_TESTS_RESULT);
            Set<String> userStoryTriggers = new Set<String>{ 'AccountTrigger' };

            // Exercise
            Integer triggersWithoutCoverage = testsResult.getMetadataWithoutCoverage(75, userStoryTriggers).size();

            // Verify
            Assert.areEqual(1, triggersWithoutCoverage, 'There should only be one trigger without coverage');
        }
    }

    @IsTest
    private static void getTestRunCoverage() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup
            ApexTestsResult testsResult = new ApexTestsResult().fromJson(MOCK_APEX_TESTS_RESULT);
            Set<String> metadata = new Set<String>{ 'HelloMars', 'HelloWorld', 'AccountTrigger' };

            // Exercise
            Integer testRunCoverage = testsResult.getTestRunCoverage(metadata);

            // Verify
            Assert.areEqual(79, testRunCoverage, 'Test run coverage should be 79');
        }
    }

    @IsTest
    private static void getTestRunCoverageWithOnlyTestClassesCommit() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup
            ApexTestsResult testsResult = new ApexTestsResult().fromJson(MOCK_APEX_TESTS_RESULT);
            // When we are trying to evaluate the coverage for a user story which only contains test classes
            // then metadata varibale will be an empty Set.
            Set<String> metadata = new Set<String>();

            // Exercise
            Integer testRunCoverage = testsResult.getTestRunCoverage(metadata);

            // Verify
            Assert.areEqual(100, testRunCoverage, 'Test run coverage should be 100');
        }
    }

    @IsTest
    private static void getTestRunCoverageForClassesWithNoExecutableLogic() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup
            ApexTestsResult testsResult = new ApexTestsResult().fromJson(MOCK_APEX_TESTS_RESULT);
            Set<String> metadata = new Set<String>{ 'HelloWorldWrapper' };

            // Exercise
            Integer testRunCoverage = testsResult.getTestRunCoverage(metadata);

            // Verify
            Assert.areEqual(100, testRunCoverage, 'Test run coverage should be 100');
        }
    }

    @IsTest
    private static void getPassRate() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup
            ApexTestsResult testsResult = new ApexTestsResult().fromJson(MOCK_APEX_TESTS_RESULT);

            // Exercise
            Integer testsPassRate = testsResult.getPassRate();

            // Verify
            Assert.areEqual(67, testsPassRate, 'Test run pass rate should be 67');
        }
    }

    @IsTest
    private static void getFailRate() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup
            ApexTestsResult testsResult = new ApexTestsResult().fromJson(MOCK_APEX_TESTS_RESULT);

            // Exercise
            Integer testsFailRate = testsResult.getFailRate();

            // Verify
            Assert.areEqual(32, testsFailRate, 'Test run fail rate should be 32');
        }
    }

    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
    }
}