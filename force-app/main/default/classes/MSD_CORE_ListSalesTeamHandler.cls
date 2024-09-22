/**
* @author - Brian Pfeil, Merck & Co.,Inc.
* @className - MSD_CORE_ListSalesTeamHandler.cls
* @description - processing logic for the List Sales Team object
* @createdate - Apr 14th, 2015
*
*/


public class MSD_CORE_ListSalesTeamHandler implements MSD_CORE_ITrigger {

	public MSD_CORE_ListSalesTeamHandler() {}
	public void bulkBefore() {}
	public void bulkAfter() {
	    if (Trigger.isDelete) {
	        // delete tracking
            MSD_CORE_RecordsOperationServices.postDeletedRecordsForTracking(Trigger.old);
        }
	}
	public void beforeInsert(SObject so) {}
	public void beforeUpdate(SObject oldSo, SObject so) {}
	public void beforeDelete(SObject so) {}
	public void afterInsert(SObject so) {}
	public void afterUpdate(SObject oldSo, SObject so) {}
	public void afterDelete(SObject so) {}
	public void andFinally() {}

}