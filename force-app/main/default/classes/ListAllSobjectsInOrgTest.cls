@IsTest
private with sharing class ListAllSobjectsInOrgTest {
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
    private static void listAllSobjectsInOrg() {
        // Setup
        copado__Org__c org = [SELECT Id FROM copado__Org__c LIMIT 1];

        String fixedResponse =
            '{' +
                '"statusCode" : 200,' +
                '"content" : "{' +
                    '\\"sobjects\\" : [' +
                        '{' +
                            '\\"Name\\": \\"ApexClass\\"' +
                        '}' +
                    ']' +
                '}"' +
            '}';

        MockHttpResponseGenerator mockResponse = new MockHttpResponseGenerator(200, 'Complete', fixedResponse, null);
        Test.setMock(HttpCalloutMock.class, mockResponse);

        // Exercise
        Test.startTest();
        List<SobjectItem> allSobjects = new ListAllSobjectsInOrg(org.Id).execute();
        Test.stopTest();

        // Verify
        String content = (String) ((Map<String, Object>) JSON.deserializeUntyped(fixedResponse)).get('content');
        List<Object> expectedRecords = (List<Object>) ((Map<String, Object>) JSON.deserializeUntyped(content)).get('sobjects');
        System.assertEquals(expectedRecords.size(), allSobjects.size(), 'All sObjects result should match');
    }

}