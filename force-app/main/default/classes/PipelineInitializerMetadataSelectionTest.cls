@IsTest
private class PipelineInitializerMetadataSelectionTest {
    private static final String SELECTED_METADATA = 'Selected Metadata';
    private static final String DIFFERENCE_METADATA = 'DifferenceMetadata';

    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void executeWithNoExistingFile() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;
            Id environmentId = [SELECT Id FROM copado__Environment__c LIMIT 1].Id;

            PipelineInitializerMetadataSelection.EnvironmentSelectionsRequest selectionsRequest = new PipelineInitializerMetadataSelection.EnvironmentSelectionsRequest();
            selectionsRequest.groupTitle = 'Create Initialization Class';
            selectionsRequest.groupDescription = 'Description of Create Initialization Class';
            selectionsRequest.pipelineId = pipelineId;
            selectionsRequest.environmentId = environmentId;
            selectionsRequest.changes = getChanges();

            String request = JSON.serialize(selectionsRequest);

            // EXERCISE
            Test.startTest();
            String response = PipelineInitializerMetadataSelection.saveSelectionsOnEnvironment(request);
            Test.stopTest();

            // VERIFY
            List<ContentDocumentLink> contentDocumentLinks = [SELECT Id, ContentDocument.Title, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :environmentId];
            PipelineInitializerSaveSelectionsImpl.MetadataGroups groupsInFile = getExistingMetadataGroupsFromFile(contentDocumentLinks[0].ContentDocumentId);

