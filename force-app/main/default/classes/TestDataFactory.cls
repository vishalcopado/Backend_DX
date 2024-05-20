@isTest
@SuppressWarnings('PMD.ExcessiveParameterList, PMD.ExcessivePublicCount')
public with sharing class TestDataFactory {
    // When we create a list of SObjects, we need to have a unique field for the insert if there isn't an autonumber field.
    // Usually we use the Name field, but some objects don't have a name field.
    private static Map<Schema.SObjectType, Schema.SObjectField> nameFieldMap = new Map<Schema.SObjectType, Schema.SObjectField>{
        Contact.SObjectType => Contact.LastName,
        Case.SObjectType => Case.CaseNumber, //this is the autonumber field
        User.SObjectType => User.LastName,
        PermissionSetAssignment.SObjectType => PermissionSetAssignment.Id
    };

    public static User createUser(String profileName) {
        return new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = :profileName]
            .Id,
            FirstName = profileName,
            LastName = 'LastName',
            Email = 'test@copado.com',
            Username = 'testcmcsf@copado.com' + System.currentTimeMillis(),
            CompanyName = 'Copado',
            Title = 'Title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
    }

    public static void assignPermissionSet(User u, Set<String> permSetNames) {
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();

        for (PermissionSet ps : [SELECT Id FROM PermissionSet WHERE Name IN :permSetNames]) {
            assignments.add(new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id));
        }
        insert assignments;
    }

    public static void assignLicense(
        String userId,
        Boolean cadEnabled,
        Boolean cchEnabled,
        Boolean ccmEnabled,
        Boolean copadoEnabled,
        Boolean cstEnabled
    ) {
        new copado.GlobalAPI()
            .upsertCopadoLicense(new copado.GlobalAPI.UserLicense(userId, cadEnabled, cchEnabled, ccmEnabled, copadoEnabled, cstEnabled));
    }

    public static copado__Git_Repository__c createGitRepository(String name) {
        return new copado__Git_Repository__c(Name = name);
    }

    public static copado__Environment__c createEnvironment(String name, String type, String platform) {
        return new copado__Environment__c(Name = name, copado__Type__c = type, copado__Platform__c = platform);
    }

    public static copado__Org__c createCredential(String name, String userName, Id environmentId, String orgType) {
        return new copado__Org__c(
            Name = name,
            copado__Org_Type__c = orgType,
            copado__Username__c = userName,
            copado__Environment__c = environmentId,
            copado__Oauth_Signature__c = 'signature',
            copado__Validated_Date__c = System.now()
        );
    }

    public static copado__Deployment_Flow__c createPipeline(String name, Id gitRepositoryId) {
        return new copado__Deployment_Flow__c(Name = name, copado__Git_Repository__c = gitRepositoryId, copado__Active__c = true);
    }

    public static copado__Pipeline_Action__c createPipelineAction(String action, Id pipelineId, Id templateId) {
        return new copado__Pipeline_Action__c(
            copado__Action__c = action,
            copado__Job_Template__c = templateId,
            copado__Pipeline__c = pipelineId,
            copado__Default__c = true
        );
    }

    public static copado__Deployment_Flow_Step__c createPipelineConnection(Id deploymentFlowId, Id sourceEnvironmentId, Id destinationEnvironmentId) {
        return new copado__Deployment_Flow_Step__c(
            copado__Deployment_Flow__c = deploymentFlowId,
            copado__Source_Environment__c = sourceEnvironmentId,
            copado__Destination_Environment__c = destinationEnvironmentId
        );
    }

    public static copado__Project__c createProject(String name, Id deploymentFlowId) {
        return new copado__Project__c(Name = name, copado__Deployment_Flow__c = deploymentFlowId);
    }

    public static copado__Release__c createRelease(String name, Id projectId) {
        return new copado__Release__c(Name = name, copado__Project__c = projectId);
    }

    public static copado__User_Story__c createUserStory(
        String title,
        String status,
        String sprintId,
        String projectId,
        String releaseId,
        String orgId
    ) {
        return new copado__User_Story__c(
            copado__User_Story_Title__c = title,
            copado__Status__c = status,
            copado__Sprint__c = sprintId,
            copado__Project__c = projectId,
            copado__Release__c = releaseId,
            copado__Org_Credential__c = orgId
        );
    }

    public static copado__Artifact__c createPackage(String name, String recTypeDevName) {
        return new copado__Artifact__c(
            Name = name,
            RecordTypeId = Schema.SObjectType.copado__Artifact__c.getRecordTypeInfosByDeveloperName().get(recTypeDevName).getRecordTypeId()
        );
    }

    public static copado__Artifact_Version__c createPackageVersion(String name, Id packageId) {
        return new copado__Artifact_Version__c(Name = name, copado__Artifact__c = packageId);
    }

    public static copado__Artifact_Dependency__c createPackageDependency(Id dependentPkgId, Id dependingPkgId, Id dependingPkgVersionId) {
        return new copado__Artifact_Dependency__c(
            copado__Dependent_Artifact__c = dependentPkgId,
            copado__Depending_Artifact__c = dependingPkgId,
            copado__Depending_Artifact_Version__c = dependingPkgVersionId
        );
    }

    public static copado__JobTemplate__c createJobTemplate(String name) {
        return new copado__JobTemplate__c(Name = name, copado__Version__c = 1);
    }

    public static SObject createSObject(SObject sObj, Map<Schema.SObjectField, Object> fieldDefaults) {
        addFieldDefaults(sObj, fieldDefaults);
        return sObj;
    }

    private static void addFieldDefaults(SObject sObj, Map<Schema.SObjectField, Object> defaults) {
        // Loop through the map of fields and if they weren't specifically assigned, fill them.
        Map<String, Object> populatedFields = sObj.getPopulatedFieldsAsMap();
        for (Schema.SObjectField field : defaults.keySet()) {
            if (!populatedFields.containsKey(String.valueOf(field))) {
                sObj.put(field, defaults.get(field));
            }
        }
    }

    public static List<SObject> createSObjectList(SObject sObj, Integer numberOfObjects) {
        return createSObjectList(sObj, numberOfObjects, null, null);
    }

    public static List<SObject> createSObjectList( // NOPMD : Supressing rule to avoid large refactor.
        SObject sObj,
        Integer numberOfObjects,
        Map<Schema.SObjectField, Object> fieldDefaults,
        Map<Schema.SObjectType, Set<Schema.SObjectField>> incrementalFields
    ) {
        List<SObject> sObjs = new List<SObject>{};
        SObject newObj;
        newObj = createSObject(sObj, fieldDefaults);

        // Get the name field for the object
        String nameField = String.valueOf(nameFieldMap.get(sObj.getSObjectType()));
        if (nameField == null) {
            nameField = 'Name';
        }
        Boolean nameIsAutoNumber = sObj.getSObjectType().getDescribe().fields.getMap().get(nameField).getDescribe().isAutoNumber();

        // Clone the object the number of times requested. Increment the name field so each record is unique
        for (Integer i = 0; i < numberOfObjects; i++) {
            SObject clonedSObj = newObj.clone(false, true);
            if (!nameIsAutoNumber && nameField != 'Id') {
                clonedSObj.put(nameField, (String) clonedSObj.get(nameField) + ' ' + i);
            }
            if (incrementalFields.containsKey(sObj.getSObjectType())) {
                for (Schema.SObjectField field : incrementalFields.get(sObj.getSObjectType())) {
                    clonedSObj.put(field, (String) clonedSObj.get(field) + ' ' + i);
                }
            }
            sObjs.add(clonedSObj);
        }
        return sObjs;
    }

    public static Attachment createAttachment(String parentId, String name) {
        MetaDataItem metadataItem = getMetadataItem('ApexClass', 'SampleClass', 'Test Test', '1900-01-01');
        List<MetaDataItem> metadataItems = new List<MetaDataItem>{ metadataItem };
        Blob attachmentBody = Blob.valueOf(JSON.serialize(metadataItems));
        return new Attachment(ParentId = parentId, Name = name, Body = attachmentBody);
    }

    public static MetaDataItem getMetadataItem(String metadataType, String name, String createdBy, String createdDate) {
        MetaDataItem metaDataItem = new MetaDataItem();
        metaDataItem.t = metadataType;
        metaDataItem.n = name;
        metaDataItem.cb = createdBy;
        metaDataItem.cd = createdDate;
        return metaDataItem;
    }

    public static MetaDataItem getMetadataItemWithCategory(String metadataType, String name, String createdBy, String createdDate, String category) {
        MetaDataItem metaDataItem = new MetaDataItem();
        metaDataItem.t = metadataType;
        metaDataItem.n = name;
        metaDataItem.c = category;
        metaDataItem.cb = createdBy;
        metaDataItem.cd = createdDate;
        return metaDataItem;
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static MetaDataItem createMetadataItem(
        String name,
        String namespace,
        String type,
        Boolean selected,
        Boolean committedInUS,
        String lastModifiedBy,
        String lastModifiedDate,
        List<MetaDataItem> children
    ) {
        MetaDataItem result = new MetaDataItem();
        result.n = name;
        result.ns = namespace;
        result.t = type;
        result.s = selected;
        result.cm = committedInUS;
        result.mb = lastModifiedBy;
        result.md = lastModifiedDate;
        if (children != null && !children.isEmpty()) {
            result.children = children;
        }
        return result;
    }
}