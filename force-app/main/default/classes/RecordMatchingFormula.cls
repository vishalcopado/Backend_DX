public class RecordMatchingFormula extends DomainBuilder {
    public RecordMatchingFormula() {
        super(copado__Record_Matching_Formula__c.SObjectType);
    }

    public RecordMatchingFormula name(String value) {
        return (RecordMatchingFormula) set(copado__Record_Matching_Formula__c.Name, value);
    }

    public RecordMatchingFormula field1(String value) {
        return (RecordMatchingFormula) set(copado__Record_Matching_Formula__c.copado__Field_1__c, value);
    }

    public RecordMatchingFormula field2(String value) {
        return (RecordMatchingFormula) set(copado__Record_Matching_Formula__c.copado__Field_2__c, value);
    }

    public RecordMatchingFormula field3(String value) {
        return (RecordMatchingFormula) set(copado__Record_Matching_Formula__c.copado__Field_3__c, value);
    }

    public RecordMatchingFormula hashFormula(Boolean value) {
        return (RecordMatchingFormula) set(copado__Record_Matching_Formula__c.copado__Hash_Formula__c, value);
    }

    public RecordMatchingFormula object(String value) {
        return (RecordMatchingFormula) set(copado__Record_Matching_Formula__c.copado__Object__c, value);
    }

    public RecordMatchingFormula configSourceOrg(Id value) {
        return (RecordMatchingFormula) set(copado__Record_Matching_Formula__c.copado__Configuration_Source_Org__c, value);
    }
}