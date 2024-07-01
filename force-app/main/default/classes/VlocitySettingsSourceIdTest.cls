@IsTest
private class VlocitySettingsSourceIdTest {
    private final static String VLOCITY_SETTINGS_YAML_FILE = 'vlocity-settings';

    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    private static void createData() {
        TestUtilities.createEnvironment('Env1');
        JobTemplate template = TestUtilities.createJobTemplate('SFDX Vlocity Commit');
        TestUtilities.createJobStep(template, 'Vlocity Commit', 'Function').persist();
    }

    @IsTest
    private static void getVlocitySettingsSourceId() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            Id envId = TestUtilities.getEnvironment('Env1').Id;
            createJobExecution(TestUtilities.getTemplateObj('SFDX Vlocity Commit'), TestUtilities.getEnvironmentObj('Env1'));
            createContentVersionOn('retrieve', VLOCITY_SETTINGS_YAML_FILE, envId);

            // EXERCISE

            Test.startTest();
            String result = (new VlocitySettingsSourceId()).execute(getJobStep('Vlocity Commit')?.Id);
            Test.stopTest();

            // VERIFY

           Assert.areEqual(getContentVersion(VLOCITY_SETTINGS_YAML_FILE).Id, result, 'should successfully get vlocity-settings.yaml content version id');
        }
    }

    private static void createContentVersionOn(String data, String fileName, Id linkedEntityId) {
        ContentVersion contentVersion = new ContentVersion(
            Title = fileName,
            origin = 'C',
            PathOnClient = fileName,
            VersionData = Blob.valueOf(data)
        );
        insert contentVersion;

        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id LIMIT 1].ContentDocumentId;
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(LinkedEntityId = linkedEntityId, ContentDocumentId = contentDocumentId);
        insert contentDocumentLink;
    }

    private static List<ContentDocumentLink> getContentDocumentLink(Id recordId) {
        return new ContentDocumentLinksSelector().byLinkedEntityIdAndTitles(new Set<Id>{ recordId }, new Set<String>{ VLOCITY_SETTINGS_YAML_FILE });
    }

    private static void createJobExecution(JobTemplate template, Environment env) {
        new JobExecution(template, env).source(env).status('In Progress').add(getJobStepObj('Vlocity Commit')).persist();
    }

    private static copado__JobExecution__c getJobExecution() {
        return [SELECT Id,copado__Destination__c, copado__Source__c, Name, copado__Status__c  FROM copado__JobExecution__c LIMIT 1];
    }

    private static JobStep getJobStepObj(String name) {
        return new JobStep().recordId(getJobStep(name).Id);
    }

    private static copado__JobStep__c getJobStep(String name) {
        return [SELECT Name, Id FROM copado__JobStep__c WHERE Name = :name LIMIT 1];
    }

    private static ContentVersion getContentVersion(String fileName) {
        return [ Select Id from contentversion where Title =: fileName LIMIT 1];
    }
}