@isTest
private class SchedulerControllerTest{
 
    @isTest(SeeAllData=true)
    private static void getSchedulerLinkTest(){
        Database.SaveResult dsr;
        Scheduler_Configuration__c drScheduler_Configuration_c;
        drScheduler_Configuration_c=new Scheduler_Configuration__c();
        dsr=Database.insert(drScheduler_Configuration_c,false);
        Test.startTest();
        try{
        SchedulerController.getSchedulerLink(dsr.getId(),'source');
        }catch(Exception e){}
        try{
        SchedulerController.getSchedulerLink(dsr.getId(),'iframe');
        }catch(Exception e){}
        Test.stopTest();
    }
    @isTest
    private static void SchedulerControllerTest(){
        SchedulerController obj = new SchedulerController();
    }
}