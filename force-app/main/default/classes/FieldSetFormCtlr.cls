public with sharing class FieldSetFormCtlr {
    private final static String IS_SUCCESS = 'isSuccess';
    private final static String OBJECT_NAME = 'objectName';
    private final static String FIELDS_INFO = 'fields';
    private final static String MESSAGE = 'message';

    @AuraEnabled
    public static Map<String, Object> getObjectAndFieldDetails(Id recordId, String fieldset) {
        Map<String, Object> result = new Map<String, Object>{ IS_SUCCESS => false };
        try {
            String objectName = recordId?.getSObjectType().getDescribe().getName();
            Map<String, Schema.SObjectType> describeResult = Schema.getGlobalDescribe();
            if (describeResult.containsKey(objectName)) {
                Map<String, Schema.FieldSet> fieldSetResult = describeResult.get(objectName).getDescribe().fieldSets.getMap();
                if (fieldSetResult.containsKey(fieldset)) {
                    result.put(IS_SUCCESS, true);
                    result.put(OBJECT_NAME, objectName);
                    result.put(FIELDS_INFO, getFields(fieldSetResult.get(fieldset).getFields()));
                } else {
                    result.put(MESSAGE, String.format(Label.NO_FIELD_SET_FOUND, new List<String>{ fieldset }));
                }
            } else {
                result.put(MESSAGE, String.format(Label.NO_OBJECT_FOUND, new List<String>{ objectName }));
            }
        } catch (Exception e) {
            result.put(MESSAGE, e.getMessage());
        }
        return result;
    }

    private static List<String> getFields(List<Schema.FieldSetMember> fieldSetMembers) {
        List<String> fields = new List<String>();
        for (Schema.FieldSetMember fieldSetMember : fieldSetMembers) {
            fields.add(fieldSetMember.getFieldPath());
        }
        return fields;
    }
}