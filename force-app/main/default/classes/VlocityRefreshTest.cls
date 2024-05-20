@IsTest
public class VlocityRefreshTest {
    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void functionRunSuccessful() {
        System.runAs(TestUtilities.getRunAsUser()) {
            //SETUP
            Id resultId;
            SObject mockResult = createResult().persist();
            VlocityRefresh.mockResult = getResultObj(mockResult.Id);

            // EXERCISE

            Test.startTest();
            resultId = VlocityRefresh.execute(TestUtilities.getCredentialObj(true).Id);
            Test.stopTest();

            //VERIFY
            Assert.areEqual('copado__Result__c', resultId.getSObjectType().getDescribe().getName(), 'Result should be created successfully');
        }
    }

    @IsTest
    private static void invalidCredential() {
        System.runAs(TestUtilities.getRunAsUser()) {
            //SETUP
            String exceptionMessage;

            // EXERCISE

            Test.startTest();
            try {
                VlocityRefresh.execute(null);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            //VERIFY

            Assert.isTrue(exceptionMessage.contains(Label.Credential_Not_Found), 'The exception message should be ' + Label.Credential_Not_Found);
        }
    }

    private static void createData() {
        TestUtilities.createEnvironment('Vlocity Test Environment').persist();

        TestUtilities.createCredential(true, TestUtilities.getEnvironmentObj('Vlocity Test Environment')).persist();
    }

    private static Result createResult() {
        return new Result().type('Function');
    }

    private static Result getResultObj(Id recordId) {
        return new Result().recordId(recordId);
    }
}