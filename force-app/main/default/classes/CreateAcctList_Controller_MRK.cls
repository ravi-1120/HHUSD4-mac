public class CreateAcctList_Controller_MRK{

//10/17/2012 bid This code is invoked by a button on the campaign screen.  It creates an Account List
//               for the current user that contains each of the target accounts that the user has
//               in one of their territories.
/*
    History:
    
    2-1-2013    Jeff Kelso  Removed query to ATL and now selecting Campaigns based on Account Share (My Accounts)

    2-15-2013   Kevin Brace Class was changed from a Webservice to standard class. Class is now called from a VF
                            Page instead of a Webservice.

    8-9-2013    Kevin Brace Logic that limits accounts from the user's territory and one level below was removed. 
                            New Logic will report on accounts from the user's territory plus 79 territory nodes below the User's
                            Territory. If the number of nodes exceeds 80, the process aborts. Limit is in place so that we
                            do not hit the Salesforce "Too Many SOQL Statements" Limit. (max 200 issued per session)

*/    


   private final Campaign_vod__c campaign;
   private final String currentUserId {get; set;}
   public String campaignId {get; set;}
   public ApexPages.standardController controller {get; set;}
   public String confirmationPageMessage {get; set;}
   public Integer territoryCounter {get; set;}
   List<Id> masterList = new List<Id>();
   public final Integer maxTerritoryNodes = 81; 
   
    public CreateAcctList_Controller_MRK(ApexPages.StandardController stdController){
       controller = stdController;
       campaign = (Campaign_vod__c) stdController.getRecord();
       campaignId = campaign.Id;
       currentUserId = UserInfo.getUserId();
       system.debug('Debug_CreateAcctList_Controller_MRK: current user: ' + currentUserId );
    }
    
    public PageReference autoRun(){
   
    try{  
       if (campaignId == null) {
         // Go back to the originating Campaign Page….
         return null;
       }
 
      //Get the campaign short description, we'll use it for the list name along with the current month/day
       string campaignShortDesc;
       Campaign_vod__c CMP = [Select c.Campaign_Short_Description_MRK__c from Campaign_vod__c c where c.Id = :campaignId limit 1];
       date myDate = date.today();
       Datetime dt = datetime.newInstance(myDate.year(), myDate.month(),myDate.day());
       string myStrDate=dt.format('MMdd');  
        
       campaignShortDesc = CMP.Campaign_Short_Description_MRK__c + '_' + myStrDate;
   
      //Setup the external id as a concatenation of the campaign and owner ids then Upsert the account list record.
       string externalId = campaignId + '_' + currentUserId;
       Account_List_vod__c acList = new Account_List_vod__c 
       (Name = campaignShortDesc,
        Access_vod__c = 'Private_vod',
        Icon_Name_vod__c = '22',
        External_Id_MRK__c = externalId);
 
       Upsert acList External_Id_MRK__c;
        
       //Get the Account List id so that we can delete existing account list items
       Account_List_vod__c acList2 = [Select al.Id FROM Account_List_vod__c al 
                    WHERE (al.External_Id_MRK__c  = :externalId) limit 1];   
       string acListId = acList2.Id;
        
       Account_List_Item_vod__c [] aclToDelete = [Select acl.id from Account_List_Item_vod__c acl
                                               where Account_List_vod__c = :acListId];
       Delete aclToDelete;      
        
       //Initiate a new list to hold all the account list items we want to add
       List<Account_List_Item_vod__c> aliToAdd = new List<Account_List_Item_vod__c>();
        
       //JK - Get User's Territory
       System.debug('Debug_CreateAcctList_Controller_MRK:: Entering routine to loop over Users Territory and recursively walk the tree: ');

        //KRB 2/12/2020 - Out for TM2.0
        //for (UserTerritory ut : [SELECT TerritoryId from UserTerritory where UserId = :currentUserId]) {
        //KRB 2/12/2020 - Out for TM2.0
        for (UserTerritory2Association ut : [select Territory2Id 
                                             from UserTerritory2Association 
                                             where UserId = :currentUserId 
                                             AND IsActive = true  
                                             AND Territory2.Territory2Model.state ='Active']) {

        
          masterList.add(ut.Territory2Id);
          System.debug('Debug_CreateAcctList_Controller_MRK: masterList.size(): ' + masterList.size());
 
          //If we went over the 80 Territory Limit, throw an exeption. User will not see the List. 
          if (masterList.size() >= maxTerritoryNodes){
            System.debug('Debug_CreateAcctList_Controller_MRK:: masterList.size() of '+ masterList.size() +' exceeds the limit. throwning an exception...');
            System.debug('Debug_CreateAcctList_Controller_MRK:: Exiting getChildTerritoriesFor routine');

            throw new CreateAcctList_ControllerException('The Number of Territories to Process exceeds the Limit. List cannot be Processed.');
          } 
 
          System.debug('Debug_CreateAcctList_Controller_MRK:: Users Territory: ' + ut.Territory2Id );
          getChildTerritoriesFor(ut.Territory2Id);
       }
        
       System.debug('Debug_CreateAcctList_Controller_MRK:: Completed looping over Users Territory and recursively walking the tree: ');
               
       //If we went over the 80 Territory Limit, throw an exeption. User will not see the List. 
       if (masterList.size() >= maxTerritoryNodes){
          System.debug('Debug_CreateAcctList_Controller_MRK:: masterList.size() of '+ masterList.size() +' exceeds the limit. throwning an exception...');
          System.debug('Debug_CreateAcctList_Controller_MRK:: Exiting getChildTerritoriesFor routine');

          throw new CreateAcctList_ControllerException('The Number of Territories to Process exceeds the Limit. List cannot be Processed.');
       } 
        
       //JK - Get Group IDs - This will get both Territory and TerritoryAndSubordinates (can filter on Territory if need be)
       List<Id> groupIds = new List<Id>();
       for (Group g : [SELECT Id,Type FROM Group WHERE RelatedId IN :masterList]) {
         System.debug('GroupId: ' + g.Id );
         groupIds.add(g.Id);
       }

      //JK - Get Account Ids from Account Share - essentially My Accounts
      List<Id> myAccountIds = new List<Id>();
      for (AccountShare ac : [SELECT AccountId FROM AccountShare WHERE UserOrGroupId IN :groupIds]) {
        System.debug('AccountShare: ' + ac.AccountId );
        myAccountIds.add(ac.AccountId);
      }

      //JK - Get Campaigns with my Accounts
      List<Campaign_Target_vod__c> campaignTargets = [SELECT Target_Account_vod__c 
                                                      FROM Campaign_Target_vod__c
                                                      WHERE Campaign_vod__c = :campaignId AND
                                                      Target_Account_vod__c IN :myAccountIds];
    
      //JK - create an Account List Item for each campaign target
      for (Campaign_Target_vod__c ct : campaignTargets) {
        System.debug('Debug_CreateAcctList_Controller_MRK::campaignTarget: ' + ct.Id );
        Account_List_Item_vod__c ali = new Account_List_Item_vod__c();
        ali.Account_List_vod__c = acListId;
        ali.Account_vod__c = ct.Target_Account_vod__c;
        aliToAdd.add(ali);
      }                                                          
    
      //JK - Finally, insert all of the Account List Items.
      If (!aliToAdd.IsEmpty()) {
         insert(aliToAdd);
      }
      
      confirmationPageMessage = 'Process has completed.';
    
    }catch(CreateAcctList_ControllerException ex){
       confirmationPageMessage = ex.getMessage();
        
    }catch(Exception ex){
       confirmationPageMessage = 'Process failed for the following Reasons:\n\n' + ex.getMessage();
       System.debug('Debug_CreateAcctList_Controller_MRK::Exception type caught: ' + ex.getTypeName());
       System.debug('Debug_CreateAcctList_Controller_MRK::Message: ' + ex.getMessage());
       System.debug('Debug_CreateAcctList_Controller_MRK::Cause: ' + ex.getCause()); // returns null
       System.debug('Debug_CreateAcctList_Controller_MRK::Line number: ' + ex.getLineNumber());
       System.debug('Debug_CreateAcctList_Controller_MRK::Stack trace: ' + ex.getStackTraceString());
   }
      
      PageReference pageRef = new PageReference('/apex/Create_Account_List_Confirmation_MRK');
      return pageRef;
   
  
    }
   
    /*
       Method to handle the UI Back Button
    */
    public PageReference back(){
       //Return the user back to the Campaign Record
      PageReference pageRef = new PageReference('/' + campaignId);
      pageRef.setRedirect(true);
      return pageRef;   
    }

    /*
       Recursively walks the user's Territory hierarchy
    */
    
    public void getChildTerritoriesFor(String territoryId) {
      
       System.debug('Debug_CreateAcctList_Controller_MRK:: Just entered getChildTerritoriesFor Routine. masterList.size(): ' + masterList.size() );
       
       //Exit the routine if we went over the limit...Need to avoid hitting the Governing Limits
       if (masterList.size() >= maxTerritoryNodes){
          System.debug('Debug_CreateAcctList_Controller_MRK:: 3 We hit the Limit! Total count of territories is: ' + masterList.size() );
          System.debug('Debug_CreateAcctList_Controller_MRK:: Forcefully Exiting getChildTerritoriesFor routine');
          return; //results;
       } 
        
       for (Territory2 t : [SELECT Id, ParentTerritory2Id 
                            FROM   Territory2 
                            WHERE  ParentTerritory2Id = :territoryId
                            AND    Territory2Model.state ='Active'
                           ]) {
          masterList.add(t.Id);
          System.debug('Debug_CreateAcctList_Controller_MRK:: Just Added Territory: ' + t.Id );
          System.debug('Debug_CreateAcctList_Controller_MRK:: masterList.size(): ' + masterList.size()  );
       
           //Exit the routine if we went over the limit...Need to avoid hitting the Governing Limits
          if (masterList.size()  >= maxTerritoryNodes){
             System.debug('Debug_CreateAcctList_Controller_MRK:: We hit the Limit! Total count of territories is: ' + masterList.size()  );
             System.debug('Debug_CreateAcctList_Controller_MRK:: Forcefully Exiting getChildTerritoriesFor routine');
          
             return; //results;
          } 
          
          System.debug('Debug_CreateAcctList_Controller_MRK:: About to get all child Territories for Territory: ' + t.Id );

           getChildTerritoriesFor(t.Id);
       }
       return; 
    }

 /*
   Custom Exception Class for this Class Only
 */
 private class CreateAcctList_ControllerException extends Exception {}
}