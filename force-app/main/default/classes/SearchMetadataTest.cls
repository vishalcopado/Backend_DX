@IsTest
private with sharing class SearchMetadataTest {
    @TestSetup
    private static void setup() {
        copado__Environment__c env = new copado__Environment__c();
        env.Name = 'Dev env';
        env.copado__Index_Back_Promotion_metadata__c = true;
        env.copado__Type__c = 'Production/Developer';
        insert env;

        copado__Org__c org = new copado__Org__c();
        org.Name = 'Uat2';
        org.copado__Org_Type__c = 'Production/Developer';
        org.copado__Oauth_Signature__c = 'signature';
        org.copado__Username__c = 'testusername@test.com';
        org.copado__Environment__c = env.Id;

        insert org;
    }

    @IsTest
    private static void searchMetadataTypeErrorResponse() {
        // Bad Request
        try {
            searchMetadataByType('ApexComponent', 'test');
        } catch (Exception ex) {
            // Verify
            System.assertEquals(ex.getMessage(), 'ApexComponent with name test is not available', 'Wrong error response');
        }
    }

    @IsTest
    private static void searchMetadataTypeApex() {
        // DEFAULT_FIELDS & NAME_FIELD_TYPES
        List<MetadataSearchResult> tableRows = searchMetadataByType('ApexClass', 'test');
        // Verify
        System.assertEquals('DummyClassForTest', tableRows[0].name, 'Metadata Name is not as expected');
        System.assertEquals('ApexClass', tableRows[0].type, 'Metadata Type is not as expected');
    }

    @IsTest
    private static void searchMetadataTypeCustomField() {
        // FIELD_DEVELOPER_NAME & ENTITY_FIELD_TYPES
        List<MetadataSearchResult> tableRows = searchMetadataByType('CustomField', 'test');
        // Verify
        System.assertEquals('copado__User_Story__c.Test_Field__c', tableRows[0].name, 'Metadata Name is not as expected');
        System.assertEquals('CustomField', tableRows[0].type, 'Metadata Type is not as expected');
    }

    @IsTest
    private static void searchMetadataTypeLayout() {
        // NAME_FIELD_TYPES & ENTITY_FIELD_TYPES
        List<MetadataSearchResult> tableRows = searchMetadataByType('Layout', 'test');
        // Verify
        System.assertEquals('copado__User_Story__c-copado__Test Layout', tableRows[0].name, 'Metadata Name is not as expected');
        System.assertEquals('Layout', tableRows[0].type, 'Metadata Type is not as expected');
    }

    @IsTest
    private static void searchMetadataTypeValidationRule() {
        // FIELD_VALIDATION_NAME & ENTITY_FIELD_TYPES
        List<MetadataSearchResult> tableRows = searchMetadataByType('ValidationRule', 'test');
        // Verify
        System.assertEquals('copado__User_Story__c.copado__Test_Validation_Rule', tableRows[0].name, 'Metadata Name is not as expected');
        System.assertEquals('ValidationRule', tableRows[0].type, 'Metadata Type is not as expected');
    }

    @IsTest
    private static void searchMetadataTypeFlow() {
        // NO_NAMESPACE_FIELD_TYPES & DEFINITION_FIELD_TYPES & CONDITIONAL_QUERY_TYPES
        List<MetadataSearchResult> tableRows = searchMetadataByType('Flow', 'test');
        // Verify
        System.assertEquals('copado__User_Story_Test_Flow', tableRows[0].name, 'Metadata Name is not as expected');
        System.assertEquals('Flow', tableRows[0].type, 'Metadata Type is not as expected');
    }

    @IsTest
    private static void searchMetadataTypeProfile() {
        // NO_NAMESPACE_FIELD_TYPES & NAME_FIELD_TYPES
        List<MetadataSearchResult> tableRows = searchMetadataByType('Profile', 'Test');
        // Verify
        System.assertEquals('Standard Test Profile', tableRows[0].name, 'Metadata Name is not as expected');
        System.assertEquals('Profile', tableRows[0].type, 'Metadata Type is not as expected');
    }

    @IsTest
    private static void searchMetadataTypeCustomObject() {
        // NO_CREATED_FIELDS_TYPES & TOOLING_API_TYPES_BY_METADATA_API_TYPE
        List<MetadataSearchResult> tableRows = searchMetadataByType('CustomObject', 'test');
        // Verify
        System.assertEquals('copado__User_Story_Test__c', tableRows[0].name, 'Metadata Name is not as expected');
        System.assertEquals('CustomObject', tableRows[0].type, 'Metadata Type is not as expected');
    }

    @IsTest
    private static void searchMetadataTypeFlexiPage() {
        // NO_OWNER_TYPES
        List<MetadataSearchResult> tableRows = searchMetadataByType('FlexiPage', 'test');
        // Verify
        System.assertEquals('copado__User_Story_Test_Record_Page', tableRows[0].name, 'Metadata Name is not as expected');
        System.assertEquals('FlexiPage', tableRows[0].type, 'Metadata Type is not as expected');
    }

    @IsTest
    private static void searchMetadataTypePermissionSet() {
        // NAME_FIELD_TYPES & CONDITIONAL_QUERY_TYPES
        List<MetadataSearchResult> tableRows = searchMetadataByType('PermissionSet', 'test');
        // Verify
        System.assertEquals('copado__Test_Suite', tableRows[0].name, 'Metadata Name is not as expected');
        System.assertEquals('PermissionSet', tableRows[0].type, 'Metadata Type is not as expected');
    }

    @IsTest
    private static void searchMetadataTypeCompactLayout() {
        // FULL NAME TO DISPLAY & DEVELOPER NAME TO FILTER
        List<MetadataSearchResult> tableRows = searchMetadataByType('CompactLayout', 'test');
        // Verify
        System.assertEquals('copado__User_Story__c.TestHighlightPanel', tableRows[0].name, 'Metadata Name is not as expected');
        System.assertEquals('CompactLayout', tableRows[0].type, 'Metadata Type is not as expected');
    }

    @IsTest
    private static void searchMetadataTypeExternalServiceRegistration() {
        // MasterLabel
        List<MetadataSearchResult> tableRows = searchMetadataByType('ExternalServiceRegistration', 'test');
        // Verify
        System.assertEquals('copado__Test_Service', tableRows[0].name, 'Metadata Name is not as expected');
        System.assertEquals('ExternalServiceRegistration', tableRows[0].type, 'Metadata Type is not as expected');
    }

    @IsTest
    private static void searchMetadataTypeCertificate() {
        // MasterLabel
        List<MetadataSearchResult> tableRows = searchMetadataByType('Certificate', 'test');
        // Verify
        System.assertEquals('Test_Certificate', tableRows[0].name, 'Metadata Name is not as expected');
        System.assertEquals('Certificate', tableRows[0].type, 'Metadata Type is not as expected');
    }

    @IsTest
    private static void searchMetadataTypeCustomTab() {
        List<MetadataSearchResult> tableRows = searchMetadataByType('CustomTab', '');
        // Verify
        System.assertEquals('App_Page_for_Api_Adapters', tableRows[0].name, 'Metadata Name is as expected');
        System.assertEquals('CustomTab', tableRows[0].type, 'Metadata Type is as expected');
    }

    private static List<MetadataSearchResult> searchMetadataByType(String type, String searchTerm) {
        // Setup
        copado__Org__c org = [SELECT Id FROM copado__Org__c LIMIT 1];

        // Exercise
        Test.startTest();
        List<MetadataSearchResult> searchMetadata = new SearchMetadata(org.Id, type, searchTerm).execute();
        Test.stopTest();

        // Verify
        System.assert(searchMetadata.size() > 0, 'Search metadata result should be non-empty');
        return searchMetadata;
    }
}