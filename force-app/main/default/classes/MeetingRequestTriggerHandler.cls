/**
 * Component Name:      MeetingRequestTriggerHandler
 * Created By:          Focal CXM
 * Description:         Used for  Meeting Request Custom Object
 * Test Class:          MeetingRequestTriggerHandlerTest
 * @description MeetingRequestTriggerHandler
 */
public class MeetingRequestTriggerHandler { 
    List<Meeting_Request_vod__c> recordNewList = new List<Meeting_Request_vod__c>();
    List<Meeting_Request_vod__c> recordOldList = new List<Meeting_Request_vod__c>();
    Map<Id, Meeting_Request_vod__c> recordNewMap = new Map<Id, Meeting_Request_vod__c>();
    Map<Id, Meeting_Request_vod__c> recordOldMap = new Map<Id, Meeting_Request_vod__c>();    
    Boolean isInsert, isUpdate, isDelete, isUndelete = false;
    public static boolean recursionController = true;
    public static boolean flag = true;
    
     /**
     * @description MeetingRequestTriggerHandler
    */
    public MeetingRequestTriggerHandler(List<Meeting_Request_vod__c> newList, List<Meeting_Request_vod__c> oldList, Map<Id, Meeting_Request_vod__c> newMap, Map<Id, Meeting_Request_vod__c> oldMap, boolean isInsert, boolean isUpdate, Boolean isDelete, Boolean isUndelete) {
        this.recordNewList = newList;
        this.recordOldList = oldList;
        this.recordNewMap = newMap;
        this.recordOldMap = oldMap;
        this.isInsert = isInsert;
        this.isUpdate = isUpdate;
        this.isDelete = isDelete;
        this.isUndelete = isUndelete;
    }

    /**
     * @description beforeInsertEvent
     * @return void
    */
    public void beforeInsertEvent(){
        System.debug(LoggingLevel.WARN, 'test');
    }
    
     /**
     * @description BeforeUpdateEvent
     * @return void
    */
    public void BeforeUpdateEvent(){
       //date:03-jan-2023:bypassed startdate and duration validation for view upon requests
        List<Meeting_Request_vod__C> MRQList = [select id ,MSD_CORE_Status__c,MSD_CORE_Source__c,Duration_vod__c,Start_DateTime_vod__c,MSD_CORE_Resource__r.MSD_CORE_Delivery_Framework__c from Meeting_Request_vod__C where Id in :recordNewList];
        for (Meeting_Request_vod__C mrq: MRQList) {
            
            if (mrq.MSD_CORE_Source__c == 'MFR' || mrq.MSD_CORE_Source__c == 'MHEE') {
                if(mrq.MSD_CORE_Resource__r.MSD_CORE_Delivery_Framework__c != 'View Upon Request'){
                    if(recordNewMap.get(mrq.Id).MSD_CORE_Status__c == 'Approved' && (recordOldMap.get(mrq.id).MSD_CORE_Status__c == 'Pending' ||recordOldMap.get(mrq.id).MSD_CORE_Status__c == 'Closed')){    
                        if (mrq.Duration_vod__c == null || mrq.Start_DateTime_vod__c == null) {
                            recordNewMap.get(mrq.Id).addError('Please Fill the Duration and Start Datetime before Approving the Meeting Request');
                        }
                    } 
                }
            }
        }
        
    }
    
     /**
     * @description beforeDeleteEvent
     * @return void
    */
    public void beforeDeleteEvent(){
        System.debug(LoggingLevel.WARN, 'test');
    }
    
     /**
     * @description afterInsertEvent
     * @return void
    */
    public void afterInsertEvent(){
        System.debug(LoggingLevel.WARN, 'test');
    }
    
    /**
     * @description afterUpdateEvent
     * @return void
    */
    public void afterUpdateEvent(){
        createSharedNotification();
    }
    
     /**
     * @description afterDeleteEvent
     * @return void
    */
    public void afterDeleteEvent(){
        System.debug(LoggingLevel.WARN, 'test');
    }
    
      /**
     * @description afterUndeleteEvent
     * @return void
    */
    public void afterUndeleteEvent(){
        System.debug(LoggingLevel.WARN, 'test');
    }

