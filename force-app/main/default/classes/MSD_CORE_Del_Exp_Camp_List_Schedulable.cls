global class MSD_CORE_Del_Exp_Camp_List_Schedulable implements Schedulable {

    global void execute(SchedulableContext sc) {
        Id eventBatchProcessID = Database.executeBatch(new MSD_CORE_Delete_Expired_Campaign_List(),2000);
        //System.debug('callBatchProcessID = ' + callBatchProcessID + ', eventBatchProcessID = ' + eventBatchProcessID);
    }

}