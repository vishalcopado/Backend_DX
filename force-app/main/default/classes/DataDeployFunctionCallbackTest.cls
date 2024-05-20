@IsTest
private class DataDeployFunctionCallbackTest {
    private static final String DEPLOYMENT_SUMMARY_VIEWER_JSON = 'DeploymentSummaryViewer.json';
    private static final Id TEMPLATE_ID = fflib_IDGenerator.generate('a0U');

    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void executeWithCorrectFormatFile() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            copado__Result__c result = getResult();
            Blob fileContent = getFileContent(getData(), getColumns());
            Id contentDocumentId = createFile(DEPLOYMENT_SUMMARY_VIEWER_JSON, fileContent, result.Id);
            createFile('Account Template_deployment_details.csv', Blob.valueOf('templatename,deployedrecords'), result.Id);

            // EXERCISE

            new DataDeployFunctionCallback().execute(getFunction(), result, 'Success');

            // VERIFY

            List<ContentVersion> tableContent = getContentVersion(result.Id, DEPLOYMENT_SUMMARY_VIEWER_JSON);
            Assert.isFalse(tableContent.isEmpty(), 'The result record should have the file ' + DEPLOYMENT_SUMMARY_VIEWER_JSON + ' linked to it');

            List<DataDeployFunctionCallback.DeploymentSummary> deploymentSummaryList = (List<DataDeployFunctionCallback.DeploymentSummary>) JSON.deserialize(
                JSON.serialize(getValueForKey(tableContent[0].VersionData, 'data')),
                List<DataDeployFunctionCallback.DeploymentSummary>.class
            );
            Assert.isTrue(deploymentSummaryList.size() == 1, 'The data property in the file content should contain a list of one template');
            Assert.areEqual(
                'Account Template',
                deploymentSummaryList[0].templateName,
                'The template name ' +
                deploymentSummaryList[0].templateName +
                ' is incorrect'
            );
            Assert.areEqual(
                getOrgDomainUrl() +
                '/' +
                TEMPLATE_ID,
                deploymentSummaryList[0].templateUrl,
                'The template url ' +
                deploymentSummaryList[0].templateUrl +
                ' is incorrect'
            );
            Assert.areEqual(
                'Account Template_deployment_details.csv',
                deploymentSummaryList[0].csvFileName,
                'The csvFileName ' +
                deploymentSummaryList[0].csvFileName +
                ' is incorrect'
            );
            Assert.areEqual(
                2,
                deploymentSummaryList[0].deployedRecords,
                'The deployedRecords ' +
                deploymentSummaryList[0].deployedRecords +
                ' is incorrect'
            );
            Assert.areEqual(
                0,
                deploymentSummaryList[0].failedRecords,
                'The failedRecords ' +
                deploymentSummaryList[0].failedRecords +
                ' is incorrect'
            );
            Assert.areEqual(0, deploymentSummaryList[0].generatedIds, 'The generatedIds ' + deploymentSummaryList[0].generatedIds + ' is incorrect');
            Assert.areEqual(
                'Account',
                deploymentSummaryList[0].objectName,
                'The objectName ' +
                deploymentSummaryList[0].objectName +
                ' is incorrect'
            );

            Assert.areEqual(
                'utility:link',
                deploymentSummaryList[0].csvFileIcon,
                'The csvFileIcon ' +
                deploymentSummaryList[0].csvFileIcon +
                ' is incorrect'
            );

            Assert.areEqual(
                null,
                deploymentSummaryList[0].isCsvFileIconDisabled,
                'The isCsvFileIconDisabled ' +
                deploymentSummaryList[0].isCsvFileIconDisabled +
                ' is incorrect'
            );

