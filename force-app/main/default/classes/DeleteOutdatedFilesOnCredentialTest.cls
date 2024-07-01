@IsTest
private class DeleteOutdatedFilesOnCredentialTest {
    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            makeData();
        }
    }

    @IsTest
    private static void executeWithNoFile() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            copado__Function__c function = getFunction();
            copado__Result__c result = getResult();
            copado__Org__c credential = getCredential();
            String status = 'Success';

            // EXERCISE

            new DeleteOutdatedFilesOnCredential().execute(function, result, status);

            // VERIFY

            Assert.areEqual(
                0,
                getContentDocumentLink(credential.Id, DeleteOutdatedFilesOnCredential.METADATA_FILE).size(),
                'No metadata file should be present'
            );
            Assert.areEqual(
                0,
                getContentDocumentLink(credential.Id, DeleteOutdatedFilesOnCredential.DELETED_METADATA_FILE).size(),
                'No deleted metadata file should be present'
            );
        }
    }

    @IsTest
    private static void executeWithMultipleMetadataFile() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            copado__Function__c function = getFunction();
            copado__Result__c result = getResult();
            copado__Org__c credential = getCredential();
            String status = 'Success';
            createContentVersion(
                DeleteOutdatedFilesOnCredential.METADATA_FILE,
                DeleteOutdatedFilesOnCredential.METADATA_FILE + '.json',
                credential.Id,
                getMetaDataFileContent(1)
            );
            createContentVersion(
                DeleteOutdatedFilesOnCredential.METADATA_FILE,
                DeleteOutdatedFilesOnCredential.METADATA_FILE + '.json',
                credential.Id,
                getMetaDataFileContent(2)
            );
            createContentVersion(
                DeleteOutdatedFilesOnCredential.METADATA_FILE,
                DeleteOutdatedFilesOnCredential.METADATA_FILE + '.json',
                credential.Id,
                getMetaDataFileContent(3)
            );

            List<ContentDocumentLink> metaDataFileLinksBeforeExecution = getContentDocumentLink(
                credential.Id,
                DeleteOutdatedFilesOnCredential.METADATA_FILE
            );

            // EXERCISE

            new DeleteOutdatedFilesOnCredential().execute(function, result, status);

            // VERIFY

            List<ContentDocumentLink> metaDataFileLinksAfterExecution = getContentDocumentLink(
                credential.Id,
                DeleteOutdatedFilesOnCredential.METADATA_FILE
            );

            Assert.areEqual(3, metaDataFileLinksBeforeExecution.size(), 'Three metadata files should be present before callback execution');
            Assert.areEqual(1, metaDataFileLinksAfterExecution.size(), 'One metadata file should be present after callback execution');
            Assert.areEqual(
                metaDataFileLinksBeforeExecution[0].Id,
                metaDataFileLinksAfterExecution[0].Id,
                'The callback has deleted incorrect metadata file'
            );
            Assert.areEqual(
                0,
                getContentDocumentLink(credential.Id, DeleteOutdatedFilesOnCredential.DELETED_METADATA_FILE).size(),
                'No deleted metadata file should be present after callback execution'
            );
        }
    }

    @IsTest
    private static void executeWithMultipleDeletedMetadataFile() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            copado__Function__c function = getFunction();
            copado__Result__c result = getResult();
            copado__Org__c credential = getCredential();
            String status = 'Failed';
            createContentVersion(
                DeleteOutdatedFilesOnCredential.DELETED_METADATA_FILE,
                DeleteOutdatedFilesOnCredential.DELETED_METADATA_FILE + '.json',
                credential.Id,
                getDeletedMetaDataFileContent(1)
            );
            createContentVersion(
                DeleteOutdatedFilesOnCredential.DELETED_METADATA_FILE,
                DeleteOutdatedFilesOnCredential.DELETED_METADATA_FILE + '.json',
                credential.Id,
                getDeletedMetaDataFileContent(2)
            );
            createContentVersion(
                DeleteOutdatedFilesOnCredential.DELETED_METADATA_FILE,
                DeleteOutdatedFilesOnCredential.DELETED_METADATA_FILE + '.json',
                credential.Id,
                getDeletedMetaDataFileContent(3)
            );

            List<ContentDocumentLink> deletedMetaDataFileLinksBeforeExecution = getContentDocumentLink(
                credential.Id,
                DeleteOutdatedFilesOnCredential.DELETED_METADATA_FILE
            );

            // EXERCISE

            new DeleteOutdatedFilesOnCredential().execute(function, result, status);

            // VERIFY

            List<ContentDocumentLink> deletedMetaDataFileLinksAfterExecution = getContentDocumentLink(
                credential.Id,
                DeleteOutdatedFilesOnCredential.DELETED_METADATA_FILE
            );

            Assert.areEqual(
                3,
                deletedMetaDataFileLinksBeforeExecution.size(),
                'Three deleted metadata files should be present before callback execution'
            );
            Assert.areEqual(1, deletedMetaDataFileLinksAfterExecution.size(), 'One deleted metadata file should be present after callback execution');
            Assert.areEqual(
                deletedMetaDataFileLinksBeforeExecution[0].Id,
                deletedMetaDataFileLinksAfterExecution[0].Id,
                'The callback has deleted incorrect deleted metadata file'
            );
            Assert.areEqual(
                0,
                getContentDocumentLink(credential.Id, DeleteOutdatedFilesOnCredential.METADATA_FILE).size(),
                'No metadata file should be present after callback execution'
            );
        }
    }

    @IsTest
    private static void executeWithMultipleFiles() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            copado__Function__c function = getFunction();
            copado__Result__c result = getResult();
            copado__Org__c credential = getCredential();
            String status = 'Failed';
            createContentVersion(
                DeleteOutdatedFilesOnCredential.METADATA_FILE,
                DeleteOutdatedFilesOnCredential.METADATA_FILE + '.json',
                credential.Id,
                getMetaDataFileContent(1)
            );
            createContentVersion(
                DeleteOutdatedFilesOnCredential.METADATA_FILE,
                DeleteOutdatedFilesOnCredential.METADATA_FILE + '.json',
                credential.Id,
                getMetaDataFileContent(2)
            );
            createContentVersion(
                DeleteOutdatedFilesOnCredential.DELETED_METADATA_FILE,
                DeleteOutdatedFilesOnCredential.DELETED_METADATA_FILE + '.json',
                credential.Id,
                getDeletedMetaDataFileContent(3)
            );
            createContentVersion(
                DeleteOutdatedFilesOnCredential.DELETED_METADATA_FILE,
                DeleteOutdatedFilesOnCredential.DELETED_METADATA_FILE + '.json',
                credential.Id,
                getDeletedMetaDataFileContent(4)
            );

            List<ContentDocumentLink> metaDataFileLinksBeforeExecution = getContentDocumentLink(
                credential.Id,
                DeleteOutdatedFilesOnCredential.METADATA_FILE
            );

            List<ContentDocumentLink> deletedMetaDataFileLinksBeforeExecution = getContentDocumentLink(
                credential.Id,
                DeleteOutdatedFilesOnCredential.DELETED_METADATA_FILE
            );

            // EXERCISE

            new DeleteOutdatedFilesOnCredential().execute(function, result, status);

            // VERIFY

            List<ContentDocumentLink> metaDataFileLinksAfterExecution = getContentDocumentLink(
                credential.Id,
                DeleteOutdatedFilesOnCredential.METADATA_FILE
            );

            List<ContentDocumentLink> deletedMetaDataFileLinksAfterExecution = getContentDocumentLink(
                credential.Id,
                DeleteOutdatedFilesOnCredential.DELETED_METADATA_FILE
            );

            Assert.areEqual(2, metaDataFileLinksBeforeExecution.size(), 'Two metadata files should be present before callback execution');
            Assert.areEqual(
                2,
                deletedMetaDataFileLinksBeforeExecution.size(),
                'Two deleted metadata files should be present before callback execution'
            );
            Assert.areEqual(1, metaDataFileLinksAfterExecution.size(), 'One metadata file should be present after callback execution');
            Assert.areEqual(1, deletedMetaDataFileLinksAfterExecution.size(), 'One deleted metadata file should be present after callback execution');
            Assert.areEqual(
                metaDataFileLinksBeforeExecution[0].Id,
                metaDataFileLinksAfterExecution[0].Id,
                'The callback has deleted incorrect metadata file'
            );
            Assert.areEqual(
                deletedMetaDataFileLinksBeforeExecution[0].Id,
                deletedMetaDataFileLinksAfterExecution[0].Id,
                'The callback has deleted incorrect deleted metadata file'
            );
        }
    }

    // HELPER

    private static void makeData() {
        Function createDeletedMetadata = new Function().name('SFDX Create Deleted Metadata').apiName('SFDX_Create_Deleted_Metadata');
        Credential devCredential = new Credential().name('dev').type('Production/Developer').type('Production/Developer');
        new Result().type('Function').setContext(devCredential).status('Success').function(createDeletedMetadata).persist();
    }

    private static copado__Org__c getCredential() {
        return [SELECT Id FROM copado__Org__c WHERE Name = 'dev'];
    }

    private static copado__Result__c getResult() {
        return [SELECT Id, copado__ParentId__c FROM copado__Result__c LIMIT 1];
    }

    private static copado__Function__c getFunction() {
        return [SELECT Id FROM copado__Function__c LIMIT 1];
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static void createContentVersion(String title, String pathOnClient, Id firstPublishLocationId, Blob data) {
        new ContentVersion_t().title(title).pathOnClient(pathOnClient).firstPublishLocationId(firstPublishLocationId).versionData(data).persist();
        /* 
            We are introducing a delay of 1 second, so that there is a gap 
            between the creation of multiple files which is needed for this test case.
        */
        TestUtilities.delay(1);
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

    private static List<ContentDocumentLink> getContentDocumentLink(Id linkedEntityId, String title) {
        return [
            SELECT Id
            FROM ContentDocumentLink
            WHERE ContentDocument.Title = :title AND LinkedEntityId = :linkedEntityId
            ORDER BY ContentDocument.CreatedDate DESC
        ];
    }
}