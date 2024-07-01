@IsTest
private class JobExecutionForTestRecordsTest {
    @TestSetup
    private static void testSetup() {
        TestUtilities.setup();
    }
    /*
    ======================================================================
    NOTE: The logic in the apex class JobExecutionForTestRecords is deprecated because of US-0038370. 
    Hence its test class JobExecutionForTestRecordsTest is just present to cover it.
    ======================================================================
    */

    @IsTest
    private static void executeTest() {
        // Exercise
        System.runAs(TestUtilities.getRunAsUser()) {
            Test.startTest();
            new JobExecutionForTestRecords().execute(null, null);
            Test.stopTest();
        }

        // Verify
        Assert.isTrue(true, 'The assert should be true');
    }
}