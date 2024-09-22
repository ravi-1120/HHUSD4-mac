@isTest
private class Test_MRKSampleSendBeforeUpdate {
   Static testMethod void myUnitTest(){
      test.startTest();
   
      /* Data set up for first test. Set the Ship Address Status to 
         addr.Address_Send_Status_MRK__c == 'Unknown'
         Need to verify that it gets switched to 'Pending'
      */
       
       //Add a new Account:
       
       
      List<Account> accountsToInsert = new List<Account>();

      Account acct = new Account(
         RecordTypeId = [select Id from RecordType where developername = 'Professional_vod'].Id, //'012U0000000Iqc2IAC',
         firstName = 'John',
         lastName = 'Jones');

     accountsToInsert.add(acct);
     insert(accountsToInsert);

       //insert a new Address for the new Account.
       
       List<Address_vod__c> AddrTestDataToInsert = new List<Address_vod__c>();
       //String AccountId = [Select Id from Account where LastName = 'Alexander' and FirstName = 'Keith'].Id;
       
       Address_vod__c anAddr = new Address_vod__c(
          Name = 'Addr1Test', 
          RecordTypeId = [Select Id from RecordType where DeveloperName = 'RepMaintained' and SobjectType = 'Address_Vod__c'].Id,
          Account_vod__c = acct.Id, //[Select Id from Account where LastName = 'Alexander' and FirstName = 'Keith'],
          Address_line_2_vod__c = 'Addr2Test', 
          Phone_vod__c = '1231231234',
          City_vod__c = 'CityTest', 
          License_vod__c = '123456',
          License_Expiration_Date_vod__c= Date.today()+5, 
          License_Status_vod__c = 'Valid_vod', 
          Zip_4_vod__c = '1234',
          Zip_vod__c = '12345', 
          Source_vod__c ='Manual', 
          State_vod__c = 'PA',
          Address_Send_Status_MRK__c = 'Unknown');
       
       
       AddrTestDataToInsert.add(anAddr);
       insert(AddrTestDataToInsert);
       
       //Now, make an update to the Address to force it into the Trigger...
       List<Address_vod__c> AddrTestDataToUpdate = new List<Address_vod__c>();
       AddrTestDataToUpdate = [Select Phone_vod__c, Id from Address_vod__c where Id =: anAddr.Id];
       AddrTestDataToUpdate[0].Phone_vod__c = '9999999999';
       update(AddrTestDataToUpdate);
       
       //First, confirm the update to the phone took, then that Sample_Send_Status_vod__c = 'Valid_vod'
       String AddressPhone = [Select Phone_vod__c from Address_vod__c where Id =: anAddr.Id].Phone_vod__c;
       System.AssertEquals(AddressPhone, '9999999999');
       String AddressSampleSendStatus = [Select Sample_Send_Status_vod__c from Address_vod__c where Id =: anAddr.Id].Sample_Send_Status_vod__c;
       System.AssertEquals(AddressSampleSendStatus, 'Valid_vod');
       
       //Null out the Phone Number and retest for an INVLAID status.
       List<Address_vod__c> AddrTestDataToUpdate2 = new List<Address_vod__c>();
       AddrTestDataToUpdate2 = [Select Phone_vod__c, Id from Address_vod__c where Id =: anAddr.Id];
       AddrTestDataToUpdate2[0].Phone_vod__c = NULL;
       update(AddrTestDataToUpdate2);
       String AddressSampleSendStatus2 = [Select Sample_Send_Status_vod__c from Address_vod__c where Id =: anAddr.Id].Sample_Send_Status_vod__c;
       System.AssertEquals(AddressSampleSendStatus2, 'Invalid_vod');
 
       
       //Update the Address Send status to Pending and enter a new phone number and retest
       List<Address_vod__c> AddrTestDataToUpdate3 = new List<Address_vod__c>();
       AddrTestDataToUpdate3 = [Select Address_Send_Status_MRK__c, Phone_vod__c, Id from Address_vod__c where Id =: anAddr.Id];
       AddrTestDataToUpdate3[0].Address_Send_Status_MRK__c = 'Pending';
       AddrTestDataToUpdate3[0].Phone_vod__c = '5555555555';
       update(AddrTestDataToUpdate3);
       String AddressSampleSendStatus3 = [Select Sample_Send_Status_vod__c from Address_vod__c where Id =: anAddr.Id].Sample_Send_Status_vod__c;
       System.AssertEquals(AddressSampleSendStatus3, 'Invalid_vod');

       //Test entering the Bypass Logic:
       SamplesHelper.setAvoidUnknownAddressStatusUpdate(true);
       List<Address_vod__c> AddrTestDataToUpdate4 = new List<Address_vod__c>();
       AddrTestDataToUpdate4 = [Select Address_Send_Status_MRK__c, Phone_vod__c, Id from Address_vod__c where Id =: anAddr.Id];
       AddrTestDataToUpdate4[0].Address_Send_Status_MRK__c = 'Unknown';
       AddrTestDataToUpdate4[0].Phone_vod__c = '3333333333';
       update(AddrTestDataToUpdate4);
       String AddressSampleSendStatus4 = [Select Sample_Send_Status_vod__c from Address_vod__c where Id =: anAddr.Id].Sample_Send_Status_vod__c;
       System.AssertEquals(AddressSampleSendStatus4, 'Valid_vod');
    
       //Test entering the Bypass Logic:
       SamplesHelper.setAvoidUnknownAddressStatusUpdate(true);
       List<Address_vod__c> AddrTestDataToUpdate5 = new List<Address_vod__c>();
       AddrTestDataToUpdate5 = [Select City_vod__c, Id from Address_vod__c where Id =: anAddr.Id];
       AddrTestDataToUpdate5[0].City_vod__c = 'someCity';
       update(AddrTestDataToUpdate5);
       String AddressSampleSendStatus5 = [Select Sample_Send_Status_vod__c from Address_vod__c where Id =: anAddr.Id].Sample_Send_Status_vod__c;
       System.AssertEquals(AddressSampleSendStatus5, 'Valid_vod');
     
       
       test.stopTest();   
        
   }
    
}