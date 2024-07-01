@isTest
public class PackageVersionCreateActionTest {
    private static final String SUBSCRIBER_VERSION_ID = fflib_IDGenerator.generate('04t5i0');
    private static final String SUBSCRIBER_PACKAGE_ID = fflib_IDGenerator.generate('0Ho5i0');
    private static final String DESCRIPTION_WITH_SPECIAL_CHARS = 'version description with \'!@#$%^&*) chars here';
    private static final String DESCRIPTION = 'version description here';
    private static final String QUOTES = '\\"';

    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void getPackageVersionPayload() {
        System.runAs(TestUtilities.getRunAsUser()) {
            //SETUP

            String versionId = TestUtilities.getPackageVersions()[0].Id;
            SObject jobExecution = TestUtilities.createJobExecution(
                    TestUtilities.getTemplateObj('SFDX Package Version Create'),
                    TestUtilities.getEnvironmentObj('Test Environment'),
                    getDataJson('Test Description', versionId)
                )
                .persist();

            // EXERCISE

            Test.startTest();
            List<PackageVersionCreateAction.Response> response = PackageVersionCreateAction.execute(
                createRequest(DESCRIPTION, QUOTES + versionId + QUOTES, jobExecution.Id)
            );
            Test.stopTest();

            // VERIFY

            Map<String, Object> versionRecord = (Map<String, Object>) JSON.deserializeUntyped(response[0].version.unescapeJava());

            Assert.areEqual(DESCRIPTION, versionRecord.get('copado__Version_Description__c'), 'Description should match here');
            Assert.areEqual('Testpkg - 0.1.0.4', versionRecord.get('Name'), 'Name should match here');
            Assert.areEqual('0.1.0.4', versionRecord.get('copado__Version_number__c'), 'Version number should match here');
            Assert.areEqual('tagTest', versionRecord.get('copado__Tag__c'), 'Tag should match here');
            Assert.areEqual('ver 0.1', versionRecord.get('copado__Version_Name__c'), 'Version name should match here');
            Assert.areEqual(SUBSCRIBER_VERSION_ID, versionRecord.get('copado__Subscriber_Version_Id__c'), 'Subscriber Id should match here');
            Assert.areEqual(SUBSCRIBER_PACKAGE_ID, versionRecord.get('copado__Package_Version_Id__c'), 'Package Id should match here');
            Assert.areEqual(true, versionRecord.get(getNamespacePrefix() + 'Has_Installation_Key__c'), 'Installation key should be present');
            Assert.isFalse(versionRecord.containsKey('copado__Artifact__c'), 'Package Id should be null');

            PackageVersionCreateAction.DataJson data = (PackageVersionCreateAction.DataJson) JSON.deserialize(
                TestUtilities.getJobExecution(jobExecution.Id).copado__DataJson__c,
                PackageVersionCreateAction.DataJson.class
            );
            PackageVersionCreateAction.JsonInformation jsonInformation = (PackageVersionCreateAction.JsonInformation) JSON.deserialize(
                data.jsonInformation,
                PackageVersionCreateAction.JsonInformation.class
            );
            Assert.areEqual('****', jsonInformation.installationkey, 'Installation Key in Data Json of Job Execution should be masked');
        }
    }

    @IsTest
    private static void payloadWithSpecialChars() {
        System.runAs(TestUtilities.getRunAsUser()) { 
            //SETUP

            String versionId = TestUtilities.getPackageVersions()[0].Id;
            SObject jobExecution = TestUtilities.createJobExecution(
                    TestUtilities.getTemplateObj('SFDX Package Version Create'),
                    TestUtilities.getEnvironmentObj('Test Environment'),
                    getDataJson('Test Description', versionId)
                )
                .persist();

            // EXERCISE

            Test.startTest();
            List<PackageVersionCreateAction.Response> response = PackageVersionCreateAction.execute(
                createRequest(DESCRIPTION_WITH_SPECIAL_CHARS, QUOTES + versionId + QUOTES, jobExecution.Id)
            );
            Test.stopTest();

            // VERIFY

            Map<String, Object> versionRecord = (Map<String, Object>) JSON.deserializeUntyped(response[0].version.unescapeJava());

            Assert.areEqual(DESCRIPTION_WITH_SPECIAL_CHARS, versionRecord.get('copado__Version_Description__c'), 'Description should match here');
            Assert.areEqual('Testpkg - 0.1.0.4', versionRecord.get('Name'), 'Name should match here');
            Assert.areEqual('0.1.0.4', versionRecord.get('copado__Version_number__c'), 'Version number should match here');
            Assert.areEqual('tagTest', versionRecord.get('copado__Tag__c'), 'Tag should match here');
            Assert.areEqual('ver 0.1', versionRecord.get('copado__Version_Name__c'), 'Version name should match here');
            Assert.areEqual(SUBSCRIBER_VERSION_ID, versionRecord.get('copado__Subscriber_Version_Id__c'), 'Subscriber Id should match here');
            Assert.areEqual(SUBSCRIBER_PACKAGE_ID, versionRecord.get('copado__Package_Version_Id__c'), 'Package Id should match here');
            Assert.areEqual(true, versionRecord.get(getNamespacePrefix() + 'Has_Installation_Key__c'), 'Installation key should be present');
            Assert.isFalse(versionRecord.containsKey('copado__Artifact__c'), 'Package Id should be null');

            PackageVersionCreateAction.DataJson data = (PackageVersionCreateAction.DataJson) JSON.deserialize(
                TestUtilities.getJobExecution(jobExecution.Id).copado__DataJson__c,
                PackageVersionCreateAction.DataJson.class
            );
            PackageVersionCreateAction.JsonInformation jsonInformation = (PackageVersionCreateAction.JsonInformation) JSON.deserialize(
                data.jsonInformation,
                PackageVersionCreateAction.JsonInformation.class
            );
            Assert.areEqual('****', jsonInformation.installationkey, 'Installation Key in Data Json of Job Execution should be masked');
        }
    }

