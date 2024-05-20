@SuppressWarnings('PMD.ExcessivePublicCount')
public with sharing class DataTemplateDetail {
    // PUBLIC

    public static final String ATTACHMENT_NAME = 'Template Detail';
    public DataTemplateDetails dataTemplate;
    public List<RelationTemplateDetails> parentObjectsReferenceList;
    public List<RelationTemplateDetails> childrenObjectsReferenceList;
    public Map<String, CopadoSelectedField> selectableFieldsMap;
    public Map<String, CopadoSelectedChildRelationship> selectableChildRelationsMap;
    public List<QueryEditor.CriteriaWrapper> queryFilterList;

    public DataTemplateDetail() {
        this.dataTemplate = new DataTemplateDetails();
        this.parentObjectsReferenceList = new List<RelationTemplateDetails>();
        this.childrenObjectsReferenceList = new List<RelationTemplateDetails>();
        this.selectableFieldsMap = new Map<String, CopadoSelectedField>();
        this.selectableChildRelationsMap = new Map<String, CopadoSelectedChildRelationship>();
        this.queryFilterList = new List<QueryEditor.CriteriaWrapper>();
    }

    // INNER

    public class DataTemplateDetails {
        public String templateId;
        public String templateName;
        public String templateSourceOrg;
        public String templateMainObject;
        public Boolean templateMatchOwners;
        public Boolean templateMatchRecordTypes;
        public String templateContinueOnError;
        public Boolean templateActive;
        public String templateDescription;
        public String templateAttachmentOption;
        public String templateFilterLogic;
        public Integer templateBatchSize;
        public Integer templateQueryLimit;
        public String templateSelectedAttachmentType;
    }

    public class RelationTemplateDetails {
        public String templateId;
        public String relationName;
        public String childSObject;
    }

    public class CopadoField {
        public Boolean autonumber;
        public Boolean calculated;
        public Boolean externalId;
        public Boolean filterable;
        public String label;
        public String name;
        public Boolean nillable;
        public String relationshipName;
        public List<String> referenceTo;
        public String type;
        public Boolean unique;
        public Double replaceValueNumber;
        public Date replaceValueDate;
        public Datetime replaceValueDatetime;
    }

    public class CopadoSelectedField {
        public Boolean isSelected;
        public Boolean useAsExternalId;
        public Boolean externalId;
        public String label;
        public String name;
        public String fieldType;
        public Map<String, String> parentObjectApiNameMap;
        public Map<String, String> contentValueUpdateValues;
        public String fieldContentUpdate;
        public String replaceValue;
        public Double replaceValueNumber;
        public Date replaceValueDate;
        public Datetime replaceValueDatetime;
        public Map<String, String> deploymentTemplateNameMap;
        public String deploymentTemplate;
    }

    public class CopadoSelectedChildRelationship {
        public Boolean isSelected;
        public String childSObject;
        public String field;
        public String relationshipName;
        public Map<String, String> objectApiNameMap;
        public Map<String, String> deploymentTemplateNameMap;
        public String deploymentTemplate;
    }
}