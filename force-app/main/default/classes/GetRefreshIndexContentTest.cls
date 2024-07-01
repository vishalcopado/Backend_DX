@IsTest
private class GetRefreshIndexContentTest {
    private final static String METADATA = 'Metadata';
    private final static String VLOCITY = 'Vlocity.json';
    private final static List<String> ONLY_METADATA = new List<String>{ METADATA };
    private final static List<String> ONLY_VLOCITY = new List<String>{ VLOCITY };
    private final static List<String> METADATA_AND_VLOCITY = new List<String>{ METADATA, VLOCITY };

    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    private static void createData() {
        Credential credential = new Credential(new Environment().platform('SFDX').type('Production/Developer')).type('Production/Developer');
        new UserStory().title('US 1').status('Draft').credential(credential);
        Function createDeletedMetadata = new Function()
            .name('SFDX Create Deleted Metadata')
            .apiName(UserStoryMetadataListCtlr.SFDX_CREATE_DELETED_METADATA);
        new Result().type('Function').setContext(credential).status('Success').function(createDeletedMetadata).persist();
    }


    @IsTest
    private static void throwExceptionOnEmptyCredentialId() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id credentialId = null;
            List<GetRefreshIndexContent.Response> response = new List<GetRefreshIndexContent.Response>();

            // EXERCISE

            Test.startTest();
            response = GetRefreshIndexContent.execute(credentialId, ONLY_METADATA);
            Test.stopTest();

            // VERIFY

