@isTest
private class Test_Sample_Transfer_Lot_Expire {

    static testMethod void myUnitTest() {
              
       test.startTest();

       List<Sample_Transaction_vod__c> transfers = new List<Sample_Transaction_vod__c>{};
       
    
       Sample_Transaction_vod__c st = new Sample_Transaction_vod__c(
          Approving_Manager_MRK__c = '005Z0000000Meo1IAC',
      	  Lot_vod__c = 'a0aZ000000047QEIAY',
          Quantity_vod__c = 14.0,
          Reason_vod__c = 'Change in Product Responsibility',
          Sample_vod__c = 'Cholecap 10 mg',
          Transferred_From_vod__c =  '005Z0000000MKjpIAG',
          Transfer_To_vod__c = '005Z0000000MKlHIAW',
          Type_vod__c = 'Transfer_vod',
          Comments_vod__c ='TestClassExecution'
          
       );
       
       transfers.add(st);
       
       insert transfers;   
       
        List<Sample_Transaction_vod__c> newTransfers = new List<Sample_Transaction_vod__c>{};
      
        newTransfers = [SELECT Quantity_vod__c FROM Sample_Transaction_vod__c WHERE Comments_vod__c = 'TestClassExecution'];
        
        for (Sample_Transaction_vod__c t : newTransfers){
        	System.assertEquals(t.Quantity_vod__c, 14.0);
        }
 
       
       test.stopTest();
       

    }
}