public class VeevaExternalCalendarUTDeleteBatch implements Database.Batchable<Id> {

    private List<Id> unavailableTimes;

    public VeevaExternalCalendarUTDeleteBatch(List<Id> unavailableTimes) {
        this.unavailableTimes = unavailableTimes;
    }

    public Iterable<Id> start(Database.BatchableContext bc) {
        return unavailableTimes;
    }
    
    public void execute(Database.BatchableContext bc, List<Id> records) {
        List<Database.DeleteResult> results = Database.delete(records, false); // all or nothing set to false

        for (Database.DeleteResult result : results) {
            if (!result.isSuccess()) {
                for (Database.Error error : result.getErrors()) {
                    System.debug(LoggingLevel.ERROR, 'Error deleting record ' + result.getId() + ': ' + error.getMessage());
                }
            }
        }
    }
    
    public void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    }
}