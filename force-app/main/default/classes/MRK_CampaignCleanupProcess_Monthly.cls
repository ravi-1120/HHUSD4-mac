global class MRK_CampaignCleanupProcess_Monthly implements Schedulable {
   global void execute(SchedulableContext sc) {
      list<MSD_CORE_List__c>  lists = [SELECT Id,MSD_CORE_Name__c,MSD_CORE_Request_Type__c,MSD_CORE_Status__c FROM MSD_CORE_List__c WHERE MSD_CORE_Status__c IN ('inactive','expired') and MSD_CORE_Request_Type__c = 'Prod Metric Campaign' and createdDate = LAST_N_YEARS:2]; 
	  list<String>  listnames = new list<String>();
	  list<String>  viewnames = new list<String>();
	  list<String>  listids = new list<String>();
      list<String>  productIds = new list<String>();
      
      for(MSD_CORE_List__c lst: lists)
      {
         listnames.add(String.valueOf(lst.MSD_CORE_Name__c));   
         viewnames.add(String.valueOf('~ '+lst.MSD_CORE_Name__c));   
         listids.add(String.valueOf(lst.Id));
         lst.MSD_CORE_Status__c = 'inactive';
         // system.debug(lst.MSD_CORE_Name__c);
      }
      update lists;
      list<Product_vod__c>  products = [SELECT Id,Name FROM Product_vod__c WHERE External_Product_Type_MRK__c = 'Campaign' and Product_Type_vod__c = 'Detail' and Name IN :listnames];
      for(Product_vod__c product: products)
	  {
         productIds.add(String.valueOf(product.Id));   
      }
      MRK_CampaignCleanupProcess cleanup = new MRK_CampaignCleanupProcess('LISTITEMS',listnames,viewnames,listids,productids); 
      Database.executeBatch(cleanup, 200);
   }
}