@IsTest
private class UpdatePackageVersionTest {
    @TestSetup
    private static void setupData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void createInstallationKeySuccess() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            copado__Artifact_Version__c record = TestUtilities.getPackageVersions()[0];

            PackageVersionUpdateJob.Version version = new PackageVersionUpdateJob.Version();
            version.packageVersion = record;
			
            JobTemplate template = TestUtilities.getTemplateObj('SFDX Package Version Update_1');
            SObject jobExecution = TestUtilities.createJobExecution(template, TestUtilities.getEnvironmentObj('Environment Test 1'), getDataJson()).persist();
            
            JobStep jobStep = createJobStep('Update Package Version', 'Function', TestUtilities.getJobExecutionObj(jobExecution.Id));
            createResult(jobStep, JSON.serialize(version), 'SFDX_Package_Version_Update');

            UpdatePackageVersion.Request request = new UpdatePackageVersion.Request();
            request.prevResultId = getResult(jobStep.Id).Id;
            request.installationKey = 'installation key here';

            // EXERCISE
            
            Test.startTest();
            UpdatePackageVersion.updateRecords(new List<UpdatePackageVersion.Request>{ request });
            Test.stopTest();

            // VERIFY

            PackageVersionInstallationKey__c key = getkey(record.copado__Subscriber_Version_Id__c);
            Assert.areEqual('installation key here', key?.InstallationKey__c, 'Installation Key should be updated.');
            Assert.areEqual('ver 0.1', key?.Name, 'Installation Key name should be same as version name.');
            Assert.isTrue(TestUtilities.getPackageVersions()[0].Has_Installation_Key__c, 'Has installation key checkbox should be true');

            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(TestUtilities.getJobExecution(jobExecution.Id).copado__DataJson__c);
            Assert.areEqual('****', data.get('installationKey'), 'Installation Key in Data Json of Job Execution should be masked');
        }
    }

    @IsTest
    private static void updateInstallationKeySuccess() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            copado__Artifact_Version__c record = TestUtilities.getPackageVersions()[0];
            createInstalationKey('somekey', record.copado__Subscriber_Version_Id__c);

            PackageVersionUpdateJob.Version version = new PackageVersionUpdateJob.Version();
            version.packageVersion = record;
			
       
            SObject jobExecution = TestUtilities.createJobExecution(TestUtilities.getTemplateObj('SFDX Package Version Update_1'), TestUtilities.getEnvironmentObj('Environment Test 1'), getDataJson()).persist();
            JobStep jobStep = createJobStep('Update Package Version', 'Function', TestUtilities.getJobExecutionObj(jobExecution.Id));
            createResult(jobStep, JSON.serialize(version), 'SFDX_Package_Version_Update');

            UpdatePackageVersion.Request request = new UpdatePackageVersion.Request();
            request.prevResultId = getResult(jobStep.Id).Id;
            request.installationKey = 'some other key';

            // EXERCISE
            
            Test.startTest();
            UpdatePackageVersion.updateRecords(new List<UpdatePackageVersion.Request>{ request });
            Test.stopTest();

            // VERIFY

            PackageVersionInstallationKey__c key = getkey(record.copado__Subscriber_Version_Id__c);
            Assert.areEqual('some other key', key?.InstallationKey__c, 'Installation Key should be updated.');
            Assert.areEqual('ver 0.1', key?.Name, 'Installation Key name should be same as version name.');
			
            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(TestUtilities.getJobExecution(jobExecution.Id).copado__DataJson__c);
            Assert.areEqual('****', data.get('installationKey'), 'Installation Key in Data Json of Job Execution should be masked');
        }
    }

    @IsTest
    private static void invalidPrevResultIdFailure() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            String exceptionMessage;

            copado__Artifact_Version__c record = TestUtilities.getPackageVersions()[0];
            createInstalationKey('somekey', record.copado__Subscriber_Version_Id__c);

            PackageVersionUpdateJob.Version version = new PackageVersionUpdateJob.Version();
            version.packageVersion = record;
			
            SObject jobExecution = TestUtilities.createJobExecution(TestUtilities.getTemplateObj('SFDX Package Version Update_1'), TestUtilities.getEnvironmentObj('Environment Test 1'), getDataJson()).persist();
            
            JobStep jobStep = createJobStep('Update Package Version', 'Function', TestUtilities.getJobExecutionObj(jobExecution.Id));
            createResult(jobStep, JSON.serialize(version), 'SFDX_Package_Version_Update');

            UpdatePackageVersion.Request request = new UpdatePackageVersion.Request();
            request.prevResultId = createFakeId('04t');
            request.installationKey = 'some other key';

            // EXERCISE
            
            Test.startTest();
            try {
                UpdatePackageVersion.updateRecords(new List<UpdatePackageVersion.Request>{ request });
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            Test.stopTest();

            // VERIFY
            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(TestUtilities.getJobExecution(jobExecution.Id).copado__DataJson__c);
            Assert.areEqual(data.get('installationKey'),'key here', 'Installation Key in Data Json of Job Execution should be masked');
        }
    }

    private static String getDataJson() {
        return '{\"packageVersion\":{\"attributes\":{\"type\":\"copado__Artifact_Version__c\",\"url\":\"/services/data/v57.0/sobjects/copado__Artifact_Version__c/a047Q00000Dd3vNQAR\"},\"Name\":\"Polling Parent Pckg - 0.1.0.5\",\"copado__Version_number__c\":\"0.1.0.5\",\"copado__Branch__c\":\"master\",\"copado__Status__c\":\"Pre-Release\",\"copado__Is_released__c\":false,\"copado__Tag__c\":\"PollingParentPckg@0.1.0-5-master\",\"copado__Subscriber_Version_Id__c\":\"04t2w0000093mefAAA\",\"copado__Artifact__c\":\"a057Q000008dDMXQA2\",\"copado__Version_Name__c\":\"ver 0.1\",\"Code_Coverage__c\":false,\"Has_Installation_Key__c\":true,\"Post_Install_URL__c\":\"https://login.salesforce.com/packaging/installPackage.apexp?p0=04t2w0000093mefAAA\",\"Skip_Validation__c\":false,\"copado__Data_JSON__c\":\"{\\"codecoverage\\":\\"\\"}\",\"Id\":\"a047Q00000Dd3vNQAR\",\"copado__Artifact__r\":{\"attributes\":{\"type\":\"copado__Artifact__c\",\"url\":\"/services/data/v57.0/sobjects/copado__Artifact__c/a057Q000008dDMXQA2\"},\"Name\":\"Polling Parent Pckg\",\"copado__Package_Id__c\":\"0Ho2w000000CbNwCAK\",\"copado__Pipeline__c\":\"a0W7Q000002G2rsUAC\",\"copado__DefaultBranch__c\":\"master\",\"copado__Target_Dev_Hub_Org__c\":\"a117Q000000u9m1QAA\",\"Id\":\"a057Q000008dDMXQA2\",\"copado__Target_Dev_Hub_Org__r\":{\"attributes\":{\"type\":\"copado__Org__c\",\"url\":\"/services/data/v57.0/sobjects/copado__Org__c/a117Q000000u9m1QAA\"},\"copado__Environment__c\":\"a0c7Q000000KeyBQAS\",\"Id\":\"a117Q000000u9m1QAA\"}}},\"installationKey\":\"key here\",\"apiVersion\":null}';
    }

    private static void createData() {
        TestUtilities.createEnvironment('Environment Test 1');
        TestUtilities.createJobTemplate('SFDX Package Version Update_1').persist();
        createPackageVersion(createPackage(TestUtilities.createRepository(), 'Unlocked', null)).persist();
    }

    private static copado__Result__c getResult(Id jobStepId) {
        return [
            SELECT copado__Result_Data__c, copado__JobStep__c, copado__JobStep__r.copado__JobExecution__c
            FROM copado__Result__c
            WHERE copado__JobStep__c = :jobStepId
        ];
    }

    private static Artifact createPackage(Repository repo, String type, Credential cred) {
        return new Artifact(repo).name('Testpkg').type(type).recordTypeId('Package_Artifact').targetDevHub(cred);
    }

    private static ArtifactVersion createPackageVersion(Artifact pkg) {
        return new ArtifactVersion(pkg)
            .name('ver 0.1')
            .versionNumber('0.1.0.1')
            .versionId(createFakeId('04t'))
            .description('Winter 20XX Release')
            .versionName('v 3.2')
            .postInstallUrl('PostInstallScript')
            .postInstallScript('PostInstallScript')
            .releaseNotesUrl('https://expenser.com/winter-2020-release-notes.html')
            .uninstallScript('UninstallScript')
            .definitionFile('config/scratch-org-def.json')
            .ancestorVersion('0.1.0.0')
            .ancestorId(createFakeId('04t'));
    }

    private static Id createFakeId(String keyPrefix) {
        return fflib_IDGenerator.generate(keyPrefix);
    }

    private static void createInstalationKey(String key, String subscriberVersionId) {
        insert new PackageVersionInstallationKey__c(PackageVersionId__c = subscriberVersionId, InstallationKey__c = key, Name = 'Key Name');
    }

    private static JobStep createJobStep(String name, String type, JobExecution execution) {
        return new JobStep(TestUtilities.getTemplateObj('SFDX Package Version Update_1')).name(name).type(type).execution(execution);
    }

    private static void createResult(JobStep step, String resultData, String jobType) {
        new Result(step).data(resultData).type(jobType).persist();
    }

    private static PackageVersionInstallationKey__c getkey(Id subscriberVersionId) {
        List<PackageVersionInstallationKey__c> keys = new PackageVersionInstallationKeySelector()
            .byPackageVersionId(new Set<Id>{ subscriberVersionId });

        return keys[0];
    }
}