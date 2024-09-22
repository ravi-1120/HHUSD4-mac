/**
 * @description MSD_CORE_NotificationTriggerHandler
 */
public class MSD_CORE_NotificationTriggerHandler { 

    List<MSD_CORE_Notification__c> recordNewList = new List<MSD_CORE_Notification__c>();//recordNewList
    List<MSD_CORE_Notification__c> recordOldList = new List<MSD_CORE_Notification__c>();//recordOldList
    Map<Id, MSD_CORE_Notification__c> recordNewMap = new Map<Id, MSD_CORE_Notification__c>();//recordNewMap
    Map<Id, MSD_CORE_Notification__c> recordOldMap = new Map<Id, MSD_CORE_Notification__c>();//recordOldMap
    Boolean isInsert = false;//isInsert
    Boolean isUpdate = false;//isUpdate
    Boolean isDelete = false;//isDelete
    Boolean isUndelete = false;//isUndelete
    public static boolean recursionController = true;//recursionController
    public static boolean flag = true;//flag
    
    public MSD_CORE_NotificationTriggerHandler(List<MSD_CORE_Notification__c> newList, List<MSD_CORE_Notification__c> oldList, Map<Id, MSD_CORE_Notification__c> newMap, Map<Id, MSD_CORE_Notification__c> oldMap, boolean isInsert, boolean isUpdate, Boolean isDelete, Boolean isUndelete) {
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
     */
    public void beforeInsertEvent(){
        System.debug(LoggingLevel.WARN,'beforeInsertEvent');
    } 
     /**
     * @description beforeUpdateEvent
     */
    public void beforeUpdateEvent(){
        System.debug(LoggingLevel.WARN,'beforeUpdateEvent');
    }
    
    /**
     * @description beforeDeleteEvent
     */
    public void beforeDeleteEvent(){
         System.debug(LoggingLevel.WARN,'beforeDeleteEvent');
    }
    
    /**
     * @description afterInsertEvent
     */
    public void afterInsertEvent(){
        System.debug(LoggingLevel.WARN,'afterInsertEvent');
    }
    
    /**
     * @description afterUpdateEvent
     */
    public void afterUpdateEvent(){
        System.debug(LoggingLevel.WARN,'afterUpdateEvent');
    }
    
    /**
     * @description afterDeleteEvent
     */
    public void afterDeleteEvent(){
        System.debug(LoggingLevel.WARN,'afterDeleteEvent');
    }
    
    /**
     * @description afterUndeleteEvent
     */
    public void afterUndeleteEvent(){
        System.debug(LoggingLevel.WARN,'afterUndeleteEvent');
    }
}