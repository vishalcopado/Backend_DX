@IsTest
public class GetVlocityDependenciesTest {
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
            String selectedDatapacks = JSON.serialize(
                new List<CommitChanges>{
                    new CommitChanges('OmniScript', 'sample_canBeAnything_English', 'File path is handled automatically', 'Vlocity', 'Add')
                }
            );

            SObject mockResult = createResult().persist();
            GetVlocityDependencies.mockResult = getResultObj(mockResult.Id);

            // EXERCISE

            Test.startTest();
            resultId = GetVlocityDependencies.execute(TestUtilities.getCredentialObj(true).Id, selectedDatapacks);
            Test.stopTest();

            //VERIFY
            Assert.areEqual('copado__Result__c', resultId.getSObjectType().getDescribe().getName(), 'Result should be created successfully');
        }
    }

    @IsTest
    private static void invalidCredential() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String exceptionMessage;
            String selectedDatapacks = JSON.serialize(
                new List<CommitChanges>{
                    new CommitChanges('OmniScript', 'sample_canBeAnything_English', 'File path is handled automatically', 'Vlocity', 'Add')
                }
            );

            // EXERCISE

            Test.startTest();
            try {
                GetVlocityDependencies.execute(null, selectedDatapacks);
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

        createFunctionObj('vlocity_retrieve').persist();
    }

    private static Function createFunctionObj(String apiName) {
        return new Function().apiName(apiName).script('script here');
    }

    private static Result createResult() {
        return new Result().type('Function');
    }

    private static Result getResultObj(Id recordId) {
        return new Result().recordId(recordId);
    }

    private static copado__Result__c getResult(Id recordId) {
        return [SELECT Id, copado__Function__c, copado__ParentId__c FROM copado__Result__c WHERE Id = :recordId];
    }

    public class CommitChanges {
        private String a;
        private String c;
        private String m;
        private String n;
        private String t;

        @SuppressWarnings('PMD.ExcessiveParameterList')
        public CommitChanges(String type, String name, String module, String category, String action) {
            this.t = type;
            this.n = name;
            this.m = module;
            this.c = category;
            this.a = action;
        }
    }
}