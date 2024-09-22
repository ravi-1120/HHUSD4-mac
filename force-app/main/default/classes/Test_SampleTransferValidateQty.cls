@isTest
private class Test_SampleTransferValidateQty {

   Static testMethod void myUnitTest(){
      test.startTest();
       
      Profile p = [select id from profile where name='MRK - Sales Representative'];
 
      User testUserSampler1 = new User(alias = 'u1', email='dbrace0894@gmail.com',
      emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
      localesidkey='en_US', profileid = p.Id, country='United States',
      timezonesidkey='America/Los_Angeles', username='dbrace0894@gmail.com',
      Sampling_Rep_MRK__c = true);
 
      insert testUserSampler1;
       
      User testUserSampler2 = new User(alias = 'u1', email='dbrace0894a@gmail.com',
      emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
      localesidkey='en_US', profileid = p.Id, country='United States',
      timezonesidkey='America/Los_Angeles', username='dbrace0894a@gmail.com',
      Sampling_Rep_MRK__c = true);
 
      insert testUserSampler2;
       
      Profile pMgr = [select id from profile where name='MRK - Sales Manager'];
       
      User testManagerSampler3 = new User(alias = 'u1', email='dbrace0894b@gmail.com',
      emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
      localesidkey='en_US', profileid = pMgr.id, country='United States',
      timezonesidkey='America/Los_Angeles', username='dbrace0894b@gmail.com');
 
      insert testManagerSampler3;
       
      //set up Product:
      Product_vod__c testProduct = new Product_vod__c(
           Name = 'TestSampleProduct',
           Product_Type_vod__c = 'Sample',
           Sample_U_M_vod__c = 'Box',
           Quantity_Per_Case_vod__c = 10.0);
      
       insert testProduct;
       
       //Insert the Sample Lot:
       Sample_Lot_vod__c testLot = new Sample_Lot_vod__c(
           Sample_vod__c = 'TestSampleProduct',
           Active_vod__c = true,
           U_M_vod__c = 'Units',
           Expiration_Date_vod__c = Date.today()+5);
       
       insert testLot;
      //Now, insert the Sample Transaction Record. 
 
      Sample_Transaction_vod__c testSampleTransaction = new Sample_Transaction_vod__c(
         RecordTypeId = [Select Id  from RecordType where DeveloperName = 'Transfer_vod' and SobjectType = 'Sample_Transaction_vod__c'].Id,
         Lot_vod__c = testLot.id,
         Transferred_From_vod__c = testUserSampler1.id,
         Transferred_Date_vod__c = Date.today(),
         Transfer_To_vod__c = testUserSampler2.id,
         Status_vod__c = 'Submitted_vod',
         U_M_vod__c = 'Units',
         Sample_vod__c = 'TestSampleProduct',
         Quantity_vod__c = 20.0,
         Type_vod__c = 'Transfer_vod',
         Reason_vod__c = 'Region Reapportionment'      
      );
      
      insert testSampleTransaction;
       
      //now try a quantity that is not in the right multiples for the product
       
      Sample_Transaction_vod__c testSampleTransactionError = new Sample_Transaction_vod__c(
         RecordTypeId = [Select Id  from RecordType where DeveloperName = 'Transfer_vod' and SobjectType = 'Sample_Transaction_vod__c'].Id,
         Lot_vod__c = testLot.id,
         Transferred_From_vod__c = testUserSampler1.id,
         Transferred_Date_vod__c = Date.today(),
         Transfer_To_vod__c = testUserSampler2.id,
         Status_vod__c = 'Submitted_vod',
         U_M_vod__c = 'Units',
         Sample_vod__c = 'TestSampleProduct',
         Quantity_vod__c = 3.0,
         Type_vod__c = 'Transfer_vod',
         Reason_vod__c = 'Region Reapportionment'      
      );
 
       try{
           insert testSampleTransactionError;
       }catch(Exception e){
           Boolean expectedExceptionThrown = e.getMessage().contains('Invalid Amount Entered for Quantity Transfered Boxes. Amount is not in multiples of the defined Box Quantity Per Case.');
           System.AssertEquals(expectedExceptionThrown, true);
           
       }
       
       
      Test.stopTest();
       
   }
}