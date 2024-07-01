@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.CyclomaticComplexity')
global with sharing class GetDataTemplatePayload implements copado.ParameterExpressionCallable {
    @TestVisible
    private static final String DATA_TEMPLATE = 'dataTemplate';
    @TestVisible
    private static final Integer MAXIMUM_TEMPLATES_TO_BE_PROCESSED = 30;
    private static final String RECORD_MATCHING = ';recordmatching';
    private List<String> templateNames = new List<String>();
    private DataSetForExternalId dataSetForExternalId = new DataSetForExternalId();

    // GLOBAL

    global String execute(Id contextId) {
        JobStepDataDeployController.DataTemplate dataTemplate = getDataTemplateFromConfigJson(contextId);
        return JSON.serialize(getPayload(dataTemplate));
    }

    // PRIVATE

    private DataTemplatePayload getPayload(JobStepDataDeployController.DataTemplate dataTemplate) {
        DataTemplatePayload payload = new DataTemplatePayload();
        payload.main_template = getMainTemplate(dataTemplate?.templateId, dataTemplate?.queryFilterList, dataTemplate?.filterLogic);
        addRelatedtemplates(payload.related_templates, getRelatedTemplateIds(payload.main_template));
        setExternalIdForPayload(payload);
        return payload;
    }

    private JobStepDataDeployController.DataTemplate getDataTemplateFromConfigJson(Id jobStepId) {
        JobStepDataDeployController.DataTemplate result;
        List<copado__JobStep__c> jobSteps = new JobStepsSelector().byIds(new Set<Id>{ jobStepId });
        if (!jobSteps.isEmpty() && String.isNotBlank(jobSteps[0].copado__ConfigJson__c)) {
            StepConfig stepConfig = (StepConfig) JSON.deserialize(jobSteps[0].copado__ConfigJson__c, StepConfig.class);
            for (Copado.CopadoFunctions.FunctionParameter functionParameter : stepConfig.parameters) {
                if (functionParameter.name == DATA_TEMPLATE) {
                    result = (JobStepDataDeployController.DataTemplate) JSON.deserialize(
                        functionParameter.value,
                        JobStepDataDeployController.DataTemplate.class
                    );
                    break;
                }
            }
        }
        return result;
    }

    private List<DataTemplateDetail> getDataTemplateDetails(List<Id> dataTemplateIds) {
        List<DataTemplateDetail> result = new List<DataTemplateDetail>();
        List<Attachment> attachments = new AttachmentsSelector()
            .byParentIdsAndNames(new Set<Id>(dataTemplateIds), new Set<String>{ DataTemplateDetail.ATTACHMENT_NAME }, dataTemplateIds.size());
            if (attachments.isEmpty()) {
                throw new ApplicationException(Label.Data_Template_Missing);
            }
            for (Attachment attachment : attachments) {
                String content = attachment.Body?.toString();
                if (String.isNotBlank(content)) {
                    DataTemplateDetail dataTemplateDetail = (DataTemplateDetail) JSON.deserialize(content, DataTemplateDetail.class);
                    result.add(dataTemplateDetail);
                }
            }
        if (result.isEmpty()) {
            throw new ApplicationException(Label.Data_Template_Missing);
        }
        return result;
    }

    private DataTemplatePayload.DataTemplate getDataTemplate(DataTemplateDetail dataTemplateDetail) {
        DataTemplatePayload.DataTemplate result = new DataTemplatePayload.DataTemplate(dataTemplateDetail)
            .setColumnsAndExternalId(dataTemplateDetail)
            .setRelatedTemplate(dataTemplateDetail)
            .setFilters(dataTemplateDetail)
            .setAttachmentAndFileOption(dataTemplateDetail);
        return result;
    }

    private DataTemplatePayload.DataTemplate getMainTemplate(
        Id dataTemplateId,
        List<QueryEditor.CriteriaWrapper> queryFilterList,
        String filterLogic
    ) {
        if (String.isBlank(dataTemplateId)) {
            throw new ApplicationException(Label.Data_Template_Id_Missing);
        }

        DataTemplateDetail dataTemplateDetail = getDataTemplateDetails(new List<Id>{ dataTemplateId })[0];
        validateTotalTemplateCount(dataTemplateDetail);
        DataTemplatePayload.DataTemplate result = getDataTemplate(dataTemplateDetail);
        if (String.isNotBlank(result.externalIdField) && result.externalIdField.endsWith(RECORD_MATCHING)) {
            result.externalIdField = result.externalIdField.removeEnd(RECORD_MATCHING);
            dataSetForExternalId.isMainTemplateUsingExternalId = true;
            dataSetForExternalId.objects.add(dataTemplateDetail.dataTemplate.templateMainObject);
        }
        setFiltersForMainTemplate(result, queryFilterList, filterLogic);
        return result;
    }

    private void setFiltersForMainTemplate(
        DataTemplatePayload.DataTemplate dataTemplate,
        List<QueryEditor.CriteriaWrapper> queryFilterList,
        String filterLogic
    ) {
        dataTemplate.filters = new List<String>();
        dataTemplate.queryTemplate = null;
        if (queryFilterList != null) {
            queryFilterList.sort();
            for (QueryEditor.CriteriaWrapper criteriaWrapper : queryFilterList) {
                if (String.isNotBlank(criteriaWrapper.finalValue)) {
                    dataTemplate.filters.add(criteriaWrapper.finalValue);
                }
            }
            dataTemplate.queryTemplate = dataTemplate.filters.isEmpty() ? null : filterLogic;
        }
    }

    private void addRelatedtemplates(List<DataTemplatePayload.DataTemplate> dataTemplates, List<Id> relatedTemplateIds) {
        if (relatedTemplateIds.isEmpty()) {
            return;
        }

        List<DataTemplateDetail> dataTemplateDetails = getDataTemplateDetails(relatedTemplateIds);
        List<Id> relatedTemplateIdsForNextIteration = new List<Id>();
        for (DataTemplateDetail dataTemplateDetail : dataTemplateDetails) {
            validateTotalTemplateCount(dataTemplateDetail);
            DataTemplatePayload.DataTemplate dataTemplate = getDataTemplate(dataTemplateDetail);
            if (String.isNotBlank(dataTemplate.externalIdField) && dataTemplate.externalIdField.endsWith(RECORD_MATCHING)) {
                dataTemplate.externalIdField = dataTemplate.externalIdField.removeEnd(RECORD_MATCHING);
                dataSetForExternalId.indexesOfRelatedDataTemplateUsingExternalId.add(dataTemplates.size());
                dataSetForExternalId.objects.add(dataTemplateDetail.dataTemplate.templateMainObject);
            }
            dataTemplates.add(dataTemplate);
            relatedTemplateIdsForNextIteration.addAll(getRelatedTemplateIds(dataTemplate));
        }
        addRelatedtemplates(dataTemplates, relatedTemplateIdsForNextIteration);
    }

    private List<Id> getRelatedTemplateIds(DataTemplatePayload.DataTemplate dataTemplate) {
        List<Id> result = new List<Id>();
        result.addAll(getRelatedTemplateIds(dataTemplate.parentTemplates));
        result.addAll(getRelatedTemplateIds(dataTemplate.childTemplates));
        return result;
    }

    private List<Id> getRelatedTemplateIds(List<DataTemplatePayload.RelationTemplateDetails> relatedTemplates) {
        List<Id> result = new List<Id>();
        for (DataTemplatePayload.RelationTemplateDetails relationTemplateDetail : relatedTemplates) {
            result.add(relationTemplateDetail.templateId);
        }
        return result;
    }

    private void validateTotalTemplateCount(DataTemplateDetail dataTemplateDetail) {
        this.templateNames.add(dataTemplateDetail.dataTemplate?.templateName);
        if (this.templateNames.size() > MAXIMUM_TEMPLATES_TO_BE_PROCESSED) {
            throw new ApplicationException(
                String.format(
                    Label.Maximum_Data_Template_Processing_Error,
                    new List<Object>{ MAXIMUM_TEMPLATES_TO_BE_PROCESSED, String.join(this.templateNames, ',') }
                )
            );
        }
    }

    private void setExternalIdForPayload(DataTemplatePayload payload) {
        if (
            !dataSetForExternalId.objects.isEmpty() &&
            (!dataSetForExternalId.indexesOfRelatedDataTemplateUsingExternalId.isEmpty() || dataSetForExternalId.isMainTemplateUsingExternalId)
        ) {
            Map<String, copado__Record_Matching_Formula__c> recordMatchingFormulaByObject = getRecordMatchingFormula(dataSetForExternalId.objects);
            setExternalIdForRelatedTemplates(payload, recordMatchingFormulaByObject);
            setExternalIdForMainTemplates(payload, recordMatchingFormulaByObject);
        }
    }

    private List<String> getExternalIdFormulaFields(copado__Record_Matching_Formula__c recordMatchingFormula) {
        List<String> result = new List<String>();
        if (String.isNotBlank(recordMatchingFormula.copado__Field_1__c)) {
            result.add(recordMatchingFormula.copado__Field_1__c);
        }
        if (String.isNotBlank(recordMatchingFormula.copado__Field_2__c)) {
            result.add(recordMatchingFormula.copado__Field_2__c);
        }
        if (String.isNotBlank(recordMatchingFormula.copado__Field_3__c)) {
            result.add(recordMatchingFormula.copado__Field_3__c);
        }
        return result;
    }

    private void setExternalIdForRelatedTemplates(
        DataTemplatePayload payload,
        Map<String, copado__Record_Matching_Formula__c> recordMatchingFormulaByObject
    ) {
        for (Integer index : dataSetForExternalId.indexesOfRelatedDataTemplateUsingExternalId) {
            DataTemplatePayload.DataTemplate dataTemplate = payload.related_templates.get(index);
            if (recordMatchingFormulaByObject.containsKey(dataTemplate?.table?.toLowerCase())) {
                copado__Record_Matching_Formula__c recordMatchingFormula = recordMatchingFormulaByObject.get(dataTemplate?.table?.toLowerCase());
                setExternalIdOnDataTemplate(dataTemplate, recordMatchingFormula);
            }
        }
    }

    private void setExternalIdForMainTemplates(
        DataTemplatePayload payload,
        Map<String, copado__Record_Matching_Formula__c> recordMatchingFormulaByObject
    ) {
        if (
            dataSetForExternalId.isMainTemplateUsingExternalId &&
            recordMatchingFormulaByObject.containsKey(payload.main_template?.table?.toLowerCase())
        ) {
            copado__Record_Matching_Formula__c recordMatchingFormula = recordMatchingFormulaByObject.get(payload.main_template?.table?.toLowerCase());
            setExternalIdOnDataTemplate(payload.main_template, recordMatchingFormula);
        }
    }

    private void setExternalIdOnDataTemplate(
        DataTemplatePayload.DataTemplate dataTemplate,
        copado__Record_Matching_Formula__c recordMatchingFormula
    ) {
        dataTemplate.setExternalIdGeneration(true, recordMatchingFormula.copado__Hash_Formula__c, getExternalIdFormulaFields(recordMatchingFormula));
    }

    private Map<String, copado__Record_Matching_Formula__c> getRecordMatchingFormula(Set<String> objects) {
        Map<String, copado__Record_Matching_Formula__c> result = new Map<String, copado__Record_Matching_Formula__c>();
        for (copado__Record_Matching_Formula__c recordMatchingFormula : new RecordMatchingFormulaSelector().byObjects(objects)) {
            result.put(recordMatchingFormula.copado__Object__c.toLowerCase(), recordMatchingFormula);
        }
        return result;
    }

    // INNER

    @TestVisible
    private class StepConfig {
        public String functionName;
        public List<Copado.CopadoFunctions.FunctionParameter> parameters;
    }

    private class DataSetForExternalId {
        private List<Integer> indexesOfRelatedDataTemplateUsingExternalId;
        private Boolean isMainTemplateUsingExternalId;
        private Set<String> objects;

        public DataSetForExternalId() {
            this.indexesOfRelatedDataTemplateUsingExternalId = new List<Integer>();
            this.isMainTemplateUsingExternalId = false;
            this.objects = new Set<String>();
        }
    }
}