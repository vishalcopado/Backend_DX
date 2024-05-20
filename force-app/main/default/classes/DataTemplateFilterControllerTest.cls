@IsTest
private class DataTemplateFilterControllerTest {
    private static final String ADD_DESCRIBE_SOBJECT = 'ADD_Describe_SObject_Result';
    @TestSetup
    private static void makeData() {
        TestUtilities.setup();
        System.runAs(TestUtilities.getRunAsUser()) {
            createData();
        }
    }

    @IsTest
    private static void testMainObjectFieldsNoAttachment() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            String exceptionMessage;

            // EXERCISE
            try {
                DataTemplateFilterController.getMainObjectFields(getDataTemplate('Test Template').id);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY
            Assert.areEqual('Error getting sobject fields', exceptionMessage, 'The exception message is incorrect');
        }
    }

    @IsTest
    private static void testMainObjectFieldsSuccess() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP

             // SETUP
             DataTemplate dataTemplate = getDataTemplate('Test Template');
             createAttachment(dataTemplate, getFields()); 

            // EXERCISE

            List<DataTemplateFilterController.Field> fields = DataTemplateFilterController.getMainObjectFields(dataTemplate.id);

            // VERIFY

            Assert.areEqual(2, fields.size(), 'The number of fields should be 2');
            Assert.areEqual('Account Id', fields[0].label, 'The label for field is incorrect');
            Assert.areEqual('Id', fields[0].name, 'The name for field is incorrect');
            Assert.areEqual('ID', fields[0].type, 'The type for field is incorrect');

            Assert.areEqual(2, fields[0].operators.size(), 'The number of operators for field is incorrect');
            Assert.areEqual('e', fields[0].operators[0].code, 'The operator code for field 1 is incorrect');
            Assert.areEqual('equals', fields[0].operators[0].label, 'The operator label for field 1 is incorrect');
            Assert.areEqual('n', fields[0].operators[1].code, 'The operator code for field 1 is incorrect');
            Assert.areEqual('not equal to', fields[0].operators[1].label, 'The operator label for field 1 is incorrect');

            Assert.areEqual('Account Name', fields[1].label, 'The label for field is incorrect');
            Assert.areEqual('Name', fields[1].name, 'The name for field is incorrect');
            Assert.areEqual('STRING', fields[1].type, 'The type for field is incorrect');

            Assert.areEqual(5, fields[1].operators.size(), 'The number ofoperators for field is incorrect');
            Assert.areEqual('c', fields[1].operators[0].code, 'The operator code for field 2 is incorrect');
            Assert.areEqual('contains', fields[1].operators[0].label, 'The operator label for field 2 is incorrect');
            Assert.areEqual('k', fields[1].operators[1].code, 'The operator code for field 2 is incorrect');
            Assert.areEqual('does not contain', fields[1].operators[1].label, 'The operator label for field 2 is incorrect');

            Assert.areEqual('e', fields[1].operators[2].code, 'The operator code for field 2 is incorrect');
            Assert.areEqual('equals', fields[1].operators[2].label, 'The operator label for field 2 is incorrect');
            Assert.areEqual('n', fields[1].operators[3].code, 'The operator code for field 2 is incorrect');
            Assert.areEqual('not equal to', fields[1].operators[3].label, 'The operator label for field 2 is incorrect');
            Assert.areEqual('s', fields[1].operators[4].code, 'The operator code for field 2 is incorrect');
            Assert.areEqual('starts with', fields[1].operators[4].label, 'The operator label for field 2 is incorrect');
        }
    }

    @IsTest
    private static void testMainObjectAddressOnlyFieldsFailure() {
        System.runAs(TestUtilities.getRunAsUser()) {

             // SETUP
             DataTemplate dataTemplate = getDataTemplate('Test Template');
             createAttachment(dataTemplate, getAddressOnlyFields()); 
             String exceptionMessage;

            // EXERCISE

            try {
                DataTemplateFilterController.getMainObjectFields(dataTemplate.id);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // VERIFY

            Assert.areEqual('Error getting sobject fields', exceptionMessage, 'The exception message is incorrect');
        }
    }



    @IsTest
    @SuppressWarnings('PMD.NcssMethodCount')
    private static void testQueryFiltersAndDataFiltersConversionSuccess() {
        System.runAs(TestUtilities.getRunAsUser()) {
            // SETUP
            List<QueryEditor.CriteriaWrapper> queryFilters = getQueryFilterList();

            // EXERCISE

            List<DataFilter> response = DataTemplateFilterController.convertQueryFilters(queryFilters);

            // VERIFY

            // FIELD 1
            Assert.areEqual(8, response.size(), 'The number of data filters returned is incorrect');
            Assert.areEqual('Account Name', response[0].fieldLabel, 'The fieldLabel of data filter returned is incorrect');
            Assert.areEqual('Name', response[0].fieldName, 'The fieldName of data filter returned is incorrect');
            Assert.areEqual('STRING', response[0].fieldType, 'The fieldType of data filter returned is incorrect');
            Assert.areEqual('c', response[0].operatorCode, 'The operatorCode of data filter returned is incorrect');
            Assert.areEqual(1, response[0].order, 'The order of data filter returned is incorrect');
            Assert.areEqual('Record 2', response[0].value, 'The value of data filter returned is incorrect');

            // FIELD 2
            Assert.areEqual('Created Date', response[1].fieldLabel, 'The fieldLabel of data filter returned is incorrect');
            Assert.areEqual('CreatedDate', response[1].fieldName, 'The fieldName of data filter returned is incorrect');
            Assert.areEqual('DATETIME', response[1].fieldType, 'The fieldType of data filter returned is incorrect');
            Assert.areEqual('e', response[1].operatorCode, 'The operatorCode of data filter returned is incorrect');
            Assert.areEqual(2, response[1].order, 'The order of data filter returned is incorrect');
            Assert.areEqual('TODAY', response[1].value, 'The value of data filter returned is incorrect');

            // FIELD 3
            Assert.areEqual(null, response[2].fieldLabel, 'The fieldLabel of data filter returned is incorrect');
            Assert.areEqual('Custom Filter', response[2].fieldName, 'The fieldName of data filter returned is incorrect');
            Assert.areEqual('STRING', response[2].fieldType, 'The fieldType of data filter returned is incorrect');
            Assert.areEqual('e', response[2].operatorCode, 'The operatorCode of data filter returned is incorrect');
            Assert.areEqual(3, response[2].order, 'The order of data filter returned is incorrect');
            Assert.areEqual('Name=\'Test\'', response[2].value, 'The value of data filter returned is incorrect');

            // FIELD 4
            Assert.areEqual(null, response[3].fieldLabel, 'The fieldLabel of data filter returned is incorrect');
            Assert.areEqual('LastModifiedDate', response[3].fieldName, 'The fieldName of data filter returned is incorrect');
            Assert.areEqual('DATETIME', response[3].fieldType, 'The fieldType of data filter returned is incorrect');
            Assert.areEqual('e', response[3].operatorCode, 'The operatorCode of data filter returned is incorrect');
            Assert.areEqual(4, response[3].order, 'The order of data filter returned is incorrect');
            Assert.areEqual('TODAY', response[3].value, 'The value of data filter returned is incorrect');

            // FIELD 5
            Assert.areEqual('Account Name', response[4].fieldLabel, 'The fieldLabel of data filter returned is incorrect');
            Assert.areEqual('Name', response[4].fieldName, 'The fieldName of data filter returned is incorrect');
            Assert.areEqual('STRING', response[4].fieldType, 'The fieldType of data filter returned is incorrect');
            Assert.areEqual('k', response[4].operatorCode, 'The operatorCode of data filter returned is incorrect');
            Assert.areEqual(5, response[4].order, 'The order of data filter returned is incorrect');
            Assert.areEqual('Record 3', response[4].value, 'The value of data filter returned is incorrect');

            // FIELD 6
            Assert.areEqual('Created Date', response[5].fieldLabel, 'The fieldLabel of data filter returned is incorrect');
            Assert.areEqual('CreatedDate', response[5].fieldName, 'The fieldName of data filter returned is incorrect');
            Assert.areEqual('DATETIME', response[5].fieldType, 'The fieldType of data filter returned is incorrect');
            Assert.areEqual('e', response[5].operatorCode, 'The operatorCode of data filter returned is incorrect');
            Assert.areEqual(6, response[5].order, 'The order of data filter returned is incorrect');
            Assert.areEqual('LAST_N_DAYS:10', response[5].value, 'The value of data filter returned is incorrect');

            // FIELD 7
            Assert.areEqual('Created Date', response[6].fieldLabel, 'The fieldLabel of data filter returned is incorrect');
            Assert.areEqual('CreatedDate', response[6].fieldName, 'The fieldName of data filter returned is incorrect');
            Assert.areEqual('DATETIME', response[6].fieldType, 'The fieldType of data filter returned is incorrect');
            Assert.areEqual('n', response[6].operatorCode, 'The operatorCode of data filter returned is incorrect');
            Assert.areEqual(7, response[6].order, 'The order of data filter returned is incorrect');
            Assert.areEqual('2023-06-02T17:43:00Z', response[6].value, 'The value of data filter returned is incorrect');

            // FIELD 8
            Assert.areEqual('Employees', response[7].fieldLabel, 'The fieldLabel of data filter returned is incorrect');
            Assert.areEqual('NumberOfEmployees', response[7].fieldName, 'The fieldName of data filter returned is incorrect');
            Assert.areEqual('INT', response[7].fieldType, 'The fieldType of data filter returned is incorrect');
            Assert.areEqual('h', response[7].operatorCode, 'The operatorCode of data filter returned is incorrect');
            Assert.areEqual(8, response[7].order, 'The order of data filter returned is incorrect');
            Assert.areEqual('200.0', response[7].value, 'The value of data filter returned is incorrect');

            // EXERCISE
            List<QueryEditor.CriteriaWrapper> result = DataTemplateFilterController.convertFilters(response);

            // VERIFY

            // CRITERIA 1
            Assert.areEqual(1, result[0].order, 'The order of the criteria is incorrect');
            Assert.areEqual('Account Name', result[0].fieldLabel, 'The fieldLabel of the criteria is incorrect');
            Assert.areEqual('Account Name-Name', result[0].fieldName, 'The fieldName of the criteria is incorrect');
            Assert.areEqual('STRING', result[0].fieldType, 'The fieldType of the criteria is incorrect');
            Assert.areEqual('c', result[0].operator, 'The operator of the criteria is incorrect');
            Assert.areEqual('Record 2', result[0].input, 'The input of the criteria is incorrect');
            Assert.areEqual(null, result[0].dateInput, 'The dateInput of the criteria is incorrect');
            Assert.areEqual(null, result[0].dateTimeInput, 'The dateTimeInput of the criteria is incorrect');
            Assert.areEqual(null, result[0].numberInput, 'The numberInput of the criteria is incorrect');
            Assert.areEqual('Name LIKE \'%Record 2%\'', result[0].finalValue, 'The finalValue of the criteria is incorrect');
            Assert.areEqual(true, result[0].isValid, 'The isValid of the criteria is incorrect');

            // CRITERIA 2
            Assert.areEqual(2, result[1].order, 'The order of the criteria is incorrect');
            Assert.areEqual('Created Date', result[1].fieldLabel, 'The fieldLabel of the criteria is incorrect');
            Assert.areEqual('Created Date-CreatedDate', result[1].fieldName, 'The fieldName of the criteria is incorrect');
            Assert.areEqual('DATETIME', result[1].fieldType, 'The fieldType of the criteria is incorrect');
            Assert.areEqual('e', result[1].operator, 'The operator of the criteria is incorrect');
            Assert.areEqual('TODAY', result[1].input, 'The input of the criteria is incorrect');
            Assert.areEqual(null, result[1].dateInput, 'The dateInput of the criteria is incorrect');
            Assert.areEqual(null, result[1].dateTimeInput, 'The dateTimeInput of the criteria is incorrect');
            Assert.areEqual(null, result[1].numberInput, 'The numberInput of the criteria is incorrect');
            Assert.areEqual('CreatedDate = TODAY', result[1].finalValue, 'The finalValue of the criteria is incorrect');
            Assert.areEqual(true, result[1].isValid, 'The isValid of the criteria is incorrect');

            // CRITERIA 3
            Assert.areEqual(3, result[2].order, 'The order of the criteria is incorrect');
            Assert.areEqual(null, result[2].fieldLabel, 'The fieldLabel of the criteria is incorrect');
            Assert.areEqual('null-Custom Filter', result[2].fieldName, 'The fieldName of the criteria is incorrect');
            Assert.areEqual('STRING', result[2].fieldType, 'The fieldType of the criteria is incorrect');
            Assert.areEqual('e', result[2].operator, 'The operator of the criteria is incorrect');
            Assert.areEqual('Name=\'Test\'', result[2].input, 'The input of the criteria is incorrect');
            Assert.areEqual(null, result[2].dateInput, 'The dateInput of the criteria is incorrect');
            Assert.areEqual(null, result[2].dateTimeInput, 'The dateTimeInput of the criteria is incorrect');
            Assert.areEqual(null, result[2].numberInput, 'The numberInput of the criteria is incorrect');
            Assert.areEqual('Name=\'Test\'', result[2].finalValue, 'The finalValue of the criteria is incorrect');
            Assert.areEqual(true, result[2].isValid, 'The isValid of the criteria is incorrect');

            // CRITERIA 4
            Assert.areEqual(4, result[3].order, 'The order of the criteria is incorrect');
            Assert.areEqual(null, result[3].fieldLabel, 'The fieldLabel of the criteria is incorrect');
            Assert.areEqual('null-LastModifiedDate', result[3].fieldName, 'The fieldName of the criteria is incorrect');
            Assert.areEqual('DATETIME', result[3].fieldType, 'The fieldType of the criteria is incorrect');
            Assert.areEqual('e', result[3].operator, 'The operator of the criteria is incorrect');
            Assert.areEqual('TODAY', result[3].input, 'The input of the criteria is incorrect');
            Assert.areEqual(null, result[3].dateInput, 'The dateInput of the criteria is incorrect');
            Assert.areEqual(null, result[3].dateTimeInput, 'The dateTimeInput of the criteria is incorrect');
            Assert.areEqual(null, result[3].numberInput, 'The numberInput of the criteria is incorrect');
            Assert.areEqual('LastModifiedDate = TODAY', result[3].finalValue, 'The finalValue of the criteria is incorrect');
            Assert.areEqual(true, result[3].isValid, 'The isValid of the criteria is incorrect');

            // CRITERIA 5
            Assert.areEqual(5, result[4].order, 'The order of the criteria is incorrect');
            Assert.areEqual('Account Name', result[4].fieldLabel, 'The fieldLabel of the criteria is incorrect');
            Assert.areEqual('Account Name-Name', result[4].fieldName, 'The fieldName of the criteria is incorrect');
            Assert.areEqual('STRING', result[4].fieldType, 'The fieldType of the criteria is incorrect');
            Assert.areEqual('k', result[4].operator, 'The input of the criteria is incorrect');
            Assert.areEqual('Record 3', result[4].input, 'The order of the criteria is incorrect');
            Assert.areEqual(null, result[4].dateInput, 'The dateInput of the criteria is incorrect');
            Assert.areEqual(null, result[4].dateTimeInput, 'The dateTimeInput of the criteria is incorrect');
            Assert.areEqual(null, result[4].numberInput, 'The numberInput of the criteria is incorrect');
            Assert.areEqual(' (NOT Name LIKE \'%Record 3%\') ', result[4].finalValue, 'The finalValue of the criteria is incorrect');
            Assert.areEqual(true, result[4].isValid, 'The isValid of the criteria is incorrect');

            // CRITERIA 6
            Assert.areEqual(6, result[5].order, 'The order of the criteria is incorrect');
            Assert.areEqual('Created Date', result[5].fieldLabel, 'The fieldLabel of the criteria is incorrect');
            Assert.areEqual('Created Date-CreatedDate', result[5].fieldName, 'The fieldName of the criteria is incorrect');
            Assert.areEqual('DATETIME', result[5].fieldType, 'The fieldType of the criteria is incorrect');
            Assert.areEqual('e', result[5].operator, 'The input of the criteria is incorrect');
            Assert.areEqual('LAST_N_DAYS:n', result[5].input, 'The order of the criteria is incorrect');
            Assert.areEqual(null, result[5].dateInput, 'The dateInput of the criteria is incorrect');
            Assert.areEqual(null, result[5].dateTimeInput, 'The dateTimeInput of the criteria is incorrect');
            Assert.areEqual(10, result[5].numberInput, 'The numberInput of the criteria is incorrect');
            Assert.areEqual('CreatedDate = LAST_N_DAYS:10', result[5].finalValue, 'The finalValue of the criteria is incorrect');
            Assert.areEqual(true, result[5].isValid, 'The isValid of the criteria is incorrect');

            // CRITERIA 7
            Assert.areEqual(7, result[6].order, 'The order of the criteria is incorrect');
            Assert.areEqual('Created Date', result[6].fieldLabel, 'The fieldLabel of the criteria is incorrect');
            Assert.areEqual('Created Date-CreatedDate', result[6].fieldName, 'The fieldName of the criteria is incorrect');
            Assert.areEqual('DATETIME', result[6].fieldType, 'The fieldType of the criteria is incorrect');
            Assert.areEqual('n', result[6].operator, 'The operator of the criteria is incorrect');
            Assert.areEqual('customDate', result[6].input, 'The input of the criteria is incorrect');
            Assert.areEqual(null, result[6].dateInput, 'The dateInput of the criteria is incorrect');
            Assert.areEqual(Datetime.newInstance(2023, 6, 2, 10, 43, 0), result[6].dateTimeInput, 'The dateTimeInput of the criteria is incorrect');
            Assert.areEqual(null, result[6].numberInput, 'The numberInput of the criteria is incorrect');
            Assert.areEqual('CreatedDate != 2023-06-02T17:43:00Z', result[6].finalValue, 'The finalValue of the criteria is incorrect');
            Assert.areEqual(true, result[6].isValid, 'The isValid of the criteria is incorrect');

            // CRITERIA 8
            Assert.areEqual(8, result[7].order, 'The order of the criteria is incorrect');
            Assert.areEqual('Employees', result[7].fieldLabel, 'The fieldLabel of the criteria is incorrect');
            Assert.areEqual('Employees-NumberOfEmployees', result[7].fieldName, 'The fieldName of the criteria is incorrect');
            Assert.areEqual('INT', result[7].fieldType, 'The fieldType of the criteria is incorrect');
            Assert.areEqual('h', result[7].operator, 'The operator of the criteria is incorrect');
            Assert.areEqual('200.0', result[7].input, 'The input of the criteria is incorrect');
            Assert.areEqual(null, result[7].dateInput, 'The dateInput of the criteria is incorrect');
            Assert.areEqual(null, result[7].dateTimeInput, 'The dateTimeInput of the criteria is incorrect');
            Assert.areEqual(200, result[7].numberInput, 'The numberInput of the criteria is incorrect');
            Assert.areEqual('NumberOfEmployees >= 200.0', result[7].finalValue, 'The finalValue of the criteria is incorrect');
            Assert.areEqual(true, result[7].isValid, 'The isValid of the criteria is incorrect');
        }
    }

    private static void createData() {
        Credential dev1 = new Credential().name('dev1');

        new DataTemplate().name('Test Template').batchSize(200).templateSourceOrg(dev1).activate().persist();
    }

    private static void createAttachment(DataTemplate dataTemplate, List<DescribeSObjectService.CopadoField> fields) {
        new Attachment_t().name(ADD_DESCRIBE_SOBJECT).parent(dataTemplate).body(getSobjectFieldsDescribe(fields)).persist();
    }

    private static DataTemplate getDataTemplate(String name) {
        copado__Data_Template__c dataTemplate = [SELECT Id FROM copado__Data_Template__c WHERE Name = :name LIMIT 1];
        return new DataTemplate().recordId(dataTemplate.Id);
    }

    private static Blob getSobjectFieldsDescribe(List<DescribeSObjectService.CopadoField> fields) {
        DescribeSObjectService.DescribeResponse describeResponse = new DescribeSObjectService.DescribeResponse();
        describeResponse.fields = fields;
        return Blob.valueOf(JSON.serialize(describeResponse));
    }

    private static List<DescribeSObjectService.CopadoField> getFields() {
        List<DescribeSObjectService.CopadoField> fields = new List<DescribeSObjectService.CopadoField>();
        fields.add(createField('Name', 'Account Name', 'string'));
        fields.add(createField('Id', 'Account Id', 'id'));
        return fields;
    }

    private static List<DescribeSObjectService.CopadoField> getAddressOnlyFields() {
        List<DescribeSObjectService.CopadoField> fields = new List<DescribeSObjectService.CopadoField>();
        fields.add(createField('Billing Address', 'BillingAddress', 'ADDRESS'));
        return fields;
    }

    private static DescribeSObjectService.CopadoField createField(String name, String label, String type) {
        DescribeSObjectService.CopadoField field = new DescribeSObjectService.CopadoField();
        field.label = label;
        field.name = name;
        field.type = type;
        return field;
    }

    private static List<QueryEditor.CriteriaWrapper> getQueryFilterList() {
        List<QueryEditor.CriteriaWrapper> queryFilters = new List<QueryEditor.CriteriaWrapper>();
        queryFilters.add(
            createQueryFilter('Account Name', 'Account Name-Name', 'STRING', 'Name LIKE \'Record 2\'', 'Record 2', true, 'c', 1, null, null)
        );
        queryFilters.add(
            createQueryFilter('Created Date', 'Created Date-CreatedDate', 'DATETIME', 'CreatedDate = TODAY', 'TODAY', true, 'e', 2, null, null)
        );
        queryFilters.add(createQueryFilter(null, 'null-Custom Filter', 'STRING', 'Name=\'Test\'', 'Name=\'Test\'', true, 'e', 3, null, null));
        queryFilters.add(createQueryFilter(null, 'null-LastModifiedDate', 'DATETIME', 'LastModifiedDate = TODAY', 'TODAY', true, 'e', 4, null, null));
        queryFilters.add(
            createQueryFilter('Account Name', 'Account Name-Name', 'STRING', ' (NOT Name LIKE \'%Record 3%\') ', 'Record 3', true, 'k', 5, null, null)
        );

        queryFilters.add(
            createQueryFilter(
                'Created Date',
                'Created Date-CreatedDate',
                'DATETIME',
                'CreatedDate = LAST_N_DAYS:10',
                'LAST_N_DAYS:n',
                true,
                'e',
                6,
                null,
                Double.valueOf(10)
            )
        );  
        queryFilters.add(
            createQueryFilter(
                'Created Date',
                'Created Date-CreatedDate',
                'DATETIME',
                'CreatedDate != 2023-06-02T10:43:00.000Z',
                'customDate',
                true,
                'n',
                7,
                Datetime.newInstance(2023, 6, 2, 10, 43, 0),
                null
            )
        );
        queryFilters.add(
            createQueryFilter(
                'Employees',
                'Employees-NumberOfEmployees',
                'INT',
                'NumberOfEmployees >= 200',
                '200',
                true,
                'h',
                8,
                null,
                Double.valueOf(200.0)
            )
        );
        return queryFilters;
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static QueryEditor.CriteriaWrapper createQueryFilter(
        String fieldLabel,
        String fieldName,
        String fieldType,
        String finalValue,
        String input,
        Boolean isValid,
        String operator,
        Integer order,
        Datetime dateTimeInput,
        Double numberInput
    ) {
        QueryEditor.CriteriaWrapper queryFilter = new QueryEditor.CriteriaWrapper();
        queryFilter.fieldLabel = fieldLabel;
        queryFilter.fieldName = fieldName;
        queryFilter.fieldType = fieldType;
        queryFilter.finalValue = finalValue;
        queryFilter.input = input;
        queryFilter.isValid = isValid;
        queryFilter.operator = operator;
        queryFilter.order = order;
        queryFilter.dateTimeInput = dateTimeInput;
        queryFilter.numberInput = numberInput;
        return queryFilter;
    }
}