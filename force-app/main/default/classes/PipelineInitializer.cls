@SuppressWarnings('PMD.PropertyNamingConventions')
// PropertyNamingConventions: Needed for Skeleton Attributes, as we are using a name starting by uppercase

public inherited sharing class PipelineInitializer implements CopadoDomain {
    /************ PRE-STEPS ************/

    // SKELETON Attribute
    // Parameter name starts with a capital letter for execution signature to look like static execution.
    public static PreSteps PreSteps {
        get {
            if (PreSteps == null) {
                PreSteps = new PreSteps();
            }
            return PreSteps;
        }
        set;
    }

    /*
        SENSITIVE CLASS
        - Changes in this class will potentially impact many usages and use cases.
        - Please get an architect approval before changing this class.
        - [TDD] If the change is approved please start by creating a Unit test for your change first.
        - When the change is done execute the PipelineInitializer Domain test suite not just your test.
        - If the new test is not included in the test suite, make sure to add it.
        - Pull request for changes happened in this class must contain an architect approval.
    */

    public inherited sharing class PreSteps implements CopadoService {

        public void checkRequirements(Id pipelineId) {
            // Note: Not setting savepoint as this service is only querying records, not writing to database
            // Note: Not checking git repository details here
            try {
                PipelineRequirementValidationImpl.execute(pipelineId);
            } catch (Exception ex) {
                throw new ApplicationException(ex.getMessage());
            }
        }

        public InitializeMainBranchResult initializeMainBranch(InitializeMainBranchRequest request) {
            Savepoint sp = Database.setSavepoint();

            try {
                return PipelineInitializeMainBranchImpl.execute(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        public void refreshMetadata(RefreshMetadataRequest request) {
            // Note: not setting savepoint as this service has callouts
            try {
                PipelineInitializerRefreshMetadataImpl.execute(request);
            } catch (Exception ex) {
                throw new ApplicationException(ex.getMessage());
            }
        }

        public void runDifferenceAnalysis(Id pipelineId) {
            Savepoint sp = Database.setSavepoint();

            try {
                PipelineInitializerDiffAnalysisImpl.execute(pipelineId);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        public StatusResult status(Id pipelineId) {
            // Note: not setting savepoint as this service is only querying records, not writing to database
            try {
                return PreStepsStatusImpl.execute(pipelineId);
            } catch (Exception ex) {
                throw new ApplicationException(ex.getMessage());
            }
        }
    }

    @JsonAccess(serializable='always' deserializable='always')
    public inherited sharing class InitializeMainBranchRequest implements CopadoServiceRequest {
        public Id pipelineId; // Required, Pipeline Id
        public String initializationType; // Valid values - Direct Branch Creation, WIP Full, WIP Diff
    }

    @JsonAccess(serializable='always' deserializable='always')
    public inherited sharing class InitializeMainBranchResult implements CopadoServiceResult {
        public copado__JobExecution__c jobExecution; // Job Execution created for the Salesforce project initialization
    }

    @JsonAccess(serializable='always' deserializable='always')
    public inherited sharing class RefreshMetadataRequest implements CopadoServiceRequest {
        public Id pipelineId; // Required, Pipeline Id
        public Boolean isDiffAnalysisNeeded = false;

        // CONSTRUCTOR

        public RefreshMetadataRequest(Id pipelineId) {
            this(pipelineId, false);
        }

        public RefreshMetadataRequest(Id pipelineId, Boolean isDiffAnalysisNeeded) {
            this.pipelineId = pipelineId;
            this.isDiffAnalysisNeeded = isDiffAnalysisNeeded;
        }
    }

    @JsonAccess(serializable='always' deserializable='always')
    public inherited sharing class StatusResult implements CopadoServiceResult {
        public String jobStatus; // Job Execution Status
        public List<copado__JobStep__c> steps; // List with step statuses
        public String pipelineInitializationStatus;

        // CONSTRUCTOR

        public StatusResult(String jobStatus, List<copado__JobStep__c> steps) {
            this.jobStatus = jobStatus;
            this.steps = steps;
        }

        public StatusResult(String jobStatus, List<copado__JobStep__c> steps, String status) {
            this.jobStatus = jobStatus;
            this.steps = steps;
            this.pipelineInitializationStatus = status;
        }
    }

    /************ PRE-STEPS ************/

    /************ SELECTIONS ************/

    // SKELETON Attribute
    // Parameter name starts with a capital letter for execution signature to look like static execution.
    public static Selections Selections {
        get {
            if (Selections == null) {
                Selections = new Selections();
            }
            return Selections;
        }
        set;
    }

    /*
        SENSITIVE CLASS
        - Changes in this class will potentially impact many usages and use cases.
        - Please get an architect approval before changing this class.
        - [TDD] If the change is approved please start by creating a Unit test for your change first.
        - When the change is done execute the PipelineInitializer Domain test suite not just your test.
        - If the new test is not included in the test suite, make sure to add it.
        - Pull request for changes happened in this class must contain an architect approval.
    */

    public inherited sharing class Selections implements CopadoService {
        public SelectionsSaveResult save(SelectionsSaveRequest request) {
            Savepoint sp = Database.setSavepoint();

            try {
                return PipelineInitializerSaveSelectionsImpl.execute(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        public SelectionsSaveResult addMetadataGroups(SelectionsSaveRequest request) {
            Savepoint sp = Database.setSavepoint();

            try {
                return AddMetadataGroupImpl.execute(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        public SelectionsSaveResult removeMetadataGroups(MetadataGroupRemovalRequest request) {
            Savepoint sp = Database.setSavepoint();

            try {
                return RemoveMetadataGroupImpl.execute(request);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }
    }

    @JsonAccess(serializable='always' deserializable='always')
    public inherited sharing class SelectionsSaveRequest implements CopadoServiceRequest {
        public Id pipelineId; // Required, Pipeline Id
        public Id environmentId; // Required, Id of the environment where the selections need to be saved
        public List<MetadataGroup> metadataGroups; // Required

        // CONSTRUCTOR

        public SelectionsSaveRequest(Id pipelineId, Id environmentId, List<MetadataGroup> metadataGroups) {
            this.pipelineId = pipelineId;
            this.environmentId = environmentId;
            this.metadataGroups = metadataGroups;
        }
    }

    @JsonAccess(serializable='always' deserializable='always')
    public inherited sharing class MetadataGroup {
        public String groupName; // Required, Has to be unique
        public String groupDescription;
        public Boolean isProcessed = false;
        public List<copado.Actions.CommitChange> selectedMetadata;
    }

    @JsonAccess(serializable='always' deserializable='always')
    public inherited sharing class SelectionsSaveResult implements CopadoServiceResult {
        public Id selectionsFileId; // Selections file Id on environment

        // CONSTRUCTOR

        public SelectionsSaveResult(Id selectionsFileId) {
            this.selectionsFileId = selectionsFileId;
        }
    }

    @JsonAccess(serializable='always' deserializable='always')
    public inherited sharing class MetadataGroupRemovalRequest implements CopadoServiceRequest {
        public Id pipelineId; // Required, Pipeline Id
        public Id environmentId; // Required, Id of the environment where the selections need to be saved
        public List<String> metadataGroupNames; // Required

        // CONSTRUCTOR

        public MetadataGroupRemovalRequest(Id pipelineId, Id environmentId, List<String> metadataGroupNames) {
            this.pipelineId = pipelineId;
            this.environmentId = environmentId;
            this.metadataGroupNames = metadataGroupNames;
        }
    }

    /************ SELECTIONS ************/

    /************ INITIALIZE ************/

    // SKELETON Attribute
    // Parameter name starts with a capital letter for execution signature to look like static execution.
    public static Initialize Initialize {
        get {
            if (Initialize == null) {
                Initialize = new Initialize();
            }
            return Initialize;
        }
        set;
    }

    /*
        SENSITIVE CLASS
        - Changes in this class will potentially impact many usages and use cases.
        - Please get an architect approval before changing this class.
        - [TDD] If the change is approved please start by creating a Unit test for your change first.
        - When the change is done execute the PipelineInitializer Domain test suite not just your test.
        - If the new test is not included in the test suite, make sure to add it.
        - Pull request for changes happened in this class must contain an architect approval.
    */

    public inherited sharing class Initialize implements CopadoService {
        public ExecuteResult execute(Id pipelineId) {
            Savepoint sp = Database.setSavepoint();

            try {
                return PipelineInitializeBranchesImpl.execute(pipelineId);
            } catch (Exception ex) {
                Database.rollback(sp);
                throw new ApplicationException(ex.getMessage());
            }
        }

        public InitializeResult status(Id jobExecutionId) {
            // Note: Not setting savepoint as this service is only querying records, not writing to database
            try {
                return PipelineInitializeStatusImpl.execute(jobExecutionId);
            } catch (Exception ex) {
                throw new ApplicationException(ex.getMessage());
            }
        }
    }

    @JsonAccess(serializable='always' deserializable='always')
    public inherited sharing class ExecuteResult implements CopadoServiceResult {
        public copado__JobExecution__c jobExecution;
    }

    @JsonAccess(serializable='always' deserializable='always')
    public inherited sharing class InitializeResult implements CopadoServiceResult {
        public String jobStatus; // Job Execution Status
        public List<copado__JobStep__c> steps; // List with step statuses

        // CONSTRUCTOR

        public InitializeResult(String jobStatus, List<copado__JobStep__c> steps) {
            this.jobStatus = jobStatus;
            this.steps = steps;
        }
    }

    /************ INITIALIZE ************/
}