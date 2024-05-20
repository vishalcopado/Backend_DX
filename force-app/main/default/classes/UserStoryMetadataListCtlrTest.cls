@IsTest
private class UserStoryMetadataListCtlrTest {
    private final static String METADATA = 'Metadata';
    private final static String VLOCITY = 'Vlocity.json';
    private final static Boolean VLOCITY_ENABLED = true;
    private final static Boolean VLOCITY_DISABLED = false;
    private final static List<String> ONLY_METADATA = new List<String>{ 'Metadata' };
    private final static List<String> METADATA_AND_VLOCITY = new List<String>{ 'Metadata', 'Vlocity.json' };

    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void getMetadataAndVlocityFilesFailure() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id credentialId = null;
            Exception exceptionMessage;

            // EXERCISE

            Test.startTest();
            try {
                UserStoryMetadataListCtlr.getMetadataAndVlocityFiles(credentialId, ONLY_METADATA, VLOCITY_DISABLED, true);
            } catch (Exception ex) {
                exceptionMessage = ex;
            }
            Test.stopTest();

            // VERIFY

            System.assert(
                exceptionMessage.getMessage().contains(Label.Credential_Not_Found),
                'The exception message should be ' + Label.Credential_Not_Found
            );
        }
    }

    @IsTest
    private static void onlyVlocityPresentSuccessful() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id credentialId = getCredentialId();
            List<UserStoryMetadataListCtlr.Response> responses = new List<UserStoryMetadataListCtlr.Response>();
            List<Id> files = new List<Id>(createVlocityFiles(1));

            // EXERCISE

            Test.startTest();
            deleteAttachment();
            responses = UserStoryMetadataListCtlr.getMetadataAndVlocityFiles(credentialId, METADATA_AND_VLOCITY, VLOCITY_ENABLED, true);
            Test.stopTest();

            // VERIFY

            System.assertEquals(true, responses[0].isSuccess, 'The success parameter should return true');
            System.assertEquals(files[0], responses[0].recordId, 'The record id parameter should match vlocity file');
        }
    }

    @IsTest
    private static void onlyAttachmentPresentSuccessful() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id credentialId = getCredentialId();
            List<UserStoryMetadataListCtlr.Response> responses = new List<UserStoryMetadataListCtlr.Response>();

            // EXERCISE

            Test.startTest();

            responses = UserStoryMetadataListCtlr.getMetadataAndVlocityFiles(credentialId, METADATA_AND_VLOCITY, VLOCITY_ENABLED, true);
            Test.stopTest();

            // VERIFY

            System.assertEquals(true, responses[0].isSuccess, 'The success parameter should return true');
            System.assertEquals(getContentVersionId(METADATA), responses[0].recordId, 'The record id parameter should be blank');
        }
    }

    @IsTest
    private static void bothAttachmentAndVlocityAbsentSuccessful() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id credentialId = getCredentialId();
            List<UserStoryMetadataListCtlr.Response> responses = new List<UserStoryMetadataListCtlr.Response>();

            // EXERCISE

            Test.startTest();
            deleteAttachment();
            responses = UserStoryMetadataListCtlr.getMetadataAndVlocityFiles(credentialId, METADATA_AND_VLOCITY, VLOCITY_ENABLED, true);
            Test.stopTest();

            // VERIFY

            System.assertEquals(true, responses[0].isSuccess, 'The success parameter should return true');
            System.assert(String.isBlank(responses[0].recordId), 'The record id parameter should be blank');
        }
    }

    @IsTest
    private static void bothAttachmentAndVlocityPresentSuccessful() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id credentialId = getCredentialId();
            List<UserStoryMetadataListCtlr.Response> responses = new List<UserStoryMetadataListCtlr.Response>();
            List<Id> files = new List<Id>(createVlocityFiles(1));

            // EXERCISE

            Test.startTest();
            responses = UserStoryMetadataListCtlr.getMetadataAndVlocityFiles(credentialId, METADATA_AND_VLOCITY, VLOCITY_ENABLED, true);
            Test.stopTest();

            // VERIFY

            System.assertEquals(true, responses[0].isSuccess, 'The success parameter should return true');
            System.assertEquals(getContentVersionId(METADATA), responses[0].recordId, 'The record id should match');
            System.assertEquals(true, responses[1].isSuccess, 'The success parameter should return true');
            System.assertEquals(files[0], responses[1].recordId, 'The record id should match vlocity file');
        }
    }

    @IsTest
    private static void createFileFromUpdatedAttachmentSuccessful() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id credentialId = getCredentialId();
            List<UserStoryMetadataListCtlr.Response> oldResponses = new List<UserStoryMetadataListCtlr.Response>();
            List<UserStoryMetadataListCtlr.Response> newResponses = new List<UserStoryMetadataListCtlr.Response>();

            // EXERCISE

            Test.startTest();
            oldResponses = UserStoryMetadataListCtlr.getMetadataAndVlocityFiles(credentialId, ONLY_METADATA, VLOCITY_DISABLED, true);
            updateAttachment();
            TestUtilities.delay(1);
            newResponses = UserStoryMetadataListCtlr.getMetadataAndVlocityFiles(credentialId, ONLY_METADATA, VLOCITY_DISABLED, true);
            Test.stopTest();

            // VERIFY

            System.assertEquals(true, oldResponses[0].isSuccess, 'The success parameter should return true');
            System.assertNotEquals(getContentVersionId(METADATA), oldResponses[0].recordId, 'The record id should not match');
            System.assertEquals(true, newResponses[0].isSuccess, 'The success parameter should return true');
            System.assertEquals(getContentVersionId(METADATA), newResponses[0].recordId, 'The record id should match');
        }
    }

    @IsTest
    private static void createFileFromSameAttachmentSuccessful() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id credentialId = getCredentialId();
            List<UserStoryMetadataListCtlr.Response> oldResponses = new List<UserStoryMetadataListCtlr.Response>();
            List<UserStoryMetadataListCtlr.Response> newResponses = new List<UserStoryMetadataListCtlr.Response>();

            // EXERCISE

            Test.startTest();
            oldResponses = UserStoryMetadataListCtlr.getMetadataAndVlocityFiles(credentialId, ONLY_METADATA, VLOCITY_DISABLED, true);
            newResponses = UserStoryMetadataListCtlr.getMetadataAndVlocityFiles(credentialId, ONLY_METADATA, VLOCITY_DISABLED, true);
            Test.stopTest();

            // VERIFY

            System.assertEquals(true, oldResponses[0].isSuccess, 'The success parameter should return true');
            System.assertEquals(getContentVersionId(METADATA), oldResponses[0].recordId, 'The record id should match');
            System.assertEquals(true, newResponses[0].isSuccess, 'The success parameter should return true');
            System.assertEquals(getContentVersionId(METADATA), newResponses[0].recordId, 'The record id should match');
        }
    }

    @IsTest
    private static void executeDeletedMetadataFunctionWithSingleMetadataFile() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id credentialId = getCredentialId();
            createContentVersion(
                UserStoryMetadataListCtlr.METADATA_FILE,
                UserStoryMetadataListCtlr.METADATA_FILE + '.json',
                credentialId,
                getMetaDataFileContent(2)
            );

            // EXERCISE

            UserStoryMetadataListCtlr.mockResult = getResult();
            copado__Result__c result = UserStoryMetadataListCtlr.executeFunctionToFindDeletedMetadata(credentialId);

            // VERIFY

            Assert.isNull(result, 'There should be no result record present');
        }
    }

    @IsTest
    private static void executeDeletedMetadataFunctionWithMultipleFiles() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id credentialId = getCredentialId();
            createContentVersion(
                UserStoryMetadataListCtlr.METADATA_FILE,
                UserStoryMetadataListCtlr.METADATA_FILE + '.json',
                credentialId,
                getMetaDataFileContent(2)
            );
            createContentVersion(
                UserStoryMetadataListCtlr.METADATA_FILE,
                UserStoryMetadataListCtlr.METADATA_FILE + '.json',
                credentialId,
                getMetaDataFileContent(4)
            );
            createContentVersion(
                UserStoryMetadataListCtlr.DELETED_METADATA_FILE,
                UserStoryMetadataListCtlr.DELETED_METADATA_FILE + '.json',
                credentialId,
                getDeletedMetaDataFileContent(2)
            );

            // EXERCISE

            UserStoryMetadataListCtlr.mockResult = getResult();
            copado__Result__c result = UserStoryMetadataListCtlr.executeFunctionToFindDeletedMetadata(credentialId);

            // VERIFY

            Assert.areEqual(getResult().Id, result.Id, 'The result record is incorrect');
        }
    }

    private static void createData() {
        Credential credential = new Credential(new Environment().platform('SFDX').type('Production/Developer')).type('Production/Developer');
        new UserStory().title('US 1').status('Draft').credential(credential);
        Blob data = getMetadataItem('ApexClass', 'SampleClass', 'Test Test', '1900-01-01');
        Function createDeletedMetadata = new Function()
            .name('SFDX Create Deleted Metadata')
            .apiName(UserStoryMetadataListCtlr.SFDX_CREATE_DELETED_METADATA);
        new Result().type('Function').setContext(credential).status('Success').function(createDeletedMetadata);
        new Attachment_t().name(METADATA).body(data).parent(credential).persist();
    }

    private static Set<Id> createVlocityFiles(Integer numberOfFiles) {
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        while (numberOfFiles > 0) {
            contentVersions.add(new contentVersion(PathOnClient = VLOCITY, Title = VLOCITY, versiondata = Blob.valueOf(getVlocityContent())));
            numberOfFiles--;
        }
        insert contentVersions;

        Set<Id> contentVersionIds = getContentVersionIds(contentVersions);
        List<ContentDocumentLink> documentLinks = new List<ContentDocumentLink>();
        for (ContentVersion recordId : new ContentVersionsSelector().byIdsAndTitles(contentVersionIds, new Set<String>{ VLOCITY })) {
            documentLinks.add(
                new ContentDocumentLink(ContentDocumentId = recordId.ContentDocumentId, LinkedEntityId = getCredentialId(), ShareType = 'V')
            );
        }
        insert documentLinks;

        return contentVersionIds;
    }

    private static Set<Id> getContentVersionIds(List<SObject> contentVersions) {
        Set<Id> result = new Set<Id>();
        for (SObject version : contentVersions) {
            result.add(version.Id);
        }

        return result;
    }

    private static String getVlocityContent() {
        List<MetaDataItem> result = new List<MetaDataItem>();
        result.add(TestDataFactory.getMetadataItem('DecisionMatrix', 'Vlocity1', 'Test User', '2023-02-17T10:41:48.000+0000'));
        result.add(TestDataFactory.getMetadataItem('DecisionMatrix', 'Vlocity2', 'Test User', '2023-02-17T10:41:48.000+0000'));
        return JSON.serialize(result);
    }

    private static Id getCredentialId() {
        return [SELECT copado__Org_Credential__c FROM copado__User_Story__c LIMIT 1].copado__Org_Credential__c;
    }

    private static void deleteAttachment() {
        delete [SELECT Id FROM Attachment WHERE Name = :METADATA LIMIT 1];
    }

    private static void updateAttachment() {
        Attachment attachment = [SELECT Id FROM Attachment WHERE Name = :METADATA LIMIT 1];
        Blob data = getMetadataItem('ApexClass', 'SampleClass', 'Test Test', '1900-01-01');
        new Attachment_t().recordId(attachment.Id).body(data).persist();
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static Blob getMetadataItem(String type, String name, String createdBy, String createdDate) {
        MetaDataItem item = TestDataFactory.getMetadataItem(type, name, createdBy, createdDate);
        List<MetaDataItem> items = new List<MetaDataItem>{ item };
        Blob data = Blob.valueOf(JSON.serialize(items));
        return data;
    }

    private static Id getContentVersionId(String title) {
        return [SELECT Id FROM ContentVersion WHERE Title = :title ORDER BY ContentDocument.CreatedDate DESC][0].Id;
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static void createContentVersion(String title, String pathOnClient, Id firstPublishLocationId, Blob data) {
        new ContentVersion_t().title(title).pathOnClient(pathOnClient).firstPublishLocationId(firstPublishLocationId).versionData(data).persist();
    }

    private static Blob getMetaDataFileContent(Integer count) {
        List<MetaDataItem> metaDataItems = new List<MetaDataItem>();
        for (Integer i = 0; i < count; i++) {
            metaDataItems.add(TestDataFactory.getMetadataItem('ApexClass', 'SampleClass' + 1, 'Test Test', '1900-01-01'));
        }
        return Blob.valueOf(JSON.serialize(metaDataItems));
    }

    private static Blob getDeletedMetaDataFileContent(Integer count) {
        List<MetaDataItem> metaDataItems = new List<MetaDataItem>();
        for (Integer i = 0; i < count; i++) {
            metaDataItems.add(TestDataFactory.getMetadataItem('ApexClass', 'SampleDeletedClass' + 1, 'Test Test', '1900-01-01'));
        }
        return Blob.valueOf(JSON.serialize(metaDataItems));
    }

    private static copado__Result__c getResult() {
        return [SELECT Id, copado__ParentId__c FROM copado__Result__c LIMIT 1];
    }
}