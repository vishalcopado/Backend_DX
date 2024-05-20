@IsTest
private class FieldSetFormCtlrTest {
    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void getObjectAndFieldDetails() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup
            Id promotionId = getPromotionId();
            String namespacePrefix = TestUtilities.getNamespacePrefix();
            namespacePrefix = String.isNotBlank(namespacePrefix) ? namespacePrefix + '__' : namespacePrefix;

            List<String> fields = getFieldsFromFieldSet('copado__Promotion__c', namespacePrefix + 'SFDX_Extension_Fields');

            // Exercise
            Test.startTest();
            Map<String, Object> result = FieldSetFormCtlr.getObjectAndFieldDetails(promotionId, namespacePrefix + 'SFDX_Extension_Fields');
            Test.stopTest();

            // Verify
            System.assertEquals(true, (Boolean) result.get('isSuccess'), 'The success parameter should return true');
            System.assertEquals('copado__Promotion__c', (String) result.get('objectName'), 'The objectName parameter should be copado__Promotion__c');
            List<String> fieldSetFields = (List<String>) result.get('fields');
            for (String field : fields) {
                System.assert(fieldSetFields.contains(field), field + ' should be present in the result');
            }
            System.assertEquals(fields.size(), fieldSetFields.size(), 'There should be ' + fields.size() + ' fields in the result');
        }
    }

    @IsTest
    private static void incorrectNameForFieldset() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup
            Id promotionId = getPromotionId();
            String errorMessage = String.format(Label.NO_FIELD_SET_FOUND, new List<String>{ 'Incorrect_Name' });

            // Exercise
            Test.startTest();
            Map<String, Object> result = FieldSetFormCtlr.getObjectAndFieldDetails(promotionId, 'Incorrect_Name');
            Test.stopTest();

            // Verify
            System.assertEquals(false, (Boolean) result.get('isSuccess'), 'The success parameter should return false');
            System.assertEquals(errorMessage, (String) result.get('message'), 'The message parameter should be "' + errorMessage + '"');
        }
    }

    @IsTest
    private static void incorrectSobject() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup
            Id promotionId = null;
            String errorMessage = String.format(Label.NO_OBJECT_FOUND, new List<String>{ 'null' });

            // Exercise
            Test.startTest();
            Map<String, Object> result = FieldSetFormCtlr.getObjectAndFieldDetails(promotionId, 'SFDX_Extension_Fields');
            Test.stopTest();

            // Verify
            System.assertEquals(false, (Boolean) result.get('isSuccess'), 'The success parameter should return false');
            System.assertEquals(errorMessage, (String) result.get('message'), 'The message parameter should be "' + errorMessage + '"');
        }
    }

    private static Id getPromotionId() {
        return [SELECT Id FROM copado__Promotion__c LIMIT 1].Id;
    }

    private static List<String> getFieldsFromFieldSet(String objectName, String fieldset) {
        List<String> fields = new List<String>();
        for (
            Schema.FieldSetMember fieldSetMember : Schema.getGlobalDescribe()
                .get(objectName)
                .getDescribe()
                .fieldSets.getMap()
                .get(fieldset)
                .getFields()
        ) {
            fields.add(fieldSetMember.getFieldPath());
        }
        return fields;
    }

    private static void createData() {
        Environment sourceEnv = new Environment().platform('SFDX').type('Production/Developer');
        Environment destinationEnv = new Environment().platform('SFDX').type('Production/Developer');

        Credential sourceCred = new Credential(sourceEnv).type('Production/Developer');
        Credential destinationCred = new Credential(destinationEnv).type('Production/Developer');

        Promotion promotion = new Promotion(
            new Project(new Pipeline(new Repository().name('Repo 1')).platform('SFDX')),
            sourceCred,
            sourceEnv,
            destinationCred,
            destinationEnv
        );
        promotion.persist();
    }
}