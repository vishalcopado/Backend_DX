@IsTest
private class GetAllTestClassesFromOrgTest {
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

            String response = getSuccessResponse(getResponseContent());
            GetAllTestClassesFromOrg.mockResponse = response;

            // EXERCISE

            copado.GlobalAPI.ProxyOrgResponse result = new GetAllTestClassesFromOrg(getOrgCredentialId()).execute();

            // VERIFY

            Assert.areEqual(200, result.statusCode, 'The status code is incorrect');
            Assert.areEqual(getResponseContent(), result.content, 'The content of the response is incorrect');
            Assert.areEqual(null, result.errorCode, 'The errorCode of the response is incorrect');
            Assert.areEqual(null, result.errorMessage, 'The errorMessage of the response is incorrect');
        }
    }

    @IsTest
    private static void executeSuccessfullyWithSearchTerm() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String response = getSuccessResponse(getResponseContentBasedOnSearchTerm());
            GetAllTestClassesFromOrg.mockResponse = response;

            // EXERCISE

            copado.GlobalAPI.ProxyOrgResponse result = new GetAllTestClassesFromOrg(
                    getOrgCredentialId(),
                    new Set<String>{ 'new SampleTest\\(', 'SampleTest.' }
                )
                .execute();

            // VERIFY

            Assert.areEqual(200, result.statusCode, 'The status code is incorrect');
            Assert.areEqual(getResponseContentBasedOnSearchTerm(), result.content, 'The content of the response is incorrect');
            Assert.areEqual(null, result.errorCode, 'The errorCode of the response is incorrect');
            Assert.areEqual(null, result.errorMessage, 'The errorMessage of the response is incorrect');
        }
    }

    @IsTest
    private static void executeWithFailureWithErrorMessage() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String response = getFailureResponseWithErrorMessage();
            GetAllTestClassesFromOrg.mockResponse = response;

            // EXERCISE
            String exceptionMessage;
            try {
                new GetAllTestClassesFromOrg(getOrgCredentialId()).execute();
            } catch (Exception error) {
                exceptionMessage = error.getMessage();
            }

            // VERIFY

            Assert.areEqual('Test error message', exceptionMessage, 'The exception message is incorrect');
        }
    }

    @IsTest
    private static void executeWithFailureWithoutErrorMessage() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String response = getFailureResponseWithoutErrorMessage();
            GetAllTestClassesFromOrg.mockResponse = response;

            // EXERCISE

            String exceptionMessage;
            try {
                new GetAllTestClassesFromOrg(getOrgCredentialId()).execute();
            } catch (Exception error) {
                exceptionMessage = error.getMessage();
            }

            // VERIFY

            Assert.areEqual(Label.Error_Finding_Test_Classes_From_Org, exceptionMessage, 'The exception message is incorrect');
        }
    }

    @IsTest
    private static void validateSOSLQueryWithoutSearchTerm() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Set<String> searchTerms = null;

            // EXERCISE

            String result = GetAllTestClassesFromOrg.getSOSLQuery(searchTerms);

            // VERIFY

            Assert.areEqual(
                'FIND {(@IsTest OR "testMethod void")} IN ALL FIELDS RETURNING ApexClass(Name, NamespacePrefix, LastModifiedDate, LastModifiedBy.Name WHERE Status = \'Active\' ORDER BY LastModifiedDate DESC)',
                result,
                'The SOSL query is incorrect'
            );
        }
    }

    @IsTest
    private static void validateSOSLQueryWithSearchTerm() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Set<String> searchTerms = new Set<String>{ 'new SampleClass\\(', 'SampleClass.*' };

            // EXERCISE

            String result = GetAllTestClassesFromOrg.getSOSLQuery(searchTerms);

            // VERIFY

            Assert.areEqual(
                'FIND {(@IsTest OR "testMethod void") AND ("new SampleClass\\(" OR "SampleClass.*")} IN ALL FIELDS RETURNING ApexClass(Name, NamespacePrefix, LastModifiedDate, LastModifiedBy.Name WHERE Status = \'Active\' ORDER BY LastModifiedDate DESC)',
                result,
                'The SOSL query is incorrect'
            );
        }
    }

    private static Id getOrgCredentialId() {
        return [SELECT Id FROM copado__Org__c LIMIT 1].Id;
    }

    private static String getResponseContent() {
        return '{' +
            '"searchRecords" : [' +
            '{' +
            '"Name": "fflib_IDGeneratorTest",' +
            '"LastModifiedDate": "2022-03-09T14:53:33.000+0000",' +
            '"LastModifiedBy": ' +
            '{' +
            '"Name": "User User"' +
            '},' +
            '"attributes": ' +
            '{' +
            '"type": "Apex Class"' +
            '},' +
            '"NamespacePrefix": "copado"' +
            '},' +
            '{' +
            '"Name": "DXControllerTest",' +
            '"LastModifiedDate": "2022-03-09T14:53:33.000+0000",' +
            '"LastModifiedBy": ' +
            '{' +
            '"Name": "User User"' +
            '},' +
            '"attributes": ' +
            '{' +
            '"type": "Apex Class"' +
            '},' +
            '"NamespacePrefix": "copado"' +
            '},' +
            '{' +
            '"Name": "SampleClassTest",' +
            '"LastModifiedDate": "2022-03-09T14:53:33.000+0000",' +
            '"LastModifiedBy": ' +
            '{' +
            '"Name": "User User"' +
            '},' +
            '"attributes": ' +
            '{' +
            '"type": "Apex Class"' +
            '},' +
            '"NamespacePrefix": "copado"' +
            '}' +
            ']' +
            '}"' +
            '}';
    }

    private static String getResponseContentBasedOnSearchTerm() {
        return '{' +
            '"searchRecords" : [' +
            '{' +
            '"Name": "SampleTest",' +
            '"LastModifiedDate": "2022-03-09T14:53:33.000+0000",' +
            '"LastModifiedBy": ' +
            '{' +
            '"Name": "User User"' +
            '},' +
            '"attributes": ' +
            '{' +
            '"type": "Apex Class"' +
            '},' +
            '"NamespacePrefix": ""' +
            '},' +
            '{' +
            '"Name": "SampleTest1",' +
            '"LastModifiedDate": "2022-03-09T14:53:33.000+0000",' +
            '"LastModifiedBy": ' +
            '{' +
            '"Name": "User User"' +
            '},' +
            '"attributes": ' +
            '{' +
            '"type": "Apex Class"' +
            '},' +
            '"NamespacePrefix": ""' +
            '},' +
            '{' +
            '"Name": "SampleTest2",' +
            '"LastModifiedDate": "2022-03-09T14:53:33.000+0000",' +
            '"LastModifiedBy": ' +
            '{' +
            '"Name": "User User"' +
            '},' +
            '"attributes": ' +
            '{' +
            '"type": "Apex Class"' +
            '},' +
            '"NamespacePrefix": ""' +
            '}' +
            ']' +
            '}"' +
            '}';
    }

    private static String getSuccessResponse(String response) {
        return new ProxyOrgResponse(200, response, null, null).getResponse();
    }

    private static String getFailureResponseWithErrorMessage() {
        return new ProxyOrgResponse(500, '', '', 'Test error message').getResponse();
    }

    private static String getFailureResponseWithoutErrorMessage() {
        return new ProxyOrgResponse(500, '', '', '').getResponse();
    }

    private static void makeData() {
        new Credential(new Environment()).persist();
    }
}