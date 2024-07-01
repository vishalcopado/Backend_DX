@SuppressWarnings('PMD.ExcessivePublicCount')
public with sharing class QueryEditor {
    public class CriteriaWrapper implements Comparable {
        @AuraEnabled
        public String fieldName { get; set; }
        @AuraEnabled
        public String fieldType { get; set; }
        @AuraEnabled
        public String fieldLabel { get; set; }
        @AuraEnabled
        public Integer order { get; set; }
        @AuraEnabled
        public String operator { get; set; }
        public List<SelectOption> operatorSet { get; set; }
        @AuraEnabled
        public String input { get; set; }
        @AuraEnabled
        public Double numberInput { get; set; }
        @AuraEnabled
        public Date dateInput { get; set; }
        @AuraEnabled
        public Datetime dateTimeInput { get; set; }
        @AuraEnabled
        public String finalValue { get; set; }
        @AuraEnabled
        public Boolean isValid { get; set; }

        public CriteriaWrapper() {
            this.fieldName = '--None--';
            this.fieldLabel = '';
            this.fieldType = 'STRING';
            this.operator = '--None--';
            this.operatorSet = new List<SelectOption>();
            this.input = '';
            this.numberInput = 0;
            this.dateInput = null;
            this.dateTimeInput = null;
            this.finalValue = '';
            this.isValid = true;
        }

        public Integer compareTo(Object compareTo) {
            CriteriaWrapper criteriaWrapper = (CriteriaWrapper) compareTo;
            if (this.order == criteriaWrapper.order) {
                return 0;
            }
            if (this.order > criteriaWrapper.order) {
                return 1;
            }
            return -1;
        }
    }
}