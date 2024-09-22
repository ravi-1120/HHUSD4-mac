trigger MRK_User_Sales_Team on User_Sales_Team_MRK__c (after delete, after insert, after update, before delete, before insert, before update) {
/* Copyright, 2016 MERCK & CO, INC., Kevin Brace ALL RIGHTS RESERVED */

    //KRB - 4.2016

   if(Trigger.isUpdate){
      for (User_Sales_Team_MRK__c rec : Trigger.new) {
         rec.addError('Records in this Object cannot be updated. Please Delete and Add New.');
      }
   }else{
      //US Instance 
      MSD_CORE_VE_Trigger_Factory.process(User_Sales_Team_MRK__c.sObjectType);
       
      //Global Instance
      //MSD_CORE_VE_Trigger_Factory.process(MSD_CORE_User_Sales_Team__c.sObjectType);
   }

}