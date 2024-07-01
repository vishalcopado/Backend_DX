@IsTest
private class PollCopadoNotificationTest {
    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void copadoNotificationRecordIdNotFinished() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            Id credentialId = getCredentialId();
            CopadoNotification copadoNotification = new CopadoNotification().parentId(credentialId).isFinished(false);
            copadoNotification.persist();

            // EXERCISE
            Test.startTest();
            String nextFireCron = calculateNextFireCron();
            System.schedule(
                'Test 1 ' + nextFireCron,
                nextFireCron,
                new PollCopadoNotification(credentialId, copadoNotification.id, getResultId(), 0)
            );
            Test.stopTest();

            // VERIFY
            List<CronTrigger> cronTriggerAssertion = [
                SELECT Id
                FROM CronTrigger
                WHERE CronExpression = :nextfireCron
            ];
            Integer cronTriggerAssertionSize = cronTriggerAssertion.size();
            // Depending on the workload SF enques one or two jobs. Both scenarios are correct.
            Assert.isTrue(cronTriggerAssertionSize >= 1 && cronTriggerAssertionSize <= 2, 'Jobs are not enqueued correctly');
        }
    }

    @IsTest
    private static void copadoNotificationRecordIdIsSuccess() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            Id credentialId = getCredentialId();
            CopadoNotification copadoNotification = new CopadoNotification().parentId(credentialId).isFinished(true).isSuccess(true).status('done');
            copadoNotification.persist();
            createContentVersion(
                PollCopadoNotification.METADATA_FILE_NAME,
                PollCopadoNotification.METADATA_FILE_NAME + '.json',
                credentialId,
                getMetaDataFileContent(2)
            );

            // EXERCISE
            Test.startTest();
            String nextFireCron = calculateNextFireCron();
            System.schedule(
                'Test 2 ' + nextFireCron,
                nextFireCron,
                new PollCopadoNotification(credentialId, copadoNotification.id, getResultId(), 0)
            );
            Test.stopTest();

            // VERIFY
            List<CronTrigger> cronTriggerAssertion = [
                SELECT Id
                FROM CronTrigger
                WHERE CronExpression = :nextfireCron
            ];
            Integer cronTriggerAssertionSize = cronTriggerAssertion.size();
            // Depending on the workload SF enques one or two jobs. Both scenarios are correct.
            Assert.isTrue(cronTriggerAssertionSize >= 1 && cronTriggerAssertionSize <= 2, 'Jobs are not enqueued correctly');
        }
    }

    @IsTest
    private static void copadoNotificationRecordIdIsNotSuccess() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            Id credentialId = getCredentialId();
            CopadoNotification copadoNotification = new CopadoNotification()
                .parentId(credentialId)
                .isFinished(true)
                .isSuccess(false)
                .status('done')
                .message(
                    '{"messages":["could not upsert Attachment file MetaData on parentId: aKp4M0000008OIASA2"],"copadoJobId":"1b576190-0ac6-4fe9-af35-bdb605e4c43c","type":"MetadataRetriever","isFinished":true,"status":"done","isSuccess":false}'
                );
            copadoNotification.persist();

            // EXERCISE
            Test.startTest();
            String nextFireCron = calculateNextFireCron();
            System.schedule(
                'Test 2 ' + nextFireCron,
                nextFireCron,
                new PollCopadoNotification(credentialId, copadoNotification.id, getResultId(), 0)
            );
            Test.stopTest();

            // VERIFY
            List<CronTrigger> cronTriggerAssertion = [
                SELECT Id
                FROM CronTrigger
                WHERE CronExpression = :nextfireCron
            ];
            Integer cronTriggerAssertionSize = cronTriggerAssertion.size();
            // Depending on the workload SF enques one or two jobs. Both scenarios are correct.
            Assert.isTrue(cronTriggerAssertionSize >= 1 && cronTriggerAssertionSize <= 2, 'Jobs are not enqueued correctly');
        }
    }

    @IsTest
    private static void itearationExceeded() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            Id credentialId = getCredentialId();

            // EXERCISE
            Test.startTest();
            String nextFireCron = calculateNextFireCron();
            String jobId = System.schedule(
                'Iteration exceeded ' + nextFireCron,
                nextFireCron,
                new PollCopadoNotification(credentialId, null, getResultId(), 121)
            );
            Test.stopTest();

            // VERIFY
            List<CronTrigger> cronTriggerAssertion = [
                SELECT Id
                FROM CronTrigger
                WHERE Id = :jobId
            ];
            Assert.isTrue(!cronTriggerAssertion.isEmpty(), 'A new job must be enqueued');
        }
    }

    private static void createData() {
        Credential credential = new Credential(new Environment().type('Production/Developer')).type('Production/Developer');
        new Attachment_t().name('MetaData').parent(credential).body(Blob.valueOf(''));
        new Result().type('Integration').status('Success').data('{"commitId":"sampleCommitId"}').persist();
    }

    private static Id getCredentialId() {
        return [SELECT Id FROM copado__Org__c LIMIT 1][0].Id;
    }

    private static Id getResultId() {
        return [SELECT Id FROM copado__Result__c LIMIT 1][0].Id;
    }

    private static String calculateNextFireCron() {
        CronCalculator result = new CronCalculator();
        return result.nextFireCron(5);
    }

    private static Blob getMetaDataFileContent(Integer count) {
        List<MetaDataItem> metaDataItems = new List<MetaDataItem>();
        for (Integer i = 0; i < count; i++) {
            metaDataItems.add(TestDataFactory.getMetadataItem('ApexClass', 'SampleClass' + 1, 'Test Test', '1900-01-01'));
        }
        return Blob.valueOf(JSON.serialize(metaDataItems));
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static void createContentVersion(String title, String pathOnClient, Id firstPublishLocationId, Blob data) {
        new ContentVersion_t().title(title).pathOnClient(pathOnClient).firstPublishLocationId(firstPublishLocationId).versionData(data).persist();
    }
}