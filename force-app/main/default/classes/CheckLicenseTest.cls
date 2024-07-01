@IsTest
private class CheckLicenseTest {

    @TestSetup
    private static void makeData() {
        User u = TestDataFactory.createUser('Standard User');
        insert u;

        TestDataFactory.assignPermissionSet(u, new Set<String>{ 'Copado_User' });
    }

    @IsTest
    private static void userWithLicense() {
        User u = getRunAsUser();
        System.runAs(u) {
            // Setup

            TestDataFactory.assignLicense(u.Id, true, true, true, true, true);

            // Exercise

            Boolean hasUserLicense = new CheckLicense(u.Id).has('Copado User');
            Boolean hasAdminLicense = new CheckLicense(u.Id).has('Copado Admin');
            Boolean hasCCHLicense = new CheckLicense(u.Id).has('Compliance Hub');
            Boolean hasCSTLicense = new CheckLicense(u.Id).has('Selenium Testing');

            // Verify

            Assert.areEqual(true, hasUserLicense, 'User should have a license.');
            Assert.areEqual(true, hasAdminLicense, 'User should have a license.');
            Assert.areEqual(true, hasCCHLicense, 'User should have a license.');
            Assert.areEqual(true, hasCSTLicense, 'User should have a license.');
        }
    }

    @IsTest
    private static void areLicensesExceededTest() {
        User u = getRunAsUser();
        System.runAs(u) {
            // Setup

            TestDataFactory.assignLicense(u.Id, true, true, true, true, true);

            // Exercise

            Boolean licensesExceeded =  CheckLicense.areLicensesExceeded();

            // Verify

            Assert.areEqual(false, licensesExceeded, 'Licenses should be available');
        }
    }

    @IsTest
    private static void userWithoutLicense() {
        User u = getRunAsUser();
        System.runAs(u) {
            // Setup

            TestDataFactory.assignLicense(u.Id, false, false, false, false, false);

            // Exercise

            Boolean hasLicense = new CheckLicense(u.Id).has('Copado User');

            // Verify

            Assert.areEqual(false, hasLicense, 'User should not have a license.');
        }
    }

    // HELPER

    private static User getRunAsUser() {
        return [
            SELECT Id
            FROM User
            WHERE Profile.Name = 'Standard User' AND UserName LIKE '%testcmcsf@copado.com%'
            LIMIT 1
        ];
    }
}