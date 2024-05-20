@IsTest
private class PipelineSaveSelectionsImplTest {

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
                PipelineInitializer.Selections.save(request);
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
                user.Id, environmentId, getMetadataGroups()
            );

            // EXERCISE
            Test.startTest();
            try {
                PipelineInitializer.Selections.save(request);
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
                pipelineId, environmentId, getMetadataGroups()
            );

            // EXERCISE
            Test.startTest();
            try {
                PipelineInitializer.Selections.save(request);
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
    private static void executeToCreateFileWithNoExistingFile() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;
            Id environmentId = [SELECT Id FROM copado__Environment__c LIMIT 1].Id;
            PipelineInitializer.SelectionsSaveRequest request = new PipelineInitializer.SelectionsSaveRequest(
                pipelineId, environmentId, getMetadataGroups()
            );

            // EXERCISE
            Test.startTest();
            PipelineInitializer.SelectionsSaveResult response = PipelineInitializer.Selections.save(request);
            Test.stopTest();

            // VERIFY
            List<ContentDocumentLink> contentDocumentLinks = [SELECT Id, ContentDocument.Title, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :environmentId];
            PipelineInitializerSaveSelectionsImpl.MetadataGroups groupsInFile = getExistingMetadataGroupsFromFile(contentDocumentLinks[0].ContentDocumentId);

            Assert.isNotNull(response, 'Response is null.');
            Assert.areEqual(1, contentDocumentLinks.size(), 'The number of files do not match.');
            Assert.areEqual(pipelineId + '_' + environmentId + '_' + SELECTED_METADATA, contentDocumentLinks[0].ContentDocument.Title, 'The title does not match.');
            Assert.areEqual(1, groupsInFile.metadataGroups.size(), 'The number of metadata groups do not match');
            Assert.areEqual('Create Initialization Class', groupsInFile.metadataGroups[0].groupName, 'The group name does not match');
        }
    }

    @IsTest
    private static void executeToCreateFileWithExistingFile() {
        System.runAs(TestUtilities.getRunAsUser()) {

            // SETUP
            Id pipelineId = [SELECT Id FROM copado__Deployment_Flow__c].Id;
            Id environmentId = [SELECT Id FROM copado__Environment__c LIMIT 1].Id;
            String fileTitle = pipelineId + '_' + environmentId + '_' + SELECTED_METADATA;
            createFile(fileTitle, environmentId);

            PipelineInitializer.SelectionsSaveRequest request = new PipelineInitializer.SelectionsSaveRequest(
                pipelineId, environmentId, getMetadataGroups()
            );

            List<ContentDocumentLink> currentContentDocumentLinks = [SELECT Id, ContentDocument.Title, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :environmentId];
            Assert.areEqual(1, currentContentDocumentLinks.size(), 'The number of files do not match.');

            // EXERCISE
            Test.startTest();
            PipelineInitializer.SelectionsSaveResult response = PipelineInitializer.Selections.save(request);
            Test.stopTest();

            // VERIFY
            List<ContentDocumentLink> contentDocumentLinks = [SELECT Id, ContentDocument.Title, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :environmentId];
            PipelineInitializerSaveSelectionsImpl.MetadataGroups groupsInFile = getExistingMetadataGroupsFromFile(contentDocumentLinks[0].ContentDocumentId);

            Assert.isNotNull(response, 'Response is null.');
            Assert.areEqual(1, contentDocumentLinks.size(), 'The number of files do not match.');
            Assert.areEqual(fileTitle, contentDocumentLinks[0].ContentDocument.Title, 'The title does not match.');
            Assert.areEqual(1, groupsInFile.metadataGroups.size(), 'The number of metadata groups do not match');
            Assert.areEqual('Create Initialization Class', groupsInFile.metadataGroups[0].groupName, 'The group name does not match');
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