@IsTest
private class PipelineInitializerDeleteMetadataTest {
    
    private static final String SELECTED_METADATA = 'Selected Metadata';

    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void executeWithIncompleteRequest() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            String exceptionMessage;

            // EXERCISE
            Test.startTest();
            try {
                PipelineInitializerDeleteMetadataGroup.removeMetadataGroup(null, null, '');
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // VERIFY
            Assert.isNotNull(exceptionMessage, 'There is no exception');
            Assert.areEqual('Script-thrown exception', exceptionMessage, 'There is a different exception');
        }
    }

    @IsTest
    private static void executeToRemoveGroupFromExistingFile() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;
            Id environmentId = [SELECT Id FROM copado__Environment__c LIMIT 1].Id;
            String fileTitle = pipelineId + '_' + environmentId + '_' + SELECTED_METADATA;

            List<PipelineInitializer.MetadataGroup> metadataGroupsForFileCreation = getMetadataGroups('ExecuteLogs', 'Create new class', 'This new class handles execution logic.');
            metadataGroupsForFileCreation.addAll(getMetadataGroups('AddTest', 'Write Unit Tests', 'This new class has the unit tests.'));
            metadataGroupsForFileCreation.addAll(getMetadataGroups('RetrieveSourceEnvironment', 'Logic to fetch source', 'This new class fetches the source environment.'));

            createFile(fileTitle, environmentId, JSON.serializePretty(new PipelineInitializerSaveSelectionsImpl.MetadataGroups(metadataGroupsForFileCreation)));

            // Note : Asserting current file
            List<ContentDocumentLink> currentContentDocumentLinks = [SELECT Id, ContentDocument.Title, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :environmentId];
            PipelineInitializerSaveSelectionsImpl.MetadataGroups currentGroupsInFile = getExistingMetadataGroupsFromFile(currentContentDocumentLinks[0].ContentDocumentId);
            Assert.areEqual(1, currentContentDocumentLinks.size(), 'The number of files do not match.');
            Assert.areEqual(3, currentGroupsInFile.metadataGroups.size(), 'The number of metadata groups do not match');

            // EXERCISE
            Test.startTest();
            Id result = PipelineInitializerDeleteMetadataGroup.removeMetadataGroup(pipelineId, environmentId, 'Write Unit Tests');
            Test.stopTest();

            // VERIFY
            List<ContentDocumentLink> contentDocumentLinks = [SELECT Id, ContentDocument.Title, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :environmentId];
            PipelineInitializerSaveSelectionsImpl.MetadataGroups groupsInFile = getExistingMetadataGroupsFromFile(contentDocumentLinks[0].ContentDocumentId);
            Set<String> groupNames = new Set<String>{ 'Create new class', 'Logic to fetch source' };

            Assert.isNotNull(result, 'Result is null.');
            Assert.areEqual(1, contentDocumentLinks.size(), 'The number of files do not match.');
            Assert.areEqual(fileTitle, contentDocumentLinks[0].ContentDocument.Title, 'The title does not match.');
            Assert.areEqual(2, groupsInFile.metadataGroups.size(), 'The number of metadata groups do not match');
            Assert.isTrue(groupNames.contains(groupsInFile.metadataGroups[0].groupName), 'The group name does not match with input data');
            Assert.isTrue(groupNames.contains(groupsInFile.metadataGroups[1].groupName), 'The group name does not match with input data');
            Assert.areNotEqual('Write Unit Tests', groupsInFile.metadataGroups[0].groupName, 'The deleted group name matches');
            Assert.areNotEqual('Write Unit Tests', groupsInFile.metadataGroups[1].groupName, 'The deleted group name matches');
        }
    }

    @IsTest
    private static void executeToRemoveGroupNotPresentInFile() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;
            Id environmentId = [SELECT Id FROM copado__Environment__c LIMIT 1].Id;
            String fileTitle = pipelineId + '_' + environmentId + '_' + SELECTED_METADATA;

            List<PipelineInitializer.MetadataGroup> metadataGroupsForFileCreation = getMetadataGroups('ExecuteLogs', 'Create new class', 'This new class handles execution logic.');
            metadataGroupsForFileCreation.addAll(getMetadataGroups('AddTest', 'Write Unit Tests', 'This new class has the unit tests.'));
            metadataGroupsForFileCreation.addAll(getMetadataGroups('RetrieveSourceEnvironment', 'Logic to fetch source', 'This new class fetches the source environment.'));

            createFile(fileTitle, environmentId, JSON.serializePretty(new PipelineInitializerSaveSelectionsImpl.MetadataGroups(metadataGroupsForFileCreation)));

            // Note : Asserting current file
            List<ContentDocumentLink> currentContentDocumentLinks = [SELECT Id, ContentDocument.Title, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :environmentId];
            PipelineInitializerSaveSelectionsImpl.MetadataGroups currentGroupsInFile = getExistingMetadataGroupsFromFile(currentContentDocumentLinks[0].ContentDocumentId);
            Assert.areEqual(1, currentContentDocumentLinks.size(), 'The number of files do not match.');
            Assert.areEqual(3, currentGroupsInFile.metadataGroups.size(), 'The number of metadata groups do not match');

            // EXERCISE
            Test.startTest();
            Id result = PipelineInitializerDeleteMetadataGroup.removeMetadataGroup(pipelineId, environmentId, 'Random group');
            Test.stopTest();

            // VERIFY
            List<ContentDocumentLink> contentDocumentLinks = [SELECT Id, ContentDocument.Title, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :environmentId];
            PipelineInitializerSaveSelectionsImpl.MetadataGroups groupsInFile = getExistingMetadataGroupsFromFile(contentDocumentLinks[0].ContentDocumentId);
            Set<String> groupNames = new Set<String>{ 'Create new class', 'Write Unit Tests', 'Logic to fetch source' };

            Assert.isNotNull(result, 'result is null.');
            Assert.areEqual(1, contentDocumentLinks.size(), 'The number of files do not match.');
            Assert.areEqual(fileTitle, contentDocumentLinks[0].ContentDocument.Title, 'The title does not match.');
            Assert.areEqual(3, groupsInFile.metadataGroups.size(), 'The number of metadata groups do not match');
            Assert.isTrue(groupNames.contains(groupsInFile.metadataGroups[0].groupName), 'The group name does not match with input data');
            Assert.isTrue(groupNames.contains(groupsInFile.metadataGroups[1].groupName), 'The group name does not match with input data');
            Assert.isTrue(groupNames.contains(groupsInFile.metadataGroups[2].groupName), 'The group name does not match with input data');
        }
    }

    // HELPER

    private static void createData() {
        System.runAs(TestUtilities.getRunAsUser()) {
            Environment dev1 = new Environment().name('Dev1');
            Environment staging = new Environment().name('Staging');
            new Credential(dev1);
            new Credential(staging);

            new Pipeline()
                .name('MyPipeline')
                .mainBranch('main')
                .platform('SFDX')
                .add(new Project())
                .add(new PipelineConnection().sourceEnvironment(dev1).destinationEnvironment(staging).destinationBranch('staging').branch('dev1'))
            .persist();
        }
    }

    private static List<PipelineInitializer.MetadataGroup> getMetadataGroups(String metadataName, String groupName, String groupDescription) {
        copado.Actions.CommitChange change = new copado.Actions.CommitChange();
        change.t = 'ApexClass';
        change.n = metadataName;
        change.m = 'File path is handled automatically';
        change.c = 'SFDX';
        change.a = 'Add';

        List<copado.Actions.CommitChange> changes = new List<copado.Actions.CommitChange> { change };

        List<PipelineInitializer.MetadataGroup> metadataGroups = new List<PipelineInitializer.MetadataGroup>();

        PipelineInitializer.MetadataGroup group1 = new PipelineInitializer.MetadataGroup();
        group1.groupName = groupName;
        group1.groupDescription = groupDescription;
        group1.selectedMetadata = changes;

        metadataGroups.add(group1);

        return metadataGroups;
    }

    private static PipelineInitializerSaveSelectionsImpl.MetadataGroups getExistingMetadataGroupsFromFile(Id contentDocumentId) {
        String fileContent = new ContentVersionsSelector()
                .byContentDocumentIdWithLatest(new Set<Id>{ contentDocumentId })[0].VersionData.toString();

        return (PipelineInitializerSaveSelectionsImpl.MetadataGroups) JSON.deserialize(fileContent, PipelineInitializerSaveSelectionsImpl.MetadataGroups.class);
    }

    private static Id createFile(String title, Id recordId, String body) {
        ContentVersion fileVersion = (ContentVersion) new ContentVersion_t()
            .firstPublishLocationId(recordId)
            .title(title)
            .pathOnClient(title)
            .versionData(Blob.valueOf(body))
            .persist();
        return fileVersion.ContentDocumentId;
    }
}