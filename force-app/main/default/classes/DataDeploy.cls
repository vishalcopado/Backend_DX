@SuppressWarnings('PMD.PropertyNamingConventions')
// PropertyNamingConventions: Needed for Skeleton Attributes, as we are using a name starting by uppercase

public with sharing class DataDeploy implements CopadoDomain {
    /************ CHECK-CONFIGURATION ************/

    // SKELETON Attribute
    // Parameter name starts with a capital letter for execution signature to look like static execution.
    public static DataDeployConfiguration DataDeployConfiguration {
        get {
            if (DataDeployConfiguration == null) {
                DataDeployConfiguration = new DataDeployConfiguration();
            }
            return DataDeployConfiguration;
        }
        set;
    }

    /*
        SENSITIVE CLASS
        - Changes in this class will potentially impact many usages and use cases.
        - Please get an architect approval before changing this class.
        - [TDD] If the change is approved please start by creating a Unit test for your change first.
        - When the change is done execute the DataDeploy Domain test suite not just your test.
        - If the new test is not included in the test suite, make sure to add it.
        - Pull request for changes happened in this class must contain an architect approval.
    */
    public inherited sharing class DataDeployConfiguration implements CopadoService {
        // Note: Not setting savepoint as this service is only querying records, not writing to database
        // Note: Checking Configuration to determine if Nextgen Data Deploy is Enabled
        public CheckConfigurationResult checkConfiguration(CheckConfigurationRequest request) {
            try {
                return DataDeployConfigurationCheckImpl.execute(request);
            } catch (Exception ex) {
                throw new ApplicationException(ex.getMessage());
            }
        }
    }

    @JsonAccess(serializable='always' deserializable='always')
    public inherited sharing class CheckConfigurationRequest implements CopadoServiceRequest {
        public Id pipelineId; // optional
    }

    @JsonAccess(serializable='always' deserializable='always')
    public inherited sharing class CheckConfigurationResult implements CopadoServiceResult {
        public Boolean isMCDDEnabled;

        public CheckConfigurationResult(Boolean isMCDDEnabled) {
            this.isMCDDEnabled = isMCDDEnabled;
        }
    }

    /************ CREATE DATA SET FILES ************/

    // SKELETON Attribute
    // Parameter name starts with a capital letter for execution signature to look like static execution.
    public static DataSetExecution DataSetExecution {
        get {
            if (DataSetExecution == null) {
                DataSetExecution = new DataSetExecution();
            }
            return DataSetExecution;
        }
        set;
    }

    /*
        SENSITIVE CLASS
        - Changes in this class will potentially impact many usages and use cases.
        - Please get an architect approval before changing this class.
        - [TDD] If the change is approved please start by creating a Unit test for your change first.
        - When the change is done execute the DataDeploy Domain test suite not just your test.
        - If the new test is not included in the test suite, make sure to add it.
        - Pull request for changes happened in this class must contain an architect approval.
    */
    public inherited sharing class DataSetExecution implements CopadoService {
        // Note: Checking Configuration to determine if Nextgen Data Deploy is Enabled
        public DataSetExecutionResult executeDataSetJobTemplate(DataSetExecutionRequest request) {
            try {
                return DataSetJobTemplateImpl.execute(request);
            } catch (Exception ex) {
                throw new ApplicationException(ex.getMessage());
            }
        }
    }

    // INNER
    @JsonAccess(serializable='always' deserializable='always')
    public inherited sharing class DataSetExecutionRequest implements CopadoServiceRequest {
        @InvocableVariable
        public String jobTemplateName;
        @InvocableVariable
        public String parentId;
        @InvocableVariable
        public String sourceType;
        @InvocableVariable
        public String destinationType;
        @InvocableVariable
        public String sourceCredentialId;
        @InvocableVariable
        public String destinationCredentialId;
        @InvocableVariable
        public String sourceDataSetId;
        @InvocableVariable
        public String destinationDataSetId;
        @InvocableVariable
        public String dataTemplateId;
    }

    @JsonAccess(serializable='always' deserializable='always')
    public inherited sharing class DataSetExecutionResult implements CopadoServiceResult {
        @InvocableVariable
        public Id jobExecutionId;
    }
}