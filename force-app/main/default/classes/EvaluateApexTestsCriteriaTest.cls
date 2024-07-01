@IsTest
private class EvaluateApexTestsCriteriaTest {
    private static String completeAcceptanceCriteria = '{"testsRan":{"operator":"Equals or Greater than","input":"1","type":"Integer","errorDescription":"Error : The tests run should be equals to or greater than 1"},"passing":{"operator":"Equals or Greater than","input":"1","type":"Integer","errorDescription":"Error : The passing methods should be equals to or greater than 1"},"failing":{"operator":"Equals","input":"0","type":"Integer","errorDescription":"Error : There should be no failing methods"},"skipped":{"operator":"Equals","input":"0","type":"Integer","errorDescription":"Error : There should be no skipped methods"},"passRate":{"operator":"Greater than","input":"50","type":"Percent","errorDescription":"Error : The pass rate should be greater than 50%"},"failRate":{"operator":"Less than","input":"50","type":"Percent","errorDescription":"Error : The fail rate should be less than 50%"},"testRunCoverage":{"operator":"Equals or Greater than","input":"75","type":"Percent","errorDescription":"Error : The test run coverage should be equals to or greater than 75%"},"triggersWithoutCoverage":{"operator":"Equals","input":"0","type":"Integer","errorDescription":"Error : All the apex triggers should pass the minimum coverage criteria of the user story"},"classesWithoutCoverage":{"operator":"Equals","input":"0","type":"Integer","errorDescription":"Error : All the apex classes should pass the minimum coverage criteria of the user story"}}';
    private final static String COPADO_COMMIT_CHANGES = 'Copado Commit changes';
    
    @IsTest
    private static void executeWithOnlyTestResults() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            GetApexCodeCoverageFromOrg.mockNonCoveredItemsResponse = '{"statusCode":200,"content":"{\\"records\\":[]}"}';
            EvaluateApexTestsCriteria.Request request = new EvaluateApexTestsCriteria.Request(
                completeAcceptanceCriteria,
                getMockTestResults(),
                '',
                getFlowResult().Id
            );
            List<EvaluateApexTestsCriteria.Request> requests = new List<EvaluateApexTestsCriteria.Request>{ request };

            // EXERCISE
            Test.startTest();
            List<EvaluateApexTestsCriteria.Response> result = EvaluateApexTestsCriteria.execute(requests);
            Test.stopTest();

            // VERIFY
            copado__User_Story__c updatedUserStory = getUserStory();

            for (copado__Result__c testResult : getTestResults()) {
                Assert.areEqual('Failed', testResult.copado__Status__c, 'Test result has 1 failing method but should be 0 according to the AC');
                Assert.areEqual(
                    'Failed',
                    testResult.copado__Progress_Status__c,
                    'Test result has 1 failing method but should be 0 according to the AC'
                );
                Assert.areEqual(
                    '- Error : There should be no failing methods',
                    testResult.copado__Error_Message__c,
                    'The error message of result is incorrect'
                );
            }

            Assert.isFalse(result.isEmpty(), 'The response should not be empty if the apex test results do not match the acceptance criteria');
            Assert.areEqual(
                '- Error : There should be no failing methods',
                result[0].message,
                'The error message of result is incorrect'
            );

            // @Note: Class covered in the test result has a total of 200 lines, where 175 are covered
            // The coverage should be trunc(175/(200))*100 = 87
            Assert.areEqual(87, updatedUserStory.copado__Apex_Code_Coverage__c, 'Average test run coverage should be 87 ((100+75)/2) * 100');
            Assert.areEqual(1, updatedUserStory.copado__Failing_Methods__c, 'There should be one failing method');
            Assert.areEqual(0, updatedUserStory.copado__Classes_Without_Coverage__c, 'There should be no apex class without coverage');
            Assert.areEqual(0, updatedUserStory.copado__Triggers_Without_Coverage__c, 'There should be no apex trigger without coverage');
            
