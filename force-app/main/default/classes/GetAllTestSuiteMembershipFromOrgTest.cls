@IsTest
private class GetAllTestSuiteMembershipFromOrgTest {
    private final static Id APEX_TEST_SUITE_1_ID = fflib_IDGenerator.generate(ApexTestSuite.SObjectType);
    private final static Id APEX_TEST_SUITE_2_ID = fflib_IDGenerator.generate(ApexTestSuite.SObjectType);
    private final static Id TEST_SUITE_MEMBERSHIP_1_ID = fflib_IDGenerator.generate(TestSuiteMembership.SObjectType);
    private final static Id TEST_SUITE_MEMBERSHIP_2_ID = fflib_IDGenerator.generate(TestSuiteMembership.SObjectType);

    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            makeData();
        }
    }

    @IsTest
    private static void executeWithSuccess() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            GetAllTestSuiteMembershipFromOrg.testSuiteMockResponse = getSuccessResponseForTestSuite();
            GetAllTestSuiteMembershipFromOrg.testSuiteMembershipMockResponse = getSuccessResponseForTestSuiteMembership();
            Set<Id> testSuiteMembershipIds = new Set<Id>{ TEST_SUITE_MEMBERSHIP_1_ID, TEST_SUITE_MEMBERSHIP_2_ID };

            // EXERCISE

            List<TestSuiteMembership> response = new GetAllTestSuiteMembershipFromOrg(getOrgCredentialId()).execute();

            // VERIFY

            Assert.areEqual(2, response.size(), 'There should be 2 records for TestSuiteMembership');
            for (TestSuiteMembership testSuiteMembership : response) {
                Assert.isTrue(testSuiteMembershipIds.contains(testSuiteMembership.Id), 'The received TestSuiteMembership data is incorrect');
            }
        }
    }

    @IsTest
    private static void executeWithTestSuiteFailure() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            GetAllTestSuiteMembershipFromOrg.testSuiteMockResponse = getFailureResponseForTestSuite();
            GetAllTestSuiteMembershipFromOrg.testSuiteMembershipMockResponse = getSuccessResponseForTestSuiteMembership();
            Exception exceptionMessage;

            // EXERCISE

            try {
                new GetAllTestSuiteMembershipFromOrg(getOrgCredentialId()).execute();
            } catch (Exception ex) {
                exceptionMessage = ex;
            }

            // VERIFY

            Assert.isTrue(
                exceptionMessage.getMessage().contains('Failure in retrieving Apex Test Suite data'),
                'Exception message should be received'
            );
        }
    }

    @IsTest
    private static void executeWithTestSuiteMembershipFailure() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            GetAllTestSuiteMembershipFromOrg.testSuiteMockResponse = getSuccessResponseForTestSuite();
            GetAllTestSuiteMembershipFromOrg.testSuiteMembershipMockResponse = getFailureResponseForTestSuiteMembership();
            Exception exceptionMessage;

            // EXERCISE

            try {
                new GetAllTestSuiteMembershipFromOrg(getOrgCredentialId()).execute();
            } catch (Exception ex) {
                exceptionMessage = ex;
            }

            // VERIFY

            Assert.isTrue(
                exceptionMessage.getMessage().contains('Failure in retrieving Test Suite Membership data'),
                'Exception message should be received'
            );
        }
    }

    private static String getSuccessResponseForTestSuite() {
        String content =
            '{' +
            '"size" : 2,' +
            '"totalSize" : 2,' +
            '"done" : true,' +
            '"queryLocator" : null,' +
            '"entityTypeName" : "ApexTestSuite",' +
            '"records" : [ {' +
            '"attributes" : {' +
            '"type" : "ApexTestSuite",' +
            '"url" : "/services/data/v56.0/tooling/sobjects/ApexTestSuite/' +
            APEX_TEST_SUITE_1_ID +
            '"' +
            '},' +
            '"Id" : "' +
            APEX_TEST_SUITE_1_ID +
            '"' +
            '}, {' +
            '"attributes" : {' +
            '"type" : "ApexTestSuite",' +
            '"url" : "/services/data/v56.0/tooling/sobjects/ApexTestSuite/' +
            APEX_TEST_SUITE_2_ID +
            '"' +
            '},' +
            '"Id" : "' +
            APEX_TEST_SUITE_2_ID +
            '"' +
            '} ]' +
            '}';
        return JSON.serialize(new ProxyOrgResponse(200, content, null, null));
    }

    private static String getFailureResponseForTestSuite() {
        return JSON.serialize(new ProxyOrgResponse(400, null, null, 'Failure in retrieving Apex Test Suite data'));
    }

    private static String getSuccessResponseForTestSuiteMembership() {
        Id dummyUserId = fflib_IDGenerator.generate(User.SObjectType);
        String content =
            '{' +
            '"size" : 2,' +
            '"totalSize" : 2,' +
            '"done" : true,' +
            '"queryLocator" : null,' +
            '"entityTypeName" : "TestSuiteMembership",' +
            '"records" : [ {' +
            '"attributes" : {' +
            '"type" : "TestSuiteMembership",' +
            '"url" : "/services/data/v56.0/tooling/sobjects/TestSuiteMembership/' +
            TEST_SUITE_MEMBERSHIP_1_ID +
            '"' +
            '},' +
            '"Id" : "' +
            TEST_SUITE_MEMBERSHIP_1_ID +
            '",' +
            '"ApexClass" : {' +
            '"attributes" : {' +
            '"type" : "ApexClass",' +
            '"url" : "/services/data/v56.0/tooling/sobjects/ApexClass/' +
            fflib_IDGenerator.generate(ApexClass.SObjectType) +
            '"' +
            '},' +
            '"Name" : "Sample1Test",' +
            '"NamespacePrefix" : null,' +
            '"LastModifiedDate" : "2023-04-13T03:14:45.000+0000",' +
            '"LastModifiedBy" : {' +
            '"attributes" : {' +
            '"type" : "User",' +
            '"url" : "/services/data/v56.0/tooling/sobjects/User/' +
            dummyUserId +
            '"' +
            '},' +
            '"Name" : "User User"' +
            '}' +
            '},' +
            '"ApexTestSuite" : {' +
            '"attributes" : {' +
            '"type" : "ApexTestSuite",' +
            '"url" : "/services/data/v56.0/tooling/sobjects/ApexTestSuite/' +
            APEX_TEST_SUITE_1_ID +
            '"' +
            '},' +
            '"TestSuiteName" : "TestSuite1",' +
            '"LastModifiedDate" : "2023-04-13T03:52:30.000+0000",' +
            '"LastModifiedBy" : {' +
            '"attributes" : {' +
            '"type" : "User",' +
            '"url" : "/services/data/v56.0/tooling/sobjects/User/' +
            dummyUserId +
            '"' +
            '},' +
            '"Name" : "User User"' +
            '}' +
            '}' +
            '}, {' +
            '"attributes" : {' +
            '"type" : "TestSuiteMembership",' +
            '"url" : "/services/data/v56.0/tooling/sobjects/TestSuiteMembership/' +
            TEST_SUITE_MEMBERSHIP_2_ID +
            '"' +
            '},' +
            '"Id" : "' +
            TEST_SUITE_MEMBERSHIP_2_ID +
            '",' +
            '"ApexClass" : {' +
            '"attributes" : {' +
            '"type" : "ApexClass",' +
            '"url" : "/services/data/v56.0/tooling/sobjects/ApexClass/' +
            fflib_IDGenerator.generate(ApexClass.SObjectType) +
            '"' +
            '},' +
            '"Name" : "Sample2Test",' +
            '"NamespacePrefix" : null,' +
            '"LastModifiedDate" : "2023-04-13T03:11:49.000+0000",' +
            '"LastModifiedBy" : {' +
            '"attributes" : {' +
            '"type" : "User",' +
            '"url" : "/services/data/v56.0/tooling/sobjects/User/' +
            dummyUserId +
            '"' +
            '},' +
            '"Name" : "User User"' +
            '}' +
            '},' +
            '"ApexTestSuite" : {' +
            '"attributes" : {' +
            '"type" : "ApexTestSuite",' +
            '"url" : "/services/data/v56.0/tooling/sobjects/ApexTestSuite/' +
            APEX_TEST_SUITE_2_ID +
            '"' +
            '},' +
            '"TestSuiteName" : "TestSuite2",' +
            '"LastModifiedDate" : "2023-04-13T03:52:43.000+0000",' +
            '"LastModifiedBy" : {' +
            '"attributes" : {' +
            '"type" : "User",' +
            '"url" : "/services/data/v56.0/tooling/sobjects/User/' +
            dummyUserId +
            '"' +
            '},' +
            '"Name" : "User User"' +
            '}' +
            '}' +
            '} ]' +
            '}';
        return JSON.serialize(new ProxyOrgResponse(200, content, null, null));
    }

    private static String getFailureResponseForTestSuiteMembership() {
        return JSON.serialize(new ProxyOrgResponse(400, null, null, 'Failure in retrieving Test Suite Membership data'));
    }

    private static void makeData() {
        new Credential(new Environment()).persist();
    }

    private static Id getOrgCredentialId() {
        return [SELECT Id FROM copado__Org__c LIMIT 1].Id;
    }
}