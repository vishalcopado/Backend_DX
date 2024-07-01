@SuppressWarnings('PMD.ExcessivePublicCount')
public with sharing class DataTemplatePayload {
    private static final String NONE = 'NONE';
    private static final String USER = 'USER';
    private static final String REPLACE_ATTACHMENT = 'REPLACE';
    private static final String REMOVE_ATTACHMENT = 'REMOVE';
    private static final String INSERT_ATTACHMENT = 'INSERT';
    private static final String ANONYMIZER_TYPE_NONE = 'None';
    private static final String ANONYMIZER_TYPE_REPLACE = 'Replace';
    private static final String ANONYMIZER_TYPE_SCRAMBLE = 'Scramble';
    private static final String RECORD_MATCHING = 'recordmatching';

    // PUBLIC

    @SuppressWarnings('PMD.FieldNamingConventions')
    public DataTemplate main_template;
    @SuppressWarnings('PMD.FieldNamingConventions')
    public List<DataTemplate> related_templates;

    public DataTemplatePayload() {
        this.related_templates = new List<DataTemplate>();
    }

    // INNER

    @SuppressWarnings('PMD.TooManyFields')
    public class DataTemplate {
        public String templateId;
        public String templateName;
        public String table;
        public String externalIdField;
        public Integer batchSize;
        public Boolean matchOwner;
        public Boolean matchRecordType;
        public List<Column> columns;
        public List<RelationTemplateDetails> parentTemplates;
        public List<RelationTemplateDetails> childTemplates;
        public String attachmentOption;
        public String fileOption;
        public Integer limitValue;
        public String queryTemplate;
        public List<String> filters;
        public ExternalIdGeneration externalIdGeneration;

        public DataTemplate(DataTemplateDetail dataTemplateDetail) {
            this.templateId = dataTemplateDetail.dataTemplate?.templateId;
            this.templateName = dataTemplateDetail.dataTemplate?.templateName;
            this.table = dataTemplateDetail.dataTemplate?.templateMainObject;
            this.externalIdField = this.queryTemplate = null;
            this.batchSize = dataTemplateDetail.dataTemplate?.templateBatchSize;
            this.matchOwner = dataTemplateDetail.dataTemplate?.templateMatchOwners;
            this.matchRecordType = dataTemplateDetail.dataTemplate?.templateMatchRecordTypes;
            this.columns = new List<Column>();
            this.parentTemplates = new List<RelationTemplateDetails>();
            this.childTemplates = new List<RelationTemplateDetails>();
            this.attachmentOption = this.fileOption = NONE;
            this.limitValue = dataTemplateDetail.dataTemplate?.templateQueryLimit;
            this.filters = new List<String>();
            this.externalIdGeneration = new ExternalIdGeneration(false, false, new List<String>());
        }

        public DataTemplate setColumnsAndExternalId(DataTemplateDetail dataTemplateDetail) {
            for (DataTemplateDetail.CopadoSelectedField field : dataTemplateDetail.selectableFieldsMap?.values()) {
                if (field.isSelected) {
                    this.columns.add(getColumn(field));
                    setExternalId(field);
                }
            }
            if (this.matchOwner) {
                this.columns.add(getColumnForOwnerId());
            }
            if (this.matchRecordType) {
                this.columns.add(getColumnForRecordTypeId());
            }
            return this;
        }

        public DataTemplate setRelatedTemplate(DataTemplateDetail dataTemplateDetail) {
            setRelatedTemplateForParent(dataTemplateDetail);
            setRelatedTemplateForChild(dataTemplateDetail);
            return this;
        }

        public DataTemplate setFilters(DataTemplateDetail dataTemplateDetail) {
            sortFilters(dataTemplateDetail);
            for (QueryEditor.CriteriaWrapper criteriaWrapper : dataTemplateDetail.queryFilterList) {
                if (String.isNotBlank(criteriaWrapper.finalValue)) {
                    this.filters.add(criteriaWrapper.finalValue);
                }
            }
            this.queryTemplate = this.filters.isEmpty() ? null : dataTemplateDetail.dataTemplate?.templateFilterLogic;
            return this;
        }

        public DataTemplate setAttachmentAndFileOption(DataTemplateDetail dataTemplateDetail) {
            String templateAttachmentOption = getTemplateAttachmentOption(dataTemplateDetail.dataTemplate?.templateAttachmentOption);
            switch on dataTemplateDetail.dataTemplate?.templateSelectedAttachmentType?.toLowerCase() {
                when 'files' {
                    this.attachmentOption = NONE;
                    this.fileOption = String.isBlank(templateAttachmentOption) ? NONE : templateAttachmentOption;
                }
                when 'attachments' {
                    this.attachmentOption = String.isBlank(templateAttachmentOption) ? NONE : templateAttachmentOption;
                    this.fileOption = NONE;
                }
            }
            return this;
        }

        public DataTemplate setExternalIdGeneration(Boolean generateExternalId, Boolean needsHashing, List<String> fields) {
            this.externalIdGeneration = new ExternalIdGeneration(generateExternalId, needsHashing, fields);
            return this;
        }

        private void setExternalId(DataTemplateDetail.CopadoSelectedField field) {
            if (field.useAsExternalId) {
                this.externalIdField = field.name + (field.fieldContentUpdate?.toLowerCase() == RECORD_MATCHING ? ';' + RECORD_MATCHING : '');
            }
        }

        private String getTemplateAttachmentOption(String templateAttachmentOption) {
            String result = NONE;
            switch on templateAttachmentOption?.toLowerCase() {
                when 'no attachments' {
                    result = NONE;
                }
                when 'insert attachments' {
                    result = INSERT_ATTACHMENT;
                }
                when 'replace attachment' {
                    result = REPLACE_ATTACHMENT;
                }
                when 'remove attachments' {
                    result = REMOVE_ATTACHMENT;
                }
            }
            return result;
        }

        private void setRelatedTemplateForParent(DataTemplateDetail dataTemplateDetail) {
            for (DataTemplateDetail.RelationTemplateDetails relationTemplateDetail : dataTemplateDetail.parentObjectsReferenceList) {
                this.parentTemplates.add(new RelationTemplateDetails(relationTemplateDetail.templateId, relationTemplateDetail.relationName));
            }
        }

        private void setRelatedTemplateForChild(DataTemplateDetail dataTemplateDetail) {
            Map<String, String> childRelationshipByParentField = getSelectedChildRelationship(dataTemplateDetail);
            for (DataTemplateDetail.RelationTemplateDetails relationTemplateDetail : dataTemplateDetail.childrenObjectsReferenceList) {
                String key = relationTemplateDetail.relationName + relationTemplateDetail.childSObject;
                if (childRelationshipByParentField.containsKey(key)) {
                    this.childTemplates.add(new RelationTemplateDetails(relationTemplateDetail.templateId, childRelationshipByParentField.get(key)));
                }
            }
        }

        private Map<String, String> getSelectedChildRelationship(DataTemplateDetail dataTemplateDetail) {
            Map<String, String> result = new Map<String, String>();
            for (
                DataTemplateDetail.CopadoSelectedChildRelationship copadoSelectedChildRelationship : dataTemplateDetail.selectableChildRelationsMap
                    ?.values()
            ) {
                if (copadoSelectedChildRelationship.isSelected) {
                    result.put(
                        copadoSelectedChildRelationship.relationshipName + copadoSelectedChildRelationship.childSObject,
                        copadoSelectedChildRelationship.field
                    );
                }
            }
            return result;
        }

        private Column getColumnForOwnerId() {
            return getColumn('OwnerId', 'id', NONE, new AnonymizerType());
        }

        private Column getColumnForRecordTypeId() {
            return getColumn('RecordTypeId', 'id', NONE, new AnonymizerType());
        }

        private Column getColumn(DataTemplateDetail.CopadoSelectedField field) {
            return getColumn(field.name, field.fieldType, field.parentObjectApiNameMap?.containsKey('User') ? USER : NONE, new AnonymizerType(field));
        }

        @SuppressWarnings('PMD.ExcessiveParameterList')
        private Column getColumn(String name, String type, String lookUpType, AnonymizerType anonymizerType) {
            Column result = new Column();
            result.name = name;
            result.type = type;
            result.anonymizerType = anonymizerType;
            result.lookUpType = lookUpType;
            return result;
        }

        private void sortFilters(DataTemplateDetail dataTemplateDetail) {
            dataTemplateDetail.queryFilterList?.sort();
        }
    }

    public class Column {
        public String name;
        public String type;
        public AnonymizerType anonymizerType;
        public String lookUpType;
    }

    public class AnonymizerType {
        public String type;
        public String replaceValue;
        public Boolean maintainFormat;

        public AnonymizerType() {
            this.type = ANONYMIZER_TYPE_NONE;
            this.maintainFormat = false;
            this.replaceValue = null;
        }

        public AnonymizerType(DataTemplateDetail.CopadoSelectedField field) {
            switch on field?.fieldContentUpdate?.toLowerCase() {
                when 'scramble' {
                    this.type = ANONYMIZER_TYPE_SCRAMBLE;
                    this.maintainFormat = false;
                }
                when 'scramblewithformat' {
                    this.type = ANONYMIZER_TYPE_SCRAMBLE;
                    this.maintainFormat = true;
                }
                when 'replace' {
                    this.type = ANONYMIZER_TYPE_REPLACE;
                    this.replaceValue = field.replaceValue;
                    this.maintainFormat = false;
                }
                when else {
                    this.type = ANONYMIZER_TYPE_NONE;
                    this.maintainFormat = false;
                }
            }
        }
    }

    public class ExternalIdGeneration {
        public Boolean generateExternalId;
        public Boolean needsHashing;
        public List<String> fields;

        public ExternalIdGeneration(Boolean generateExternalId, Boolean needsHashing, List<String> fields) {
            this.generateExternalId = generateExternalId;
            this.needsHashing = needsHashing;
            this.fields = fields;
        }
    }

    public class RelationTemplateDetails {
        public String templateId;
        public String fieldName;

        public RelationTemplateDetails(String templateId, String fieldName) {
            this.templateId = templateId;
            this.fieldName = fieldName;
        }
    }
}