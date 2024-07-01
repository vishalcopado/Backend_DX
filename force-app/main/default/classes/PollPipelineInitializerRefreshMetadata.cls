public inherited sharing class PollPipelineInitializerRefreshMetadata implements Schedulable {
    private Set<Id> parentIds;
    private Integer iteration;
    private Id pipelineId;
    private Datetime inputDate;

    // CONSTRUCTOR

    @SuppressWarnings('PMD.ExcessiveParameterList')
    public PollPipelineInitializerRefreshMetadata(Set<Id> credentialIds, Integer iteration, Id pipelineId, Datetime inputDate) {
        this.parentIds = credentialIds;
        this.iteration = iteration;
        this.pipelineId = pipelineId;
        this.inputDate = inputDate;
    }

    // PUBLIC

    public void execute(SchedulableContext sc) {
        try {
            List<copado__Copado_Notification__c> copadoNotifications = new CopadoNotificationSelector()
                .byParentIdsFinishedAndCreatedDate( parentIds, true, inputDate);

            if (!copadoNotifications.isEmpty() && copadoNotifications.size() == parentIds.size()) {
                runDifferenceAnalysis();
            } else {
                if (iteration > 120) {
                    return;
                }
                iteration++;
                scheduleJob(parentIds, iteration, pipelineId, inputDate);
            }
        } catch (Exception ex) {
            throw new ApplicationException(ex.getMessage() + '_' + ex.getStackTraceString());
        }
    }

    // PRIVATE

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private void scheduleJob(Set<Id> credentialIds, Integer iteration, Id pipelineId, Datetime inputDate) {
        String nextFireCron = calculateNextFireCron();
        System.schedule(
            'Poll for Refresh Metadata ' + nextFireCron,
            nextFireCron,
            new PollPipelineInitializerRefreshMetadata(credentialIds, iteration, pipelineId, inputDate)
        );
    }

    private String calculateNextFireCron() {
        CronCalculator result = new CronCalculator();
        return result.nextFireCron(5);
    }

    private void runDifferenceAnalysis() {
        if (pipelineId != null) {
            PipelineInitializer.PreSteps.runDifferenceAnalysis(pipelineId);
        }
    }
}