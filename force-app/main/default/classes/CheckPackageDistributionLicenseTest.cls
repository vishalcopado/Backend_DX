@IsTest
private class CheckPackageDistributionLicenseTest {

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

            TestDataFactory.assignLicense(u.Id, false, false, true, false, false);

            CheckPackageDistributionLicense.Request request = new CheckPackageDistributionLicense.Request();
            request.userId = u.Id;

            // Exercise

            CheckPackageDistributionLicense.Response response = CheckPackageDistributionLicense.checkLicense(
                    new List<CheckPackageDistributionLicense.Request>{ request }
                )
                .get(0);

            // Verify

            System.assertEquals(true, response.hasLicense, 'User should have a license to distribute package.');
        }
    }

    @IsTest
    private static void userWithoutLicense() {
        User u = getRunAsUser();
        System.runAs(u) {
            // Setup

            TestDataFactory.assignLicense(u.Id, false, false, false, false, false);

            CheckPackageDistributionLicense.Request request = new CheckPackageDistributionLicense.Request();
            request.userId = u.Id;

            // Exercise

            CheckPackageDistributionLicense.Response response = CheckPackageDistributionLicense.checkLicense(
                    new List<CheckPackageDistributionLicense.Request>{ request }
                )
                .get(0);

            // Verify

            System.assertEquals(false, response.hasLicense, 'User should not have a license to distribute package.');
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