            List<String> columns = (List<String>) JSON.deserialize(
                JSON.serialize(getValueForKey(tableContent[0].VersionData, 'columns')),
                List<String>.class
            );
            Assert.areEqual(2, columns.size(), 'The size of the columns list should be 2');
            Assert.isTrue(columns.contains('Column1'), 'The columns list is incorrect');
            Assert.isTrue(columns.contains('Column2'), 'The columns list is incorrect');
            Assert.isTrue(getContentDocument(contentDocumentId).size() == 0, 'The previous DeploymentSummaryViewer.json should be deleted');
        }
    }

    @IsTest
    private static void executeWithCSVFileNotPresent() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            copado__Result__c result = getResult();
            Blob fileContent = getFileContent(getData(), getColumns());
            Id contentDocumentId = createFile(DEPLOYMENT_SUMMARY_VIEWER_JSON, fileContent, result.Id);

            // EXERCISE

            new DataDeployFunctionCallback().execute(getFunction(), result, 'Success');

            // VERIFY

            List<ContentVersion> tableContent = getContentVersion(result.Id, DEPLOYMENT_SUMMARY_VIEWER_JSON);
            Assert.isFalse(tableContent.isEmpty(), 'The result record should have the file ' + DEPLOYMENT_SUMMARY_VIEWER_JSON + ' linked to it');

            List<DataDeployFunctionCallback.DeploymentSummary> deploymentSummaryList = (List<DataDeployFunctionCallback.DeploymentSummary>) JSON.deserialize(
                JSON.serialize(getValueForKey(tableContent[0].VersionData, 'data')),
                List<DataDeployFunctionCallback.DeploymentSummary>.class
            );
            Assert.isTrue(deploymentSummaryList.size() == 1, 'The data property in the file content should contain a list of one template');
            Assert.areEqual(
                'Account Template',
                deploymentSummaryList[0].templateName,
                'The template name ' +
                deploymentSummaryList[0].templateName +
                ' is incorrect'
            );
            Assert.areEqual(
                getOrgDomainUrl() +
                '/' +
                TEMPLATE_ID,
                deploymentSummaryList[0].templateUrl,
                'The template url ' +
                deploymentSummaryList[0].templateUrl +
                ' is incorrect'
            );
            Assert.areEqual(
                'Account Template_deployment_details.csv',
                deploymentSummaryList[0].csvFileName,
                'The csvFileName ' +
                deploymentSummaryList[0].csvFileName +
                ' is incorrect'
            );
            Assert.areEqual(
                2,
                deploymentSummaryList[0].deployedRecords,
                'The deployedRecords ' +
                deploymentSummaryList[0].deployedRecords +
                ' is incorrect'
            );
            Assert.areEqual(
                0,
                deploymentSummaryList[0].failedRecords,
                'The failedRecords ' +
                deploymentSummaryList[0].failedRecords +
                ' is incorrect'
            );
            Assert.areEqual(0, deploymentSummaryList[0].generatedIds, 'The generatedIds ' + deploymentSummaryList[0].generatedIds + ' is incorrect');
            Assert.areEqual(
                'Account',
                deploymentSummaryList[0].objectName,
                'The objectName ' +
                deploymentSummaryList[0].objectName +
                ' is incorrect'
            );
            Assert.areEqual(null, deploymentSummaryList[0].csvFileLink, 'The csvFileLink ' + deploymentSummaryList[0].csvFileLink + ' is incorrect');
            Assert.areEqual(
                'utility:unlinked',
                deploymentSummaryList[0].csvFileIcon,
                'The csvFileIcon ' +
                deploymentSummaryList[0].csvFileIcon +
                ' is incorrect'
            );
            Assert.areEqual(
                true,
                deploymentSummaryList[0].isCsvFileIconDisabled,
                'The isCsvFileIconDisabled ' +
                deploymentSummaryList[0].isCsvFileIconDisabled +
                ' is incorrect'
            );

            List<String> columns = (List<String>) JSON.deserialize(
                JSON.serialize(getValueForKey(tableContent[0].VersionData, 'columns')),
                List<String>.class
            );
            Assert.areEqual(2, columns.size(), 'The size of the columns list should be 2');
            Assert.isTrue(columns.contains('Column1'), 'The columns list is incorrect');
            Assert.isTrue(columns.contains('Column2'), 'The columns list is incorrect');
            Assert.isTrue(getContentDocument(contentDocumentId).size() == 0, 'The previous DeploymentSummaryViewer.json should be deleted');
        }
    }

    @IsTest
    private static void executeWithDeploymentSummaryFileNotPresent() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            copado__Result__c result = getResult();

            createFile('Account Template_deployment_details.csv', Blob.valueOf('templatename,deployedrecords'), result.Id);

            // EXERCISE

            new DataDeployFunctionCallback().execute(getFunction(), result, 'Success');

            // VERIFY
            List<ContentVersion> tableContent = getContentVersion(result.Id, DEPLOYMENT_SUMMARY_VIEWER_JSON);
            Assert.isTrue(tableContent.isEmpty(), 'The result record should not have the file ' + DEPLOYMENT_SUMMARY_VIEWER_JSON + ' linked to it');
            Assert.isTrue(String.isBlank(DataDeployFunctionCallback.exceptionMessage), 'There should be no exception ');
        }
    }

    @IsTest
    private static void executeWithInCorrectFormatFile() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            copado__Result__c result = getResult();
            Blob fileContent = getFileContent(getData(), null);
            createFile(DEPLOYMENT_SUMMARY_VIEWER_JSON, fileContent, result.Id);
            createFile('Account Template_deployment_details.csv', Blob.valueOf('templatename,deployedrecords'), result.Id);

            // EXERCISE

            new DataDeployFunctionCallback().execute(getFunction(), result, 'Success');

            // VERIFY

            List<ContentVersion> tableContent = getContentVersion(result.Id, DEPLOYMENT_SUMMARY_VIEWER_JSON);
            Assert.isFalse(tableContent.isEmpty(), 'The result record should have the file ' + DEPLOYMENT_SUMMARY_VIEWER_JSON + ' linked to it');

            List<DataDeployFunctionCallback.DeploymentSummary> deploymentSummaryList = (List<DataDeployFunctionCallback.DeploymentSummary>) JSON.deserialize(
                JSON.serialize(getValueForKey(tableContent[0].VersionData, 'data')),
                List<DataDeployFunctionCallback.DeploymentSummary>.class
            );
            Assert.isTrue(deploymentSummaryList.size() == 1, 'The data property in the file content should contain a list of one template');
            Assert.areEqual(
                'Account Template',
                deploymentSummaryList[0].templateName,
                'The template name ' +
                deploymentSummaryList[0].templateName +
                ' is incorrect'
            );
            Assert.areEqual(null, deploymentSummaryList[0].templateUrl, 'The template url ' + deploymentSummaryList[0].templateUrl + ' is incorrect');
            Assert.areEqual(null, deploymentSummaryList[0].csvFileName, 'The csvFileName ' + deploymentSummaryList[0].csvFileName + ' is incorrect');
            Assert.areEqual(
                2,
                deploymentSummaryList[0].deployedRecords,
                'The deployedRecords ' +
                deploymentSummaryList[0].deployedRecords +
                ' is incorrect'
            );
            Assert.areEqual(
                0,
                deploymentSummaryList[0].failedRecords,
                'The failedRecords ' +
                deploymentSummaryList[0].failedRecords +
                ' is incorrect'
            );
            Assert.areEqual(0, deploymentSummaryList[0].generatedIds, 'The generatedIds ' + deploymentSummaryList[0].generatedIds + ' is incorrect');
            Assert.areEqual(
                'Account',
                deploymentSummaryList[0].objectName,
                'The objectName ' +
                deploymentSummaryList[0].objectName +
                ' is incorrect'
            );
            Assert.areEqual(null, deploymentSummaryList[0].csvFileLink, 'The csvFileLink ' + deploymentSummaryList[0].csvFileLink + ' is incorrect');

            Assert.areEqual(
                'The content in the file DeploymentSummaryViewer.json is missing data or columns property',
                DataDeployFunctionCallback.exceptionMessage,
                'The execution should fail with the expected error'
            );

            Assert.areEqual(null, deploymentSummaryList[0].csvFileIcon, 'The csvFileIcon ' + deploymentSummaryList[0].csvFileIcon + ' is incorrect');
            Assert.areEqual(
                null,
                deploymentSummaryList[0].isCsvFileIconDisabled,
                'The isCsvFileIconDisabled ' +
                deploymentSummaryList[0].isCsvFileIconDisabled +
                ' is incorrect'
            );
        }
    }

    // PRIVATE

    private static void createData() {
        Function dataDeployFn = new Function().apiName('SFDX_Data_Deploy');
        new Result().type('Function').status('Success').function(dataDeployFn).persist();
    }

    private static Id createFile(String title, Blob versionData, Id resultId) {
        ContentVersion fileVersion = (ContentVersion) new ContentVersion_t()
            .firstPublishLocationId(resultId)
            .title(title)
            .pathOnClient(title)
            .versionData(versionData)
            .persist();
        return fileVersion.ContentDocumentId;
    }

    private static Blob getFileContent(Object data, Object columns) {
        Map<String, Object> fileContent = new Map<String, Object>();
        if (data != null) {
            fileContent.put('data', data);
        }
        if (columns != null) {
            fileContent.put('columns', columns);
        }
        return Blob.valueOf(JSON.serialize(fileContent));
    }

    private static Object getColumns() {
        return new List<String>{ 'Column1', 'Column2' };
    }

    private static Object getData() {
        DataDeployFunctionCallback.DeploymentSummary deploymentSummary = new DataDeployFunctionCallback.DeploymentSummary();
        deploymentSummary.templateId = TEMPLATE_ID;
        deploymentSummary.templateName = 'Account Template';
        deploymentSummary.objectName = 'Account';
        deploymentSummary.deployedRecords = 2;
        deploymentSummary.failedRecords = 0;
        deploymentSummary.generatedIds = 0;

        return new List<DataDeployFunctionCallback.DeploymentSummary>{ deploymentSummary };
    }

    private static copado__Result__c getResult() {
        return [SELECT Id FROM copado__Result__c WHERE copado__Function__r.copado__API_Name__c = 'SFDX_Data_Deploy' LIMIT 1];
    }

    private static copado__Function__c getFunction() {
        return [SELECT Id FROM copado__Function__c WHERE copado__API_Name__c = 'SFDX_Data_Deploy' LIMIT 1];
    }

    private static List<ContentVersion> getContentVersion(Id resultId, String title) {
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

    private static List<ContentDocument> getContentDocument(Id contentDocumentId) {
        return [SELECT Id FROM ContentDocument WHERE Id = :contentDocumentId];
    }

    private static List<ContentDocumentLink> getContentDocumentByLinkedEntity(Id resultId, String title) {
        return new ContentDocumentLinksSelector().byLinkedEntityIdAndTitles(new Set<Id>{ resultId }, new Set<String>{ title });
    }

    private static Object getValueForKey(Blob fileContent, String key) {
        Map<String, Object> tableDataByKey = (Map<String, Object>) JSON.deserializeUntyped(fileContent?.toString());
        return tableDataByKey.get(key);
    }

    private static String getOrgDomainUrl() {
        return Url.getOrgDomainUrl().toExternalForm();
    }
}