/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class TestProcessMedicalEventBudgetTransactio {

   
    static testMethod void myUnitTest() {
        // TO DO: implement unit test
        
       Set<Id>medEventIds = new Set<Id>();
       Set<Id>territoryBudgetIds = new Set<Id>();
       
        
        //Create 4 Budgets, one for each Medical Event, $1000 each
        List<Territory_Budget_vod__c> budgets = new List<Territory_Budget_vod__c>{};
        /*
        for (Integer i = 1; i < 5; i++) { 
            Territory_Budget_vod__c budget = new Territory_Budget_vod__c(
                        Name='Territory_'+ i, 
                        Active_vod__c = true, 
                        Start_Value_vod__c = 1000 + i,
                        Status_vod__c = 'Approved');        
           budgets.add(budget);
        }
        
        insert budgets;
        */
              
        
        
         /*
                  
           Test 1: Create 2 new Medical Events and assign new Expenses to them.
           
         */
                              
        Territory_Budget_vod__c budget1 = new Territory_Budget_vod__c(
                        Name='Territory_1', 
                        Active_vod__c = true, 
                        Start_Value_vod__c = 1000,
                        Status_vod__c = 'Approved');
                        
        insert budget1; 
        territoryBudgetIds.add(budget1.Id);
        
        //Med Event 1        
        Medical_Event_vod__c medicalEvent1 = new Medical_Event_vod__c(
            Name='RFM_Trigger_Test_1', 
            Status_MRK__c = 'In Progress',
            Territory_Budget_MRK__c = budget1.Id,
            Location_Type_MRK__c = 'Office',
            State_MRK__c = 'PA',
            Event_Type__c = 'Standard RFM',
            Start_Date_vod__c = Date.today(),
            End_Date_vod__c = Date.today()+1
        );
        
        insert medicalEvent1;
        medEventIds.add(medicalEvent1.Id);
               
        Event_Expense_MRK__c medicalEventExpense1 = new Event_Expense_MRK__c(
                        Amount_MRK__c = 100, 
                        Category_MRK__c = 'Equipment Rental',
                        Medical_Event_MRK__c = medicalEvent1.Id);
        
        insert medicalEventExpense1;
        
        //add an attendee:
        
        List<Account> accountsToInsert = new List<Account>();

        Account acct = new Account(
         RecordTypeId = [select Id from RecordType where developername = 'Professional_vod'].Id, 
         firstName = 'John',
         lastName = 'Jones');

        accountsToInsert.add(acct);
        insert(accountsToInsert);
        
        Event_Attendee_vod__c ea = new Event_Attendee_vod__c(
            Account_vod__c = acct.Id, //'001K000000H8GHQIA3',
            Status_vod__c = 'Invited',
            Medical_Event_vod__c = medicalEvent1.Id);
            
        insert ea;
        //SELECT Account_vod__c,Attendee_Name_vod__c,Attendee_Type_vod__c,Attendee_vod__c,Contact_vod__c,CreatedById,CreatedDate,Id,IsDeleted,IsLocked,LastModifiedById,LastModifiedDate,MayEdit,Meal_Declined_MRK__c,Medical_Event_vod__c,Mobile_ID_vod__c,Name,Signature_Datetime_vod__c,Signature_vod__c,Start_Date_vod__c,Status_vod__c,SystemModstamp,User_vod__c FROM Event_Attendee_vod__c
        
        //Med Event 2  
         Territory_Budget_vod__c budget2 = new Territory_Budget_vod__c(
                        Name='Territory_2', 
                        Active_vod__c = true, 
                        Start_Value_vod__c = 1000,
                        Status_vod__c = 'Approved');
                        
        insert budget2; 
        territoryBudgetIds.add(budget2.Id);
 
        Medical_Event_vod__c medicalEvent2 = new Medical_Event_vod__c(
            Name='RFM_Trigger_Test_2', 
            Status_MRK__c = 'In Progress',
            Territory_Budget_MRK__c = budget2.Id,
            Location_Type_MRK__c = 'Office',
            State_MRK__c = 'PA',
            Event_Type__c = 'Standard RFM',
            Start_Date_vod__c = Date.today(),
            End_Date_vod__c = Date.today()+1
);
        insert medicalEvent2;
        
        Event_Attendee_vod__c ea2 = new Event_Attendee_vod__c(
            Account_vod__c = acct.Id, //'001K000000H8GHQIA3',
            Status_vod__c = 'Invited',
            Medical_Event_vod__c = medicalEvent2.Id);
   
        insert  ea2; 
 
        
        medEventIds.add(medicalEvent2.Id);
        
        Event_Expense_MRK__c medicalEventExpense2 = new Event_Expense_MRK__c(
                        Amount_MRK__c = 100, 
                        Category_MRK__c = 'Equipment Rental',
                        Medical_Event_MRK__c = medicalEvent2.Id);
         insert  medicalEventExpense2;     
            

        //Change the Medical Events to "Submitted" Status.
        
         List<Medical_Event_vod__c> medicalEventUpdates = [SELECT  Id,
                                        Status_MRK__c
                                FROM    Medical_Event_vod__c
                                WHERE   Id IN : medEventIds
                              ];
                
        for (Medical_Event_vod__c medEvt : medicalEventUpdates){
               medEvt.Status_MRK__c = 'Submitted';
        }
        
        test.startTest();
        if (medicalEventUpdates.size() > 0){
           update medicalEventUpdates;
        }
        
        //Assert that the Budgets are at $900
        
         budgets = [SELECT Current_Value_vod__c 
                    FROM   Territory_Budget_vod__c
                    WHERE  Id IN :territoryBudgetIds];
        
        
        for (Territory_Budget_vod__c t : budgets){
            System.assertEquals(t.Current_Value_vod__c, 900.0);
        }
        
        //Now update the Medical Expenses with a new expense and test the new value.
        medicalEventUpdates = [SELECT  Id,
                                       Status_MRK__c
                                FROM   Medical_Event_vod__c
                                WHERE  Id IN : medEventIds
                              ];       
 
         for (Medical_Event_vod__c medEvt : medicalEventUpdates){
               medEvt.Status_MRK__c = 'In Progress';
         }
        
         update medicalEventUpdates;
         
         /*
                  
           TEST 2:  Now Add a $100 Expense to each of the Medical Events
           
         */
         
        Event_Expense_MRK__c medicalEventExpense3 = new Event_Expense_MRK__c(
                        Amount_MRK__c = 100, 
                        Category_MRK__c = 'Equipment Rental',
                        Medical_Event_MRK__c = medicalEvent1.Id);
                   
        
        medicalEventExpense3.Medical_Event_MRK__c = medicalEvent1.Id;
        
        insert medicalEventExpense3;


        Event_Expense_MRK__c medicalEventExpense4 = new Event_Expense_MRK__c(
                        Amount_MRK__c = 100, 
                        Category_MRK__c = 'Equipment Rental',
                        Medical_Event_MRK__c = medicalEvent2.Id);
                   
        
        medicalEventExpense4.Medical_Event_MRK__c = medicalEvent2.Id;
        
        insert medicalEventExpense4;

         medicalEventUpdates = [SELECT Id,
                                       Status_MRK__c
                                FROM   Medical_Event_vod__c
                                WHERE  Id IN : medEventIds
                              ];       
 
         for (Medical_Event_vod__c medEvt : medicalEventUpdates){
               medEvt.Status_MRK__c = 'Submitted';
         }
         
         update medicalEventUpdates;
         
         //Test that the Budgets now say $800
        
         budgets = [SELECT Current_Value_vod__c 
                    FROM   Territory_Budget_vod__c
                    WHERE  Id IN :territoryBudgetIds];
        
        for (Territory_Budget_vod__c t : budgets){
            System.assertEquals(t.Current_Value_vod__c, 800.0);
        }
        
       //Test Deletes of ME that have Attendees and Expenses attached.
       //Tests will cover deletion of the Expense, Attend and ME
       //This will cover all the Triggets associated to ME and Associated Object Deletions.
        
        
        //Test deleting a ME that has been submitted
        try
        {
           delete medicalEvent1;
          //throw new MyException('An exception should have been thrown by the trigger but was not.'); // 1. If we get to this line it means an error was not added and the test class should throw an exception here. 2. MyException class extends Exception.
         }
         catch(Exception e)
         {
            Boolean expectedExceptionThrown =  e.getMessage().contains('This RFM has Expenses tied to a Budget. Expenses must be deleted first before the RFM is Deleted.') ? true : false;
           System.AssertEquals(expectedExceptionThrown, true);
          } 
        
       //Test the deletion of an Expense Associated to a Submitted ME
        
          try
        {
           delete medicalEventExpense1;
         }
         catch(Exception e)
         {
            Boolean expectedExceptionThrown =  e.getMessage().contains('Cannot delete an Expense of a Submitted RFM.') ? true : false;
           System.AssertEquals(expectedExceptionThrown, true);
          } 
      
        
       //Test the deletion of an Attendee associated to a Submitted ME
        
          try
        {
           delete ea2;
         }
         catch(Exception e)
         {
            Boolean expectedExceptionThrown =  e.getMessage().contains('Cannot delete an Attendee of a Submitted RFM.') ? true : false;
           System.AssertEquals(expectedExceptionThrown, true);
          } 
 
        
        
         test.stopTest();
        
        

        
    }
        
        
        
  
    
}