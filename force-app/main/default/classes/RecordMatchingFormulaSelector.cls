public with sharing class RecordMatchingFormulaSelector extends fflib_SObjectSelector {
    // CONSTRUCTOR

    public RecordMatchingFormulaSelector() {
        this(true, true);
    }

    public RecordMatchingFormulaSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(false, enforceCRUD, enforceFLS, false);
    }

    // PUBLIC

    public SObjectType getSObjectType() {
        return copado__Record_Matching_Formula__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{ copado__Record_Matching_Formula__c.copado__Object__c };
    }

    public List<copado__Record_Matching_Formula__c> byObjects(Set<String> objects) {
        return Database.query(
            newQueryFactory()
                .selectFields(
                    new List<String>{
                        'copado__Field_1__c',
                        'copado__Field_2__c',
                        'copado__Field_3__c',
                        'copado__Hash_Formula__c'
                    }
                )
                .setCondition('copado__Object__c IN : objects')
                .toSOQL()
        );
    }
}