@IsTest
private with sharing class CustomHighlightPanelCtrlTest {
    @TestSetup
    private static void testSetup() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void getFieldListandRecordTypeTest() {
        System.runAs(TestUtilities.getRunAsUser()) {
            //Setup
            copado__User_Story__c userStory = [SELECT Id FROM copado__User_Story__C WHERE copado__User_Story_Title__c = 'Ctrl'];
            String namespace = 'copado__';

            //Exercise
            Test.startTest();
            List<customHighlightPanelController.FieldDefinition> fieldDefinition = CustomHighlightPanelController.getFieldList(
                userStory.Id,
                namespace + 'Commit_Page'
            );
            Test.stopTest();

            // Verify
            System.assert(fieldDefinition.size() > 0, 'The response is empty');
        }

    }

    @IsTest
    private static void getObjectNameTest() {
        System.runAs(TestUtilities.getRunAsUser()) {
            //Setup
            copado__User_Story__c userStory = [SELECT Id FROM copado__User_Story__C WHERE copado__User_Story_Title__c = 'Ctrl'];

            //Exercise
            Test.startTest();
            String objectName = CustomHighlightPanelController.getObjectPluralName(userStory.Id);
            Test.stopTest();

            // Verify
            System.assertEquals(objectName, 'User Stories', 'The object name matches');
        }
    }

    @IsTest
    private static void getRecordTypeNameTest() {
        System.runAs(TestUtilities.getRunAsUser()) {
            //Setup
            String exceptionMessage;
            String recordName;
            copado__User_Story__c userStory = [SELECT Id FROM copado__User_Story__C WHERE copado__User_Story_Title__c = 'Ctrl'];

            //Exercise
            try {
                Test.startTest();
                recordName = CustomHighlightPanelController.getRecordTypeName(userStory.Id);
                Test.stopTest();
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // Verify
            System.assertEquals(null, exceptionMessage, 'The exception messages match');
            System.assert(String.isNotBlank(recordName), 'The record type name is not blank');
        }
    }

    // HELPER

    private static void createData() {
        Id recordTypeId = Schema.SObjectType.copado__User_Story__c.getRecordTypeInfosByName().get('User Story').getRecordTypeId();
        copado__User_Story__c userStory = new copado__User_Story__c(copado__User_Story_Title__c = 'Ctrl', RecordTypeId = recordTypeId);
        insert userStory;
    }
}