@IsTest
private class JobStepDataDeployControllerTest {
    public static final String ATTACHMENT_NAME = 'Template Detail';

    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void testLoadAllActiveTemplatesWithSuccess() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // EXERCISE

            Map<Id, JobStepDataDeployController.DataTemplate> result = JobStepDataDeployController.loadActiveDataTemplates();
            JobStepDataDeployController.DataTemplate dataTemplate1 = result.values()[0];
            JobStepDataDeployController.DataTemplate dataTemplate2 = result.values()[1];

            // VERIFY

            Assert.areEqual(2, result.size(), 'The number of data templates returned should be 2');
            Assert.areEqual(200, dataTemplate1.batchSize, 'The batch size is incorrect');
            Assert.areEqual('dev1', dataTemplate1.sourceOrg, 'The source org name is incorrect');
            Assert.areEqual(2, dataTemplate1.totalRelatedObjects, 'The total related objects list is incorrect is incorrect');
            Assert.areEqual(2, dataTemplate1.queryFilterList.size(), 'The size of the query filter list should be 2');
            Assert.areEqual('1 AND 2', dataTemplate1.filterLogic, 'The filter logic is incorrect');

            for (QueryEditor.CriteriaWrapper criterion : dataTemplate1.queryFilterList) {
                switch on criterion.order {
                    when 1 {
                        Assert.areEqual('Name LIKE \'%test1%\'', criterion.finalValue, 'The finalvalue of the query filter criterion incorrect');
                    }
                    when 2 {
                        Assert.areEqual(
                            '(NOT Name LIKE \'%test2%\')',
                            criterion.finalValue,
                            'The finalvalue of the query filter criterion incorrect'
                        );
                    }
                }
            }

