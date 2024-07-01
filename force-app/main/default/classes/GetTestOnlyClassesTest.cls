// This test class is a dummy class because its main class is not needed now, more details are on US-0081612
@IsTest
private class GetTestOnlyClassesTest {
    @TestSetup
    private static void testSetup() {
        TestUtilities.setup();
    }

    @IsTest
    private static void executeTest() {
        System.runAs(TestUtilities.getRunAsUser()) {
            new GetTestOnlyClasses().execute(null);
            Assert.isTrue(true, 'This is a dummy assert which will always pass');
        }
    }
}