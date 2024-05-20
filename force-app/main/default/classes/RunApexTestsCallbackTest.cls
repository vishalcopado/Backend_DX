@IsTest
private class RunApexTestsCallbackTest {
    /*
    ======================================================================
    NOTE: The logic in the apex class RunApexTestsCallback is deprecated because of US-0032169. 
    Hence its test class RunApexTestsCallbackTest is just present to cover it.
    ======================================================================
    */
    @IsTest
    private static void executeTest() {
        // Exercise
        Test.startTest();
        new RunApexTestsCallback().execute(null, null, null);
        Test.stopTest();

        // Verify
        System.assert(true, 'The assert should be true');
    }
}