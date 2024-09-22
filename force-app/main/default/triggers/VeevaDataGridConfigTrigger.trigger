trigger VeevaDataGridConfigTrigger on Data_Grid_Loader_Configuration_vod__c (before insert, before update) { 
    VeevaTriggerHandler handler = new VeevaDataGridConfigTriggerHandler();
    handler.handleTrigger();
}