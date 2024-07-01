@IsTest
private class LwcLabelsTranslationTest {
    @TestSetup
    private static void testSetup() {
        TestUtilities.setup();
    }

    @IsTest
    private static void testTranslationForInvalidLabel() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            List<String> labels = new List<String>{ 'SampleLabel1' };

            // EXERCISE

            Map<String, String> result = LwcLabelsTranslation.execute(labels);

            // VERIFY

            for (String label : labels) {
                Assert.isTrue(String.isBlank(result.get(label)), 'No translation should be present for the provided label');
            }
        }
    }

    @IsTest
    private static void testTranslationForValidLabel() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            List<String> labels = new List<String>{ 'Result_Viewer_Header' };

            // EXERCISE

            Map<String, String> result = LwcLabelsTranslation.execute(labels);

            // VERIFY

            for (String label : labels) {
                Assert.areEqual('Result Report ({0})', result.get(label), 'The translated text is incorrect');
            }
        }
    }
}