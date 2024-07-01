@IsTest
private class CredentialListViewTest {    
    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
    }

    @IsTest
    private static void getListViewOfCredentailsSuccessfully() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            TestUtilities.createCredential(false);
            TestUtilities.createCredential(false).persist();

            // EXERCISE

            Test.startTest();
            List<ListView> listViews = CredentialListView.getSobjectListviews('copado__Org__c');
            Test.stopTest();

            // VERIFY

            Assert.isTrue(hasListView(listViews, 'All'), 'Credentials List View should have list view named All');
        }
    }

    @IsTest
    private static void getRecordsOfSObjectsSuccessfully() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            TestUtilities.createCredential(false).name('Test').persist();
            String query = 'SELECT Name, Id, CreatedDate, LastModifiedDate, SystemModstamp FROM copado__Org__c';

            // EXERCISE

            Test.startTest();
            List<copado__Org__c> result = CredentialListView.getRecords(query);
            Test.stopTest();

            // VERIFY

            Assert.isTrue(hasCredential(result, 'Test'), 'Credentials should be present.');
        }
    }

    @IsTest
    private static void getListViewRecordsSuccessfully() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            TestUtilities.createCredential(false).sfdcOrgId(UserInfo.getOrganizationId() + '_' + UserInfo.getUserId()).oauthSignature('signature').validatedDate(System.now()).persist();

            String query = 'SELECT Name, copado__Platform__c, toLabel(copado__Org_Type__c), copado__Username__c, copado__SFDC_Org_ID__c, toLabel(copado__Test_Frequency__c), copado__Validated_Date__c, copado__Validated_Status__c, CreatedBy.Name, toLabel(copado__Last_Git_Backup_Status__c), toLabel(copado__Last_Apex_Tests_Status__c), Id, CreatedDate, LastModifiedDate, SystemModstamp, CreatedBy.Id, CreatedById FROM copado__Org__c ORDER BY copado__Platform__c DESC NULLS LAST, Id ASC NULLS FIRST';
            List<ListView> listViews = CredentialListView.getSobjectListviews('copado__Org__c');

            String listViewId = listViews[0].Id;
            CredentialListView.mockResponse = new ProxyOrgResponse(200, '{"columns":[{"ascendingLabel":"Z-A","descendingLabel":"A-Z","fieldNameOrPath":"Name","hidden":false,"label":"Credential Name","searchable":true,"selectListItem":"Name","sortable":true,"type":"string"}],"id":"00B7Q00000FCYTe","orderBy":[{"fieldNameOrPath":"copado__Platform__c","nullsPosition":"last","sortDirection":"descending"},{"fieldNameOrPath":"Id","nullsPosition":"first","sortDirection":"ascending"}],"query":"'+ query +'","scope":"everything","sobjectType":"copado__Org__c","whereCondition":{"conditions":[],"conjunction":"and"}}', null, null).getResponse();

            // EXERCISE

            Test.startTest();
            String result = CredentialListView.getListViewRecords(listViewId);
            Test.stopTest();

            // VERIFY
            Map<String, Object> res = (Map<String, Object>) JSON.deserializeUntyped(result);
            Assert.areEqual(query, res.get('query'), 'Http callout to describe list View should be done.');
        }
    }

    @IsTest
    private static void throwErrorOnGetiingRecordsByIncorrectQuery() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String query = 'Select Id From dummy';
            String exceptionMessage = '';

            // EXERCISE
            try{
                Test.startTest();
                CredentialListView.getRecords(query);
                Test.stopTest();
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY

            Assert.isNotNull(exceptionMessage, 'Exception of unsupported sobject type' );
        }
    }

    @IsTest
    private static void throwErrorOnGetingListViewRecords() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            TestUtilities.createCredential(false).persist();
            List<ListView> listViews = CredentialListView.getSobjectListviews('copado__Org__c');
            String listViewId = listViews[0].Id;

            CredentialListView.mockResponse = new ProxyOrgResponse(200, '', '', null).getResponse();
            String exceptionMessage = '';

            // EXERCISE
            try{
                Test.startTest();
                CredentialListView.getListViewRecords(listViewId);
                Test.stopTest();
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY
            Assert.areEqual(Label.Credential_Not_Found, exceptionMessage, 'Exception of non validated credential.' );
        }
    }

    @IsTest
    private static void throwErrorOnHttpCalloutToGetListViewRecords() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            String errorMessage = 'Test Error Message';
            TestUtilities.createCredential(false).sfdcOrgId(UserInfo.getOrganizationId() + '_' + UserInfo.getUserId()).oauthSignature('signature').validatedDate(System.now()).persist();
            List<ListView> listViews = CredentialListView.getSobjectListviews('copado__Org__c');
            String listViewId = listViews[0].Id;

            CredentialListView.mockResponse = new ProxyOrgResponse(500, '', '', errorMessage).getResponse();
            String exceptionMessage = '';

            // EXERCISE
            try{
                Test.startTest();
                CredentialListView.getListViewRecords(listViewId);
                Test.stopTest();
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY
            Assert.areEqual(errorMessage, exceptionMessage, 'Exception from HTTP callout to get list view.' );
        }
    }

    @IsTest
    private static void throwErrorOnLoggedInNonValidatedCredential() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            TestUtilities.createCredential(false).sfdcOrgId(UserInfo.getOrganizationId() + '_' + UserInfo.getUserId()).persist();
            List<ListView> listViews = CredentialListView.getSobjectListviews('copado__Org__c');
            String listViewId = listViews[0].Id;
            String exceptionMessage = '';

            // EXERCISE
            try{
                Test.startTest();
                CredentialListView.getListViewRecords(listViewId);
                Test.stopTest();
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY
            Assert.areEqual(Label.Org_Is_Not_Valid, exceptionMessage, 'Logged In Org should have validated credential.' );
        }
    }

    private static boolean hasCredential(List<copado__Org__c> credentials, String credName) {
        Boolean result = false;
        for(copado__Org__c cred : credentials) {
            if(cred.Name == credName) {
                result = true;
                break;
            }
        }
        return result;
    }

    private static boolean hasListView(List<ListView> listViews, String name) {
        Boolean result = false;
        for(ListView view : listViews) {
            if(view.DeveloperName == name) {
                result = true;
                break;
            }
        }
        return result;
    }

}