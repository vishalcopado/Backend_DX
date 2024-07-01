@IsTest
public with sharing class DistributePackagesTest {
    @TestSetup
    public static void makeData() {
        TestUtilities.setup();
    }

    @IsTest
    public static void getPackageVersion() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            DataHelper helper = new DataHelper()
                .createRepository('Git Repo')
                .createEnvironment('SF Envirnment', 'SFDX')
                .addCredential('Credential 1')
                .createPackage('SF_Package')
                .addPackageVersion('Version 1', 'test')
                .addPackageVersion('Version 2', 'test');

            // EXERCISE

            List<copado__Artifact_Version__c> versions = DistributePackages.fetchPkgVersionsFor(helper.pkg.Id);

            // VERIFY

            Assert.areEqual(2, versions.size(), 'Versions size should be 2');
            Assert.areEqual('Version 1', versions[0].Name, 'Version name is incorrect');
            Assert.areEqual('Version 2', versions[1].Name, 'Version name is incorrect');
        }
    }

    @IsTest
    public static void getEmptyPackageVersionList() {
        System.runAs(TestUtilities.getRunAsUser()) {
            String exceptionMessage;
            List<copado__Artifact_Version__c> versions = new List<copado__Artifact_Version__c>();

            // SETUP

            DataHelper helper = new DataHelper()
                .createRepository('Git Repo')
                .createEnvironment('SF Envirnment', 'SFDX')
                .addCredential('Credential 1')
                .createPackage('SF_Package');

            // EXERCISE

            try {
                versions = DistributePackages.fetchPkgVersionsFor(helper.pkg.Id);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY

            Assert.areEqual(0, versions.size(), 'No package version available.');
            Assert.areEqual(Label.No_Generated_Package_Versions, exceptionMessage, 'Show Error on empty package vesrion list.');
        }
    }

    @IsTest
    public static void getGeneratedPackageVersions() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            DataHelper helper = new DataHelper()
                .createRepository('Git Repo')
                .createEnvironment('SF Envirnment', 'SFDX')
                .addCredential('Credential 1')
                .createPackage('SF_Package')
                .addPackageVersion('Version 1', 'test')
                .addPackageVersion('Version 2', 'test')
                .addPackageVersion('Version 3', ''); // Here no subscriber Id means package version is not generated.

            // EXERCISE

            List<copado__Artifact_Version__c> versions = DistributePackages.fetchPkgVersionsFor(helper.pkg.Id);

            // VERIFY

            System.assertEquals(2, versions.size(), 'Get versions with status Pre-Release and Published.');
        }
    }

    @IsTest
    public static void getCredentials() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            DataHelper helper = new DataHelper()
                .createRepository('Git Repo')
                .createEnvironment('SF Envirnment', 'SFDX')
                .addCredential('Credential 1')
                .addCredential('Credential 2');

            // EXERCISE

            List<copado__Org__c> credentials = DistributePackages.getCredentials(new List<String>{ helper.credentials[0].Id });

            // VERIFY

            Assert.areEqual(1, credentials.size(), 'Credentials size should be 2');
            Assert.areEqual(helper.credentials[0].Id, credentials[0].Id, 'Credentials Ids should match');
        }
    }

    @IsTest
    public static void getCredentialsOnEmptyList() {
        System.runAs(TestUtilities.getRunAsUser()) {
            String exceptionMessage;
            List<copado__Org__c> credentials = new List<copado__Org__c>();

            // SETUP

            new DataHelper().createRepository('Git Repo').createEnvironment('Other Environment', 'Other').addCredential('Credential 1');
            // EXERCISE
            try {
                credentials = DistributePackages.getCredentials(new List<String>{});
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            // VERIFY

            Assert.areEqual(0, credentials.size(), 'No credential available of type SFDX and Salesforce');
            Assert.areEqual(
                Label.No_SFDX_Platform_Environment,
                exceptionMessage,
                'Show error on empty enviornment list of SFDX and Salesforce Platform type'
            );
        }
    }

    @IsTest
    public static void getAllCredentials() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            new DataHelper()
                .createRepository('Git Repo')
                .createEnvironment('SF Environment', 'SFDX')
                .addCredential('Credential 1')
                .addCredential('Credential 2');

            new DataHelper().createRepository('Git Repo').createEnvironment('Salesforce Environment', 'Salesforce').addCredential('Credential 3');

            new DataHelper().createRepository('Git Repo').createEnvironment('Other Environment', 'Other').addCredential('Credential 4');

            List<String> credentialsnames = new List<String>{ 'Credential 1', 'Credential 2', 'Credential 3', 'SF Environment' };

            // EXERCISE
            List<copado__Org__c> credentials = DistributePackages.getCredentials(new List<String>{});

            //Verify
            for (copado__Org__c credential : credentials) {
                Assert.isTrue(credentialsnames.contains(credential.name), 'Credentials name should match');
            }
            // VERIFY
            // Note: Its 4 because a credential is automatically created for SFDX platform
            Assert.areEqual(4, credentials.size(), 'Credentials size should be 4');
        }
    }

    @IsTest
    public static void getProjects() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            new DataHelper().createRepository('Git Repo SFDX').createPipeline('Pipeline SFDX', 'SFDX').addProject('Project 1');
            new DataHelper().createRepository('Git Repo Salesforce').createPipeline('Pipeline salesforce', 'Salesforce').addProject('Project 2');
            DataHelper data = new DataHelper()
                .createRepository('Git Repo Salesforce 2')
                .createPipeline('Pipeline salesforce', 'Salesforce')
                .addProject('Project 3');
            update new copado__Deployment_Flow__c(Id = data.pipeline.Id, copado__Git_Repository__c = null); // I remove the repository to check properly the result of getprojects.

            // EXERCISE

            List<copado__Project__c> projects = DistributePackages.getProjects();

            // VERIFY
            Assert.areEqual(2, projects.size(), 'Projects counter should be 2');
            Assert.areEqual('Pipeline SFDX', projects[0].copado__Deployment_Flow__r.Name, 'Pipeline should be SFDX');
            Assert.areEqual('Pipeline salesforce', projects[1].copado__Deployment_Flow__r.Name, 'Pipeline should be Salesforce');
        }
    }

    @IsTest
    public static void initiateDistributionFor() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            DataHelper helper = new DataHelper()
                .createJobTemplate('SFDX Package Distribution')
                .addJobStep('Get Dependencies', 'Function')
                .addJobStep('Install package', 'Function')
                .createRepository('Git Repo')
                .createEnvironment('SF Envirnment', 'SFDX')
                .addCredential('Credential 1')
                .createPackage('SF_Package')
                .addPackageVersion('Version 1', '');

            copado__JobTemplate__c template = [
                SELECT Id, copado__ApiName__c
                FROM copado__JobTemplate__c
                WHERE Name = 'SFDX Package Distribution'
                LIMIT 1
            ];
            template.copado__ApiName__c = 'SFDX Package Distribution_1';
            update template;

            // EXERCISE

            List<copado__JobExecution__c> result = DistributePackages.initiateDistributionFor(
                helper.versions[0].id,
                new List<String>{ helper.credentials[0].Id },
                'AllUsers'
            );

            // VERIFY

            DeployPackages.PackageVersion version = (DeployPackages.PackageVersion) JSON.deserialize(
                result[0].copado__DataJson__c,
                DeployPackages.PackageVersion.class
            );
            Assert.areEqual(1, result.size(), 'Job Executions creation has failed.');
            Assert.areEqual(
                helper.credentials[0].copado__Environment__c,
                result[0].copado__Destination__c,
                'Job executed created for incorrect environment.'
            );
            Assert.areEqual(null, version.deploymentJobId, 'DeploymentJobId is not updated on the Job Execution DataJSON');
            Assert.areEqual('54.0', version.apiVersion, 'Api Version should be updated from package version record on the Job Execution DataJSON');
            Assert.areEqual(
                'AllUsers',
                version.installSecurityType,
                'Package Installation security type should be updated on Job Execution DataJSON'
            );
            Assert.areEqual(null, version.installationKey, 'Installation key should be updated on the Job Execution DataJSON');
        }
    }

    // HELPER

    private class DataHelper {
        private copado__Git_Repository__c repository;
        private copado__Deployment_Flow__c pipeline;
        private copado__Project__c project;
        private copado__Environment__c environment;
        private List<copado__Org__c> credentials = new List<copado__Org__c>();
        private copado__Artifact__c pkg;
        private List<copado__Artifact_Version__c> versions = new List<copado__Artifact_Version__c>();
        private copado__JobTemplate__c template;
        private List<copado__JobStep__c> jobSteps = new List<copado__JobStep__c>();

        private DataHelper createRepository(String name) {
            repository = TestDataFactory.createGitRepository(name);
            insert repository;

            return this;
        }

        private DataHelper createEnvironment(String name, String platform) {
            environment = TestDataFactory.createEnvironment(name, 'Production/Developer', platform);
            insert environment;

            return this;
        }

        private DataHelper addCredential(String name) {
            copado__Org__c credential = TestDataFactory.createCredential(name, UserInfo.getUserName(), environment.Id, environment.copado__Type__c);
            credential.copado__Validated_Date__c = System.today();
            credential.copado__is_Developer_Hub_Org__c = true;
            insert credential;

            credentials.add(credential);

            return this;
        }

        private DataHelper createPipeline(String name, String platform) {
            pipeline = TestDataFactory.createPipeline(name, repository.Id);
            pipeline.copado__Platform__c = platform;
            insert pipeline;

            return this;
        }

        private DataHelper addProject(String name) {
            project = TestDataFactory.createProject(name, pipeline.Id);
            insert project;

            return this;
        }

        private DataHelper createPackage(String name) {
            pkg = TestDataFactory.createPackage(name, 'Package_Artifact');
            pkg.copado__Artifact_Repository__c = repository.Id;
            pkg.copado__Target_Dev_Hub_Org__c = credentials[0].Id;
            insert pkg;

            return this;
        }

        private DataHelper addPackageVersion(String name, String subscriberVersionId) {
            copado__Artifact_Version__c version = TestDataFactory.createPackageVersion(name, pkg.Id);
            version.copado__Subscriber_Version_Id__c = subscriberVersionId;
            version.Api_Version__c = '54.0';
            insert version;

            versions.add(version);

            return this;
        }

        public DataHelper createJobTemplate(String name) {
            template = TestDataFactory.createJobTemplate(name);
            insert template;
            return this;
        }

        public DataHelper addJobStep(String name, String type) {
            copado__JobStep__c step = new copado__JobStep__c(Name = name, copado__Type__c = type, copado__JobTemplate__c = template.Id);
            insert step;

            jobSteps.add(step);
            return this;
        }
    }
}