@IsTest
private class PromotionRollbackCtrlTest {
    private static final String ROLLBACK_ENABLED = 'rollback_enabled';
    private static final String ADMIN_USERNAME = 'username-admin@myemail.com';

    @TestSetup
    private static void setup() {
        TestUtilities.setup();
        TestUtilities.setupAdminUser(ADMIN_USERNAME);
    }

    @IsTest
    private static void checkSystemPropertySharingSuccess() {
        Id promotionId;
        System.runAs(TestUtilities.getRunAsUser(ADMIN_USERNAME)) {
            //SETUP
            promotionId = createDataAndGetPromotionId('true', ROLLBACK_ENABLED, true);
        }

        System.runAs(TestUtilities.getRunAsUser()) {
            Boolean rollbackEnabled;

            //EXERCISE
            Test.startTest();
            rollbackEnabled = PromotionRollbackCtrl.isRollbackEnabledFor(promotionId);
            Test.stopTest();

            //VERIFY
            Assert.isTrue(rollbackEnabled, 'Rollback should be enabled');
        }
    }

    @IsTest
    private static void checkRollbackEnabledSuccess() {
        System.runAs(TestUtilities.getRunAsUser()) {
            //SETUP
            Boolean rollbackEnabled;

            Id promotionId = createDataAndGetPromotionId('true', ROLLBACK_ENABLED, true);

            //EXERCISE
            Test.startTest();
            rollbackEnabled = PromotionRollbackCtrl.isRollbackEnabledFor(promotionId);
            Test.stopTest();

            //VERIFY
            Assert.isTrue(rollbackEnabled, 'Rollback should be enabled');
        }
    }

    @IsTest
    private static void checkRollbackDisabledSuccess() {
        System.runAs(TestUtilities.getRunAsUser()) {
            //SETUP
            Boolean rollbackEnabled;
            Id promotionId = createDataAndGetPromotionId('false', ROLLBACK_ENABLED, true);

            //EXERCISE
            Test.startTest();
            rollbackEnabled = PromotionRollbackCtrl.isRollbackEnabledFor(promotionId);
            Test.stopTest();

            //VERIFY
            Assert.isFalse(rollbackEnabled, 'Rollback should not be enabled');
        }
    }

    @IsTest
    private static void checkRollbackForInvalidSystemProperty() {
        System.runAs(TestUtilities.getRunAsUser()) {
            //SETUP
            Boolean rollbackEnabled;
            Id promotionId = createDataAndGetPromotionId('true', 'rollback_enabled_invalid_api_name', true);

            //EXERCISE
            Test.startTest();
            rollbackEnabled = PromotionRollbackCtrl.isRollbackEnabledFor(promotionId);
            Test.stopTest();

            //VERIFY
            Assert.isFalse(rollbackEnabled, 'Rollback should not be enabled');
        }
    }

    @IsTest
    private static void checkRollbackWhenNoSystemPropertyExists() {
        System.runAs(TestUtilities.getRunAsUser()) {
            //SETUP
            Boolean rollbackEnabled;
            Id promotionId = createDataAndGetPromotionId('', '', false);

            //EXERCISE
            Test.startTest();
            rollbackEnabled = PromotionRollbackCtrl.isRollbackEnabledFor(promotionId);
            Test.stopTest();

            //VERIFY
            Assert.isFalse(rollbackEnabled, 'Rollback should not be enabled');
        }
    }

    @IsTest
    private static void checkRollbackEnabledCaseInsensitive() {
        System.runAs(TestUtilities.getRunAsUser()) {
            //SETUP
            Boolean rollbackEnabled;
            Id promotionId = createDataAndGetPromotionId('TrUe', ROLLBACK_ENABLED, true);

            //EXERCISE
            Test.startTest();
            rollbackEnabled = PromotionRollbackCtrl.isRollbackEnabledFor(promotionId);
            Test.stopTest();

            //VERIFY
            Assert.isTrue(rollbackEnabled, 'Rollback should be enabled');
        }
    }

    @IsTest
    private static void checkRollbackForIncorrectContext() {
        User user = TestUtilities.getRunAsUser();
        System.runAs(user) {
            //SETUP
            String exceptionMessage;
            Boolean rollbackEnabled;

            //EXERCISE

            Test.startTest();
            try {
                rollbackEnabled = PromotionRollbackCtrl.isRollbackEnabledFor(user.Id);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            //VERIFY
            Assert.areEqual('Script-thrown exception', exceptionMessage, 'The exception messages match');
            Assert.areEqual(null, rollbackEnabled, 'Rollback should not be enabled');
        }
    }

    @IsTest
    private static void checkRollbackForNoContext() {
        System.runAs(TestUtilities.getRunAsUser()) {
            //SETUP
            String exceptionMessage;
            Boolean rollbackEnabled;

            //EXERCISE

            Test.startTest();
            try {
                rollbackEnabled = PromotionRollbackCtrl.isRollbackEnabledFor(null);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            //VERIFY
            Assert.areEqual('Script-thrown exception', exceptionMessage, 'The exception messages match');
            Assert.areEqual(null, rollbackEnabled, 'Rollback should not be enabled');
        }
    }

    // HELPER

    private static Id createDataAndGetPromotionId(String value, String apiName, Boolean createProperty) {
        Environment sourceEnv = new Environment().name('Dev').platform('SFDX').type('Production/Developer');
        Environment destinationEnv = new Environment().name('Test').platform('SFDX').type('Production/Developer');

        Credential sourceCred = new Credential(sourceEnv).type('Production/Developer');
        Credential destinationCred = new Credential(destinationEnv).type('Production/Developer');

        Promotion promotion = new Promotion(
            new Project(new Pipeline(new Repository().name('Repo 1')).platform('SFDX')),
            sourceCred,
            sourceEnv,
            destinationCred,
            destinationEnv
        );

        if (createProperty) {
            new SystemProperty(destinationEnv).apiName(apiName).value(value).persist();
        } else {
            promotion.persist();
        }

        return promotion.Id;
    }
}