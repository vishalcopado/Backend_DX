@SuppressWarnings('PMD.ExcessivePublicCount, PMD.CognitiveComplexity, PMD.CyclomaticComplexity')
public with sharing class EvaluateApexTestsCriteria {
    private static final String APEX_CLASS = 'ApexClass';
    private static final String APEX_TRIGGER = 'ApexTrigger';
    private static final String ADD = 'Add';
    private static final String OUTPUT_FILE_NAME = 'apex-tests-output.json';

    // PUBLIC

    @InvocableMethod(
        label='Evaluate Apex Tests Criteria'
        description='Evaluate test execution result with respect to the acceptance criteria'
        category='Copado Test'
    )
    public static List<Response> execute(List<Request> requests) {
        List<Response> result = new List<Response>();
        if (isRequestValid(requests)) {
            try {
                // Note: Right now it always is one request, no need to bulkify
                Request request = requests[0];
                List<Id> testResultIds = request.getParsedResultIds();
                Id consolidatedResultId = getConsolidatedResultId(request);
                AcceptanceCriteria criteria = request.getParsedAcceptanceCriteria();
                copado__Result__c resultRecord = getResult(request.resultId);
                List<copado__User_Story__c> userStories = getRelatedUserStories(resultRecord);

                UpdateTestsInfoOnStories.ApexTestDetails apexTestDetails = UpdateTestsInfoOnStories.execute(
                    new List<UpdateTestsInfoOnStories.Request>{
                        new UpdateTestsInfoOnStories.Request(
                        testResultIds,
                            consolidatedResultId,
                            userStories,
                            requests[0].fileWithSelectedChanges,
                            requests[0].recreateFeatureBranch
                        )
                    }
                );
                
                String acceptanceCriteriaErrorMessages = evaluateAcceptanceCriteria(criteria, apexTestDetails, userStories);
                
                updateTestAndConsolidatedResults(testResultIds, consolidatedResultId, acceptanceCriteriaErrorMessages);

                attachOutputFileToResult(getJobExecutionResultIds(resultRecord), resultRecord);

                if (String.isNotBlank(acceptanceCriteriaErrorMessages)) {
                    result.add(new EvaluateApexTestsCriteria.Response(acceptanceCriteriaErrorMessages));
                }
            } catch (Exception ex) {
                result.add(new Response(ex.getMessage() + ' ' + ex.getStackTraceString()));
            }
        }
        return result;
    }

    // PRIVATE

    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static void updateTestAndConsolidatedResults(List<Id> testResultIds, Id consolidatedResultId, String acceptanceCriteriaErrorMessages) {
        List<copado__Result__c> resultsToUpdate = new List<copado__Result__c>();
        String finalStatus = String.isBlank(acceptanceCriteriaErrorMessages) ? 'Success' : 'Failed';

        for (Id resultId : testResultIds) {
            resultsToUpdate.add(new copado__Result__c(
                Id = resultId,
                copado__Status__c = finalStatus,
                copado__Progress_Status__c = finalStatus,
                copado__Error_Message__c = acceptanceCriteriaErrorMessages
            ));
        }
        if (String.isNotBlank(acceptanceCriteriaErrorMessages) && String.isNotBlank(consolidatedResultId)) {
            resultsToUpdate.add(new copado__Result__c(
                Id = consolidatedResultId,
                copado__Error_Message__c = acceptanceCriteriaErrorMessages
            ));
        }
        Database.update(resultsToUpdate, true, AccessLevel.USER_MODE);
    }

    private static copado__Result__c getResult(Id resultId) {
        return new ResultsSelector().byIds(new Set<Id>{ resultId })[0];
    }

    private static List<copado__User_Story__c> getRelatedUserStories(copado__Result__c resultRecord) {
        List<copado__User_Story__c> result = new List<copado__User_Story__c>();
        Set<Id> testsIds = new Set<Id>();
        Set<Id> userStoryIds = new Set<Id>();

        String jobExecutionPayload = resultRecord?.copado__JobStep__r?.copado__JobExecution__r?.copado__DataJson__c;
        if (String.isNotBlank(jobExecutionPayload)) {
            Map<String, Object> jobPayload = (Map<String, Object>) JSON.deserializeUntyped(jobExecutionPayload);
            List<Object> testIds = (List<Object>) jobPayload.get('testIds');
            for (Object testId : testIds) {
                testsIds.add((Id) testId);
            }
            List<copado__Test__c> testItems = new TestsSelector().byIds(testsIds);
            for (copado__Test__c testItem : testItems) {
                userStoryIds.add(testItem.copado__User_Story__c);
            }
            result = new UserStoriesSelector()
                .byIdsWithUserStoryMetadataTypes(userStoryIds, new Set<String>{ APEX_CLASS, APEX_TRIGGER }, new Set<String>{ ADD });
        }
        return result;
    }

    private static String evaluateAcceptanceCriteria(
        AcceptanceCriteria criteria,
        UpdateTestsInfoOnStories.ApexTestDetails apexTestDetails,
        List<copado__User_Story__c> userStories
    ) {
        Set<String> result = new Set<String>();
        evaluateTestsRanCriteria(criteria, apexTestDetails.testsResult, result);
        evaluatePassingCriteria(criteria, apexTestDetails.testsResult, result);
        evaluateFailingCriteria(criteria, apexTestDetails.testsResult, result);
        evaluateSkippedCriteria(criteria, apexTestDetails.testsResult, result);
        evaluatePassRateCriteria(criteria, apexTestDetails.testsResult, result);
        evaluateFailRateCriteria(criteria, apexTestDetails.testsResult, result);
        evaluateCoverageCriteria(criteria, apexTestDetails, userStories, result);
        
        return result.isEmpty()
        ? ''
        : '- ' + String.join(new List<String>(result), '\n- ');
    }

    private static void evaluateTestsRanCriteria(AcceptanceCriteria criteria, ApexTestsResult testsResult, Set<String> errorMessage) {
        validateAcceptanceCriteria(criteria.testsRan, testsResult.result.summary.testsRan, errorMessage);
    }

    private static void evaluatePassingCriteria(AcceptanceCriteria criteria, ApexTestsResult testsResult, Set<String> errorMessage) {
        validateAcceptanceCriteria(criteria.passing, testsResult.result.summary.passing, errorMessage);
    }

    private static void evaluateFailingCriteria(AcceptanceCriteria criteria, ApexTestsResult testsResult, Set<String> errorMessage) {
        validateAcceptanceCriteria(criteria.failing, testsResult.result.summary.failing, errorMessage);
    }

    private static void evaluateSkippedCriteria(AcceptanceCriteria criteria, ApexTestsResult testsResult, Set<String> errorMessage) {
        validateAcceptanceCriteria(criteria.skipped, testsResult.result.summary.skipped, errorMessage);
    }

    private static void evaluatePassRateCriteria(AcceptanceCriteria criteria, ApexTestsResult testsResult, Set<String> errorMessage) {
        validateAcceptanceCriteria(criteria.passRate, testsResult.getPassRate(), errorMessage);
    }

    private static void evaluateFailRateCriteria(AcceptanceCriteria criteria, ApexTestsResult testsResult, Set<String> errorMessage) {
        validateAcceptanceCriteria(criteria.failRate, testsResult.getFailRate(), errorMessage);
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static void evaluateCoverageCriteria(
        AcceptanceCriteria criteria,
        UpdateTestsInfoOnStories.ApexTestDetails apexTestDetails,
        List<copado__User_Story__c> userStories,
        Set<String> errorMessage
    ) {
        CodeCoverageResult codeCoverageResult = getCoverageDetails(apexTestDetails, userStories);
        evaluateTestRunCoverageCriteria(criteria, codeCoverageResult.codeCoverage, errorMessage);
        evaluateClassesWithoutCoverageCriteria(criteria, codeCoverageResult.classesWithoutCoverage, errorMessage);
        evaluateTriggersWithoutCoverageCriteria(criteria, codeCoverageResult.triggersWithoutCoverage, errorMessage);
    }

    private static void evaluateTestRunCoverageCriteria(AcceptanceCriteria criteria, Integer testRunCoverage, Set<String> errorMessage) {
        validateAcceptanceCriteria(criteria.testRunCoverage, testRunCoverage, errorMessage);
    }

    private static void evaluateClassesWithoutCoverageCriteria(
        AcceptanceCriteria criteria,
        Integer classesWithoutCoverage,
        Set<String> errorMessage
    ) {
        validateAcceptanceCriteria(criteria.classesWithoutCoverage, classesWithoutCoverage, errorMessage);
    }

    private static void evaluateTriggersWithoutCoverageCriteria(
        AcceptanceCriteria criteria,
        Integer triggersWithoutCoverage,
        Set<String> errorMessage
    ) {
        validateAcceptanceCriteria(criteria.triggersWithoutCoverage, triggersWithoutCoverage, errorMessage);
    }

    private static Boolean isRequestValid(List<Request> requests) {
        return !requests.isEmpty() && String.isNotBlank(requests[0].resultId);
    }

    private static Id getConsolidatedResultId(Request request) {
        return String.isBlank(request.consolidatedResultId) ? null : request.consolidatedResultId;
    }

    private static void validateAcceptanceCriteria(CriteriaItem criteria, Integer apexTestResultValue, Set<String> errorMessage) {
        if (criteria != null && !criteria.passesEvaluationWith(apexTestResultValue)) {
            errorMessage.add(
                String.isNotBlank(criteria.errorDescription)
                    ? String.escapeSingleQuotes(criteria.errorDescription)
                    : Label.Apex_Test_Acceptance_Criteria_Failure_Message
            );
        }
    }

    private static CodeCoverageResult getCoverageDetails(
        UpdateTestsInfoOnStories.ApexTestDetails apexTestDetails,
        List<copado__User_Story__c> userStories
    ) {
        CodeCoverageResult result;
        ApexTestsResult testsResult = apexTestDetails.testsResult;
        Map<String, UserStoryMetadata> userStoryToMetadataMapping = apexTestDetails.userStoryToMetadataMapping;
        UserStoryMetadata userStoryMetadata;
        Set<String> classesWithoutCoverage = new Set<String>();
        Set<String> triggersWithoutCoverage = new Set<String>();
        Set<String> metadata = new Set<String>();

        if (userStories.size() == 1) {
            result = new CodeCoverageResult(
                apexTestDetails.codeCoverage,
                apexTestDetails.classesWithoutCoverage,
                apexTestDetails.triggersWithoutCoverage
            );
        } else {
            for (copado__User_Story__c userStory : userStories) {
                if (userStoryToMetadataMapping.containsKey(userStory.Id)) {
                    userStoryMetadata = userStoryToMetadataMapping.get(userStory.Id);
                    classesWithoutCoverage.addAll(
                        testsResult.getMetadataWithoutCoverage(
                            (Integer) userStory.copado__Minimum_Apex_Code_Coverage__c,
                            userStoryMetadata.userStoryClasses
                        )
                    );
                    triggersWithoutCoverage.addAll(
                        testsResult.getMetadataWithoutCoverage(
                            (Integer) userStory.copado__Minimum_Apex_Code_Coverage__c,
                            userStoryMetadata.userStoryTriggers
                        )
                    );
                    metadata.addAll(userStoryMetadata.userStoryClasses);
                    metadata.addAll(userStoryMetadata.userStoryTriggers);
                }
            }
            result = new CodeCoverageResult(testsResult.getTestRunCoverage(metadata), classesWithoutCoverage.size(), triggersWithoutCoverage.size());
        }
        return result;
    }

    private static Set<Id> getJobExecutionResultIds(copado__Result__c resultRecord) {
        Set<Id> result = new Set<Id>();

        String jobExecutionPayload = resultRecord?.copado__JobStep__r?.copado__JobExecution__r?.copado__DataJson__c;

        if (String.isNotBlank(jobExecutionPayload)) {
            JobExecutionPayload jobPayload = (JobExecutionPayload) System.JSON.deserialize(jobExecutionPayload, JobExecutionPayload.class);

            if (String.isNotBlank(jobPayload.resultId)) {
                result.add((Id) jobPayload.resultId);
            } else if (jobPayload.resultIds != null || !jobPayload.resultIds.isEmpty()) {
                result.addAll((List<Id>) jobPayload.resultIds);
            }
        }

        return result;
    }

    private static void attachOutputFileToResult(Set<Id> resultIds, copado__Result__c lastStepResult) {
        if (!resultIds.isEmpty()) {
            List<ContentDocumentLink> fileLinks = new ContentDocumentLinksSelector().byLinkedEntityIdAndTitles(resultIds, new Set<String>{OUTPUT_FILE_NAME});

            if (!fileLinks.isEmpty()) {
                Utilities.performDML(new List<ContentDocumentLink> {new ContentDocumentLink(LinkedEntityId = lastStepResult.Id, ContentDocumentId = fileLinks[0].ContentDocumentId)}, 'insert', AccessLevel.SYSTEM_MODE);
            }
        }
    }

    // INNER PUBLIC

    public with sharing class Request {
        @InvocableVariable(
            label='Acceptance Criteria (JSON)'
            description='Acceptance Criteria that will be evaluated to compute the Test Result final status'
        )
        public String acceptanceCriteria;

        @InvocableVariable(label='Tests Results' description='Test result ids, provided by the DataJson__c (Payload) in the Job Execution')
        public String resultIds;

        @InvocableVariable(
            label='Consolidated Result'
            description='Consolidated result id, provided by the DataJson__c (Payload) in the Job Execution'
        )
        public String consolidatedResultId;

        @InvocableVariable(label='Result Id' description='The result id of job step')
        public String resultId;

        @InvocableVariable(label='File With Selected Changes' description='This is the file id of the changes selected on the user story')
        public String fileWithSelectedChanges;

        @InvocableVariable(label='Recreate Feature Branch')
        public String recreateFeatureBranch;

        @SuppressWarnings('PMD.EmptyStatementBlock')
        public Request() {
        }

        @TestVisible
        @SuppressWarnings('PMD.ExcessiveParameterList')
        private Request(String acceptanceCriteria, String resultIds, String consolidatedResultId, String resultId) {
            this.acceptanceCriteria = acceptanceCriteria;
            this.resultIds = resultIds;
            this.consolidatedResultId = consolidatedResultId;
            this.resultId = resultId;
        }

        @TestVisible
        @SuppressWarnings('PMD.ExcessiveParameterList')
        private Request(String acceptanceCriteria, String resultIds, String consolidatedResultId, String resultId, Id fileWithSelectedChanges, String recreateFeatureBranch) { 
            this(acceptanceCriteria, resultIds, consolidatedResultId, resultId);
            this.fileWithSelectedChanges = fileWithSelectedChanges;
            this.recreateFeatureBranch = recreateFeatureBranch;
        }

        public List<Id> getParsedResultIds() {
            return String.isNotBlank(resultIds) ? (List<Id>) JSON.deserialize(resultIds, List<Id>.class) : new List<Id>();
        }

        public AcceptanceCriteria getParsedAcceptanceCriteria() {
            return (AcceptanceCriteria) JSON.deserialize(acceptanceCriteria.unescapeUnicode(), AcceptanceCriteria.class);
        }
    }

    public class Response {
        @InvocableVariable(label='Response')
        public String message;

        public Response(String message) {
            this.message = message;
        }
    }

    // INNER PRIVATE

    private class AcceptanceCriteria {
        public CriteriaItem testsRan;
        public CriteriaItem passing;
        public CriteriaItem failing;
        public CriteriaItem skipped;
        public CriteriaItem passRate;
        public CriteriaItem failRate;
        public CriteriaItem testRunCoverage;
        public CriteriaItem classesWithoutCoverage;
        public CriteriaItem triggersWithoutCoverage;
    }

    private class CriteriaItem {
        private String operator;
        private String input;
        private String type;
        private String errorDescription;

        public Boolean passesEvaluationWith(Integer value) {
            Integer criteriaInput = getInputAsInteger();

            switch on operator.toLowerCase() {
                when 'equals' {
                    return value == criteriaInput;
                }
                when 'equals or greater than' {
                    return value >= criteriaInput;
                }
                when 'equals or less than' {
                    return value <= criteriaInput;
                }
                when 'greater than' {
                    return value > criteriaInput;
                }
                when 'less than' {
                    return value < criteriaInput;
                }
                when else {
                    return false;
                }
            }
        }

        private Integer getInputAsInteger() {
            return (Integer) Decimal.valueOf(input).round();
        }
    }

    private class CodeCoverageResult {
        public Integer codeCoverage;
        public Integer classesWithoutCoverage;
        public Integer triggersWithoutCoverage;

        public CodeCoverageResult(Integer codeCoverage, Integer classesWithoutCoverage, Integer triggersWithoutCoverage) {
            this.codeCoverage = codeCoverage;
            this.classesWithoutCoverage = classesWithoutCoverage;
            this.triggersWithoutCoverage = triggersWithoutCoverage;
        }
    }

    private class JobExecutionPayload {
        private String resultId;
        private List<String> resultIds;
    }
}