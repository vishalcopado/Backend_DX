/*
    This class is a wrapper for the sobject describe response that is saved in the attachment ADD_Describe_SObject_Result  on the  copado__DataTemplate__c record
    It is being used in the extension to fetch the fields of the main object of the data template
*/
public with sharing class DescribeSObjectService {
    public with sharing class DescribeResponse {
        public List<CopadoField> fields;
    }

    public with sharing class CopadoField implements Comparable {
        public String label;
        public String name;
        public String type;

        public Integer compareTo(Object compareTo) {
            CopadoField compareToField = (CopadoField) compareTo;
            return label.compareTo(compareToField.label);
        }
    }
}