@IsTest
private with sharing class SourceMemberTest {
    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            makeData();
        }
    }

    @IsTest
    private static void testGetItemsFromSourceMember() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            SourceMember.mockResponse = getProxyOrgResponse(200, getSourceMemberItemsResponse(), '', '');
            Id orgCredentialId = getOrgCredentialId('Scratch Org');
            String memberName = '';
            String memberType = 'Test';
            String changedDateTimeFilter = '2024-01-01T09:58:00.000Z';
            String changedBy = 'User';

            // EXERCISE

            List<SourceMemberResult> response = SourceMember.getItems(orgCredentialId, memberName, memberType, changedDateTimeFilter, changedBy);

            // VERIFY

            Assert.areEqual(2, response.size(), 'The number of source member items is incorrect');
            Assert.areEqual('testprofile', response.get(0).MemberName, 'The MemberName of source member item is incorrect');
            Assert.areEqual('Profile', response.get(0).MemberType, 'The MemberType of source member item is incorrect');
            Assert.areEqual(
                'Test__c-Testテスáćト日本語áć%21%40%23%24%25%5E%26*%28%29_%2B-%3D%7B%7D%5B%5D%7C%3A%3B%3C%3E%2C.%3F%2F',
                response.get(1).MemberName,
                'The MemberName of source member item is incorrect'
            );
            Assert.areEqual('Layout', response.get(1).MemberType, 'The MemberType of source member item is incorrect');
        }
    }

    @IsTest
    private static void getDeletedMetadataItems() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            SourceMember.mockResponse = getProxyOrgResponse(200, getDeletedSourceMemberItemsResponse(), '', '');
            Id orgCredentialId = getOrgCredentialId('Scratch Org');

            // EXERCISE

            List<SourceMemberResult> response = SourceMember.getDeletedItems(orgCredentialId);

            // VERIFY

            Assert.areEqual(2, response.size(), 'The number of source member items is incorrect');
            Assert.areEqual('testpage', response.get(0).MemberName, 'The MemberName of source member item is incorrect');
            Assert.areEqual('ApexPage', response.get(0).MemberType, 'The MemberType of source member item is incorrect');
            Assert.areEqual(
                'Test__c-Testテスáćト日本語áć%21%40%23%24%25%5E%26*%28%29_%2B-%3D%7B%7D%5B%5D%7C%3A%3B%3C%3E%2C.%3F%2F',
                response.get(1).MemberName,
                'The MemberName of source member item is incorrect'
            );
            Assert.areEqual('Layout', response.get(1).MemberType, 'The MemberType of source member item is incorrect');
        }
    }

    @IsTest
    private static void getDeletedMetadataItemsFailure() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            String errorMessage = 'Error executing source member query';
            String exceptionMessage;
            SourceMember.mockResponse = getProxyOrgResponse(500, '', '', errorMessage);
            Id orgCredentialId = getOrgCredentialId('Scratch Org');

            // EXERCISE

            try {
                SourceMember.getDeletedItems(orgCredentialId);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY

            Assert.areEqual(errorMessage, exceptionMessage, 'The exceptionMessage is incorrect');
        }
    }

    private static String getSourceMemberItemsResponse() {
        SourceMember.SourceMemberQueryResult result = new SourceMember.SourceMemberQueryResult();
        result.records = new List<SourceMemberResult>();
        result.records.add(new SourceMemberResult('testprofile', 'Profile', false));
        result.records.add(new SourceMemberResult('Test__c-Testテスáćト日本語áć!@#$%^&*()_+-={}[]|:;<>,.?/', 'Layout', false));
        return JSON.serialize(result);
    }

    private static String getDeletedSourceMemberItemsResponse() {
        SourceMember.SourceMemberQueryResult result = new SourceMember.SourceMemberQueryResult();
        result.records = new List<SourceMemberResult>();
        result.records.add(new SourceMemberResult('testpage', 'ApexPage', true));
        result.records.add(new SourceMemberResult('Test__c-Testテスáćト日本語áć!@#$%^&*()_+-={}[]|:;<>,.?/', 'Layout', true));
        return JSON.serialize(result);
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static String getProxyOrgResponse(Integer statusCode, String content, String errorCode, String errorMessage) {
        return JSON.serialize(new ProxyOrgResponse(statusCode, content, errorCode, errorMessage));
    }

    private static void makeData() {
        new Credential().type('Scratch Org').type('Scratch Org')?.persist();
        new Credential().type('Production/Developer').type('Production/Developer')?.persist();
    }

    private static Id getOrgCredentialId(String type) {
        return [SELECT Id, copado__Org_Type__c FROM copado__Org__c WHERE copado__Org_Type__c = :type LIMIT 1].Id;
    }
}