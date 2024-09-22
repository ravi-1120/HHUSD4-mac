@isTest
private class Test_MRKUpdateAddressAfterSubmit {

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

       
       
       //insert a new Address for Keith A.
       
       List<Address_vod__c> AddrTestDataToInsert = new List<Address_vod__c>();

       Address_vod__c anAddr = new Address_vod__c(
          Name = 'TestCaseName', 
          RecordTypeId = [Select Id from RecordType where DeveloperName = 'RepMaintained' and SobjectType = 'Address_Vod__c'].Id,
          Account_vod__c = acct.Id,
          Address_line_2_vod__c = 'TestCaseAddr1', 
          City_vod__c = 'TestCase1City', 
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
              
       
       //create the Call and submit
       
       List<Call2_vod__c> callsToInsert = new List<Call2_vod__c>();

       Call2_vod__c aCall = new Call2_vod__c(
          RecordTypeId = [select Id from RecordType where developername = 'CallReport_vod' and SobjectType = 'Call2_vod__c'].Id, //'012U0000000Iqc2IAC',
          Account_vod__c = acct.Id,
          Status_vod__c ='Saved_vod',
          Parent_Address_vod__c  = anAddr.Id,   
          Call_Datetime_vod__c = datetime.now(),
          Disclaimer_vod__c  = 'I, a licensed practitioner, requested...',
          Signature_Date_vod__c = datetime.now(),
          Signature_vod__c = 'iVBORw0KGgoAAAANSUhEUgAAApAAAACNCAYAAAAAYko8AABAAElEQVR4AeydBZgcRdqA/5BgAYK7Q3AIBPcEC+7uEDTAAcE5XIIEgrsFCM7hrglyuLsTIPjhdsjB/75703uzsz0z3TM9szO7Vc/zprqrvvqq6uvu6q+qazbd/vrrr/8LIVggWCBYIFggWCBYIFggWCBYIKkFxkoqGOSCBYIFggWCBYIFggWCB',
          Territory_vod__c  = '1S1A',
          Call_Type_vod__c = 'Sample Only',
          Address_vod__c  = '100 Elm Street, Merriam, PA 72056',
          Attendees_vod__c = 0.0,
          Attendee_Type_vod__c  = 'Person_Account_vod',
          Call_Date_vod__c  = Date.today(),
          License_vod__c = '3442356',
          Last_Device_vod__c  = 'Online_vod',
          Ship_Address_Line_1_vod__c  = '100 Elm Street',
          Ship_City_vod__c = 'Merriam',
          Ship_License_Expiration_Date_vod__c  = Date.today(),
          Ship_License_Status_vod__c  = 'Valid_vod',
          Ship_License_vod__c = '3442356',
          Ship_State_vod__c  = 'PA',
          Ship_To_Address_vod__c  = anAddr.Id, 
          Ship_Zip_vod__c  = '72056',
          Address_Line_1_vod__c  = 'TestCase',
          City_vod__c = 'Merriam',
          State_vod__c = 'PA',
          Zip_vod__c = '72056',
          Signature_Timestamp_vod__c  = 783021.0,
          Location_Services_Status_vod__c  = 'Enabled_vod',
          Signature_Location_Latitude_vod__c = 40.22485,
          Signature_Location_Longitude_vod__c = -75.2837);

       callsToInsert.add(aCall);
       insert(callsToInsert);
       
       //Now, need to force an update inorder for us to hit the MRK_Update_Address_After_Submit Trigger
       List<Call2_vod__c> callsToUpdate = new List<Call2_vod__c>();
       callsToUpdate = [Select Id, Status_vod__c FROM Call2_vod__c where Id =: aCall.Id];
       callsToUpdate[0].Status_vod__c ='Submitted_vod';
       update(callsToUpdate);
       
       
       //Test Case 1. to see if an Address_Send_Status_MRK__c of Unknown flips to a Pending.
       String AddressSendStatus = [Select Address_Send_Status_MRK__c from Address_vod__c where Id =: anAddr.Id].Address_Send_Status_MRK__c;
       System.Debug('foobar: ' + AddressSendStatus);
       System.AssertEquals(AddressSendStatus, 'Pending');
       
            //insert a new Address for Keith A.
       
       List<Address_vod__c> AddrTestData2ToInsert = new List<Address_vod__c>();

       Address_vod__c anAddrForTest2 = new Address_vod__c(
          Name = 'TestCaseName', 
          RecordTypeId = [Select Id from RecordType where DeveloperName = 'RepMaintained' and SobjectType = 'Address_Vod__c'].Id,
          Account_vod__c = acct.Id,
          Address_line_2_vod__c = 'TestCaseAddr2', 
          City_vod__c = 'TestCase2City', 
          License_vod__c = '123456',
          License_Expiration_Date_vod__c= Date.today()+5, 
          License_Status_vod__c = 'Valid_vod', 
          Zip_4_vod__c = '1234',
          Zip_vod__c = '12345', 
          Source_vod__c ='Manual', 
          State_vod__c = 'PA',
          Address_Send_Status_MRK__c = 'Pending');

       AddrTestData2ToInsert.add(anAddrForTest2);
       insert(AddrTestData2ToInsert);
  
       
       
       
       //create the Call as Saved_vod and then update to submitted_vod to force it into the Trigger...
       
       List<Call2_vod__c> callsToInsertTest2 = new List<Call2_vod__c>();

       Call2_vod__c aCallforTest2 = new Call2_vod__c(
          RecordTypeId = [select Id from RecordType where developername = 'CallReport_vod' and SobjectType = 'Call2_vod__c'].Id, //'012U0000000Iqc2IAC',
          Account_vod__c = acct.Id,
          Status_vod__c ='Saved_vod',
          Parent_Address_vod__c  = anAddrForTest2.Id,   
          Call_Datetime_vod__c = datetime.now(),
          Disclaimer_vod__c  = 'I, a licensed practitioner, requested...',
          Signature_Date_vod__c = datetime.now(),
          Signature_vod__c = 'iVBORw0KGgoAAAANSUhEUgAAApAAAACNCAYAAAAAYko8AABAAElEQVR4AeydBZgcRdqA/5BgAYK7Q3AIBPcEC+7uEDTAAcE5XIIEgrsFCM7hrglyuLsTIPjhdsjB/75703uzsz0z3TM9szO7Vc/zprqrvvqq6uvu6q+qazbd/vrrr/8LIVggWCBYIFggWCBYIFggWCBYIKkFxkoqGOSCBYIFggWCBYIFggWCB',
          Territory_vod__c  = '1S1A',
          Call_Type_vod__c = 'Sample Only',
          Address_vod__c  = '100 Elm Street, Merriam, PA 72056',
          Attendees_vod__c = 0.0,
          Attendee_Type_vod__c  = 'Person_Account_vod',
          Call_Date_vod__c  = Date.today(),
          License_vod__c = '3442356',
          Last_Device_vod__c  = 'Online_vod',
          Ship_Address_Line_1_vod__c  = '100 Elm Street',
          Ship_City_vod__c = 'TestCase2Update',
          Ship_License_Expiration_Date_vod__c  = Date.today(),
          Ship_License_Status_vod__c  = 'Valid_vod',
          Ship_License_vod__c = '3442356',
          Ship_State_vod__c  = 'PA',
          Ship_To_Address_vod__c  = anAddrForTest2.Id, 
          Ship_Zip_vod__c  = '72056',
          Address_Line_1_vod__c  = 'TestCase',
          City_vod__c = 'Merriam',
          State_vod__c = 'PA',
          Zip_vod__c = '72056',
          Signature_Timestamp_vod__c  = 783021.0,
          Location_Services_Status_vod__c  = 'Enabled_vod',
          Signature_Location_Latitude_vod__c = 40.22485,
          Signature_Location_Longitude_vod__c = -75.2837);

       callsToInsertTest2.add(aCallforTest2);
       insert(callsToInsertTest2);
       
       //Now, need to force an update inorder for us to hit the MRK_Update_Address_After_Submit Trigger
       List<Call2_vod__c> callsToUpdateforTestCase2 = new List<Call2_vod__c>();
       callsToUpdateforTestCase2 = [Select Id, Status_vod__c FROM Call2_vod__c where Id =: aCallforTest2.Id];
       callsToUpdateforTestCase2[0].Status_vod__c ='Submitted_vod';
       update(callsToUpdateforTestCase2);
       
       //validate that after the change was submitted to the Addresses City that the Addr Status is now Unknown
       String AddressSendStatusTestCase3 = [Select Address_Send_Status_MRK__c from Address_vod__c where Id =: anAddrForTest2.Id].Address_Send_Status_MRK__c;
       System.Debug('foobar3: ' + AddressSendStatusTestCase3);
       System.AssertEquals(AddressSendStatusTestCase3, 'Pending');
 
       //Verify that the Address City was updated.
       String AddressCityTestCase3 = [Select City_vod__c from Address_vod__c where Id =: anAddrForTest2.Id].City_vod__c;
       System.Debug('foobar4: ' + AddressCityTestCase3);
       //System.AssertEquals(AddressCityTestCase3, 'TestCase2Update');
        
       
       test.stopTest();   
        
   }
    
}