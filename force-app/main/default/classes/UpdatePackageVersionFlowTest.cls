@IsTest
private class UpdatePackageVersionFlowTest {
    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
    }

    @IsTest
    private static void success() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            
            TestUtilities.createJobTemplate('SFDX Package Version Update_1').persist();
            DataHelper helper = new DataHelper()
                .createRepository('Git Repo')
                .createEnvironment('Env 1')
                .addCredential('Cred 1')
                .createPackage('SF_Package')
                .addPackageVersion('Version 1')
                .createResult(null, null)
                .createJobExecution(getDataJson());

            String data =
                '{"packageVersion":{"Id":"' +
                helper.version.Id +
                '","copado__Artifact__r":{"Id":"' +
                helper.pkg.Id +
                '"},"Has_Installation_Key__c":false,"copado__Subscriber_Version_Id__c": "04t5i000000d6tCAAQ","Name": "Version 1"}}';
            Map<String, Object> flowParams = new Map<String, Object>{
                'prevResultId' => new DataHelper().createResult(data, createJobStep(helper.jobExecution.Id, 'Function').Id).result.Id,
                'resultId' => helper.result.Id,
                'installationKey' => 'key here'
            };

            // EXERCISE

            Test.startTest();
            new Flow.Interview.UpdatePackageVersion(flowParams).start();
            Test.stopTest();

            // VERIFY

            copado__Result__c result = [SELECT copado__Status__c, copado__Error_Message__c FROM copado__Result__c WHERE Id = :helper.result.Id];
            Assert.areEqual('Success', result.copado__Status__c, 'Flow should run successfully.');
            Assert.isTrue(getPackageVersion(helper.version.id).Has_Installation_Key__c, 'Has installation key checkbox should be true');
        }
    }

    @IsTest
    private static void failure() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            DataHelper helper = new DataHelper()
                .createRepository('Git Repo')
                .createEnvironment('Env 1')
                .addCredential('Cred 1')
                .createPackage('SF_Package')
                .addPackageVersion('Version 1')
                .createInstallationKey('pwd1')
                .createResult(null, null);

            Map<String, Object> flowParams = new Map<String, Object>{
                'newVersion' => '{versionName:null,tag:null,"subscriberVersionId":"04t5g000000UgWxAAK","installationKey":"123456","description":null,"branch":"main"}',
                'resultId' => helper.result.Id
            };

            // EXERCISE

            Test.startTest();
            new Flow.Interview.UpdatePackageVersion(flowParams).start();
            Test.stopTest();

            // VERIFY

            copado__Result__c result = [SELECT copado__Status__c FROM copado__Result__c WHERE Id = :helper.result.Id LIMIT 1];
            Assert.areEqual('Failed', result.copado__Status__c, 'Flow should fail.');
        }
    }

    private static String getDataJson() {
        return '{"packageVersion":{"VersionNumber":null,"VersionName":null,"VersionDescription":null,"Tag":null,"SubscriberVersionId":null,"Status":null,"SkipValidation":null,"PostInstallUrl":null,"Name":"Polling child package 2 - 0.1.0.4","IsReleased":null,"Id":"a047Q00000CYhaEQAT","HasInstallationKey":null,"DataJSON":null,"CodeCoverage":null,"Branch":null,"attributes":{"url":"/services/data/v57.0/sobjects/copado__Artifact_Version__c/a047Q00000CYhaEQAT","type":"copado__Artifact_Version__c"},"ArtifactObj":null,"Artifact":null},"installationKey":"key here"}';
    }

    private static copado__JobStep__c createJobStep(Id execution, String type) {
        copado__JobStep__c jobStep = new copado__JobStep__c(
            copado__JobExecution__c = execution,
            copado__Type__c = type,
            copado__JobTemplate__c = TestUtilities.getJobTemplate('SFDX Package Version Update_1').Id
        );
        insert jobStep;

        return jobStep;
    }

    // HELPER

    private class DataHelper {
        private copado__Git_Repository__c repository;
        private copado__Environment__c environment;
        private copado__Org__c credential;
        private copado__Artifact__c pkg;
        private copado__Artifact_Version__c version;
        private PackageVersionInstallationKey__c installationKey;
        private copado__Result__c result;
        private copado__JobExecution__c jobExecution;

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

        private DataHelper addCredential(String name) {
            credential = TestDataFactory.createCredential(name, UserInfo.getUserName(), environment?.Id, environment?.copado__Type__c);
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

        @SuppressWarnings('PMD.AvoidHardcodingId')
        private DataHelper addPackageVersion(String name) {
            version = TestDataFactory.createPackageVersion(name, pkg.Id);
            version.copado__Subscriber_Version_Id__c = '04t5g000000UgWxAAK';
            insert version;

            return this;
        }

        private DataHelper createInstallationKey(String key) {
            installationKey = new PackageVersionInstallationKey__c(
                PackageVersionId__c = version.copado__Subscriber_Version_Id__c,
                InstallationKey__c = key,
                Name = version.Name
            );
            insert installationKey;

            return this;
        }

        private DataHelper createResult(String resultData, Id jobStep) {
            result = new copado__Result__c();
            result.copado__Job_Type__c = 'UpdatePackageVersion';
            result.copado__Result_Data__c = resultData;
            result.copado__JobStep__c = jobStep;
            insert result;

            return this;
        }

        private DataHelper createJobExecution(String dataJson) {
            jobExecution = new copado__JobExecution__c();
            jobExecution.copado__DataJson__c = dataJson;

            insert jobExecution;

            return this;
        }
    }

    private static copado__Artifact_Version__c getPackageVersion(Id recordId) {
        return [
            SELECT Id, Has_Installation_Key__c, copado__LastJobExecutionId__c, copado__Subscriber_Version_Id__c
            FROM copado__Artifact_Version__c
            WHERE Id = :recordId
        ];
    }
}