       /**
     * @description Create Shared Notification Record
     * @return void
    */
    public void createSharedNotification() {
        set<Id> IdCataloglist = new set<Id>();
        
        for (Meeting_Request_vod__c mr : recordNewList) {
            IdCataloglist.add(mr.MSD_CORE_Resource__c);
        }
    
        //Get All the Saved Catalogs 
        Map<Id, MSD_CORE_Library__c>  maplib = new Map<Id,MSD_CORE_Library__c >([Select Id, MSD_CORE_Product_Payor__c, MSD_CORE_Payor__c from MSD_CORE_Library__c where MSD_CORE_Catalog__c IN:IdCataloglist]);
        Set<Id> productPayorId = new Set<Id>();
        for(MSD_CORE_Library__c objLib: maplib.values()){
            productPayorId.add(objLib.MSD_CORE_Payor__c);
        }
        
        List<MSD_CORE_Notification__c> notificaionnewlst = new List<MSD_CORE_Notification__c>();
        for (Meeting_Request_vod__c mr : recordNewList) {
            if(mr.MSD_CORE_Source__c == 'MFR'){
                if (mr.MSD_CORE_S3_Link_2__c != null && mr.MSD_CORE_Request_Progress__c == 'Received post-presentation materials' 
                    && recordOldMap.get(mr.Id).MSD_CORE_Request_Progress__c != mr.MSD_CORE_Request_Progress__c) {
                        
                        Meeting_Request_vod__c mrd = [SELECT Id, Name, Assignee_vod__c, MSD_CORE_Product_Payor__c, MSD_CORE_Payor__c, Assignee_vod__r.FirstName, Assignee_vod__r.LastName, MSD_CORE_Resource__c, MSD_CORE_Resource__r.Name, MSD_CORE_Resource__r.MSD_CORE_Resource_Title__c FROM Meeting_Request_vod__c WHERE Id =: mr.Id LIMIT 1];
                        MSD_CORE_Notification__c mcnoti = new MSD_CORE_Notification__c();
                        mcnoti.MSD_CORE_Activity_Label__c = 'Meeting_Request__c';
                        mcnoti.MSD_CORE_Activity__c = '<p style="color: #333333; font-size: 18px;font-family: Invention;line-height: 27px;">'+mrd.Assignee_vod__r.FirstName+'<style="color: #333333; font-size: 18px; "> '+mrd.Assignee_vod__r.LastName+'<style="color: #333333; font-size: 18px;line-height: 27px;"> has shared </strong><a href='+((productPayorId.contains(mr.MSD_CORE_Payor__c))?(System.Label.MerckPortalLibrary+mr.MSD_CORE_Product_Payor__c) :(System.Label.MerckProductDetail+mr.MSD_CORE_Product_Payor__c) )+'  target="_self" style="font-size: 18px; text-decoration: underline;color: rgb(0, 133, 124); font-family: Invention;"> <style="color: rgb(0, 133, 124); font-size: 18px;line-height: 27px; ">'+mrd.MSD_CORE_Resource__r.MSD_CORE_Resource_Title__c+'</a><style="color: #333333; font-size: 18px;line-height: 27px;"> with you.</p>';
                        mcnoti.MSD_CORE_Label__c = 'Saved';
                        mcnoti.MSD_CORE_Meeting_Request__c = mrd.Id;
                        mcnoti.MSD_CORE_Payor__c = mrd.MSD_CORE_Payor__c;
                        mcnoti.MSD_CORE_Product_Payor__c = mrd.MSD_CORE_Product_Payor__c;
                        mcnoti.MSD_CORE_Read__c = false;
                        mcnoti.MSD_CORE_Resource__c = mrd.MSD_CORE_Resource__c;
                        // insert mcnoti;
                        notificaionnewlst.add(mcnoti);
                        
                        List<MSD_CORE_Notification__c> msdnotilst = [SELECT Id, MSD_CORE_Meeting_Request__c, MSD_CORE_Notification__c FROM MSD_CORE_Notification__c WHERE MSD_CORE_Meeting_Request__c =: mrd.Id AND Id !=: mcnoti.Id];
                        for(MSD_CORE_Notification__c mcn : msdnotilst){
                            mcn.MSD_CORE_Notification__c = mcnoti.Id;
                            // update mcn;
                            notificaionnewlst.add(mcn);
                        }
                    }
            }
        }
        upsert notificaionnewlst;
    }
}