            Assert.areEqual(false, response[0].isSuccess, 'The credential Id is null therefore it should return failure.');
            Assert.areEqual(true, response[0].message.contains(Label.Credential_Not_Found), 'The exception message should be ' + Label.Credential_Not_Found);
        }
    }

    @IsTest
    private static void getContentOfVlocityFilePresentInCredentialSuccessfully() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id credentialId = getCredentialId();
            List<GetRefreshIndexContent.Response> responses = new List<GetRefreshIndexContent.Response>();
            List<Id> files = new List<Id>(createFiles(VLOCITY, getVlocityContent(), 1));

            // EXERCISE

            Test.startTest();
            responses = GetRefreshIndexContent.execute(credentialId, ONLY_VLOCITY);
            Test.stopTest();
            // VERIFY

            Assert.areEqual(true, responses[0].isSuccess, 'The success parameter should return true');
            Assert.areEqual(files[0], responses[0].recordId, 'The record id parameter should match vlocity file');
        }
    }

    @IsTest
    private static void getContentOfMetadataFilePresentInCredentialSuccessfully() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id credentialId = getCredentialId();
            List<GetRefreshIndexContent.Response> responses = new List<GetRefreshIndexContent.Response>();
            List<Id> files = new List<Id>(createFiles(METADATA, getMetaDataContent(), 1));

            // EXERCISE

            Test.startTest();
            responses = GetRefreshIndexContent.execute(credentialId, ONLY_METADATA);
            Test.stopTest();
            // VERIFY

            Assert.areEqual(true, responses[0].isSuccess, 'The success parameter should return true');
            Assert.areEqual(files[0], responses[0].recordId, 'The record id parameter should match vlocity file');
        }
    }

    @IsTest
    private static void getContentOfLatestVlocityFileAndDeleteRestSuccessfully() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id credentialId = getCredentialId();
            List<GetRefreshIndexContent.Response> responses = new List<GetRefreshIndexContent.Response>();
            List<Id> files = new List<Id>(createFiles(VLOCITY, getVlocityContent(), 3));

            // EXERCISE

            Test.startTest();
            responses = GetRefreshIndexContent.execute(credentialId, ONLY_VLOCITY);
            Test.stopTest();

            // VERIFY

            Assert.areEqual(1, responses.size(), 'Method should return only latest version of Vlocity file.');
            Assert.areEqual(1, getContentVersions(VLOCITY).size(), 'Only one Vlocity file should left while refreshing and rest should be deleted.');
            Assert.areEqual(true, responses[0].isSuccess, 'The success parameter should return true');
            Assert.areEqual(files[0], responses[0].recordId, 'The record id parameter should match vlocity file');
        }
    }

    @IsTest
    private static void bothMetadataAndVlocityFilesAreAbsent() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id credentialId = getCredentialId();
            List<GetRefreshIndexContent.Response> responses = new List<GetRefreshIndexContent.Response>();

            // EXERCISE

            Test.startTest();
            responses = GetRefreshIndexContent.execute(credentialId, METADATA_AND_VLOCITY);
            Test.stopTest();

            // VERIFY

            Assert.areEqual(true, responses[0].isSuccess, 'The success parameter should return true');
            Assert.isTrue(String.isBlank(responses[0].recordId), 'The record id parameter should be blank');
        }
    }

    @IsTest
    private static void bothMetadataAndVlocityFilesArePresent() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id credentialId = getCredentialId();
            List<GetRefreshIndexContent.Response> responses = new List<GetRefreshIndexContent.Response>();
            List<Id> vlocityVersionId = new List<Id>(createFiles(VLOCITY, getVlocityContent(), 2));
            List<Id> metadataVersonId = new List<Id>(createFiles(METADATA, getMetadataContent(), 2));

            // EXERCISE

            Test.startTest();
            responses = GetRefreshIndexContent.execute(credentialId, METADATA_AND_VLOCITY);
            Test.stopTest();

            // VERIFY

            Assert.areEqual(2, responses.size(), 'Method should return only latest version of both files.');
            
            for(GetRefreshIndexContent.Response response: responses) {
                if(response.fileName == METADATA) {
                    Assert.areEqual(true, response.isSuccess, 'The success parameter should return true');
                    Assert.areEqual(METADATA, response.fileName, 'The fileName should return Metadata');
                    Assert.areEqual(metadataVersonId[0], response.recordId, 'The record id should match metadata file');
                } else {
                    Assert.areEqual(true, response.isSuccess, 'The success parameter should return true');
                    Assert.areEqual(vlocityVersionId[0], response.recordId, 'The record id should match vlocity file');
                    Assert.areEqual(VLOCITY, response.fileName, 'The fileName should return Metadata');
                } 
            }
        }
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static Blob getMetadataItem(String type, String name, String createdBy, String createdDate) {
        MetaDataItem item = TestDataFactory.getMetadataItem(type, name, createdBy, createdDate);
        List<MetaDataItem> items = new List<MetaDataItem>{ item };
        Blob data = Blob.valueOf(JSON.serialize(items));
        return data;
    }

    private static Set<Id> createFiles(String fileName, String content, Integer numberOfFiles) {
        for (Integer fileNumber = 1; fileNumber <= numberOfFiles; fileNumber++) {
            createContentVersion(fileName, fileNumber, content);
            /* 
                We are introducing a delay of 1 second, so that there is a gap 
                between the creation of multiple files which is needed for this test case.
            */
            TestUtilities.delay(1);
        }

        Set<Id> contentVersionIds = getContentVersionIds(getContentVersions(fileName));
        List<ContentDocumentLink> documentLinks = new List<ContentDocumentLink>();
        for (ContentVersion recordId : new ContentVersionsSelector().byIdsAndTitles(contentVersionIds, new Set<String>{ fileName })) {
            documentLinks.add(
                new ContentDocumentLink(ContentDocumentId = recordId.ContentDocumentId, LinkedEntityId = getCredentialId(), ShareType = 'V')
            );
        }
        insert documentLinks;

        return contentVersionIds;
    }

    private static void createContentVersion(String fileName, Integer fileNumber, String content) {
        insert new contentVersion(PathOnClient = fileName, Title = fileName, versiondata = Blob.valueOf(content.replace('$1', String.valueOf(fileNumber))));
    }

    private static Set<Id> getContentVersionIds(List<SObject> contentVersions) {
        Set<Id> result = new Set<Id>();
        for (SObject version : contentVersions) {
            result.add(version.Id);
        }

        return result;
    }

    private static Id getCredentialId() {
        return [SELECT copado__Org_Credential__c FROM copado__User_Story__c LIMIT 1].copado__Org_Credential__c;
    }

    private static String getVlocityContent() {
        List<MetaDataItem> result = new List<MetaDataItem>();
        result.add(TestDataFactory.getMetadataItem('DecisionMatrix', 'DM_$1', 'Test User', '2023-02-17T10:41:48.000+0000'));
        result.add(TestDataFactory.getMetadataItem('IntegrationProcedure', 'IP_$1', 'Test User', '2023-02-17T10:41:48.000+0000'));
        return JSON.serialize(result);
    }

    private static String getMetadataContent() {
        List<MetaDataItem> result = new List<MetaDataItem>();
        result.add(TestDataFactory.getMetadataItem('ApexClass', 'Test_Class_$1', 'Test User', '2023-02-17T10:41:48.000+0000'));
        result.add(TestDataFactory.getMetadataItem('ApexPage', 'Test_Page_$1', 'Test User', '2023-02-17T10:41:48.000+0000'));
        return JSON.serialize(result);
    }

    private static List<ContentVersion> getContentVersions(String title) {
        return [SELECT Id, VersionData FROM ContentVersion WHERE Title = :title ORDER BY ContentDocument.CreatedDate DESC];
    }
}