/*
TODO: We are not using the corresponsing main class and its flow anymore, this class needs to be removed from the package.
*/
@IsTest
private class GetPackageVersionWithKeysTest {
    private static final String VERSION_SUBSCRIBER_ID = createFakeId('04t');
    private static final String DEPENDENCY_SUBSCRIBER_ID = createFakeId('04t');

    @TestSetup
    private static void makeData() {
        User u = TestDataFactory.createUser('Standard User');
        insert u;

        TestDataFactory.assignPermissionSet(u, new Set<String>{ 'Copado_User', 'Copado_Job_Engine', 'CMC_SFDX_Admin' });

        System.runAs(u) {
            TestDataFactory.assignLicense(u.Id, true, true, true, true, true);
        }
    }

    @IsTest
    private static void executeSuccessful() {
        System.runAs(getRunAsUser()) {
            // SETUP

            DataHelper helper = new DataHelper()
                .createRepository('Git Repo')
                .createEnvironment('SF Envirnment')
                .createCredential('Credential 1')
                .createPackage('SF_Package')
                .createPackageVersion('Version 1', null)
                .addPackageDependency('Pre_Install_Pkg2', null);

            GetPackageVersionWithKeys.VersionDetails details = new GetPackageVersionWithKeys.VersionDetails();
            details.subscriberPackageId = 'Test';
            details.dependencies = new List<Id>{ helper.dependencies[0].copado__Subscriber_Version_Id__c };
            details.subscriberVersionId = helper.version.copado__Subscriber_Version_Id__c;
            details.versionNumber = '0.1.0.1';

            GetPackageVersionWithKeys.Request request = new GetPackageVersionWithKeys.Request();
            request.subscriberVersionId = helper.version.copado__Subscriber_Version_Id__c;
            request.versionDetails = JSON.serialize(details);

            // EXERCISE

            GetPackageVersionWithKeys.Response response = GetPackageVersionWithKeys.execute(new List<GetPackageVersionWithKeys.Request>{ request })
                .get(0);

            List<GetPackageVersionWithKeys.PackageVersion> versions = (List<GetPackageVersionWithKeys.PackageVersion>) JSON.deserialize(
                response.versions.unescapeEcmaScript(),
                List<GetPackageVersionWithKeys.PackageVersion>.class
            );

            // VERIFY

            System.assertEquals(2, versions.size(), 'Package Version with Dependencies and keys should be returned.');
            System.assertEquals(helper.version.copado__Subscriber_Version_Id__c, versions[1].id, 'Package Version should be last element.');
            System.assertEquals(null, versions[1].key, 'Package Version should be returned with key.');
            System.assertEquals('0.1.0.1', versions[1].versionNumber, 'Package Version number should not be null.');
            System.assertEquals('Test', versions[1].subscriberPackageId, 'Subscriber Package ID should not be null.');
            System.assertEquals(VERSION_SUBSCRIBER_ID, versions[1].id, 'Package Version should be last element.');

            System.assertEquals(
                helper.dependencies[0].copado__Subscriber_Version_Id__c,
                versions[0].id,
                'Dependency Package Version should be first element.'
            );
            System.assertEquals(null, versions[0].key, 'Dependency Package Version should be returned with key.');
            System.assertEquals(null, versions[0].versionNumber, 'Dependency Package Version number should be null.');
            System.assertEquals(null, versions[0].subscriberPackageId, 'Dependency Subscriber Package ID should be null.');
            System.assertEquals(DEPENDENCY_SUBSCRIBER_ID, versions[0].id, 'Package Version should be first element.');
        }
    }

    @IsTest
    private static void executeFailure() {
        System.runAs(getRunAsUser()) {
            // SETUP

            new DataHelper()
                .createRepository('Git Repo')
                .createEnvironment('SF Envirnment')
                .createCredential('Credential 1')
                .createPackage('SF_Package')
                .createPackageVersion('Version 1', null)
                .addPackageDependency('Pre_Install_Pkg2', null);

            String fakeSubscriberId = createFakeId('04t');
            GetPackageVersionWithKeys.Request request = new GetPackageVersionWithKeys.Request();
            request.subscriberVersionId = fakeSubscriberId;

            String exceptionMessage;

            // EXERCISE

            try {
                Test.startTest();
                GetPackageVersionWithKeys.execute(new List<GetPackageVersionWithKeys.Request>{ request }).get(0);
                Test.stopTest();
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY

            System.assertNotEquals(null, exceptionMessage, 'Exception should be thrown.');
        }
    }

    // HELPER

    private class DataHelper {
        private copado__Git_Repository__c repository;
        private copado__Environment__c environment;
        private copado__Org__c credential;
        private copado__Artifact__c pkg;
        copado__Artifact_Version__c version;
        private List<copado__Artifact_Version__c> dependencies = new List<copado__Artifact_Version__c>();
        private copado__JobTemplate__c template;

        private DataHelper createRepository(String name) {
            repository = TestDataFactory.createGitRepository(name);
            insert repository;
            return this;
        }

        private DataHelper createEnvironment(String name) {
            environment = TestDataFactory.createEnvironment(name, 'Production/Developer', 'Salesforce');
            insert environment;
            return this;
        }

        private DataHelper createCredential(String name) {
            credential = TestDataFactory.createCredential(name, UserInfo.getUserName(), environment.Id, environment.copado__Type__c);
            credential.copado__is_Developer_Hub_Org__c = true;
            insert credential;

            return this;
        }

        private DataHelper createPackage(String name) {
            pkg = TestDataFactory.createPackage(name, 'Package_Artifact');
            pkg.copado__Artifact_Repository__c = repository.Id;
            pkg.copado__Target_Dev_Hub_Org__c = credential.Id;
            insert pkg;

            return this;
        }

        private DataHelper createPackageVersion(String name, String key) {
            version = TestDataFactory.createPackageVersion(name, pkg.Id);
            version.copado__Subscriber_Version_Id__c = VERSION_SUBSCRIBER_ID;
            version.copado__Version_number__c = '0.1.0.1';
            insert version;

            if (String.isNotBlank(key)) {
                PackageVersionInstallationKey__c versionKey = new PackageVersionInstallationKey__c(
                    Name = version.copado__Subscriber_Version_Id__c,
                    PackageVersionId__c = version.copado__Subscriber_Version_Id__c,
                    InstallationKey__c = key
                );
                insert versionKey;
            }

            return this;
        }

        private Datahelper addPackageDependency(String name, String key) {
            copado__Artifact__c dPkg = TestDataFactory.createPackage(name, 'Package_Artifact');
            dPkg.copado__Artifact_Repository__c = repository.Id;
            dPkg.copado__Target_Dev_Hub_Org__c = credential.Id;
            insert dPkg;

            copado__Artifact_Version__c dVersion = TestDataFactory.createPackageVersion(name, dPkg.Id);
            dVersion.copado__Subscriber_Version_Id__c = DEPENDENCY_SUBSCRIBER_ID;
            insert dVersion;

            dependencies.add(dVersion);

            if (String.isNotBlank(key)) {
                PackageVersionInstallationKey__c versionKey = new PackageVersionInstallationKey__c(
                    Name = dVersion.copado__Subscriber_Version_Id__c,
                    PackageVersionId__c = dVersion.copado__Subscriber_Version_Id__c,
                    InstallationKey__c = key
                );
                insert versionKey;
            }

            return this;
        }
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' AND UserName LIKE '%testcmcsf@copado.com%' LIMIT 1];
    }

    private static Id createFakeId(String keyPrefix) {
        return fflib_IDGenerator.generate(keyPrefix);
    }
}