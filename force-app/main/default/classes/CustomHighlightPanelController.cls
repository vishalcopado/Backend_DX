public with sharing class CustomHighlightPanelController {
    @AuraEnabled(cacheable=true)
    public static List<FieldDefinition> getFieldList(Id recordId, String fieldSetName) {
        if (String.isBlank(fieldSetName)) {
            return new List<FieldDefinition>();
        }
        String objectApiName = recordId.getSObjectType().getDescribe().getName();

        List<Schema.FieldSetMember> fieldSetMembers = Schema.getGlobalDescribe()
            .get(objectApiName)
            .getDescribe()
            .FieldSets.getMap()
            .get(fieldSetName)
            .getFields();

        List<FieldDefinition> fieldDescriptions = new List<FieldDefinition>();

        for (Schema.FieldSetMember field : fieldSetMembers) {
            FieldDefinition fieldDef = new FieldDefinition();
            fieldDef.apiFieldName = field.getFieldPath();
            if (fieldDescriptions.size() < 7) {
                fieldDescriptions.Add(fieldDef);
            }
        }

        return fieldDescriptions;
    }

    @AuraEnabled(cacheable=true)
    public static String getObjectPluralName(Id recordId) {
        return recordId.getSObjectType().getDescribe().getLabelPlural();
    }

    @AuraEnabled(cacheable=true)
    public static String getRecordTypeName(Id recordId) {
        try {
            String objectApiName = recordId.getSObjectType().getDescribe().getName();

            List<Schema.RecordTypeInfo> recordTypeInfos = Schema.getGlobalDescribe().get(objectApiName).getDescribe().getRecordTypeInfos();

            // NOTE - Check for recordTypeInfos is required as not all objects have record types & size > 1 because 'Master' is available, by default.
            if (recordTypeInfos != null && recordTypeInfos.size() <= 1) {
                return null;
            }

            String query =
                'SELECT Id, RecordTypeId FROM ' +
                String.escapeSingleQuotes(objectApiName) +
                ' WHERE Id = :recordId WITH USER_MODE LIMIT 1';
            SObject sObj = Database.query(query);
            return Schema.getGlobalDescribe()
                .get(objectApiName)
                .getDescribe()
                .getRecordTypeInfosById()
                .get(String.valueOf(sObj.get('RecordTypeId')))
                .getName();
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    public class FieldDefinition {
        @AuraEnabled
        public String apiFieldName { get; set; }
    }
}