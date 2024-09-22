public class MSD_CORE_ae_RelatedRecords implements Queueable {
    private List<SObject> relatedRecords;
    
    public MSD_CORE_ae_RelatedRecords(List<SObject> relatedRecords) {
        this.relatedRecords = relatedRecords;
    }
    
    public void execute(QueueableContext context) {
        if (!relatedRecords.isEmpty()) {
            try {
                insert relatedRecords;
            } catch (Exception ex) {
                System.debug('Error inserting related records asynchronously: ' + ex.getMessage());
                AMOExceptionHandler.logException(ex, 'MSD_CORE_ae_RelatedRecords', 'execute', null, 'Error');
                MSD_CORE_ae_CaseController.sendErrorEmail(ex.getTypeName() + ' - ' + ex.getMessage());
            }
        }
    }
}