            Assert.areEqual(150, dataTemplate2.batchSize, 'The batch size is incorrect');
            Assert.areEqual('dev2', dataTemplate2.sourceOrg, 'The source org name is incorrect');
            Assert.areEqual(0, dataTemplate2.totalRelatedObjects, 'The total related objects list is incorrect is incorrect');
            Assert.areEqual(0, dataTemplate2.queryFilterList.size(), 'The size of the query filter list should be 0');
            Assert.isTrue(String.isBlank(dataTemplate2.filterLogic), 'The filter logic is incorrect');
        }
    }

    @IsTest
    private static void testFunctionParametersReturnedSuccessfully() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String functionApiName = 'Function_1';

            new Function().apiName(functionApiName).script('Test Script').params(getFunctionParams()).persist();

            // EXERCISE

            String result = JobStepDataDeployController.getFunctionParameters(functionApiName);

            List<copado.CopadoFunctions.FunctionParameter> functionParams = (List<copado.CopadoFunctions.FunctionParameter>) JSON.deserialize(
                result,
                List<copado.CopadoFunctions.FunctionParameter>.class
            );

            // VERIFY

            Assert.areEqual(2, functionParams.size(), 'Both the parameters should be returned');
            for (copado.CopadoFunctions.FunctionParameter functionParam : functionParams) {
                switch on functionParam.name {
                    when 'param 1' {
                        Assert.areEqual('value1', functionParam.value, 'The value for the parameter is incorrect');
                    }
                    when 'param 2' {
                        Assert.areEqual('value2', functionParam.value, 'The value for the parameter is incorrect');
                    }
                }
            }
        }
    }

    @IsTest
    private static void testFunctionParametersWithEmptyParameters() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String functionApiName = 'Function_1';

            new Function().apiName(functionApiName).script('Test Script').persist();

            // EXERCISE

            String result = JobStepDataDeployController.getFunctionParameters(functionApiName);

            // VERIFY

            Assert.areEqual('[ ]', result, 'Empty function params should be returned');
        }
    }

    @IsTest
    private static void testFunctionParametersWithFunctionNotPresent() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

            String functionApiName = 'Function_1';
            String exceptionMessage;

            // EXERCISE
            try {
                JobStepDataDeployController.getFunctionParameters(functionApiName);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY

            Assert.areEqual('Could not find the function Function_1', exceptionMessage, 'Should throw relevant error');
        }
    }


    @IsTest
    private static void testLoadDataTemplateByIdWithSuccess() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // EXERCISE
            Map<Id, JobStepDataDeployController.DataTemplate> dataTemplates = JobStepDataDeployController.loadActiveDataTemplates();
            JobStepDataDeployController.DataTemplate dataTemplateSample = dataTemplates.values()[0];
            Id testId = dataTemplateSample.templateId;

            Map<Id, JobStepDataDeployController.DataTemplate> result = JobStepDataDeployController.loadDataTemplateById(new List<Id> {testId});
            JobStepDataDeployController.DataTemplate dataTemplate = result.values()[0];

            // VERIFY
            Assert.areEqual(1, result.size(), 'The number of data templates returned should be 1');
            Assert.areEqual(testId, dataTemplate.templateId, 'The Id of data template should be ' + testId);
            Assert.areEqual(200, dataTemplate.batchSize, 'The batch size is incorrect');
            Assert.areEqual('dev1', dataTemplate.sourceOrg, 'The source org name is incorrect');
        }
    }

    @IsTest
    private static void testLoadDataTemplateByIdWithWrongId() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // EXERCISE
            Id randomId = fflib_IdGenerator.generate(SObjectType.copado__Data_Template__c.getKeyPrefix());
            Map<Id, JobStepDataDeployController.DataTemplate> result = JobStepDataDeployController.loadDataTemplateById(new List<Id> {randomId});

            // VERIFY
            Assert.isTrue(result.isEmpty(), 'The result for wrong Id should be empty');
            
        }
    }

    private static void createData() {
        Credential dev1 = new Credential().name('dev1');
        Credential dev2 = new Credential().name('dev2');

        DataTemplate dataTemplate1 = new DataTemplate().name('Template 1').batchSize(200).templateSourceOrg(dev1).activate();
        DataTemplate dataTemplate2 = new DataTemplate().name('Template 2').batchSize(150).templateSourceOrg(dev2).activate();
        DataTemplate dataTemplate3 = new DataTemplate().name('Template 3').batchSize(150).templateSourceOrg(dev2);

        new Attachment_t().name(ATTACHMENT_NAME).parent(dataTemplate1).body(getAttachmentBody());

        new Attachment_t().name(ATTACHMENT_NAME).parent(dataTemplate2).body(getAttachmentBodyWithoutFilterList());

        new Attachment_t().name(ATTACHMENT_NAME).parent(dataTemplate3).body(getAttachmentBody()).persist();
    }

    private static Blob getAttachmentBody() {
        DataTemplateDetail dataTemplate = new DataTemplateDetail();

        DataTemplateDetail.RelationTemplateDetails parentTemplate1 = new DataTemplateDetail.RelationTemplateDetails();
        parentTemplate1.templateId = fflib_IDGenerator.generate(copado__Data_Template__c.getSObjectType());
        DataTemplateDetail.RelationTemplateDetails parentTemplate2 = new DataTemplateDetail.RelationTemplateDetails();
        parentTemplate2.templateId = fflib_IDGenerator.generate(copado__Data_Template__c.getSObjectType());

        dataTemplate.parentObjectsReferenceList = new List<DataTemplateDetail.RelationTemplateDetails>();
        dataTemplate.parentObjectsReferenceList.add(parentTemplate1);
        dataTemplate.parentObjectsReferenceList.add(parentTemplate2);

        List<QueryEditor.CriteriaWrapper> queryFilterList = new List<QueryEditor.CriteriaWrapper>();
        queryFilterList.add(getCriterion(1, 'Name LIKE \'%test1%\''));
        queryFilterList.add(getCriterion(2, '(NOT Name LIKE \'%test2%\')'));
       
        dataTemplate.queryFilterList = queryFilterList;
        dataTemplate.dataTemplate.templateId = fflib_IDGenerator.generate(copado__Data_Template__c.getSObjectType());
        dataTemplate.dataTemplate.templateBatchSize = 200;
        dataTemplate.dataTemplate.templateFilterLogic = '1 AND 2';

        return Blob.valueOf(JSON.serialize(dataTemplate));
    }

    private static Blob getAttachmentBodyWithoutFilterList() {
        DataTemplateDetail dataTemplate = new DataTemplateDetail();

        dataTemplate.dataTemplate.templateId = fflib_IDGenerator.generate(copado__Data_Template__c.getSObjectType());
        dataTemplate.dataTemplate.templateBatchSize = 200;
        dataTemplate.dataTemplate.templateFilterLogic = '1';

        return Blob.valueOf(JSON.serialize(dataTemplate));
    }

    private static String getFunctionParams() {
        List<copado.CopadoFunctions.FunctionParameter> paramList = new List<copado.CopadoFunctions.FunctionParameter>();
        paramList.add(new copado.CopadoFunctions.FunctionParameter('param1', 'value1'));
        paramList.add(new copado.CopadoFunctions.FunctionParameter('param2', 'value2'));
        return JSON.serialize(paramList);
    }

    private static QueryEditor.CriteriaWrapper getCriterion(Integer order, String finalValue) {
        QueryEditor.CriteriaWrapper criterion = new QueryEditor.CriteriaWrapper();
        criterion.order = order;
        criterion.finalValue = finalValue;
        return criterion;
    }
}