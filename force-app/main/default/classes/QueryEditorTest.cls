@IsTest
private class QueryEditorTest {
    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
    }

    @IsTest
    private static void testComparableLogic() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            List<QueryEditor.CriteriaWrapper> criteriaWrappers = new List<QueryEditor.CriteriaWrapper>();

            // EXERCISE

            QueryEditor.CriteriaWrapper criteriaWrapper = new QueryEditor.CriteriaWrapper();
            criteriaWrapper.order = 3;
            criteriaWrappers.add(criteriaWrapper);
            criteriaWrapper = new QueryEditor.CriteriaWrapper();
            criteriaWrapper.order = 2;
            criteriaWrappers.add(criteriaWrapper);
            criteriaWrapper = new QueryEditor.CriteriaWrapper();
            criteriaWrapper.order = 1;
            criteriaWrappers.add(criteriaWrapper);

            criteriaWrappers.sort();

            // VERIFY

            Assert.areEqual(1, criteriaWrappers[0].order, 'The order should be 1');
            Assert.areEqual(2, criteriaWrappers[1].order, 'The order should be 2');
            Assert.areEqual(3, criteriaWrappers[2].order, 'The order should be 3');
        }
    }
}