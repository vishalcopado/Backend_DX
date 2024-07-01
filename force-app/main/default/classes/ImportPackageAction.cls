public with sharing class ImportPackageAction {
    private static final String PACKAGE_ARTIFACT = 'Package_Artifact';
    private final static String PACKAGE_VERSION_DETAILS_FILENAME = 'PackageAndVersions.json';

    @InvocableMethod(
        label='Create Package and Package Version'
        category='Package Import'
        description='Package Import only supports one package request at a time.'
    )
    public static void execute(List<Request> requests) {
        try {
            if (requests.size() > 1) {
                throw new ApplicationException(System.Label.BulkPackageImportNotSupported);
            }
            Request request = requests.get(0);
            Map<String, Object> packageWithVersions;

            if (isValid(request)) {
                String data = getDataFromContentDocument(request.prevResultId);
                PackageInfo info = PackageInfo.parse(data);
                copado__Artifact__c pkg = retrievePackage(request, info);

                packageWithVersions = new Map<String, Object>{ 'packageRecord' => pkg, 'packageVersions' => retrieveVersions(pkg, info) };
            }

            createContentVersion(JSON.serialize(packageWithVersions, true), request.currentResultId);

        } catch (Exception ex) {
            throw new ApplicationException(ex.getMessage());
        }
    }

    // PRIVATE

    private static void createContentVersion(String data, String recordId) {
        try {
            fflib_ISObjectUnitOfWork unitOfWork = new fflib_SObjectUnitOfWork(
                new List<SObjectType>{ ContentVersion.SObjectType, ContentDocumentLink.sObjectType }
            );

            ContentVersion contentVersion = new ContentVersion();
            contentVersion.ContentLocation = 'S'; // S = Stored in Salesforce
            contentVersion.PathOnClient = PACKAGE_VERSION_DETAILS_FILENAME;
            contentVersion.Title = PACKAGE_VERSION_DETAILS_FILENAME;
            contentVersion.VersionData = Blob.valueOf(data);
            contentVersion.FirstPublishLocationId = recordId;

            unitOfWork.registerNew(contentVersion);
            unitOfWork.commitWork();
        } catch (Exception ex) {
            throw new ApplicationException(ex.getMessage() + ' ' + ex.getStackTraceString());
        }
    }

    private static String getDataFromContentDocument(Id byLinkedEntityId) {
        String result = '';
        List<ContentDocumentLink> packageVersionFileDetails = getContentDocumentLink(byLinkedEntityId);
        if (!packageVersionFileDetails.isEmpty()) {
            List<ContentVersion> contentVersions = new ContentVersionsSelector().byContentDocumentIdWithLatest(new Set<Id>{packageVersionFileDetails[0].ContentDocumentId });
            if(!contentVersions.isEmpty()) {
                result = contentVersions[0]?.VersionData?.toString();
            }
        }
        return result;
    }

    private static List<ContentDocumentLink> getContentDocumentLink(Id recordId) {
        return new ContentDocumentLinksSelector().byLinkedEntityIdAndTitles(new Set<Id>{ recordId }, new Set<String>{ PACKAGE_VERSION_DETAILS_FILENAME });
    }

    private static Boolean isValid(Request request) {
        return String.isNotBlank(request.prevResultId) && String.isNotBlank(request.pipelineId) && String.isNotBlank(request.currentResultId);
    }

    private static copado__Artifact__c retrievePackage(Request input, PackageInfo info) {
        PackageInfo.Pkg pkgInfo = info.pkg;
        copado__Artifact__c result = getExistingPackage(pkgInfo.Id);

        result.copado__Artifact_Repository__c = getRepositoryId(input.pipelineId);
        result.Name = pkgInfo.Name;
        result.copado__Package_Id__c = pkgInfo.Id;
        result.copado__Description__c = pkgInfo.Description;
        result.copado__Package_Namespace__c = pkgInfo.NamespacePrefix;
        result.copado__pipeline__c = input.pipelineid;
        result.copado__Package_Type__c = pkgInfo.ContainerOptions;
        result.RecordTypeId = getRecordTypeId(PACKAGE_ARTIFACT);
        result.IsOrgDependent__c = pkgInfo.IsOrgDependent == 'Yes' ? true : false;
        result.copado__Target_Dev_Hub_Org__c = getTargetDevHub(input.jsonInformation);

        return result;
    }

    private static List<copado__Artifact_Version__c> retrieveVersions(copado__Artifact__c pkg, PackageInfo info) {
        Map<String, copado__Artifact_Version__c> versionsById = versionsById(pkg);
        List<copado__Artifact_Version__c> versions = new List<copado__Artifact_Version__c>();

        for (PackageInfo.Versions version : info.versions) {
            versions.add(createVersion(version, versionsById, pkg.Name));
        }

        return versions;
    }

    private static copado__Artifact_Version__c createVersion(
        PackageInfo.Versions version,
        Map<String, copado__Artifact_Version__c> versionsById,
        String packageName
    ) {
        String key = version.SubscriberPackageVersionId;
        copado__Artifact_Version__c record = (versionsById.containsKey(key)) ? versionsById.get(key) : new copado__Artifact_Version__c();

        record.copado__Package_Version_Id__c = version.Id;
        record.copado__Subscriber_Version_Id__c = version.SubscriberPackageVersionId;
        record.copado__Is_released__c = version.IsReleased;
        record.copado__Branch__c = version.Branch;
        record.copado__Version_Name__c = version.Name;
        record.copado__Tag__c = version.Tag;
        record.copado__Version_Description__c = version.Description;
        record.copado__Version_number__c = version.Version;
        record.Name = packageName + ' - ' + version.Version;
        record.copado__Status__c = version.IsReleased ? 'Published' : 'Pre-Release';

        record = removeFieldFromPackageVersion(record, 'copado__Artifact__c');
        return record;
    }

    private static copado__Artifact__c getExistingPackage(String packageId) {
        List<copado__Artifact__c> packages = new PackagesSelector()
            .selectBySubscriberIdWithVersions(new Set<Id>{ packageId }, new Set<String>{ 'Id', 'copado__Subscriber_Version_Id__c' });

        return !packages.isEmpty() ? packages.get(0) : new copado__Artifact__c();
    }

    private static Id getRepositoryId(String pipelineId) {
        List<copado__Deployment_Flow__c> pipelines = new PipelinesSelector().byId(new Set<Id>{ Id.valueOf(pipelineId) });

        if (pipelines.isEmpty()) {
            throw new ApplicationException(System.Label.InvalidPipeline);
        }

        return pipelines[0].copado__Git_Repository__c;
    }

    private static Id getRecordTypeId(String name) {
        Id recordTypeId = Schema.SObjectType.copado__Artifact__c.getRecordTypeInfosByDeveloperName().get(name).getRecordTypeId();

        return recordTypeId;
    }

    private static String getTargetDevHub(String jsonInformation) {
        String devHub = (String.isNotBlank(jsonInformation)) ? ParseImportPackageJson.parse(jsonInformation).devhub : null;

        return devHub;
    }

    private static Map<String, copado__Artifact_Version__c> versionsById(copado__Artifact__c pkg) {
        Map<String, copado__Artifact_Version__c> result = new Map<String, copado__Artifact_Version__c>();
        List<copado__Artifact_Version__c> versions = new PackageVersionsSelector().byPackageIds(new Set<Id>{ pkg.Id });
        for (copado__Artifact_Version__c version : versions) {
            result.put(version.copado__Subscriber_Version_Id__c, version);
        }

        return result;
    }

    private static copado__Artifact_Version__c removeFieldFromPackageVersion(copado__Artifact_Version__c version, String fieldToRemove) {
        Map<String, Object> versionToUpdate = new Map<String, Object>( version.getPopulatedFieldsAsMap() );
        versionToUpdate.remove(fieldToRemove);
        return (copado__Artifact_Version__c) JSON.deserialize( JSON.serialize( versionToUpdate ), copado__Artifact_Version__c.class );
    }

    // INNER

    public class Request {
        @InvocableVariable(required=true)
        public Id prevResultId;

        @InvocableVariable(required=true)
        public Id currentResultId;

        @InvocableVariable(required=true label='Pipeline Id')
        public String pipelineId;

        @InvocableVariable(label='Platform related arguments in JSON format')
        public String jsonInformation;
    }
}