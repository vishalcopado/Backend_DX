@IsTest
private class MCDDConfigurationCheckerTest {
    
    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
    }

    @IsTest
    private static void checkMCDDConfigurations(){
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP + EXERCISE
            List<Boolean> result = MCDDConfigurationChecker.checkMCDDConfigurations();

            //Verify
            Assert.isTrue(result.get(0), 'MCDD should be enabled by default');
        }
    }

}