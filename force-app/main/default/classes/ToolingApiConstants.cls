public with sharing class ToolingApiConstants {
    
    // VALUES PER TYPE

    public static final String FIELD_DEVELOPER_NAME = 'DeveloperName';
    public static final String FIELD_NAME = 'Name';
    public static final String FIELD_FULL_NAME = 'FullName';
    public static final String FIELD_VALIDATION_NAME = 'ValidationName';
    public static final String FIELD_DEFINITION_DEVELOPER_NAME = 'Definition.DeveloperName';
    public static final String FIELD_MASTER_LABEL = 'MasterLabel';
    
    public static final String TYPE_VALIDATION_RULE = 'ValidationRule';
    public static final String TYPE_FLOW = 'Flow';
    public static final String TYPE_PERMISSION_SET = 'PermissionSet';
    public static final String TYPE_LAYOUT = 'Layout';
    public static final String TYPE_FIELD_DEFINITION = 'FieldDefinition';
    public static final String TYPE_ENTITY_DEFINITION = 'EntityDefinition';
    public static final String TYPE_CUSTOM_FIELD = 'CustomField';
    public static final String TYPE_CUSTOM_OBJECT = 'CustomObject';
    public static final String TYPE_EXTERNAL_SERVICE_REGISTRATION = 'ExternalServiceRegistration';
    public static final String TYPE_WORKFLOW_RULE = 'WorkflowRule';
    
    public static final String DATETIME_SEPARATOR = 'T';
    public static final String NAMESPACE_SEPARATOR = '__';
    public static final String LAYOUT_SEPARATOR = '-';
    public static final String ENTITY_SEPARATOR = '.';
    public static final String CUSTOM_SUFFIX = '__c';
    
    public static final String DEFAULT_QUERY_TEMPLATE = 'SELECT+{0}+FROM+{1}+WHERE+{2}+LIKE+\'%25{3}%25\'+LIMIT+1000';
    public static final String CONDITIONAL_QUERY_TEMPLATE = 'SELECT+{0}+FROM+{1}+WHERE+{2}+LIKE+\'%25{3}%25\'+{4}+LIMIT+1000';

    public static final String ADDITIONAL_CONDITION_TYPE_FLOW = 'AND+Status=\'Active\'';
    public static final String ADDITIONAL_CONDITION_TYPE_PERMISSION_SET = 'AND+ProfileId=NULL+AND+PermissionSetGroupId=NULL+AND+IsCustom=true';

    public static final Set<String> NO_DEFAULT_FIELDS = new Set<String>{
        'Id'
    };
    public static final Set<String> DEFAULT_FIELDS = new Set<String>{
        'Id',
        'NamespacePrefix',
        'CreatedDate',
        'CreatedBy.Name',
        'LastModifiedDate',
        'LastModifiedBy.Name'
    };
    public static final Set<String> DEFAULT_FIELDS_NO_NAMESPACE = new Set<String>{
        'Id',
        'CreatedDate',
        'CreatedBy.Name',
        'LastModifiedDate',
        'LastModifiedBy.Name'
    };
    public static final Set<String> DEFAULT_FIELDS_NO_CREATED_FIELDS = new Set<String>{
        'Id',
        'NamespacePrefix',
        'LastModifiedDate',
        'LastModifiedBy.Name'
    };
    public static final Set<String> DEFAULT_FIELDS_NO_OWNER = new Set<String>{ 'Id', 'NamespacePrefix', 'CreatedDate', 'LastModifiedDate' };

    public static final Set<String> ENTITY_FIELDS = new Set<String>{
        'EntityDefinition.DeveloperName',
        'EntityDefinition.NamespacePrefix',
        'EntityDefinition.LastModifiedDate'
    };

    public static final Set<String> DEFINITION_FIELDS = new Set<String>{
        'Definition.NamespacePrefix',
        'Definition.LastModifiedDate'
    };

    // METADATA TYPES TO CATEGORIZE

    public static final Set<String> NAME_FIELD_TYPES = new Set<String>{
        'ApexClass',
        'ApexComponent',
        'ApexPage',
        'ApexTrigger',
        'BusinessProcess',
        'EmailTemplate',
        'ExternalString',
        'HomePageComponent',
        'HomePageLayout',
        'Layout',
        'PermissionSet',
        'Profile',
        'RecordType',
        'StaticResource',
        'WebLink',
        'WorkflowFieldUpdate',
        'WorkflowOutboundMessage',
        'WorkflowRule'
    };
    public static final Set<String> FULL_NAME_FIELD_TYPES = new Set<String>{
        'CompactLayout',
        'EmailTemplate',
        'IPAddressRange',
        'KeywordList',
        'ManagedContentType',
        'ModerationRule',
        'PlatformEventChannel',
        'UserCriteria',
        'WorkflowFieldUpdate',
        'WorkflowOutboundMessage',
        'WorkflowRule',
        'WorkSkillRouting'
    };
    public static final Set<String> MASTER_LABEL_FIELD_TYPES = new Set<String>{
        'ExternalServiceRegistration'
    };

    public static final Set<String> NO_NAMESPACE_FIELD_TYPES = new Set<String>{ 
        'Profile',
        'Flow',
        'Group', 
        'IPAddressRange',
        'KeywordList',
        'ManagedContentType',
        'ModerationRule',
        'UserCriteria',
        'WorkSkillRouting'
    };
    public static final Set<String> NO_CREATED_FIELDS_TYPES = new Set<String>{ 'EntityDefinition', 'CompactLayout' };
    public static final Set<String> NO_OWNER_TYPES = new Set<String>{ 'FlexiPage' };
    public static final Set<String> NO_DEFAULT_FIELDS_TYPES = new Set<String>{ 'Certificate' };

    public static final Set<String> ENTITY_FIELD_TYPES = new Set<String>{
        'BusinessProcess',
        'CustomField',
        'FieldDefinition',
        'FieldSet',
        'Layout',
        'QuickActionDefinition',
        'RecordType',
        'ValidationRule',
        'WebLink',
        'WorkflowAlert',
        'WorkflowFieldUpdate',
        'WorkflowOutboundMessage'
    };

    public static final Set<String> DEFINITION_FIELD_TYPES = new Set<String>{
        'Flow'
    };

    public static final Set<String> CONDITIONAL_QUERY_TYPES = new Set<String>{
        'Flow',
        'PermissionSet'
    };

    // CONVERSION MAP

    public static final Map<String, String> TOOLING_API_TYPES_BY_METADATA_API_TYPE = new Map<String, String>{
        'CustomLabel' => 'ExternalString',
        'CustomObject' => 'EntityDefinition',
        'ExternalServicesSettings' => 'ExternalServiceRegistration',
        'QuickAction' => 'QuickActionDefinition',
        'MatchingRules' => 'MatchingRule'
    };

}