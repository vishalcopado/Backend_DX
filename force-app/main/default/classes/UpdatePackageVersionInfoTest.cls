@IsTest
private class UpdatePackageVersionInfoTest {
    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void updateRecordSuccesfully() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            UpdatePackageVersionInfo.Request request = new UpdatePackageVersionInfo.Request();
            request.versionName = 'New Version Name';
            request.versionId = getPackageVersion().Id;
            request.description = 'New Description';
            request.tag = 'New Tag';
            request.branch = 'New Branch';

            // EXERCISE
            Test.startTest();
            UpdatePackageVersionInfo.execute(new List<UpdatePackageVersionInfo.Request>{ request });
            Test.stopTest();

            // VERIFY
            String namespacePrefix = TestUtilities.getNamespacePrefix();
            namespacePrefix = String.isNotBlank(namespacePrefix) ? namespacePrefix + '__' : namespacePrefix;
            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(getJobExecution().copado__DataJson__c);
            Map<String, Object> packageVersion = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(data.get('packageVersion')));

            System.assertEquals('New Branch', packageVersion.get('copado__Branch__c'), 'Job template should be having updated branch');
            System.assertEquals(
                'New Description',
                packageVersion.get('copado__Version_Description__c'),
                'Job template should be having updated description'
            );
            System.assertEquals('New Tag', packageVersion.get('copado__Tag__c'), 'Job template should be having updated tag');
            System.assertEquals(
                'New Version Name',
                packageVersion.get('copado__Version_Name__c'),
                'Job template should be having updated version name'
            );

            System.assertEquals('55.0', packageVersion.get(namespacePrefix + 'Api_Version__c'), 'Api Version should be updated.');

            System.assertEquals(
                getJobExecution().Id,
                getPackageVersion().copado__LastJobExecutionId__c,
                'Package Version LastJobExecutionId should be updated'
            );
        }
    }

    @IsTest
    private static void showErrorOnEmptyVersionName() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            String exceptionMessage;
            UpdatePackageVersionInfo.Request request = new UpdatePackageVersionInfo.Request();
            request.versionId = getPackageVersion().Id;
            request.versionName = '';

            // EXERCISE
            try {
                Test.startTest();
                UpdatePackageVersionInfo.execute(new List<UpdatePackageVersionInfo.Request>{ request });
                Test.stopTest();
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY
            System.assertEquals(Label.Package_Version_Name_Not_Blank, exceptionMessage, 'Exception should be thrown for empty version name');
        }
    }

    @IsTest
    private static void showErrorOnEmptyVersionDescription() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            String exceptionMessage;
            UpdatePackageVersionInfo.Request request = new UpdatePackageVersionInfo.Request();
            request.versionId = getPackageVersion().Id;
            request.versionName = 'New Version Name';
            request.description = '';

            // EXERCISE
            try {
                Test.startTest();
                UpdatePackageVersionInfo.execute(new List<UpdatePackageVersionInfo.Request>{ request });
                Test.stopTest();
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY
            System.assertEquals(
                Label.Package_Version_Description_Not_Blank,
                exceptionMessage,
                'Exception should be thrown for empty version description'
            );
        }
    }

    @IsTest
    private static void showErrorOnEmptyVersionTag() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            String exceptionMessage;
            UpdatePackageVersionInfo.Request request = new UpdatePackageVersionInfo.Request();
            request.versionId = getPackageVersion().Id;
            request.versionName = 'New Version Name';
            request.description = 'New Description';
            request.tag = '';

            // EXERCISE
            try {
                Test.startTest();
                UpdatePackageVersionInfo.execute(new List<UpdatePackageVersionInfo.Request>{ request });
                Test.stopTest();
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY
            System.assertEquals(Label.Package_Version_Tag_Not_Blank, exceptionMessage, 'Exception should be thrown for empty version tag');
        }
    }

    @IsTest
    private static void showErrorOnEmptyVersionBranch() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            String exceptionMessage;
            UpdatePackageVersionInfo.Request request = new UpdatePackageVersionInfo.Request();
            request.versionId = getPackageVersion().Id;
            request.versionName = 'New Version Name';
            request.description = 'New Description';
            request.tag = 'newTag';
            request.branch = '';

            // EXERCISE
            try {
                Test.startTest();
                UpdatePackageVersionInfo.execute(new List<UpdatePackageVersionInfo.Request>{ request });
                Test.stopTest();
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY
            System.assertEquals(Label.Package_Version_Branch_Not_Blank, exceptionMessage, 'Exception should be thrown for empty version branch');
        }
    }

    private static void createData() {
        Repository repo = createRepository();
        Pipeline pipeline = createPipeline(repo, 'SFDX');
        JobTemplate template = createJobTemplate('SFDX Package Version Update')
            .add(createJobStep('Update Package Version', 'Function'))
            .add(createJobStep('Update Records', 'Flow'));
        Credential cred = createCredential();
        createEnvironment().add(cred);
        Artifact pkg = createPackage(repo, cred, pipeline);
        createPackageVersion(pkg).persist();
        update new copado__JobTemplate__c(Id = template.id, copado__ApiName__c = 'SFDX Package Version Update_1');
    }

    private static Repository createRepository() {
        return new Repository().name('My Repo');
    }

    private static Pipeline createPipeline(Repository repo, String platform) {
        return new Pipeline(repo).platform(platform);
    }

    private static Artifact createPackage(Repository repo, Credential cred, Pipeline pipeline) {
        return new Artifact(repo)
            .name('Testpkg')
            .type('Unlocked')
            .recordTypeId('Package_Artifact')
            .targetDevHub(cred)
            .pipeline(pipeline)
            .apiVersion('54.0');
    }

    private static ArtifactVersion createPackageVersion(Artifact pkg) {
        return new ArtifactVersion(pkg)
            .versionName('old Version')
            .versionNumber('1.0.1.0')
            .description('old Description')
            .codeCoverage(false)
            .tag('oldTag')
            .branch('oldBranch')
            .apiVersion('55.0');
    }

    private static Environment createEnvironment() {
        return new Environment().platform('SFDX').type('Production/Developer');
    }

    private static Credential createCredential() {
        return new Credential().devhub(true).type('Production/Developer');
    }

    private static JobTemplate createJobTemplate(String name) {
        return new JobTemplate().name(name);
    }

    private static JobStep createJobStep(String name, String type) {
        return new JobStep().name(name).type(type);
    }

    private static copado__JobExecution__c getJobExecution() {
        return [SELECT Id, copado__DataJson__c FROM copado__JobExecution__c LIMIT 1];
    }

    private static copado__Artifact_Version__c getPackageVersion() {
        return [
            SELECT Id, copado__Version_Name__c, copado__LastJobExecutionId__c, copado__Version_Description__c
            FROM copado__Artifact_Version__c
            LIMIT 1
        ];
    }
}