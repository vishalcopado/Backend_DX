@IsTest
private class AddMetadataGroupImplTest {

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
            PipelineInitializer.SelectionsSaveRequest request = new PipelineInitializer.SelectionsSaveRequest(
                null, null, new List<PipelineInitializer.MetadataGroup>()
            );

            // EXERCISE
            Test.startTest();
            try {
                PipelineInitializer.Selections.addMetadataGroups(request);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // VERIFY
            Assert.isNotNull(exceptionMessage, 'There is no exception');
            Assert.areEqual(String.format(Label.MissingRequiredParameters, new List<Object>{ String.join(new List<String>{ 'Pipeline Id', 'Environment Id', 'Metadata Groups' }, ', ') }), exceptionMessage, 'There is a different exception');
        }
    }

    @IsTest
    private static void executeWithNonPipelineId() {
        User user = TestUtilities.getRunAsUser();
        System.runAs(user) {

            // SETUP
            String exceptionMessage;
            Id environmentId = [SELECT Id FROM copado__Environment__c LIMIT 1].Id;
            PipelineInitializer.SelectionsSaveRequest request = new PipelineInitializer.SelectionsSaveRequest(
                user.Id, environmentId, getMetadataGroups('ExecuteLogs', 'Create new class', 'This new class handles execution logic.')
            );

            // EXERCISE
            Test.startTest();
            try {
                PipelineInitializer.Selections.addMetadataGroups(request);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // VERIFY
            Assert.isNotNull(exceptionMessage, 'There is no exception');
            Assert.areEqual(Label.NoPipelineFound, exceptionMessage, 'There is a different exception');
        }
    }

    @IsTest
    private static void executeWithNonSfdxPipeline() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            String exceptionMessage;

            new Pipeline()
                .name('OtherPipeline')
                .mainBranch('main')
                .platform('Other')
                .add(new Project())
            .persist();

            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c WHERE Name = 'OtherPipeline' LIMIT 1].Id;
            Id environmentId = [SELECT Id FROM copado__Environment__c LIMIT 1].Id;

            PipelineInitializer.SelectionsSaveRequest request = new PipelineInitializer.SelectionsSaveRequest(
                pipelineId, environmentId, getMetadataGroups('ExecuteLogs', 'Create new class', 'This new class handles execution logic.')
            );

            // EXERCISE
            Test.startTest();
            try {
                PipelineInitializer.Selections.addMetadataGroups(request);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // VERIFY
            Assert.isNotNull(exceptionMessage, 'There is no exception');
            Assert.areEqual(Label.PipelineUnavailableForInitializationMessage, exceptionMessage, 'There is a different exception');
        }
    }

    @IsTest
    private static void executeToAddGroupWithNoExistingFile() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            String exceptionMessage;
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;
            Id environmentId = [SELECT Id FROM copado__Environment__c LIMIT 1].Id;
            PipelineInitializer.SelectionsSaveRequest request = new PipelineInitializer.SelectionsSaveRequest(
                pipelineId, environmentId, getMetadataGroups('ExecuteLogs', 'Create new class', 'This new class handles execution logic.')
            );

            // EXERCISE
            Test.startTest();
            try {
                PipelineInitializer.Selections.addMetadataGroups(request);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // VERIFY
            Assert.isNotNull(exceptionMessage, 'There is no exception');
            Assert.areEqual(String.format(Label.MissingRequiredParameters, new List<String> { Label.EnvironmentMetadataFile }), exceptionMessage, 'There is a different exception');
        }
    }

    @IsTest
    private static void executeToAddGroupWithExistingFile() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;
            Id environmentId = [SELECT Id FROM copado__Environment__c LIMIT 1].Id;
            String fileTitle = pipelineId + '_' + environmentId + '_' + SELECTED_METADATA;

            List<PipelineInitializer.MetadataGroup> metadataGroupsForFileCreation = getMetadataGroups('ExecuteLogs', 'Create new class', 'This new class handles execution logic.');
            createFile(fileTitle, environmentId, JSON.serializePretty(new PipelineInitializerSaveSelectionsImpl.MetadataGroups(metadataGroupsForFileCreation)));

            List<ContentDocumentLink> currentContentDocumentLinks = [SELECT Id, ContentDocument.Title, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :environmentId];
            Assert.areEqual(1, currentContentDocumentLinks.size(), 'The number of files do not match.');

            PipelineInitializer.SelectionsSaveRequest request = new PipelineInitializer.SelectionsSaveRequest(
                pipelineId, environmentId, getMetadataGroups('RetrieveSourceEnvironment', 'Add a new method', 'This new method will retrieve data.')
            );

            // EXERCISE
            Test.startTest();
            PipelineInitializer.SelectionsSaveResult response = PipelineInitializer.Selections.addMetadataGroups(request);
            Test.stopTest();

            // VERIFY
            List<ContentDocumentLink> contentDocumentLinks = [SELECT Id, ContentDocument.Title, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :environmentId];
            PipelineInitializerSaveSelectionsImpl.MetadataGroups groupsInFile = getExistingMetadataGroupsFromFile(contentDocumentLinks[0].ContentDocumentId);
            Set<String> groupNames = new Set<String>{ 'Create new class', 'Add a new method' };

            Assert.isNotNull(response, 'Response is null.');
            Assert.areEqual(1, contentDocumentLinks.size(), 'The number of files do not match.');
            Assert.areEqual(fileTitle, contentDocumentLinks[0].ContentDocument.Title, 'The title does not match.');
            Assert.areEqual(2, groupsInFile.metadataGroups.size(), 'The number of metadata groups do not match');
            Assert.isTrue(groupNames.contains(groupsInFile.metadataGroups[0].groupName), 'The group name does not match with input data');
            Assert.isTrue(groupNames.contains(groupsInFile.metadataGroups[1].groupName), 'The group name does not match with input data');
        }
    }

    @IsTest
    private static void executeToAddGroupWithSameName() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;
            Id environmentId = [SELECT Id FROM copado__Environment__c LIMIT 1].Id;
            String fileTitle = pipelineId + '_' + environmentId + '_' + SELECTED_METADATA;

            List<PipelineInitializer.MetadataGroup> metadataGroupsForFileCreation = getMetadataGroups('ExecuteLogs', 'Create new class', 'This new class handles execution logic.');
            createFile(fileTitle, environmentId, JSON.serializePretty(new PipelineInitializerSaveSelectionsImpl.MetadataGroups(metadataGroupsForFileCreation)));

            List<ContentDocumentLink> currentContentDocumentLinks = [SELECT Id, ContentDocument.Title, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :environmentId];
            Assert.areEqual(1, currentContentDocumentLinks.size(), 'The number of files do not match.');

            PipelineInitializer.SelectionsSaveRequest request = new PipelineInitializer.SelectionsSaveRequest(
                pipelineId, environmentId, getMetadataGroups('RetrieveSourceEnvironment', 'Create new class', 'This new method will retrieve data.')
            );

            // EXERCISE
            Test.startTest();
            PipelineInitializer.SelectionsSaveResult response = PipelineInitializer.Selections.addMetadataGroups(request);
            Test.stopTest();

            // VERIFY
            List<ContentDocumentLink> contentDocumentLinks = [SELECT Id, ContentDocument.Title, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :environmentId];
            PipelineInitializerSaveSelectionsImpl.MetadataGroups groupsInFile = getExistingMetadataGroupsFromFile(contentDocumentLinks[0].ContentDocumentId);

            Assert.isNotNull(response, 'Response is null.');
            Assert.areEqual(1, contentDocumentLinks.size(), 'The number of files do not match.');
            Assert.areEqual(fileTitle, contentDocumentLinks[0].ContentDocument.Title, 'The title does not match.');
            Assert.areEqual(1, groupsInFile.metadataGroups.size(), 'The number of metadata groups do not match');
            Assert.areEqual('Create new class', groupsInFile.metadataGroups[0].groupName, 'The group name does not match with input data');
            Assert.areEqual('This new method will retrieve data.', groupsInFile.metadataGroups[0].groupDescription, 'The group description does not match with input data');
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