@IsTest
private class UserStoryMetadataTriggerTest {
    @TestSetup
    private static void setUp() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            makeData();
        }
    }

    @IsTest
    private static void insertMetadataWithApex() {
        // SETUP

        // EXERCISE
        System.runAs(TestUtilities.getRunAsUser()) {
            insertMetadataTypes(TYPES_WITH_APEX);
        }

        // VERIFY
        copado__User_Story__c assertStory = getStory();

        Assert.areEqual(true, assertStory.copado__Has_Apex_Code__c, 'Story has Apex Code but field is not properly filled');
        Assert.isTrue(TYPES_WITH_APEX.containsAll(assertStory.copado__Metadata_Types_in_Selection__c.split(';')), 'Metadata types does not match');
    }

    @IsTest
    private static void insertMetadataWithOutApex() {
        // SETUP

        // EXERCISE
        System.runAs(TestUtilities.getRunAsUser()) {
            insertMetadataTypes(TYPES_WITHOUT_APEX);
        }

        // VERIFY
        copado__User_Story__c assertStory = getStory();

        Assert.areEqual(false, assertStory.copado__Has_Apex_Code__c, 'Story has NOT Apex Code but field is not properly filled');
        Assert.isTrue(TYPES_WITHOUT_APEX.containsAll(assertStory.copado__Metadata_Types_in_Selection__c.split(';')), 'Metadata types does not match');
    }

    @IsTest
    private static void modifyMetadata() {
        // SETUP
        List<copado__User_Story_Metadata__c> types = insertMetadataTypes(TYPES_WITH_APEX);

        // EXERCISE
        System.runAs(TestUtilities.getRunAsUser()) {
            for (copado__User_Story_Metadata__c record : types) {
                if (record.copado__Type__c == 'ApexClass' || record.copado__Type__c == 'ApexTrigger') {
                    record.copado__Type__c = 'StaticResource';
                }
            }
            update types;
        }

        // VERIFY
        copado__User_Story__c assertStory = getStory();

        Assert.areEqual(false, assertStory.copado__Has_Apex_Code__c, 'Story has Apex Code but field is not properly filled');
        Assert.isTrue(TYPES_WITHOUT_APEX.containsAll(assertStory.copado__Metadata_Types_in_Selection__c.split(';')), 'Metadata types does not match');
    }

    @IsTest
    private static void deleteMetadata() {
        // SETUP
        List<copado__User_Story_Metadata__c> types = insertMetadataTypes(TYPES_WITH_APEX);
        List<copado__User_Story_Metadata__c> typesToDelete = new List<copado__User_Story_Metadata__c>();
        // EXERCISE
        System.runAs(TestUtilities.getRunAsUser()) {
            for (copado__User_Story_Metadata__c record : types) {
                if (record.copado__Type__c == 'ApexClass' || record.copado__Type__c == 'ApexTrigger') {
                    typesToDelete.add(record);
                }
            }
            delete typesToDelete;
        }

        // VERIFY
        copado__User_Story__c assertStory = getStory();

        Assert.areEqual(false, assertStory.copado__Has_Apex_Code__c, 'Story has Apex Code but field is not properly filled');
        Assert.isTrue(TYPES_WITHOUT_APEX.containsAll(assertStory.copado__Metadata_Types_in_Selection__c.split(';')), 'Metadata types does not match');
    }

    @IsTest
    private static void deleteAllMetadata() {
        // SETUP
        List<copado__User_Story_Metadata__c> types = insertMetadataTypes(TYPES_WITH_APEX);

        // EXERCISE
        System.runAs(TestUtilities.getRunAsUser()) {
            delete types;
        }

        // VERIFY
        copado__User_Story__c assertStory = getStory();

        Assert.areEqual(false, assertStory.copado__Has_Apex_Code__c, 'Story has Apex Code but field is not properly filled');
        Assert.isTrue(String.isBlank(assertStory.copado__Metadata_Types_in_Selection__c), 'Metadata types should be empty');
    }

    @IsTest
    private static void retrieveOnlyMetadata() {
        // SETUP

        // EXERCISE
        System.runAs(TestUtilities.getRunAsUser()) {
            copado__User_Story__c story = getStory();

            copado__User_Story_Metadata__c apexReadOnly = newMetadata(story.Id, 'ApexClass');
            apexReadOnly.copado__Action__c = 'RetrieveOnly';

            copado__User_Story_Metadata__c customLabel = newMetadata(story.Id, 'CustomLabel');

            insert new List<copado__User_Story_Metadata__c>{ apexReadOnly, customLabel };
        }

        // VERIFY
        copado__User_Story__c assertStory = getStory();

        Assert.areEqual(false, assertStory.copado__Has_Apex_Code__c, 'Story has retriebeOnly Apex Code field must be FALSE');
        Assert.areEqual('CustomLabel', assertStory.copado__Metadata_Types_in_Selection__c, 'Metadata types does not match');
    }

    @IsTest
    private static void insertMetadataWithApexWithExistingMetadataTypes() {
        // SETUP

        copado__User_Story__c userStory = getStory();
        userStory.copado__Has_Apex_Code__c = false;
        userStory.copado__Metadata_Types_in_Selection__c = String.join(new List<String>(TYPES_WITH_APEX), ';');
        update userStory;

        // EXERCISE
        System.runAs(TestUtilities.getRunAsUser()) {
            insertMetadataTypes(TYPES_WITH_APEX);
        }

        // VERIFY
        copado__User_Story__c assertStory = getStory();

        Assert.areEqual(true, assertStory.copado__Has_Apex_Code__c, 'Story has Apex Code but field is not properly filled');
        Assert.isTrue(TYPES_WITH_APEX.containsAll(assertStory.copado__Metadata_Types_in_Selection__c.split(';')), 'Metadata types does not match');
    }

    @IsTest
    private static void insertMetadataWithoutApexWithExistingMetadataTypes() {
        // SETUP

        copado__User_Story__c userStory = getStory();
        userStory.copado__Has_Apex_Code__c = true;
        userStory.copado__Metadata_Types_in_Selection__c = String.join(new List<String>(TYPES_WITHOUT_APEX), ';');
        update userStory;

        // EXERCISE
        System.runAs(TestUtilities.getRunAsUser()) {
            insertMetadataTypes(TYPES_WITHOUT_APEX);
        }

        // VERIFY
        copado__User_Story__c assertStory = getStory();

        Assert.areEqual(false, assertStory.copado__Has_Apex_Code__c, 'Story has Apex Code but field is not properly filled');
        Assert.isTrue(TYPES_WITHOUT_APEX.containsAll(assertStory.copado__Metadata_Types_in_Selection__c.split(';')), 'Metadata types does not match');
    }

    // HELPER

    private static void makeData() {
        copado__Git_Repository__c repository = TestDataFactory.createGitRepository('MyRepo');
        insert repository;

        copado__Deployment_Flow__c pipeline = TestDataFactory.createPipeline('MyPipeline', repository.Id);
        pipeline.copado__Platform__c = 'SFDX';
        insert pipeline;

        copado__Project__c project = TestDataFactory.createProject('MyProject', pipeline.Id);
        insert project;

        copado__User_Story__c story = new copado__User_Story__c(copado__User_Story_Title__c = 'My Story', copado__Project__c = project.Id);
        insert story;
    }

    private static copado__User_Story__c getStory() {
        return [
            SELECT Id, copado__Has_Apex_Code__c, copado__Metadata_Types_in_Selection__c
            FROM copado__User_Story__c
            WHERE copado__User_Story_Title__c = 'My Story'
            LIMIT 1
        ];
    }

    private static List<copado__User_Story_Metadata__c> insertMetadataTypes(Set<String> metadataTypes) {
        copado__User_Story__c story = getStory();
        List<copado__User_Story_Metadata__c> types = new List<copado__User_Story_Metadata__c>();

        for (String type : metadataTypes) {
            copado__User_Story_Metadata__c metadata = newMetadata(story.Id, type);
            types.add(metadata);
        }

        insert types;

        return types;
    }

    private static copado__User_Story_Metadata__c newMetadata(Id storyId, String type) {
        copado__User_Story_Metadata__c metadata = new copado__User_Story_Metadata__c(
            copado__User_Story__c = storyId,
            copado__Metadata_API_Name__c = 'Class',
            copado__Type__c = type,
            copado__Action__c = 'Add'
        );
        return metadata;
    }

    @SuppressWarnings('PMD.FieldNamingConventions, PMD.FieldDeclarationsShouldBeAtStart')
    private static Set<String> TYPES_WITH_APEX = new Set<String>{
        'ApexClass',
        'CustomLabel',
        'StaticResource',
        'ApexTrigger',
        'LightningComponentBundle',
        'ApexTestSuite',
        'ApexPage'
    };
    @SuppressWarnings('PMD.FieldNamingConventions, PMD.FieldDeclarationsShouldBeAtStart')
    private static Set<String> TYPES_WITHOUT_APEX = new Set<String>{
        'CustomLabel',
        'StaticResource',
        'LightningComponentBundle',
        'ApexTestSuite',
        'ApexPage'
    };
}