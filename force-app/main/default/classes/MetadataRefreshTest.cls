@IsTest
private class MetadataRefreshTest {
    private final static String METADATA = 'Metadata';

    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void credentialFailure() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id credentialId = null;
            Exception exceptionMessage;
            MetadataRefreshDetails metadataRefreshDetails = new MetadataRefreshDetails();

            // EXERCISE

            Test.startTest();
            try {
                MetadataRefresh.execute(credentialId, metadataRefreshDetails);
            } catch (Exception ex) {
                exceptionMessage = ex;
            }
            Test.stopTest();

            // VERIFY

            Assert.isTrue(
                exceptionMessage.getMessage().contains(Label.Credential_Not_Found),
                'The exception message should be ' + Label.Credential_Not_Found
            );
        }
    }

    @IsTest
    private static void attachmentFailure() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id credentialId = getCredentialId();
            List<String> selectedMetadata = new List<String>();
            MetadataRefreshDetails metadataRefreshDetails = new MetadataRefreshDetails(METADATA, selectedMetadata, false);

            // EXERCISE

            Test.startTest();
            MetadataRefresh.Response result = MetadataRefresh.execute(credentialId, metadataRefreshDetails);
            Test.stopTest();

            // VERIFY
            String error = String.format(
                Label.Metadata_Refresh_Job_Cannot_Be_Executed,
                new List<Object>{ MetadataRefresh.MIN_INTERVAL_FOR_METADATA_REFRESH_OLD_PAGE }
            );
            Assert.areEqual(false, result.isSuccess, 'The success parameter should return false');
            Assert.areEqual(error, result.message, 'The exception message should be ' + error);
            Assert.areEqual(MetadataRefresh.INFO, result.variant, 'The variant should be ' + MetadataRefresh.INFO);
        }
    }

    @IsTest
    private static void refreshMetadataWithNotificationFailure() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id credentialId = getCredentialId();
            createCopadoNotification(credentialId);
            List<String> selectedMetadata = new List<String>();
            MetadataRefreshDetails metadataRefreshDetails = new MetadataRefreshDetails(METADATA, selectedMetadata, false);

            // EXERCISE

            Test.startTest();
            MetadataRefresh.Response result = MetadataRefresh.execute(credentialId, metadataRefreshDetails);
            Test.stopTest();

            // VERIFY

            Assert.areEqual(false, result.isSuccess, 'The success parameter should return false');
            Assert.areEqual(
                Label.Metadata_Refresh_Job_Already_In_Progress,
                result.message,
                'The exception message should be ' + Label.Metadata_Refresh_Job_Already_In_Progress
            );
            Assert.areEqual(MetadataRefresh.INFO, result.variant, 'The variant should be ' + MetadataRefresh.INFO);
        }
    }

    @IsTest
    private static void refreshMetadataWithoutAttachmentSuccessful() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id credentialId = getCredentialId();
            deleteAttachment();
            List<String> selectedMetadata = new List<String>();
            MetadataRefreshDetails metadataRefreshDetails = new MetadataRefreshDetails(METADATA, selectedMetadata, false);

            // EXERCISE

            Test.startTest();
            MetadataRefresh.Response result = MetadataRefresh.execute(credentialId, metadataRefreshDetails);
            Test.stopTest();

            // VERIFY

            Assert.areEqual(true, result.isSuccess, 'The success parameter should return true');
            Assert.isTrue(String.isBlank(result.message), 'The message should be blank');
            Assert.isNull(result.variant, 'The variant should be null');
        }
    }

    @IsTest
    private static void refreshPartialMetadataWithoutAttachmentSuccessful() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id credentialId = getCredentialId();
            deleteAttachment();
            List<String> selectedMetadata = new List<String>{ 'ApexClass', 'ApexTrigger' };
            MetadataRefreshDetails metadataRefreshDetails = new MetadataRefreshDetails(METADATA, selectedMetadata, true);

            // EXERCISE

            Test.startTest();
            MetadataRefresh.Response result = MetadataRefresh.execute(credentialId, metadataRefreshDetails);
            Test.stopTest();

            // VERIFY

            Assert.areEqual(true, result.isSuccess, 'The success parameter should return true');
            Assert.isTrue(String.isBlank(result.message), 'The message should be blank');
            Assert.isNull(result.variant, 'The variant should be null');
        }
    }

    private static void createData() {
        Credential credential = new Credential(new Environment().platform('SFDX').type('Production/Developer')).type('Production/Developer');
        new UserStory().title('US 1').status('Draft').credential(credential);
        Blob data = getMetadataItem('ApexClass', 'SampleClass', 'Test Test', '1900-01-01');
        new Attachment_t().name(METADATA).body(data).parent(credential).persist();
    }

    private static Id getCredentialId() {
        return [SELECT copado__Org_Credential__c FROM copado__User_Story__c LIMIT 1].copado__Org_Credential__c;
    }

    private static void deleteAttachment() {
        delete [SELECT Id FROM Attachment WHERE Name = :METADATA LIMIT 1];
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static Blob getMetadataItem(String type, String name, String createdBy, String createdDate) {
        MetaDataItem item = TestDataFactory.getMetadataItem(type, name, createdBy, createdDate);
        List<MetaDataItem> items = new List<MetaDataItem>{ item };
        Blob data = Blob.valueOf(JSON.serialize(items));
        return data;
    }

    private static void createCopadoNotification(String credentialId) {
        copado__Copado_Notification__c copadoNotification = new copado__Copado_Notification__c(
            copado__ParentId__c = credentialId,
            copado__isFinished__c = false
        );
        insert copadoNotification;
    }
}