    @IsTest
    private static void payloadWithoutVersionId() {
        System.runAs(TestUtilities.getRunAsUser()) {
            //SETUP

            String packageId = getPackage().Id;
            SObject jobExecution = TestUtilities.createJobExecution(
                    TestUtilities.getTemplateObj('SFDX Package Version Create'),
                    TestUtilities.getEnvironmentObj('Test Environment'),
                    getDataJson('Test Description', null)
                )
                .persist();

            // EXERCISE

            Test.startTest();
            List<PackageVersionCreateAction.Response> response = PackageVersionCreateAction.execute(
                createRequest(DESCRIPTION_WITH_SPECIAL_CHARS, null, jobExecution.Id)
            );
            Test.stopTest();

            // VERIFY

            Map<String, Object> versionRecord = (Map<String, Object>) JSON.deserializeUntyped(response[0].version.unescapeJava());

            Assert.areEqual(DESCRIPTION_WITH_SPECIAL_CHARS, versionRecord.get('copado__Version_Description__c'), 'Description should match here');
            Assert.areEqual('Testpkg - 0.1.0.4', versionRecord.get('Name'), 'Name should match here');
            Assert.areEqual('0.1.0.4', versionRecord.get('copado__Version_number__c'), 'Version number should match here');
            Assert.areEqual('tagTest', versionRecord.get('copado__Tag__c'), 'Tag should match here');
            Assert.areEqual('ver 0.1', versionRecord.get('copado__Version_Name__c'), 'Version name should match here');
            Assert.areEqual(SUBSCRIBER_VERSION_ID, versionRecord.get('copado__Subscriber_Version_Id__c'), 'Subscriber Id should match here');
            Assert.areEqual(SUBSCRIBER_PACKAGE_ID, versionRecord.get('copado__Package_Version_Id__c'), 'Package Id should match here');
            Assert.areEqual(true, versionRecord.get(getNamespacePrefix() + 'Has_Installation_Key__c'), 'Installation key should be present');
            Assert.isTrue(versionRecord.containsKey('copado__Artifact__c'), 'Package Id should be null');
            Assert.areEqual(packageId, versionRecord.get('copado__Artifact__c'), 'Package Id should be null');

            PackageVersionCreateAction.DataJson data = (PackageVersionCreateAction.DataJson) JSON.deserialize(
                TestUtilities.getJobExecution(jobExecution.Id).copado__DataJson__c,
                PackageVersionCreateAction.DataJson.class
            );
            PackageVersionCreateAction.JsonInformation jsonInformation = (PackageVersionCreateAction.JsonInformation) JSON.deserialize(
                data.jsonInformation,
                PackageVersionCreateAction.JsonInformation.class
            );
            Assert.areEqual('****', jsonInformation.installationkey, 'Installation Key in Data Json of Job Execution should be masked');
        }
    }

