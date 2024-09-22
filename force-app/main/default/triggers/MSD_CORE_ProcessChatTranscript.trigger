/* KRB 21R3.0 6/22/2021 - Keytrudra Live Chat
 * 
 * Child Cases associated to a Keytrudra Chat Interaction Case must 
 * have the Chat Transcript PDF File associated to it. This
 * Trigger handles the File association. 
 * 
 */

trigger MSD_CORE_ProcessChatTranscript on Case (before update) {

    List<Case> casesToProcessList = new List<Case>();
    List<Id> casesToProcessIdList = new List<Id>();
    List<ContentDocumentLink> cdl = new List<ContentDocumentLink>();
    List<ContentDocumentLink> cdl2 = new List<ContentDocumentLink>();
    List<Case> casesToProcessAfterFirstScrubList = new List<Case>();
    List<Case> casesToProcessAfterSecondScrubList = new List<Case>();
    List<Case> casesWhereParentDoesNotHaveChatCDL = new List<Case>();
    List<ContentDocumentLink> cdlToLoad = new List<ContentDocumentLink>();
    
    //Lets get the Id of the Active DTC Keytrudra Source...
    List<MSD_CORE_Source__c> DTCKeytrudaSourceIdList = new List<MSD_CORE_Source__c>();
    Id DTCKeytrudaSourceId;
    
    DTCKeytrudaSourceIdList = new List<MSD_CORE_Source__c>([SELECT Id FROM MSD_CORE_Source__c WHERE Name = 'DTC KEYTRUDA' and MSD_CORE_Active__c = true]);
    if(!DTCKeytrudaSourceIdList.isEmpty()){
       DTCKeytrudaSourceId = DTCKeytrudaSourceIdList[0].Id; 
    }
    
    //Lets get the Id of the Active Keytruda Campaign...
    List<Campaign> KeytrudaCampaignIdList = new List<Campaign>();
    Id KeytrudaCampaignId;
    
    KeytrudaCampaignIdList = new List<Campaign>([SELECT Id FROM Campaign WHERE Name = 'Keytruda Campaign' AND IsActive = true]);

    if(!KeytrudaCampaignIdList.isEmpty()){
      KeytrudaCampaignId = KeytrudaCampaignIdList[0].Id;
    }

    for(Case c: Trigger.new){

       if(
           (Trigger.oldMap.get(c.ID).status != c.status) && //only when the Status Changes
           (!String.isBlank(c.ParentId)) && //only if it is a Child Case
           (c.Origin == 'Chat') && //only if it is a Chat Origin Child Case
           (!String.isBlank(DTCKeytrudaSourceId) && (c.MSD_CORE_Source__c == DTCKeytrudaSourceId)) && //Only DTC Keytruda Source Cases
           (!String.isBlank(KeytrudaCampaignId) && (c.MSD_CORE_Campaign__c == KeytrudaCampaignId)) && //Only Keytruda Campaign Related Cases
           ((c.Status == 'Closed') || (c.Status == 'Submitted')) //only handle Closed and Submitted Status changes
         ){
              casesToProcessList.add(c);  
              System.debug('KRB-CDL: Adding Case Id:' + c.id + ' to the list of cases to process...');

          }      
    } 
    
    //Only continue on if we have too, else exit...
    if(!casesToProcessList.isEmpty()){
    
       //-- ---------------------------------------------------------------------------------
       //First Scrub:
       //Only Want to Handle those Child Cases that don't Already have a Chat File attached. 
       //-- ---------------------------------------------------------------------------------
       System.debug('KRB-CDL: Entering First Scrub......');

       for(Case caseToProcess : casesToProcessList){
          casesToProcessIdList.add(caseToProcess.Id);
       }    
    
       cdl = new List<ContentDocumentLink>([SELECT ContentDocumentId, LinkedEntityId 
                                            FROM   ContentDocumentLink 
                                            WHERE  ContentDocument.title like '%Chat Transcript%' 
                                            AND    LinkedEntityId in :casesToProcessIdList ]);
        
       //If the Case Id appears in the cdl List returned, nothing has to be done. Chat Transcript already exists. 
       if(!cdl.isEmpty()){

          for(Case x : casesToProcessList){
             boolean matchFound = false; 
             for (ContentDocumentLink cdlx : cdl){
                if(x.id == cdlx.LinkedEntityId){ // nothing to do here... already has a Chat Transcript loaded. 
                   matchFound = true; 
                   System.debug('KRB-CDL: Match found in first cdl Scrub, breaking....');
                   break;
                }
             }
           
             if(!matchFound){
                System.debug('KRB-CDL: No Match found after first CDL Scrub, still need to process...');
                casesToProcessAfterFirstScrubList.add(x);
             }else{
                 System.debug('KRB-CDL: Match Found case already has Chat Transcript, nothing to do... ');
             }
          }
        
       }else{
         //nothing was returned, none of the Child Cases have a Chat Transcript...
         casesToProcessAfterFirstScrubList.addAll(casesToProcessList);
         System.debug('KRB-CDL: Nothing Returned from first CDL Query, need to process all the Cases...');
         
       }
 
       //-- ---------------------------------------------------------------------------------
       //Second Scrub:
       //If the Parent has a ContentDocumentLink  WHERE  ContentDocument.title like '%Chat Transcript%' 
       //Then Good....use it to create the Link to the Child
       //ELSE - Throw an Error saying we could not find a Chat Transcript on the Interaction to copy to 
       //the Child..Can't submit/close case...
       //-- ---------------------------------------------------------------------------------
 
       //Get the Parent Case Id of all the Child Cases
       if(!casesToProcessAfterFirstScrubList.isEmpty()){   

          Set<Id> parentCaseIdSet = new Set<Id>();
          List<Id> parentCaseIdList = new List<Id>();

          System.debug('KRB-CDL:Getting Parent Ids... ');

          //Dedupe
          for(Case ssc: casesToProcessAfterFirstScrubList){
             System.debug('KRB-CDL: Adding the following Parent Id to the Set: ' + ssc.ParentId);
             parentCaseIdSet.add(ssc.ParentId);
          }
       
          //Get ready for SOQL
          for(Id parentCaseId : parentCaseIdSet){
             System.debug('KRB-CDL: Adding the following Parent Id to the List: ' + parentCaseId);
             parentCaseIdList.add(parentCaseId);  
          }
        
          //Use it to Query the ContentDocumentLink Object and pull back all the Parent information
          cdl2 = new List<ContentDocumentLink>([SELECT ContentDocumentId, LinkedEntityId, ShareType
                                            FROM   ContentDocumentLink 
                                            WHERE  ContentDocument.title like '%Chat Transcript%' 
                                            AND    LinkedEntityId in :parentCaseIdList ]);
       

        
          //Loop through all the Cases to Process: If we have a match on Parent Id and Linked Id, create
          //    a record for the ContentDoctumentLink Object. If we dont have a match, attach an error to the 
          //    Record - can't submit or close....
       
          if(!cdl2.isEmpty()){
            
             for(Case c2: casesToProcessAfterFirstScrubList){
                boolean foundMatchingCDL = false;
                ContentDocumentLink cdlRec = new ContentDocumentLink(); 
          
                for(ContentDocumentLink cdlx : cdl2){
                   if(cdlx.LinkedEntityId == c2.ParentId){ //we have a match, create a new cdl
                      foundMatchingCDL = true;
                      cdlRec = cdlx;
                      System.debug('KRB-CDL: Match Found, Breaking out of Loop...');
                      break;
                   }
                }
           
                if (foundMatchingCDL){  //we have a match, create a new cdl
                   System.debug('KRB-CDL: Creating New CDL Record for the Child Case...');

                   ContentDocumentLink newCDL = new ContentDocumentLink();
                   newCDL.ContentDocumentId = cdlRec.ContentDocumentId;
                   newCDL.LinkedEntityId = c2.Id;
                   newCDL.ShareType = cdlRec.ShareType;
                   cdlToLoad.add(newCDL);
                
                }else{
                   System.debug('KRB-CDL: No Match found, Parent does not have CDL record. Error on Rec....');
                   casesWhereParentDoesNotHaveChatCDL.add(c2);
                }
             }
        
          }else{
              System.debug('KRB-CDL: All Cases passed in, Parent does not have CDL record. Error on Rec....');

              casesWhereParentDoesNotHaveChatCDL.addAll(casesToProcessAfterFirstScrubList);
          }


          //-- -----------------------------------------------------------
          //Process Errors and load up the new CDL 
          //-- ----------------------------------------------------------- 
          // Process Errors:
          if(!casesWhereParentDoesNotHaveChatCDL.isEmpty()){
             for(Case triggerCase : Trigger.new){

                for(Case caseWithError: casesWhereParentDoesNotHaveChatCDL){
                   if(triggerCase.Id == caseWithError.id){
                      triggerCase.addError('The Interaction does not have a Chat Transcript attached. Please ensure you submitted the Chat Disposition. You cannot submit/close this case until the Chat Transcript is attached to the Interaction.'); 
                   }
                }
             }
          }
        
          if(!cdlToLoad.isEmpty()){
             insert cdlToLoad;    
          }
        
       }    
              
    }else{
        System.debug('KRB-CDL: No Chat Transcripts to Process. Exiting Trigger...');
    } //if(!casesToProcessList.isEmpty()){
  
}