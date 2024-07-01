@IsTest
public class ValidateMetadataSchemaTest {
    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
    }

    @IsTest
    private static void functionRunSuccessful() {
        System.runAs(TestUtilities.getRunAsUser()) {
            //SETUP
            Id resultId;
            SObject mockResult = createResult().persist();
            ValidateMetadataSchema.mockResult = getResultObject(mockResult.Id);
            String metadataFileId = fflib_IDGenerator.generate(ContentVersion.SObjectType);
            String metadataType = 'Layout';

            // EXERCISE

            Test.startTest();
            resultId = ValidateMetadataSchema.execute(metadataFileId, metadataType);
            Test.stopTest();

            //VERIFY
            Assert.areEqual(mockResult.Id, resultId, 'ResultId should be the same as mocked one.');
            Assert.areEqual('copado__Result__c', resultId.getSObjectType().getDescribe().getName(), 'Result should be created successfully');
        }
    }

    private static Result createResult() {
        return new Result().type('Function');
    }

    private static Result getResultObject(Id recordId) {
        return new Result().recordId(recordId);
    }
}