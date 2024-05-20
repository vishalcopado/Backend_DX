@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class GetFileVersionIdOfTestClassTestSuite implements copado.ParameterExpressionCallable {
    private final static String RUN_SPECIFIED_TESTS = 'Run Specified Tests';
    private final static String TEST_CLASSES_FILE_NAME = 'cmcSf_TestClasses';
    private final static String TEST_SUITES_FILE_NAME = 'cmcSf_TestSuites';

    // GLOBAL

    global String execute(Id contextId) {
        String result = '';
        copado__JobExecution__c jobExecution = getJobExecution(contextId);
        Context context = getContext(jobExecution);
        switch on context {
            when ROLLBACK_EXECUTION {
                result = getFileVersionIdsForRollbackContext(jobExecution);
            }
            when DEPLOY_EXECUTION {
                result = getFileVersionIdsForDeployContext(jobExecution);
            }
            when APEX_TEST_EXECUTION {
                result = getFileVersionIdsForApexTestContext(jobExecution);
            }
        }
        return result;
    }

    // PRIVATE

    private static copado__JobExecution__c getJobExecution(Id jobStepId) {
        List<copado__JobStep__c> jobSteps = new JobStepsSelector().byIds(new Set<Id>{ jobStepId });
        copado__JobExecution__c result = !jobSteps.isEmpty() ? jobSteps[0].copado__JobExecution__r : new copado__JobExecution__c();
        return result;
    }

    private static Context getContext(copado__JobExecution__c jobExecution) {
        Context result;
        String jobTemplateApiName = getJobTemplateApiName(jobExecution);
        String apexTestJobTemplateApiName = getApexTestJobTemplateApiName();

        if (jobTemplateApiName == apexTestJobTemplateApiName) {
            result = Context.APEX_TEST_EXECUTION;
        } else {
            String rollbackJobTemplateApiName = getRollbackJobTemplateApiName(jobExecution);
            result = jobTemplateApiName == rollbackJobTemplateApiName ? Context.ROLLBACK_EXECUTION : Context.DEPLOY_EXECUTION;
        }
        return result;
    }

    private static String getJobTemplateApiName(copado__JobExecution__c jobExecution) {
        return jobExecution?.copado__Template__r?.copado__ApiName__c;
    }

    private static String getApexTestJobTemplateApiName() {
        String result = copado__TestTool__mdt.getInstance('ApexTests')?.copado__JobTemplate__c;
        return result;
    }

    private static String getRollbackJobTemplateApiName(copado__JobExecution__c jobExecution) {
        String result = new ActionTemplate('Rollback', jobExecution?.copado__Pipeline__c, jobExecution?.copado__Destination__c).getApiName();
        return result;
    }

    private static String getFileVersionIdsForRollbackContext(copado__JobExecution__c jobExecution) {
        Set<Id> fileVersionIds = new Set<Id>();
        JobExecutionPayload jobExecutionPayload = getJobExecutionPayload(jobExecution);
        if (jobExecutionPayload?.testLevel == RUN_SPECIFIED_TESTS && String.isNotBlank(jobExecution?.copado__Promotion__c)) {
            fileVersionIds = getFileVersionIds(
                new Set<Id>{ jobExecution.copado__Promotion__c },
                new Set<String>{ TEST_CLASSES_FILE_NAME, TEST_SUITES_FILE_NAME }
            );
        }
        return JSON.serialize(fileVersionIds);
    }

    private static String getFileVersionIdsForDeployContext(copado__JobExecution__c jobExecution) {
        Set<Id> fileVersionIds = new Set<Id>();
        JobExecutionPayload jobExecutionPayload = getJobExecutionPayload(jobExecution);
        if (jobExecutionPayload?.userStoryIds != null && String.isNotBlank(jobExecutionPayload?.promotionId)) {
            String apexTestLevel = getApexTestLevel(jobExecutionPayload.promotionId);
            if (apexTestLevel == RUN_SPECIFIED_TESTS) {
                Set<Id> testIds = getTestIds(jobExecutionPayload.userStoryIds);
                fileVersionIds = testIds.isEmpty()
                    ? new Set<Id>()
                    : getFileVersionIds(testIds, new Set<String>{ TEST_CLASSES_FILE_NAME, TEST_SUITES_FILE_NAME });
            }
        }
        return JSON.serialize(fileVersionIds);
    }

    private static String getFileVersionIdsForApexTestContext(copado__JobExecution__c jobExecution) {
        Set<Id> fileVersionIds = new Set<Id>();
        JobExecutionPayload jobExecutionPayload = getJobExecutionPayload(jobExecution);
        if (jobExecutionPayload?.testIds != null) {
            fileVersionIds = getFileVersionIds(
                new Set<Id>(jobExecutionPayload?.testIds),
                new Set<String>{ TEST_CLASSES_FILE_NAME, TEST_SUITES_FILE_NAME }
            );
        }
        return JSON.serialize(fileVersionIds);
    }

    private static JobExecutionPayload getJobExecutionPayload(copado__JobExecution__c jobExecution) {
        return (JobExecutionPayload) JSON.deserialize(jobExecution?.copado__DataJson__c, JobExecutionPayload.class);
    }

    private static Set<Id> getTestIds(List<Id> userStoryIds) {
        List<copado__Test__c> tests = new TestsSelector().byUserStoryIds(new Set<Id>(userStoryIds));
        Map<Id, copado__Test__c> testById = new Map<Id, copado__Test__c>(tests);
        Set<Id> result = testById.keySet();
        return result;
    }

    private static String getApexTestLevel(Id promotionId) {
        String result = '';
        List<copado__Promotion__c> promotions = new PromotionsSelector().byIds(new Set<Id>{ promotionId });
        result = !promotions.isEmpty() ? promotions[0].Apex_Test_Level__c : '';
        return result;
    }

    private static Set<Id> getFileVersionIds(Set<Id> linkedEntityIds, Set<String> fileTitles) {
        Set<Id> result = new Set<Id>();
        Set<Id> contentDocumentIds = new Set<Id>();
        List<ContentDocumentLink> contentDocumentLinks = new ContentDocumentLinksSelector().byLinkedEntityIdAndTitles(linkedEntityIds, fileTitles);
        for (ContentDocumentLink contentDocumentLink : contentDocumentLinks) {
            contentDocumentIds.add(contentDocumentLink.ContentDocumentId);
        }
        if (!contentDocumentIds.isEmpty()) {
            List<ContentVersion> contentVersions = new ContentVersionsSelector().byContentDocumentId(contentDocumentIds);
            for (ContentVersion contentVersion : contentVersions) {
                result.add(contentVersion.Id);
            }
        }
        return result;
    }

    // INNER

    private with sharing class JobExecutionPayload {
        private List<Id> testIds;
        private List<Id> userStoryIds;
        private Id promotionId;
        private String testLevel;
    }

    private enum Context {
        ROLLBACK_EXECUTION,
        DEPLOY_EXECUTION,
        APEX_TEST_EXECUTION
    }
}