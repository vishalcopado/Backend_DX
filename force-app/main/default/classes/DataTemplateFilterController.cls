public with sharing class DataTemplateFilterController {
    private static final Set<String> INVALID_TYPES = new Set<String>{ 'ADDRESS' };
    private static final String ADD_DESCRIBE_SOBJECT = 'ADD_Describe_SObject_Result';

    // PUBLIC

    @AuraEnabled(cacheable=true)
    public static List<Field> getMainObjectFields(String recordId) {
        try {
            List<DescribeSObjectService.CopadoField> fields = getObjectDescribeFields(recordId);
            return convertFields(fields);
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<DataFilter> convertQueryFilters(List<QueryEditor.CriteriaWrapper> queryFilters) {
        try {
            List<DataFilter> result = new List<DataFilter>();
            for (QueryEditor.CriteriaWrapper queryFilter : queryFilters) {
                result.add(new DataFilter(queryFilter));
            }
            return result;
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<QueryEditor.CriteriaWrapper> convertFilters(List<DataFilter> filters) {
        try {
            // convert DataFilter to CriteriaWrapper (compatibility)
            List<QueryEditor.CriteriaWrapper> result = new List<QueryEditor.CriteriaWrapper>();
            for (DataFilter filter : filters) {
                result.add(filter.toQueryCriteria());
            }
            return result;
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }

    // PRIVATE

    private static List<DescribeSObjectService.CopadoField> getObjectDescribeFields(String recordId) {
        try {
            List<Attachment> attachments = new AttachmentsSelector()
                .byParentIdsAndNames(new Set<Id>{ recordId }, new Set<String>{ ADD_DESCRIBE_SOBJECT }, 1);
            if (attachments.isEmpty()) {
                throw new ApplicationException(Label.Error_Fetching_Fields);
            }
            DescribeSObjectService.DescribeResponse describeResponse = (DescribeSObjectService.DescribeResponse) JSON.deserialize(
                attachments[0].Body.toString(),
                DescribeSObjectService.DescribeResponse.class
            );
            return describeResponse.fields;
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }

    private static List<Field> convertFields(List<DescribeSObjectService.CopadoField> fields) {
        List<Field> result = new List<Field>();

        for (DescribeSObjectService.CopadoField field : fields) {
            if (!INVALID_TYPES.contains(field.type.toUpperCase())) {
                result.add(new Field(field));
            }
        }

        result.sort();

        if (result.isEmpty()) {
            throw new ApplicationException(Label.Error_Fetching_Fields);
        }
        return result;
    }

    // INNER

    public with sharing class Field implements Comparable {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public List<Operator> operators;

        public Field(DescribeSObjectService.CopadoField copadoField) {
            this.label = copadoField.label;
            this.name = copadoField.name;
            this.type = copadoField.type.toUpperCase();
            this.operators = typeOperators(this.type);
            this.operators.sort();
        }

        private List<Operator> typeOperators(String type) {
            List<Operator> operators = new List<Operator>();

            Map<String, String[]> operatorCodesByFieldType = OperatorTypeCodes.getTypeToOps();
            Map<String, String> operatorLabelByCode = OperatorTypeCodes.getOperatorCodes();
            Map<String, String> comparisonOperatorByCode = OperatorTypeCodes.getOperatorSymbols();

            if (operatorCodesByFieldType.containsKey(type)) {
                List<String> operatorCodes = operatorCodesByFieldType.get(type);
                for (String code : operatorCodes) {
                    Operator operator = new Operator();
                    operator.code = code;
                    if (operatorLabelByCode.containsKey(code)) {
                        operator.label = operatorLabelByCode.get(code);
                    }
                    // do not add operator if comparison operator is not defined
                    if (comparisonOperatorByCode.containsKey(code)) {
                        operators.add(operator);
                    }
                }
            }

            return operators;
        }

        public Integer compareTo(Object compareTo) {
            Field compareToField = (Field) compareTo;
            return label.compareTo(compareToField.label);
        }
    }

    public with sharing class Operator implements Comparable {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String code;

        public Integer compareTo(Object compareTo) {
            Operator compareToOperator = (Operator) compareTo;
            return label.compareTo(compareToOperator.label);
        }
    }
}