    @IsTest
    private static void invalidPayload() {
        System.runAs(TestUtilities.getRunAsUser()) {
            //SETUP

            String exceptionMessage;
            SObject jobExecution = TestUtilities.createJobExecution(
                    TestUtilities.getTemplateObj('SFDX Package Version Create'),
                    TestUtilities.getEnvironmentObj('Test Environment'),
                    getDataJson('Test Description', null)
                )
                .persist();

            // EXERCISE

            try {
                Test.startTest();
                PackageVersionCreateAction.execute(createInvalidRequest());
                Test.stopTest();
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY

            Assert.isTrue(exceptionMessage.contains('For input string'), 'Exception should be thrown');
            
            PackageVersionCreateAction.DataJson data = (PackageVersionCreateAction.DataJson) JSON.deserialize(
                TestUtilities.getJobExecution(jobExecution.Id).copado__DataJson__c,
                PackageVersionCreateAction.DataJson.class
            );
            PackageVersionCreateAction.JsonInformation jsonInformation = (PackageVersionCreateAction.JsonInformation) JSON.deserialize(
                data.jsonInformation,
                PackageVersionCreateAction.JsonInformation.class
            );
            Assert.areEqual('installation key final check', jsonInformation.installationkey, 'Installation Key in Data Json of Job Execution should be masked');
        }
    }

    private static String getNamespacePrefix() {
        String namespacePrefix = TestUtilities.getNamespacePrefix();
        return String.isNotBlank(namespacePrefix) ? namespacePrefix + '__' : namespacePrefix;
    }

    private static List<PackageVersionCreateAction.Request> createRequest(String description, String versionId, String jobExecutionId) {
        PackageVersionCreateAction.Request request = new PackageVersionCreateAction.Request();

        request.jobExecutionId = jobExecutionId;
        request.jsonInformation = getDataJson(description, versionId);

        request.packageVersionJson =
            '{"Package2Id":' +
            getPackage().copado__Package_Id__c +
            ',"Branch":"master","Tag":"tagTest","MajorVersion":0,"MinorVersion":1,"PatchVersion":0,"BuildNumber":4,"Id":"' +
            SUBSCRIBER_PACKAGE_ID +
            '","SubscriberPackageVersionId":"' +
            SUBSCRIBER_VERSION_ID +
            '","ConvertedFromVersionId":null,"Name":"ver 0.1","NamespacePrefix":null,"Package2Name":"test Pckg","Description":"' +
            description +
            '","Version":"0.1.0.4","IsPasswordProtected":true,"IsReleased":false,"CreatedDate":"2022-10-18 14:06","LastModifiedDate":"2022-10-18 14:06","InstallUrl":"https://login.salesforce.com/packaging/installPackage.apexp?p0=04t5g000000QzoyAAC","CodeCoverage":"","HasPassedCodeCoverageCheck":false,"ValidationSkipped":false,"AncestorId":"N/A","AncestorVersion":"N/A","Alias":"testPckg@0.1.0-4-master","IsOrgDependent":"No","ReleaseVersion":"56.0","BuildDurationInSeconds":56,"HasMetadataRemoved":"N/A","CreatedBy":"0055g00000F7fLhAAJ"}';
        return new List<PackageVersionCreateAction.Request>{ request };
    }

    private static List<PackageVersionCreateAction.Request> createInvalidRequest() {
        PackageVersionCreateAction.Request request = new PackageVersionCreateAction.Request();
        request.jsonInformation = '{"apiversion":null,"tag":null,"postinstallscript":null,"skipvalidation":false,"uninstallscript":null,"postinstallurl":null,"releasenotesurl":null,"versiondescription":"comma \' in desc","installationkeybypass":false,"installationkey":"comma \' in install key","codecoverage":false,"definitionfile":null,"branch":"master","versionId":null}';
        request.packageVersionJson =
            '{"Package2Id":' +
            getPackage().copado__Package_Id__c +
            ',"Branch":"master","Tag":"tagTest","MajorVersion":","BuildNumber":4,"Id":"' +
            SUBSCRIBER_PACKAGE_ID +
            '","SubscriberPackageVersionId":"' +
            SUBSCRIBER_VERSION_ID +
            '","Package2Name":"test17Oct","Description":"comma \' in desc","HasMetadataRemoved":"N/A","CreatedBy":"0055g00000F7fLhAAJ"}';
        return new List<PackageVersionCreateAction.Request>{ request };
    }

    private static void createData() {
        Repository repo = createRepository();
        createPackageVersion(createPackage(repo, 'Unlocked')).persist();
        TestUtilities.createJobTemplate('SFDX Package Version Create').persist();
        TestUtilities.createEnvironment('Test Environment').persist();
    }

    private static String getDataJson(String description, String versionId) {
        return '{"versionNumber":null,"versionName":null,"packageId":"a057Q000008dDMXQA2","jsonInformation":"{\\"apiversion\\":null,\\"tag\\":null,\\"postinstallscript\\":null,\\"skipvalidation\\":false,\\"uninstallscript\\":null,\\"postinstallurl\\":null,\\"releasenotesurl\\":null,\\"versiondescription\\":\\"' +
            description +
            '\\",\\"installationkeybypass\\":false,\\"installationkey\\":\\"installation key final check\\",\\"codecoverage\\":false,\\"definitionfile\\":null,\\"branch\\":\\"master\\",\\"versionId\\":' +
            versionId +
            '}","description":"","actionCallback":null}';
    }

    private static Artifact createPackage(Repository repo, String type) {
        return new Artifact(repo).name('Testpkg').type(type).recordTypeId('Package_Artifact');
    }

    private static ArtifactVersion createPackageVersion(Artifact pkg) {
        return new ArtifactVersion(pkg).name('ver 0.1').versionNumber('0.1.0.1').versionId(SUBSCRIBER_VERSION_ID).description('comma \'');
    }

    private static Repository createRepository() {
        return new Repository().name('My Repo');
    }

    private static copado__Artifact__c getPackage() {
        return [
            SELECT Name, copado__Package_Type__c, copado__Artifact_Repository__c, copado__Package_Id__c, RecordTypeId
            FROM copado__Artifact__c
            LIMIT 1
        ];
    }
}