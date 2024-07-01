@SuppressWarnings('PMD.AvoidGlobalModifier')
global class DataDeployFunctionCallback implements copado.MCCallback {
    private static final String DEPLOYMENT_SUMMARY_VIEWER_JSON = 'DeploymentSummaryViewer.json';
    private static final String CSV_FILE_LINK_ICON = 'utility:link';
    private static final String NO_CSV_FILE_LINK_ICON = 'utility:unlinked';

    @TestVisible
    private static String exceptionMessage;

    @SuppressWarnings('PMD.AvoidDebugStatements')
    global void execute(copado__Function__c function, copado__Result__c result, String status) {
        try {
            List<ContentVersion> file = getFileVersion(result.Id, DEPLOYMENT_SUMMARY_VIEWER_JSON);
            if (!file?.isEmpty()) {
                Map<String, Object> versionData = getVersionData(file);
                List<DeploymentSummary> data = getDeploymentSummary(versionData);
                Map<String, String> csvFileIdsByNames = getCsvFileIdsByNames(data, result.Id);
                List<DeploymentSummary> deploymentSummaryList = updateLinksInDeploymentSummary(data, csvFileIdsByNames);
                deleteFile(file[0].ContentDocumentId);
                createFile(result.Id, deploymentSummaryList, versionData);
            }
        } catch (Exception ex) {
            exceptionMessage = ex.getMessage();
            System.debug(LoggingLevel.ERROR, ex.getMessage() + ex.getStackTraceString());
        }
    }

    private List<ContentVersion> getFileVersion(Id resultId, String title) {
        List<ContentVersion> result = new List<ContentVersion>();
        List<ContentDocumentLink> documentLinks = new ContentDocumentLinksSelector()
            .versionDataByLinkedEntityIdsAndTitles(new Set<Id>{ resultId }, new Set<String>{ title });
        for (ContentDocumentLink documentLink : documentLinks) {
            result.add(
                new ContentVersion(
                    VersionData = documentLink.ContentDocument.LatestPublishedVersion.VersionData,
                    Title = documentLink.ContentDocument.LatestPublishedVersion.Title,
                    ContentDocumentId = documentLink.ContentDocument.Id
                )
            );
        }
        return result;
    }

    private Map<String, Object> getVersionData(List<ContentVersion> file) {
        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(file[0]?.VersionData?.toString());
        if (!result.containsKey('data') || !result.containsKey('columns')) {
            throw new ApplicationException(
                String.format(Label.Deployment_Summary_Viewer_Missing_Columns_Or_Data, new List<Object>{ DEPLOYMENT_SUMMARY_VIEWER_JSON })
            );
        }
        return result;
    }

    private List<DeploymentSummary> getDeploymentSummary(Map<String, Object> versionData) {
        String data = JSON.serialize(versionData.get('data'));
        return (List<DeploymentSummary>) JSON.deserialize(data, List<DeploymentSummary>.class);
    }

    private List<DeploymentSummary> updateLinksInDeploymentSummary(
        List<DeploymentSummary> deploymentSummaryList,
        Map<String, String> csvFileIdsByNames
    ) {
        String orgDomainUrl = Url.getOrgDomainUrl().toExternalForm();
        for (DeploymentSummary deploymentSummary : deploymentSummaryList) {
            deploymentSummary.templateUrl = orgDomainUrl + '/' + deploymentSummary.templateId;
            deploymentSummary.csvFileName = deploymentSummary.templateName + '_deployment_details.csv';
            if (csvFileIdsByNames.containsKey(deploymentSummary.csvFileName)) {
                deploymentSummary.csvFileLink = orgDomainUrl + '/' + csvFileIdsByNames.get(deploymentSummary.csvFileName);
                deploymentSummary.csvFileIcon = CSV_FILE_LINK_ICON;
            } else {
                deploymentSummary.csvFileIcon = NO_CSV_FILE_LINK_ICON;
                deploymentSummary.isCsvFileIconDisabled = true;
            }
            deploymentSummary.templateId = null;
        }
        return deploymentSummaryList;
    }

    private void deleteFile(Id contentDocumentId) {
        List<ContentDocument> contentDocuments = new List<ContentDocument>{ new ContentDocument(Id = contentDocumentId) };
        // We are running the file deletion logic in SYSTEM_MODE, because we need the
        // file to be deleted irrespective of its sharing and other permissions with respect to the current logged in user.
        Utilities.performDML(contentDocuments, 'delete', AccessLevel.SYSTEM_MODE);
    }

    private void createFile(Id resultId, List<DeploymentSummary> data, Map<String, Object> fileContent) {
        fileContent.put('data', data);
        Blob serializedJson = Blob.valueOf(JSON.serialize(fileContent, true));

        ContentVersion contentVersion = new ContentVersion(
            Title = DEPLOYMENT_SUMMARY_VIEWER_JSON,
            PathOnClient = DEPLOYMENT_SUMMARY_VIEWER_JSON,
            VersionData = serializedJson,
            FirstPublishLocationId = resultId
        );
        Utilities.performDML(new List<ContentVersion>{ contentVersion }, 'insert', AccessLevel.USER_MODE);
    }

    private Map<String, String> getCsvFileIdsByNames(List<DeploymentSummary> deploymentSummaryList, Id resultId) {
        Map<String, String> result = new Map<String, String>();

        Set<String> csvFileNames = getCsvFileNames(deploymentSummaryList);

        List<ContentDocumentLink> csvFileLinks = new ContentDocumentLinksSelector().byLinkedEntityIdAndTitles(new Set<Id>{ resultId }, csvFileNames);

        for (ContentDocumentLink csvFileLink : csvFileLinks) {
            result.put(csvFileLink.ContentDocument.Title, csvFileLink.ContentDocument.Id);
        }
        return result;
    }

    private Set<String> getCsvFileNames(List<DeploymentSummary> deploymentSummaryList) {
        Set<String> result = new Set<String>();
        for (DeploymentSummary deploymentSummary : deploymentSummaryList) {
            result.add(deploymentSummary.templateName + '_deployment_details.csv');
        }
        return result;
    }

    @TestVisible
    private class DeploymentSummary {
        @TestVisible
        Id templateId;
        @TestVisible
        String templateName;
        @TestVisible
        String objectName;
        @TestVisible
        Integer deployedRecords;
        @TestVisible
        Integer failedRecords;
        @TestVisible
        Integer generatedIds;
        @TestVisible
        String templateUrl;
        @TestVisible
        String csvFileName;
        @TestVisible
        String csvFileLink;
        @TestVisible
        String csvFileIcon;
        @TestVisible
        Boolean isCsvFileIconDisabled;
    }
}