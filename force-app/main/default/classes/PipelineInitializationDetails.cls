public inherited sharing class PipelineInitializationDetails {
    public String initializationType;
    public String status;
    public String completedDate;
    public List<Id> pendingEnvironmentIds;
    public Id currentEnvironmentId;
    public List<ActivityLog> activityLog;
    public Id latestJobExecutionId;
    public Boolean areChangesSelected = false;
    public Long lastDiffAnalysis;
    public String diffAnalysisStatus;
    public List<Id> diffAnalysisJobs;
    public String message;

    public inherited sharing class ActivityLog {
        public Long timestamp;
        public String status;
        public String title;
    }
}