            Assert.isNotNull(response, 'Response is null.');
            Assert.areEqual(contentDocumentLinks[0].Id, response, 'The file Id does not match.');
            Assert.areEqual(1, contentDocumentLinks.size(), 'The number of files do not match.');
            Assert.areEqual(pipelineId + '_' + environmentId + '_' + SELECTED_METADATA, contentDocumentLinks[0].ContentDocument.Title, 'The title does not match.');
            Assert.areEqual(1, groupsInFile.metadataGroups.size(), 'The number of metadata groups do not match');
            Assert.areEqual('Create Initialization Class', groupsInFile.metadataGroups[0].groupName, 'The group name does not match');
        }
    }

    @IsTest
    private static void executeWithExistingFile() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;
            Id environmentId = [SELECT Id FROM copado__Environment__c LIMIT 1].Id;
            String fileTitle = pipelineId + '_' + environmentId + '_' + SELECTED_METADATA;
            createFile(fileTitle, environmentId);

            List<ContentDocumentLink> currentContentDocumentLinks = [SELECT Id, ContentDocument.Title, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :environmentId];
            Assert.areEqual(1, currentContentDocumentLinks.size(), 'The number of files do not match.');

            PipelineInitializerMetadataSelection.EnvironmentSelectionsRequest selectionsRequest = new PipelineInitializerMetadataSelection.EnvironmentSelectionsRequest();
            selectionsRequest.groupTitle = 'Create Data Model Class';
            selectionsRequest.groupDescription = 'Description of schema';
            selectionsRequest.pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;
            selectionsRequest.environmentId = [SELECT Id FROM copado__Environment__c LIMIT 1].Id;
            selectionsRequest.changes = getChanges();

            String request = JSON.serialize(selectionsRequest);


            // EXERCISE
            Test.startTest();
            String response = PipelineInitializerMetadataSelection.saveSelectionsOnEnvironment(request);
            Test.stopTest();

            // VERIFY
            List<ContentDocumentLink> contentDocumentLinks = [SELECT Id, ContentDocument.Title, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :environmentId];
            PipelineInitializerSaveSelectionsImpl.MetadataGroups groupsInFile = getExistingMetadataGroupsFromFile(contentDocumentLinks[0].ContentDocumentId);

            Assert.isNotNull(response, 'Response is null.');
            Assert.areEqual(1, contentDocumentLinks.size(), 'The number of files do not match.');
            Assert.areEqual(contentDocumentLinks[0].Id, response, 'The file Id does not match.');
            Assert.areEqual(fileTitle, contentDocumentLinks[0].ContentDocument.Title, 'The title does not match.');
            Assert.areEqual(2, groupsInFile.metadataGroups.size(), 'The number of metadata groups do not match');
        }
    }

    @IsTest
    private static void fetchIndexFileWithNoExistingFile() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;
            Id environmentId = [SELECT Id FROM copado__Environment__c LIMIT 1].Id;
            String exceptionMessage;

            // EXERCISE
            Test.startTest();
            try {
                PipelineInitializerMetadataSelection.getIndexFilesForDifferenceGrid(environmentId, pipelineId);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // VERIFY
            Assert.isNotNull(exceptionMessage, 'There is no exception');
            Assert.areEqual(Label.Failure_Fetching_File, exceptionMessage, 'The exception message does not match');
        }
    }

    @IsTest
    private static void fetchIndexFileWithExistingFile() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;
            Id environmentId = [SELECT Id FROM copado__Environment__c LIMIT 1].Id;
            String fileTitle = pipelineId + '_' + environmentId + '_' + DIFFERENCE_METADATA;
            createFile(fileTitle, environmentId);

            // EXERCISE
            Test.startTest();
            List<Id> response = PipelineInitializerMetadataSelection.getIndexFilesForDifferenceGrid(environmentId, pipelineId);
            Test.stopTest();

            // VERIFY
            Assert.isNotNull(response, 'The response is null');
            Assert.areEqual(1, response.size(), 'The size of the list does not match');
            Assert.areEqual([SELECT Id FROM ContentVersion].Id, response[0], 'The content version Id does not match');
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

    private static List<PipelineInitializer.MetadataGroup> getMetadataGroups() {
        copado.Actions.CommitChange change = new copado.Actions.CommitChange();
        change.t = 'ApexClass';
        change.n = 'CopadoDomain';
        change.m = 'File path is handled automatically';
        change.c = 'SFDX';
        change.a = 'Add';

        List<copado.Actions.CommitChange> changes = new List<copado.Actions.CommitChange> { change };

        List<PipelineInitializer.MetadataGroup> metadataGroups = new List<PipelineInitializer.MetadataGroup>();

        PipelineInitializer.MetadataGroup group1 = new PipelineInitializer.MetadataGroup();
        group1.groupName = 'Create Initialization Class';
        group1.groupDescription = 'Description of Create Initialization Class';
        group1.selectedMetadata = changes;

        metadataGroups.add(group1);

        return metadataGroups;
    }

    private static List<copado.Actions.CommitChange> getChanges() {
        copado.Actions.CommitChange change = new copado.Actions.CommitChange();
        change.t = 'CustomObject';
        change.n = 'SampleObject_c';
        change.m = 'File path is handled automatically';
        change.c = 'SFDX';
        change.a = 'Add';

        return new List<copado.Actions.CommitChange> { change };
    }

    private static PipelineInitializerSaveSelectionsImpl.MetadataGroups getExistingMetadataGroupsFromFile(Id contentDocumentId) {
        String fileContent = new ContentVersionsSelector()
                .byContentDocumentIdWithLatest(new Set<Id>{ contentDocumentId })[0].VersionData.toString();

        return (PipelineInitializerSaveSelectionsImpl.MetadataGroups) JSON.deserialize(fileContent, PipelineInitializerSaveSelectionsImpl.MetadataGroups.class);
    }

    private static Id createFile(String title, Id recordId) {
        ContentVersion fileVersion = (ContentVersion) new ContentVersion_t()
            .firstPublishLocationId(recordId)
            .title(title)
            .pathOnClient(title)
            .versionData(Blob.valueOf(JSON.serializePretty(new PipelineInitializerSaveSelectionsImpl.MetadataGroups(getMetadataGroups()))))
            .persist();
        return fileVersion.ContentDocumentId;
    }
}