            List<ContentDocumentLink> fileLinks = new ContentDocumentLinksSelector()
            .byLinkedEntityIdAndTitles(new Set<Id>{ getFlowResult().Id }, new Set<String>{'apex-tests-output.json'});
            Assert.areEqual(1, fileLinks.size(), 'The flow result has the related file.');
        }
    }

    @IsTest
    private static void executeWithOnlyConsolidatedResult() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            GetApexCodeCoverageFromOrg.mockNonCoveredItemsResponse = '{"statusCode":200,"content":"{\\"records\\":[]}"}';
            EvaluateApexTestsCriteria.Request request = new EvaluateApexTestsCriteria.Request(
                completeAcceptanceCriteria,
                '[]',
                getMockConsolidatedResult(),
                getFlowResult().Id
            );
            List<EvaluateApexTestsCriteria.Request> requests = new List<EvaluateApexTestsCriteria.Request>{ request };

            // EXERCISE
            Test.startTest();
            List<EvaluateApexTestsCriteria.Response> result = EvaluateApexTestsCriteria.execute(requests);
            Test.stopTest();

            // VERIFY
            copado__User_Story__c updatedUserStory = getUserStory();

            copado__Result__c consolidatedResult = getConsolidatedResult();
            Assert.areNotEqual(
                'Failed',
                consolidatedResult.copado__Status__c,
                'The consolidated result copado__Status__c field should not be updated'
            );
            Assert.areNotEqual(
                'Failed',
                consolidatedResult.copado__Progress_Status__c,
                'The consolidated result copado__Progress_Status__c field should not be updated'
            );
            Assert.areEqual(
                '- Error : There should be no failing methods',
                consolidatedResult.copado__Error_Message__c,
                'The error message of result is incorrect'
            );
            Assert.isFalse(result.isEmpty(), 'The error message should be returned in the response');
            Assert.areEqual(
                '- Error : There should be no failing methods',
                result[0].message,
                'The error message of result is incorrect'
            );

            // @Note: Class covered in the test result has a total of 200 lines, where 175 are covered
            // The coverage should be trunc(175/(200))*100 = 87
            Assert.areEqual(87, updatedUserStory.copado__Apex_Code_Coverage__c, 'Average test run coverage should be 87 ((100+75)/2) * 100');
            Assert.areEqual(1, updatedUserStory.copado__Failing_Methods__c, 'There should be one failing method');
            Assert.areEqual(0, updatedUserStory.copado__Classes_Without_Coverage__c, 'There should be no apex class without coverage');
            Assert.areEqual(0, updatedUserStory.copado__Triggers_Without_Coverage__c, 'There should be no apex trigger without coverage');
        }
    }

    @IsTest
    private static void executeWithExactSkippedToZero() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            GetApexCodeCoverageFromOrg.mockNonCoveredItemsResponse = '{"statusCode":200,"content":"{\\"records\\":[]}"}';
            String acceptanceCriteria = '{"skipped":{"operator":"Equals","input":"0","type":"Integer","errorDescription":"..."}}';
            EvaluateApexTestsCriteria.Request request = new EvaluateApexTestsCriteria.Request(
                acceptanceCriteria,
                getMockTestResults(),
                getMockConsolidatedResult(),
                getFlowResult().Id
            );
            List<EvaluateApexTestsCriteria.Request> requests = new List<EvaluateApexTestsCriteria.Request>{ request };

            // EXERCISE
            Test.startTest();
            List<EvaluateApexTestsCriteria.Response> result = EvaluateApexTestsCriteria.execute(requests);
            Test.stopTest();

            // VERIFY Consolidated Result
            copado__User_Story__c updatedUserStory = getUserStory();

            copado__Result__c consolidatedResult = getConsolidatedResult();
            Assert.areNotEqual('Success', consolidatedResult.copado__Status__c, 'The consolidated result copado__Status__c field should not be updated');
            Assert.areNotEqual('Success', consolidatedResult.copado__Progress_Status__c, 'The consolidated result copado__Progress_Status__c field should not be updated');
            Assert.isTrue(String.isBlank(consolidatedResult.copado__Error_Message__c), 'The error message of result should be blank');

            // VERIFY Test Results
            for (copado__Result__c testResult : getTestResults()) {
                Assert.areEqual('Success', testResult.copado__Status__c, 'Skipped tests is 0 and required is exaclty is 0');
                Assert.areEqual('Success', testResult.copado__Progress_Status__c, 'Skipped tests is 0 and required is exaclty is 0');
                Assert.isTrue(String.isBlank(testResult.copado__Error_Message__c), 'The error message of result should be blank');
            }
            Assert.isTrue(result.isEmpty(), 'The response should be empty if test results match the evaluation criteria');

            // @Note: Class covered in the test result has a total of 200 lines, where 175 are covered
            // The coverage should be trunc(175/(200))*100 = 87
            Assert.areEqual(87, updatedUserStory.copado__Apex_Code_Coverage__c, 'Average test run coverage should be 87 ((100+75)/2) * 100');
            Assert.areEqual(1, updatedUserStory.copado__Failing_Methods__c, 'There should be one failing method');
            Assert.areEqual(0, updatedUserStory.copado__Classes_Without_Coverage__c, 'There should be no apex class without coverage');
            Assert.areEqual(0, updatedUserStory.copado__Triggers_Without_Coverage__c, 'There should be no apex trigger without coverage');
        }
    }

    @IsTest
    private static void executeWithBadTestRunCoverage() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            GetApexCodeCoverageFromOrg.mockNonCoveredItemsResponse = '{"statusCode":200,"content":"{\\"records\\":[]}"}';
            String acceptanceCriteria = '{"testRunCoverage":{"operator":"Equals or Greater than","input":"90","type":"Percent","errorDescription":""}}';
            EvaluateApexTestsCriteria.Request request = new EvaluateApexTestsCriteria.Request(
                acceptanceCriteria,
                getMockTestResults(),
                getMockConsolidatedResult(),
                getFlowResult().Id
            );
            List<EvaluateApexTestsCriteria.Request> requests = new List<EvaluateApexTestsCriteria.Request>{ request };

            // EXERCISE
            Test.startTest();
            List<EvaluateApexTestsCriteria.Response> result = EvaluateApexTestsCriteria.execute(requests);
            Test.stopTest();

            // VERIFY Consolidated Result
            copado__User_Story__c updatedUserStory = getUserStory();

            copado__Result__c consolidatedResult = getConsolidatedResult();
            Assert.areNotEqual('Failed', consolidatedResult.copado__Status__c, 'The consolidated result copado__Status__c field should not be updated');
            Assert.areNotEqual('Failed', consolidatedResult.copado__Progress_Status__c, 'The consolidated result copado__Progress_Status__c field should not be updated');
            Assert.areEqual(
                '- ' + Label.Apex_Test_Acceptance_Criteria_Failure_Message,
                consolidatedResult.copado__Error_Message__c,
                'The error message of result is incorrect'
            );

            // VERIFY Test Results
            for (copado__Result__c testResult : getTestResults()) {
                Assert.areEqual('Failed', testResult.copado__Status__c, 'Coverage is 85% and minimum is 90');
                Assert.areEqual('Failed', testResult.copado__Progress_Status__c, 'Coverage is 85% and minimum is 90');
                Assert.areEqual(
                    '- ' + Label.Apex_Test_Acceptance_Criteria_Failure_Message,
                    testResult.copado__Error_Message__c,
                    'The error message of result is incorrect'
                );
            }
            Assert.isFalse(result.isEmpty(), 'The error message should be returned in the response');
            Assert.areEqual(
                    '- ' + Label.Apex_Test_Acceptance_Criteria_Failure_Message,
                    result[0].message,
                    'The error message of result is incorrect'
                );

            // @Note: Class covered in the test result has a total of 200 lines, where 175 are covered
            // The coverage should be trunc(175/(200))*100 = 87
            Assert.areEqual(87, updatedUserStory.copado__Apex_Code_Coverage__c, 'Average test run coverage should be 87 ((100+75)/2) * 100');
            Assert.areEqual(1, updatedUserStory.copado__Failing_Methods__c, 'There should be one failing method');
            Assert.areEqual(0, updatedUserStory.copado__Classes_Without_Coverage__c, 'There should be no apex class without coverage');
            Assert.areEqual(0, updatedUserStory.copado__Triggers_Without_Coverage__c, 'There should be no apex trigger without coverage');
        }
    }

    @IsTest
    private static void executeWithCorrectPassRateButIncorrectFailRate() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            GetApexCodeCoverageFromOrg.mockNonCoveredItemsResponse = '{"statusCode":200,"content":"{\\"records\\":[]}"}';
            String acceptanceCriteria = '{"passRate":{"operator":"Equals or Greater than","input":"60","type":"Percent","errorDescription":"..."},"failRate":{"operator":"Less than","input":"10","type":"Percent","errorDescription":"Error : The fail rate should be less than 10%"}}';
            EvaluateApexTestsCriteria.Request request = new EvaluateApexTestsCriteria.Request(
                acceptanceCriteria,
                getMockTestResults(),
                getMockConsolidatedResult(),
                getFlowResult().Id
            );
            List<EvaluateApexTestsCriteria.Request> requests = new List<EvaluateApexTestsCriteria.Request>{ request };

            // EXERCISE
            Test.startTest();
            List<EvaluateApexTestsCriteria.Response> result = EvaluateApexTestsCriteria.execute(requests);
            Test.stopTest();

            // VERIFY Consolidated Result
            copado__User_Story__c updatedUserStory = getUserStory();

            copado__Result__c consolidatedResult = getConsolidatedResult();
            Assert.areNotEqual('Failed', consolidatedResult.copado__Status__c, 'The consolidated result copado__Status__c field should not be updated');
            Assert.areNotEqual('Failed', consolidatedResult.copado__Progress_Status__c, 'The consolidated result copado__Progress_Status__c field should not be updated');
            Assert.areEqual(
                '- Error : The fail rate should be less than 10%',
                consolidatedResult.copado__Error_Message__c,
                'The error message of result is incorrect'
            );
            Assert.isFalse(result.isEmpty(), 'The error message should be returned in the response');
            Assert.areEqual(
                '- Error : The fail rate should be less than 10%',
                    result[0].message,
                    'The error message of result is incorrect'
                );

            // VERIFY Test Results
            for (copado__Result__c testResult : getTestResults()) {
                Assert.areEqual('Failed', testResult.copado__Status__c, 'Fail rate should be "Less than" 10%');
                Assert.areEqual('Failed', testResult.copado__Progress_Status__c, 'Fail rate should be "Less than" 10%');
                Assert.areEqual(
                    '- Error : The fail rate should be less than 10%',
                    testResult.copado__Error_Message__c,
                    'The error message of result is incorrect'
                );
            }

            // @Note: Class covered in the test result has a total of 200 lines, where 175 are covered
            // The coverage should be trunc(175/(200))*100 = 87
            Assert.areEqual(87, updatedUserStory.copado__Apex_Code_Coverage__c, 'Average test run coverage should be 87 ((100+75)/2) * 100');
            Assert.areEqual(1, updatedUserStory.copado__Failing_Methods__c, 'There should be one failing method');
            Assert.areEqual(0, updatedUserStory.copado__Classes_Without_Coverage__c, 'There should be no apex class without coverage');
            Assert.areEqual(0, updatedUserStory.copado__Triggers_Without_Coverage__c, 'There should be no apex trigger without coverage');
        }
    }

    @IsTest
    private static void executeWithCorrectPassRateAndFailRate() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            GetApexCodeCoverageFromOrg.mockNonCoveredItemsResponse = '{"statusCode":200,"content":"{\\"records\\":[]}"}';
            String acceptanceCriteria = '{"passRate":{"operator":"Equals or Greater than","input":"60","type":"Percent","errorDescription":"..."},"failRate":{"operator":"Less than","input":"50","type":"Percent","errorDescription":"..."}}';
            EvaluateApexTestsCriteria.Request request = new EvaluateApexTestsCriteria.Request(
                acceptanceCriteria,
                getMockTestResults(),
                getMockConsolidatedResult(),
                getFlowResult().Id
            );
            List<EvaluateApexTestsCriteria.Request> requests = new List<EvaluateApexTestsCriteria.Request>{ request };

            // EXERCISE
            Test.startTest();
            List<EvaluateApexTestsCriteria.Response> result = EvaluateApexTestsCriteria.execute(requests);
            Test.stopTest();

            // VERIFY Consolidated Result
            copado__User_Story__c updatedUserStory = getUserStory();

            copado__Result__c consolidatedResult = getConsolidatedResult();
            Assert.areNotEqual('Success', consolidatedResult.copado__Status__c, 'The consolidated result copado__Status__c field should not be updated');
            Assert.areNotEqual('Success', consolidatedResult.copado__Progress_Status__c, 'The consolidated result copado__Progress_Status__c field should not be updated');
            Assert.isTrue(String.isBlank(consolidatedResult.copado__Error_Message__c), 'The error message of result should be blank');

            // VERIFY
            for (copado__Result__c testResult : getTestResults()) {
                Assert.areEqual('Success', testResult.copado__Status__c, 'Both pass and fail rates should be passing the criteria');
                Assert.areEqual('Success', testResult.copado__Progress_Status__c, 'Both pass and fail rates should be passing the criteria');
                Assert.isTrue(String.isBlank(testResult.copado__Error_Message__c), 'The error message of result should be blank');
            }

            Assert.isTrue(result.isEmpty(), 'The response should be empty if test results match the evaluation criteria');

            // @Note: Class covered in the test result has a total of 200 lines, where 175 are covered
            // The coverage should be trunc(175/(200))*100 = 87
            Assert.areEqual(87, updatedUserStory.copado__Apex_Code_Coverage__c, 'Average test run coverage should be 87 ((100+75)/2) * 100');
            Assert.areEqual(1, updatedUserStory.copado__Failing_Methods__c, 'There should be one failing method');
            Assert.areEqual(0, updatedUserStory.copado__Classes_Without_Coverage__c, 'There should be no apex class without coverage');
            Assert.areEqual(0, updatedUserStory.copado__Triggers_Without_Coverage__c, 'There should be no apex trigger without coverage');
        }
    }

    @IsTest
    private static void executeWithClassesAndTriggersWithoutTestsCoveringThose() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            copado__User_Story__c userStory = getUserStory();
            insert new List<copado__User_Story_Metadata__c>{
                initUserStoryMetadata('HelloMoon', 'ApexClass', userStory.Id),
                initUserStoryMetadata('SampleTrigger', 'ApexTrigger', userStory.Id)
            };
            GetApexCodeCoverageFromOrg.mockNonCoveredItemsResponse = getUncoveredUSItemsResponse();
            EvaluateApexTestsCriteria.Request request = new EvaluateApexTestsCriteria.Request(
                completeAcceptanceCriteria,
                getMockTestResults(),
                '',
                getFlowResult().Id
            );
            List<EvaluateApexTestsCriteria.Request> requests = new List<EvaluateApexTestsCriteria.Request>{ request };

            // EXERCISE
            Test.startTest();
            List<EvaluateApexTestsCriteria.Response> result = EvaluateApexTestsCriteria.execute(requests);
            Test.stopTest();

            // VERIFY
            copado__User_Story__c updatedUserStory = getUserStory();

            for (copado__Result__c testResult : getTestResults()) {
                Assert.areEqual('Failed', testResult.copado__Status__c, 'Test result has 1 failing method but should be 0 according to the AC');
                Assert.areEqual(
                    'Failed',
                    testResult.copado__Progress_Status__c,
                    'Test result has 1 failing method but should be 0 according to the AC'
                );
                Assert.areEqual(
                    '- Error : There should be no failing methods\n- Error : The test run coverage should be equals to or greater than 75%\n- Error : All the apex classes should pass the minimum coverage criteria of the user story\n- Error : All the apex triggers should pass the minimum coverage criteria of the user story',
                    testResult.copado__Error_Message__c,
                    'The error message of result is incorrect'
                );
            }
            Assert.isFalse(result.isEmpty(), 'The response should not be empty if the test results do not match the acceptance criteria');
            Assert.areEqual(
                '- Error : There should be no failing methods\n- Error : The test run coverage should be equals to or greater than 75%\n- Error : All the apex classes should pass the minimum coverage criteria of the user story\n- Error : All the apex triggers should pass the minimum coverage criteria of the user story',
                result[0].message,
                'The error message of result is incorrect'
            );

            // @Note: Class covered in the test result has a total of 200 lines, where 175 are covered.
            // The user story contains 1 apex class and 1 apex trigger uncovered by the test result, with a total of 200 lines.
            // The coverage should be trunc(175/(200+200))*100 = 43%
            Assert.areEqual(43, updatedUserStory.copado__Apex_Code_Coverage__c, 'Average test run coverage should be 43 (175/(200+200))*100');
            Assert.areEqual(1, updatedUserStory.copado__Failing_Methods__c, 'There should be one failing method');
            Assert.areEqual(1, updatedUserStory.copado__Classes_Without_Coverage__c, 'There should be 1 apex class without coverage');
            Assert.areEqual(1, updatedUserStory.copado__Triggers_Without_Coverage__c, 'There should be 1 apex trigger without coverage');
        }
    }

    @IsTest
    private static void executeWithOnlyTestClasses() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            copado__User_Story__c userStory = getUserStory();
            deleteUserStoryMetadata(userStory);
            insert new List<copado__User_Story_Metadata__c>{ initUserStoryMetadata('HelloMarsTest', 'ApexClass', userStory.Id) };
            GetApexCodeCoverageFromOrg.mockNonCoveredItemsResponse = getUncoveredUSItemsResponse();
            EvaluateApexTestsCriteria.Request request = new EvaluateApexTestsCriteria.Request(
                completeAcceptanceCriteria,
                getMockTestResults(),
                '',
                getFlowResult().Id
            );
            List<EvaluateApexTestsCriteria.Request> requests = new List<EvaluateApexTestsCriteria.Request>{ request };

            // EXERCISE
            Test.startTest();
            List<EvaluateApexTestsCriteria.Response> result = EvaluateApexTestsCriteria.execute(requests);
            Test.stopTest();

            // VERIFY
            copado__User_Story__c updatedUserStory = getUserStory();

            for (copado__Result__c testResult : getTestResults()) {
                Assert.areEqual('Failed', testResult.copado__Status__c, 'Test result has 1 failing method but should be 0 according to the AC');
                Assert.areEqual(
                    'Failed',
                    testResult.copado__Progress_Status__c,
                    'Test result has 1 failing method but should be 0 according to the AC'
                );
                Assert.areEqual(
                    '- Error : There should be no failing methods',
                    testResult.copado__Error_Message__c,
                    'The error message of result is incorrect'
                );
            }
            Assert.isFalse(result.isEmpty(), 'The response should not be empty in case the apex tests do not match the acceptance criteria');
            Assert.areEqual(
                '- Error : There should be no failing methods',
               result[0].message,
                'The error message of result is incorrect'
            );
            Assert.areEqual(
                100,
                updatedUserStory.copado__Apex_Code_Coverage__c,
                'We committed only test classes, so the coverage should be 100 %'
            );
            Assert.areEqual(1, updatedUserStory.copado__Failing_Methods__c, 'There should be one failing method');
            Assert.areEqual(0, updatedUserStory.copado__Classes_Without_Coverage__c, 'There should be no apex class without coverage');
            Assert.areEqual(0, updatedUserStory.copado__Triggers_Without_Coverage__c, 'There should be no apex trigger without coverage');
        }
    }
    @IsTest
    private static void executeCriteriaWithDecimals() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            GetApexCodeCoverageFromOrg.mockNonCoveredItemsResponse = '{"statusCode":200,"content":"{\\"records\\":[]}"}';
            String acceptanceCriteria = '{"passRate":{"operator":"Equals or Greater than","input":"66.2","type":"Percent","errorDescription":"..."},"failRate":{"operator":"Less than","input":"31.8","type":"Percent","errorDescription":"Error : The fail rate should be less than 32%"}}';
            EvaluateApexTestsCriteria.Request request = new EvaluateApexTestsCriteria.Request(
                acceptanceCriteria,
                getMockTestResults(),
                getMockConsolidatedResult(),
                getFlowResult().Id
            );
            List<EvaluateApexTestsCriteria.Request> requests = new List<EvaluateApexTestsCriteria.Request>{ request };

            // EXERCISE
            Test.startTest();
            List<EvaluateApexTestsCriteria.Response> result = EvaluateApexTestsCriteria.execute(requests);
            Test.stopTest();

            // VERIFY Consolidated Result
            copado__User_Story__c updatedUserStory = getUserStory();

            copado__Result__c consolidatedResult = getConsolidatedResult();
            
            Assert.areNotEqual('Failed', consolidatedResult.copado__Status__c, 'The consolidated result copado__Status__c field should not be updated');
            Assert.areNotEqual('Failed', consolidatedResult.copado__Progress_Status__c, 'The consolidated result copado__Progress_Status__c field should not be updated');
            Assert.areEqual(
                '- Error : The fail rate should be less than 32%',
                consolidatedResult.copado__Error_Message__c,
                'The error message of result is incorrect'
            );

            // VERIFY Test Results
            for (copado__Result__c testResult : getTestResults()) {
                Assert.areEqual('Failed', testResult.copado__Status__c, 'Fail rate should be "Less than" 32%');
                Assert.areEqual('Failed', testResult.copado__Progress_Status__c, 'Fail rate should be "Less than" 32%');
                Assert.areEqual(
                    '- Error : The fail rate should be less than 32%',
                    testResult.copado__Error_Message__c,
                    'The error message of result is incorrect'
                );
            }
            Assert.isFalse(result.isEmpty(), 'The error message should be returned in the response');
            Assert.areEqual(
                    '- Error : The fail rate should be less than 32%',
                    result[0].message,
                    'The error message of result is incorrect'
                );

            // @Note: Class covered in the test result has a total of 200 lines, where 175 are covered
            // The coverage should be trunc(175/(200))*100 = 87
            Assert.areEqual(87, updatedUserStory.copado__Apex_Code_Coverage__c, 'Average test run coverage should be 87 ((100+75)/2) * 100');
            Assert.areEqual(1, updatedUserStory.copado__Failing_Methods__c, 'There should be one failing method');
            Assert.areEqual(0, updatedUserStory.copado__Classes_Without_Coverage__c, 'There should be no apex class without coverage');
            Assert.areEqual(0, updatedUserStory.copado__Triggers_Without_Coverage__c, 'There should be no apex trigger without coverage');
        }
    }

    @IsTest
    private static void executeWithCommitQualityGate() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            copado__User_Story__c userStory = getUserStory();

            GetApexCodeCoverageFromOrg.mockNonCoveredItemsResponse = getUncoveredUSItemsResponse();
                
            createContentVersionOn(getCommitChangesWithNonCoveredApex(), COPADO_COMMIT_CHANGES, userStory.Id);
            

            EvaluateApexTestsCriteria.Request request = new EvaluateApexTestsCriteria.Request(
                completeAcceptanceCriteria,
                '[]',
                getConsolidatedResult().Id,
                getFlowResult().Id,
                getContentVersion(COPADO_COMMIT_CHANGES).Id,
                'false'
            );

            List<EvaluateApexTestsCriteria.Request> requests = new List<EvaluateApexTestsCriteria.Request>{ request };

            // EXERCISE
            Test.startTest();
            List<EvaluateApexTestsCriteria.Response> result = EvaluateApexTestsCriteria.execute(requests);
            Test.stopTest();

            // VERIFY
            copado__User_Story__c updatedUserStory = getUserStory();

            copado__Result__c consolidatedResult = getConsolidatedResult();
                Assert.areNotEqual('Failed', consolidatedResult.copado__Status__c, 'The consolidated result copado__Status__c field should not be updated');
                Assert.areNotEqual(
                    'Failed',
                    consolidatedResult.copado__Progress_Status__c,
                    'The consolidated result copado__Progress_Status__c field should not be updated'
                );
                Assert.areEqual(
                    '- Error : There should be no failing methods\n- Error : The test run coverage should be equals to or greater than 75%\n- Error : All the apex classes should pass the minimum coverage criteria of the user story\n- Error : All the apex triggers should pass the minimum coverage criteria of the user story',
                    consolidatedResult.copado__Error_Message__c,
                    'The error message of result is incorrect'
                );
                Assert.isFalse(result.isEmpty(), 'The error message should be returned in the response');
                Assert.areEqual(
                    '- Error : There should be no failing methods\n- Error : The test run coverage should be equals to or greater than 75%\n- Error : All the apex classes should pass the minimum coverage criteria of the user story\n- Error : All the apex triggers should pass the minimum coverage criteria of the user story',
                    result[0].message,
                    'The error message of result is incorrect'
                );

            // @Note: Class covered in the test result has a total of 200 lines, where 175 are covered.
            // The user story contains 1 apex class and 1 apex trigger uncovered by the test result, with a total of 200 lines.
            // The coverage should be trunc(175/(200+200))*100 = 43%
            Assert.areEqual(43, updatedUserStory.copado__Apex_Code_Coverage__c, 'Average test run coverage should be 43 (175/(200+200))*100');
            Assert.areEqual(1, updatedUserStory.copado__Failing_Methods__c, 'There should be one failing method');
            Assert.areEqual(1, updatedUserStory.copado__Classes_Without_Coverage__c, 'There should be 1 apex class without coverage');
            Assert.areEqual(1, updatedUserStory.copado__Triggers_Without_Coverage__c, 'There should be 1 apex trigger without coverage');
        }
    }
    
    @IsTest
    private static void executeWithCommitQualityGateWithRecreateFeatureBranch() {
        System.runAs( TestUtilities.getRunAsUser()) {
            // SETUP
            copado__User_Story__c userStory = getUserStory();

            GetApexCodeCoverageFromOrg.mockNonCoveredItemsResponse = getUncoveredUSItemsResponse();
                
            createContentVersionOn(getCommitChangesWithCoveredApex(), COPADO_COMMIT_CHANGES, userStory.Id);
            

            EvaluateApexTestsCriteria.Request request = new EvaluateApexTestsCriteria.Request(
                completeAcceptanceCriteria,
                '[]',
                getConsolidatedResult().Id,
                getFlowResult().Id,
                getContentVersion(COPADO_COMMIT_CHANGES).Id,
                'true'
            );

            List<EvaluateApexTestsCriteria.Request> requests = new List<EvaluateApexTestsCriteria.Request>{ request };

            // EXERCISE
            Test.startTest();
            List<EvaluateApexTestsCriteria.Response> result = EvaluateApexTestsCriteria.execute(requests);
            Test.stopTest();

            // VERIFY
            copado__User_Story__c updatedUserStory = getUserStory();

            copado__Result__c consolidatedResult = getConsolidatedResult();
                Assert.areNotEqual('Failed', consolidatedResult.copado__Status__c, 'The consolidated result copado__Status__c field should not be updated');
                Assert.areNotEqual(
                    'Failed',
                    consolidatedResult.copado__Progress_Status__c,
                    'The consolidated result copado__Progress_Status__c field should not be updated'
                );
                Assert.areEqual(
                    '- Error : There should be no failing methods',
                    consolidatedResult.copado__Error_Message__c,
                    'The error message of result is incorrect'
                );
                Assert.isFalse(result.isEmpty(), 'The error message should be returned in the response');
                Assert.areEqual(
                    '- Error : There should be no failing methods',
                    result[0].message,
                    'The error message of result is incorrect'
                );

            // @Note: Class covered in the test result has a total of 200 lines, where 175 are covered.
            // The user story contains 1 apex class and 1 apex trigger uncovered by the test result, with a total of 200 lines.
            // The coverage should be trunc(175/(200+200))*100 = 43%
            Assert.areEqual(100, updatedUserStory.copado__Apex_Code_Coverage__c, 'Average test run coverage should be 43 (175/(200+200))*100');
            Assert.areEqual(1, updatedUserStory.copado__Failing_Methods__c, 'There should be one failing method');
            Assert.areEqual(0, updatedUserStory.copado__Classes_Without_Coverage__c, 'There should be 1 apex class without coverage');
            Assert.areEqual(0, updatedUserStory.copado__Triggers_Without_Coverage__c, 'There should be 1 apex trigger without coverage');
        }
    }

    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @SuppressWarnings('PMD.EagerlyLoadedDescribeSObjectResult')
    private static void createData() {
        copado__Result__c resultOne = new copado__Result__c(copado__Job_Type__c = 'Test Independent Result');
        insert resultOne;

        copado__Result__c resultTwo = new copado__Result__c(copado__Job_Type__c = 'Test Independent Result');
        insert resultTwo;

        copado__Result__c resultThree = new copado__Result__c(copado__Job_Type__c = 'Test Independent Result');
        insert resultThree;

        copado__Result__c consolidatedResult = new copado__Result__c(copado__Job_Type__c = 'Consolidated Result');
        insert consolidatedResult;

        attachTestsOutputFileTo(resultOne.Id);
        attachTestsOutputFileTo(resultTwo.Id);
        attachTestsOutputFileTo(resultThree.Id);
        attachTestsOutputFileTo(consolidatedResult.Id);

        List<String> picklistValues = Utilities.getPicklistValues(
            SObjectType.copado__ExtensionConfiguration__c.getName(),
            // PMD is giving a false positive here.
            copado__ExtensionConfiguration__c.copado__ExtensionTool__c.getDescribe(FieldDescribeOptions.DEFAULT).getName()
        );

        copado__ExtensionConfiguration__c extensionConfiguration = new copado__ExtensionConfiguration__c(
            copado__Active__c = true,
            copado__ExtensionTool__c = !picklistValues.isEmpty() ? picklistValues[0] : '',
            copado__ExtensionApplication__c = 'Test'
        );
        insert extensionConfiguration;

        copado__User_Story__c userStory = new copado__User_Story__c(copado__Minimum_Apex_Code_Coverage__c = 75);
        insert userStory;

        copado__User_Story_Metadata__c userStoryMetadata1 = initUserStoryMetadata('HelloWorld', 'ApexClass', userStory.Id);
        copado__User_Story_Metadata__c userStoryMetadata2 = initUserStoryMetadata('HelloWorldTest', 'ApexClass', userStory.Id);
        copado__User_Story_Metadata__c userStoryMetadata3 = initUserStoryMetadata('HelloMars', 'ApexClass', userStory.Id);
        copado__User_Story_Metadata__c userStoryMetadata4 = initUserStoryMetadata('HelloMarsTest', 'ApexClass', userStory.Id);

        insert new List<copado__User_Story_Metadata__c>{ userStoryMetadata1, userStoryMetadata2, userStoryMetadata3, userStoryMetadata4 };

        copado__Test__c testItem = new copado__Test__c(
            copado__ExtensionConfiguration__c = extensionConfiguration.Id,
            copado__User_Story__c = userStory.Id
        );
        insert testItem;

        ContentVersion testDefinitionFile = new ContentVersion(
            Title = 'cmcSf_TestClasses',
            origin = 'C',
            PathOnClient = 'cmcSf_TestClasses.json',
            VersionData = Blob.valueOf('[{"s":true,"r":false,"ns":"copado","n":"fflib_IDGeneratorTest"}]')
        );
        insert testDefinitionFile;
        createContentVersionOn('[{"s":true,"r":false,"ns":"copado","n":"fflib_IDGeneratorTest"}]', 'cmcSf_TestClasses', testItem.Id);

        copado__JobTemplate__c jobTemplate = new copado__JobTemplate__c(copado__Version__c = 1);
        insert jobTemplate;

        copado__JobExecution__c jobExecution = new copado__JobExecution__c(
            copado__DataJson__c = '{"testIds":["' + testItem.Id + '"], "resultIds": []}',
            copado__Template__c = jobTemplate.Id
        );
        insert jobExecution;

        copado__JobStep__c jobStep = new copado__JobStep__c(copado__JobExecution__c = jobExecution.Id, copado__Type__c = 'Flow', copado__Order__c = 2);
        insert jobStep;

        copado__Result__c result = new copado__Result__c(
            copado__Job_Type__c = 'Flow Test Result',
            copado__JobStep__c = jobStep.Id,
            copado__Status__c = 'Success'
        );
        insert result;

        copado__JobStep__c jobStepWithFile = new copado__JobStep__c(copado__JobExecution__c = jobExecution.Id, copado__Type__c = 'Manual', copado__Order__c = 1);
        insert jobStepWithFile;

        copado__Result__c resultWithFile = new copado__Result__c(
            copado__Job_Type__c = 'Manual Test Result',
            copado__JobStep__c = jobStepWithFile.Id,
            copado__Status__c = 'Success'
        );
        insert resultWithFile;

        attachTestsOutputFileTo(resultWithFile.Id);

        copado__JobExecution__c job = new copado__JobExecution__c(
            Id = jobExecution.Id,
            copado__DataJson__c = '{"testIds":["' + testItem.Id + '"], "resultIds" : [ "' + resultWithFile.Id + '" ]}'
        );
        update job;

    }

    private static void attachTestsOutputFileTo(Id recordId) {
        ContentVersion content = new ContentVersion(
            Title = 'apex-tests-output.json',
            origin = 'C',
            PathOnClient = 'apex-tests-output.json',
            VersionData = Blob.valueOf(
                '{"result":{"summary":{"testsRan":3,"passing":2,"failing":1,"skipped":0,"passRate":"67%","failRate":"32%","testRunCoverage":"83%"},"tests":[{"ApexClass":{"Name":"HelloWorldTest"}},{"ApexClass":{"Name":"HelloMarsTest"}}],"coverage":{"coverage":[{"name":"HelloWorld","coveredPercent":75,"totalLines":100,"totalCovered":75},{"name":"HelloMars","coveredPercent":100,"totalLines":100,"totalCovered":100}]}}}'
            )
        );
        insert content;

        ContentVersion contentVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :content.Id LIMIT 1];

        ContentDocumentLink link = new ContentDocumentLink(LinkedEntityId = recordId, ContentDocumentId = contentVersion.ContentDocumentId);
        insert link;
    }

    private static List<copado__Result__c> getTestResults() {
        return [
            SELECT Id, copado__Status__c, copado__Progress_Status__c, copado__Error_Message__c
            FROM copado__Result__c
            WHERE copado__Job_Type__c = 'Test Independent Result'
            LIMIT 3
        ];
    }

    private static copado__Result__c getConsolidatedResult() {
        return [
            SELECT Id, copado__Status__c, copado__Progress_Status__c, copado__Error_Message__c
            FROM copado__Result__c
            WHERE copado__Job_Type__c = 'Consolidated Result'
            LIMIT 1
        ];
    }

    private static copado__Result__c getFlowResult() {
        return [
            SELECT Id, copado__Status__c, copado__Progress_Status__c
            FROM copado__Result__c
            WHERE copado__Job_Type__c = 'Flow Test Result'
            LIMIT 1
        ];
    }

    private static String getMockTestResults() {
        List<copado__Result__c> testResults = getTestResults();

        // Note: Those are returned in the same way that are provided by the Payload (json) in the Job Execution
        return '[ "' + testResults[0].Id + '", "' + testResults[1].Id + '", "' + testResults[2].Id + '" ]';
    }

    private static String getMockConsolidatedResult() {
        copado__Result__c consolidatedResult = getConsolidatedResult();

        // Note: This is returned in the same way that is provided by the Payload (json) in the Job Execution
        return (String) consolidatedResult.Id;
    }

    private static copado__User_Story_Metadata__c initUserStoryMetadata(String name, String type, Id userStoryId) {
        return new copado__User_Story_Metadata__c(
            Name = name,
            copado__Metadata_API_Name__c = name,
            copado__Action__c = 'Add',
            copado__Type__c = type,
            copado__User_Story__c = userStoryId
        );
    }

    private static String getUncoveredUSItemsResponse() {
        return '{"statusCode":200,"content":"{\\"records\\":[' +
            '{' +
            '\\"ApexClassOrTrigger\\": {' +
            '  \\"Name\\": \\"HelloMoon\\"' +
            '},' +
            '\\"NumLinesCovered\\": 0,' +
            '\\"NumLinesUncovered\\": 100' +
            '},' +
            '{' +
            '\\"ApexClassOrTrigger\\": {' +
            '  \\"Name\\": \\"SampleTrigger\\"' +
            '}, ' +
            '\\"NumLinesCovered\\": 0,' +
            '\\"NumLinesUncovered\\": 100' +
            '}' +
            ']}"}';
    }

    private static copado__User_Story__c getUserStory() {
        return [
            SELECT
                copado__Apex_Code_Coverage__c,
                copado__Failing_Methods__c,
                copado__Classes_Without_Coverage__c,
                copado__Triggers_Without_Coverage__c
            FROM copado__User_Story__c
            LIMIT 1
        ];
    }

    private static ContentVersion getContentVersion(String title) {
        return [SELECT Id FROM ContentVersion WHERE Title = :title LIMIT 1];
    }

    private static void deleteUserStoryMetadata(copado__User_Story__c userStory) {
        delete [SELECT Id FROM copado__User_Story_Metadata__c WHERE copado__User_Story__c = :userStory.Id];
    }

    private static void createContentVersionOn(String data, String title, Id linkedEntityId) {
        ContentVersion contentVersion = new ContentVersion(
            Title = title,
            origin = 'C',
            PathOnClient = title + '.json',
            VersionData = Blob.valueOf(data)
        );
        insert contentVersion;

        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id LIMIT 1].ContentDocumentId;
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(LinkedEntityId = linkedEntityId, ContentDocumentId = contentDocumentId);
        insert contentDocumentLink;
    }

    private static String getCommitChangesWithNonCoveredApex() {
        List<CommitChanges.Change> commitChanges = new List<CommitChanges.Change>();
        commitChanges.add(getCommitChange('ApexClass', 'HelloMoon', 'File path is handled automatically', '', 'Add'));
        commitChanges.add(getCommitChange('ApexTrigger', 'SampleTrigger', 'File path is handled automatically', '', 'Add'));
        commitChanges.add(getCommitChange('ApexClass', 'HelloWorldTest', 'File path is handled automatically', '', 'Add'));
        return JSON.serialize(commitChanges);
    }

    private static String getCommitChangesWithCoveredApex() {
        List<CommitChanges.Change> commitChanges = new List<CommitChanges.Change>();
        commitChanges.add(getCommitChange('ApexClass', 'HelloMars', 'File path is handled automatically', '', 'Add'));
        commitChanges.add(getCommitChange('ApexClass', 'HelloMarsTest', 'File path is handled automatically', '', 'Add'));
        return JSON.serialize(commitChanges);
    }
    
    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static CommitChanges.Change getCommitChange(String type, String name, String module, String category, String action) {
        return new CommitChanges.Change(type, name, module, category, action);
    }

}