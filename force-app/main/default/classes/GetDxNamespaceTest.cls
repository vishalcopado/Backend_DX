@IsTest
private class GetDxNamespaceTest {
    @IsTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    private static void execute() {
        // SETUP

        Id contextId = fflib_IDGenerator.generate(copado__JobStep__c.SObjectType);

        // EXERCISE

        String namespace = new GetDxNamespace().execute(contextId);

        // VERIFY

        if (String.isNotBlank(Settings.NS)) {
            Assert.areEqual('cmcsf__', namespace, 'Namespace should be returned in managed context.');
        } else {
            Assert.areEqual('', namespace, 'Namespace should be empty running in unmanaged context.');
        }
    }
}