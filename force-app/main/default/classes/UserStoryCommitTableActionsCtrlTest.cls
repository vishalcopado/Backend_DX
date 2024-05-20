@IsTest
@SuppressWarnings('PMD.CognitiveComplexity')
private with sharing class UserStoryCommitTableActionsCtrlTest {
    @TestSetup
    private static void setup() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void isSourceMemberAvailable() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            copado__Org__c org = [SELECT Id FROM copado__Org__c LIMIT 1];
            updateCredentialValidity(org);

            insert new Attachment(Name = 'MetaData', Body = Blob.valueOf('[{"n": "ExampleTest", "t": "ApexClass"}]'), ParentId = org.Id);

            // EXERCISE
            Test.startTest();
            Boolean isSourceMemberAvailable = UserStoryCommitTableActionsCtrl.isSourceMemberAvailable(org.Id);
            Test.stopTest();

            // VERIFY
            System.assert(isSourceMemberAvailable, 'Source member should be available');
        }
    }

    @IsTest
    private static void throwErrorOnLIsSourceMemberAvailableOnNonValidatedCredential() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String exceptionMessage = '';
            copado__Org__c org = [SELECT Id FROM copado__Org__c LIMIT 1];

            // EXERCISE

            try {
                Test.startTest();
                UserStoryCommitTableActionsCtrl.isSourceMemberAvailable(org.Id);
                Test.stopTest();
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY

            Assert.areEqual(Label.Org_Is_Not_Valid, exceptionMessage, 'Logged In Org should have validated credential.');
        }
    }

    @IsTest
    private static void retrieveRecentChanges() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup
            copado__Org__c org = [SELECT Id FROM copado__Org__c LIMIT 1];

            // Exercise
            Test.startTest();
            List<copado.SourceMemberResult> recentChanges = UserStoryCommitTableActionsCtrl.retrieveRecentChanges(
                org.Id,
                DateTime.newInstance(2021, 2, 6)
            );
            Test.stopTest();

            // Verify
            System.assertEquals(1, recentChanges.size(), 'Recent changes result should match');
        }
    }

    @IsTest
    private static void listAllSobjectsInOrg() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup
            copado__Org__c org = [SELECT Id FROM copado__Org__c LIMIT 1];

            // Exercise
            Test.startTest();
            List<SobjectItem> allSobjects = UserStoryCommitTableActionsCtrl.listAllSobjectsInOrg(org.Id);
            Test.stopTest();

            // Verify
            System.assertEquals(MetadataTypes.supportedMetadataTypes().size(), allSobjects.size(), 'All sObjects result should match');
        }
    }

    @IsTest
    private static void searchMetadata() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup
            copado__Org__c org = [SELECT Id FROM copado__Org__c LIMIT 1];

            // Exercise
            Test.startTest();
            List<MetadataSearchResult> searchMetadata = UserStoryCommitTableActionsCtrl.searchMetadata(org.Id, 'ApexClass', 'test');
            Test.stopTest();

            // Verify
            System.assertEquals('DummyClassForTest', searchMetadata[0].name, 'Metadata Name is not as expected');
            System.assertEquals('ApexClass', searchMetadata[0].type, 'Metadata Type is not as expected');
        }
    }

    @IsTest
    private static void searchMetadataException() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // Setup & Exercise
            String exceptionMessage;
            Test.startTest();
            try {
                UserStoryCommitTableActionsCtrl.searchMetadata('', 'ApexComponent', 'test');
            } catch (Exception e) {
                exceptionMessage = e.getMessage();
            }
            Test.stopTest();

            // Verify
            Assert.isTrue(String.isNotBlank(exceptionMessage), 'Exception should have been thrown');
        }
    }

    @IsTest
    private static void getDeletedMetadatasFromFile() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            copado__Org__c credential = getCredentialByEnvName('Dev env');
            updateCredentialValidity(credential);
            createDeletedMetadata(credential.Id, 'DeletedMetadata.json');

            // EXERCISE

            Test.startTest();
            String deletedMetadata = UserStoryCommitTableActionsCtrl.getDeletedMetadatas(credential.Id, 'DeletedMetadata.json');
            Test.stopTest();

            // VERIFY

            Assert.areEqual(deletedMetadata, '[{"data": "dummy"}]', 'Deleted Metadata data should be retrieved.');
        }
    }

    @IsTest
    private static void getDeletedMetadatasException() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id credentialId = null;
            String exceptionMessage;

            // EXERCISE

            try {
                Test.startTest();
                UserStoryCommitTableActionsCtrl.getDeletedMetadatas(credentialId, 'DeletedMetadata.json');
                Test.stopTest();
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY

            Assert.areEqual(exceptionMessage, Label.Credential_Not_Found, 'Exception should have been thrown');
        }
    }

    @IsTest
    private static void getUserStoryMetadata() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            copado__Org__c credential = getCredentialByEnvName('Dev env');
            UserStory userStory = new UserStory().title('US 1').status('Draft').credential(new Credential().recordId(credential.Id));
            new UserStoryMetadata_t().name('SampleClass').type('ApexClass').action('Add').userStory(userStory);
            new UserStoryMetadata_t().name('SampleApexPage').type('ApexPage').action('Add').userStory(userStory).persist();

            // EXERCISE

            Test.startTest();
            List<copado__User_Story_Metadata__c> usMetadataRecords = UserStoryCommitTableActionsCtrl.getUserStoryMetadata(userStory.Id);
            Test.stopTest();

            // VERIFY

            Assert.areEqual(2, usMetadataRecords.size(), 'User Story Metadata records should be retrieved.');
            Assert.areEqual('SampleClass', usMetadataRecords[0].copado__Metadata_API_Name__c, 'User Story Metadata record Name should be correct');
            Assert.areEqual('ApexClass', usMetadataRecords[0].copado__Type__c, 'User Story Metadata record Type should be correct');
            Assert.areEqual('Add', usMetadataRecords[0].copado__Action__c, 'User Story Metadata record Action should be correct');
            Assert.areEqual('SampleApexPage', usMetadataRecords[1].copado__Metadata_API_Name__c, 'User Story Metadata record Name should be correct');
            Assert.areEqual('ApexPage', usMetadataRecords[1].copado__Type__c, 'User Story Metadata record Type should be correct');
            Assert.areEqual('Add', usMetadataRecords[1].copado__Action__c, 'User Story Metadata record Action should be correct');
        }
    }

    private static void createData() {
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

    private static void createDeletedMetadata(Id credentialId, String fileName) {
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        contentVersions.add(new contentVersion(PathOnClient = fileName, Title = fileName, versiondata = Blob.valueOf('[{"data": "dummy"}]')));
        insert contentVersions;

        Set<Id> contentVersionIds = getContentVersionIds(contentVersions);
        List<ContentDocumentLink> documentLinks = new List<ContentDocumentLink>();
        for (ContentVersion recordId : new ContentVersionsSelector().byIdsAndTitles(contentVersionIds, new Set<String>{ fileName })) {
            documentLinks.add(
                new ContentDocumentLink(ContentDocumentId = recordId.ContentDocumentId, LinkedEntityId = credentialId, ShareType = 'V')
            );
        }
        insert documentLinks;
    }

    private static Set<Id> getContentVersionIds(List<SObject> contentVersions) {
        Set<Id> result = new Set<Id>();
        for (SObject version : contentVersions) {
            result.add(version.Id);
        }

        return result;
    }

    private static copado__Org__c getCredentialByEnvName(String value) {
        return [SELECT Id, copado__Environment__r.Name FROM copado__Org__c WHERE copado__Environment__r.Name = :value LIMIT 1];
    }

    private static void updateCredentialValidity(copado__Org__c org) {
        org.copado__SFDC_Org_ID__c = 'dummy';
        org.copado__Validated_Date__c = System.now();
        update org;
    }
}