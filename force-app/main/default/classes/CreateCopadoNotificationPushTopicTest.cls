@IsTest
private class CreateCopadoNotificationPushTopicTest {
    private static final String COPADO_NOTIFICATIONS = CreateCopadoNotificationPushTopic.COPADO_NOTIFICATIONS;
    private static final String QUERY = CreateCopadoNotificationPushTopic.QUERY;
    @TestSetup
    static void setUp() {
        TestUtilities.setup();
    }

    @IsTest
    private static void testCopadoNotificationCreation() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // EXERCISE
            LwcResponse result = CreateCopadoNotificationPushTopic.execute();
            // VERIFY
            PushTopic copadoNotification = [
                SELECT
                    Id,
                    Name,
                    Query,
                    ApiVersion,
                    NotifyForOperationCreate,
                    NotifyForOperationUpdate,
                    NotifyForOperationDelete,
                    NotifyForOperationUndelete,
                    NotifyForFields
                FROM PushTopic
                WHERE Name = :COPADO_NOTIFICATIONS
                LIMIT 1
            ];
            Assert.areEqual(COPADO_NOTIFICATIONS, copadoNotification.Name, 'Push Topic Name should be CopadoNotifications');
            Assert.areEqual(true, result.isSuccess, 'Result should be success');
            Assert.areEqual(QUERY, copadoNotification.Query, 'Push Topic Query is not correct');
            Assert.areEqual(32.0, copadoNotification.ApiVersion, 'Push Topic ApiVersion is not correct');
            Assert.areEqual(true, copadoNotification.NotifyForOperationCreate, 'Push Topic NotifyForOperationCreate should be true');
            Assert.areEqual(true, copadoNotification.NotifyForOperationUpdate, 'Push Topic NotifyForOperationUpdate should be true');
            Assert.areEqual(true, copadoNotification.NotifyForOperationDelete, 'Push Topic NotifyForOperationDelete should be true');
            Assert.areEqual(true, copadoNotification.NotifyForOperationUndelete, 'Push Topic NotifyForOperationUndelete should be true');
            Assert.areEqual('All', copadoNotification.NotifyForFields, 'Push Topic NotifyForFields should be All');
        }
    }
    @IsTest
    private static void testCopadoNotificationSkipCreation() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            PushTopic pushTopic = new PushTopic();
            pushTopic.Name = COPADO_NOTIFICATIONS;
            pushTopic.Query = QUERY;
            pushTopic.ApiVersion = 32.0;
            pushTopic.NotifyForOperationCreate = true;
            pushTopic.NotifyForOperationUpdate = true;
            pushTopic.NotifyForOperationUndelete = true;
            pushTopic.NotifyForOperationDelete = true;
            pushTopic.NotifyForFields = 'All';
            insert pushTopic;
            // EXERCISE
            LwcResponse result = CreateCopadoNotificationPushTopic.execute();
            // VERIFY
            List<PushTopic> copadoNotification = [
                SELECT Id, Name
                FROM PushTopic
                WHERE Name = :COPADO_NOTIFICATIONS
            ];
            Assert.areEqual(true, result.isSuccess, 'Result should be success');
            Assert.areEqual(1, copadoNotification.size(), 'Push Topic already exists');
        }
    }
}