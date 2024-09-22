trigger MSD_CORE_ProcessFiles on MSD_CORE_CaseTmpXInqry__c (after insert, after delete) {
   /* KRB 22R1.0 1/21/2022 - When a TempEx Inquiry Record and Case are associated, 
    * 					     any files associated to the Inquiry Record have to be associated 
    * 						 to the given Case. Opposite holds true too - if the association 
    * 						 record is deleted, the files associated to the Case that where attached
    * 						 to the Inquiry need to be removed from the Case Record. 
    * 					     Reparenting is not allowed, so only insert and delete are handled, no edits. 
    */
    
   if (Trigger.isInsert) {
      //get list of TempEx Record Ids
      //query Content Document Link
      //for each record returned, load new case to file association
      Set<Id> tempExInquiryIdsToProcessSet = new Set<Id>();
      List<Id> tempExInquiryIdsToProcessList = new List<Id>();
      List<ContentDocumentLink> tempExInquiryCDLList = new List<ContentDocumentLink>();
      List<ContentDocumentLink> CaseCDLForInsertList = new List<ContentDocumentLink>();
      
      for(MSD_CORE_CaseTmpXInqry__c x: Trigger.new){   
	     tempExInquiryIdsToProcessSet.add(x.MSD_CORE_TempExInqry__c);
      }
       
      //Convert to List for Query:
      for(Id tempExId: tempExInquiryIdsToProcessSet){   
	     tempExInquiryIdsToProcessList.add(tempExId);
      }
      
      
      tempExInquiryCDLList = new List<ContentDocumentLink>(
          						[SELECT ContentDocumentId, 
                                        Sharetype, 
                                        LinkedEntityId 
                                 FROM   ContentDocumentLink 
                                 WHERE  LinkedEntityId in :tempExInquiryIdsToProcessList ]);
   
      if(!tempExInquiryCDLList.isEmpty()){
      
         for(MSD_CORE_CaseTmpXInqry__c x: Trigger.new){   
            boolean foundMatchingCDL = false;
            ContentDocumentLink cdlRec = new ContentDocumentLink(); 
			
            for(ContentDocumentLink tempExCdl: tempExInquiryCDLList ){
                if(tempExCdl.LinkedEntityId ==x.MSD_CORE_TempExInqry__c){
                   foundMatchingCDL = true; 
                   cdlRec = tempExCdl;
                   System.debug('KRB-CDL: Match Found, Breaking out of Loop...');
                   break;
                }     
            } 
             
            if(foundMatchingCDL){//we have a match, create new CDL
               ContentDocumentLink newCDL = new ContentDocumentLink();
               newCDL.ContentDocumentId = cdlRec.ContentDocumentId;
               newCDL.LinkedEntityId = x.MSD_CORE_Case__c;
               newCDL.ShareType = cdlRec.ShareType;
               CaseCDLForInsertList.add(newCDL);               
            }else{
               System.debug('KRB-CDL: No Match found, TempEx Inquiry record does not have CDL record.');
            } 
         }
      }
       
      if(!CaseCDLForInsertList.isEmpty()){
         insert CaseCDLForInsertList;      
      }


   //On delete, we need to remove any files associated to the TempExInquiry from the Case
   }else if (Trigger.isDelete) { 
   
      Set<Id> tempExInqIdsToProcessSet = new Set<Id>();
      List<Id> tempExInqIdsToProcessList = new List<Id>();
      List<ContentDocumentLink> tempExInqCDLList = new List<ContentDocumentLink>();
      List<ContentDocumentLink> allCDLList = new List<ContentDocumentLink>();
 
      for(MSD_CORE_CaseTmpXInqry__c x: Trigger.old){   
	     tempExInqIdsToProcessSet.add(x.MSD_CORE_TempExInqry__c);
      }
      
      //Convert to List for Query:
      for(Id tempExId: tempExInqIdsToProcessSet){   
	     tempExInqIdsToProcessList.add(tempExId);
      }

      //list of all ContentDocumentId associated to the Temp Ex Inquiry
      tempExInqCDLList = new List<ContentDocumentLink>(
          						[SELECT ContentDocumentId, 
                                        Sharetype, 
                                        LinkedEntityId 
                                 FROM   ContentDocumentLink 
                                 WHERE  LinkedEntityId in :tempExInqIdsToProcessList ]);
      
      //Use list above to query ALL records associated to these specific ContentDocumentIds
      Set<Id> contentDocumentIdsToProcessSet = new Set<Id>();
      List<Id> contentDocumentIdsToProcessList = new List<Id>();
      List<ContentDocumentLink> contentDocumentlinkToDeleteList = new List<ContentDocumentLink>();
      
       for(ContentDocumentLink cdl : tempExInqCDLList){
           contentDocumentIdsToProcessSet.add(cdl.ContentDocumentId);
       }
       
       for(Id documentId: contentDocumentIdsToProcessSet ){
           contentDocumentIdsToProcessList.add(documentId);
       }
       
       allCDLList = new List<ContentDocumentLink>(
          					[SELECT ContentDocumentId, 
                                    Sharetype, 
                                    LinkedEntityId 
                             FROM   ContentDocumentLink 
                             WHERE  ContentDocumentId in :contentDocumentIdsToProcessList]);
      
      
      for(MSD_CORE_CaseTmpXInqry__c x: Trigger.old){   
          for (ContentDocumentLink cdlx: allCDLList){
              if(cdlx.LinkedEntityId == x.MSD_CORE_Case__c){
                 contentDocumentlinkToDeleteList.add(cdlx); 
              } 
          }
      }
 
      if(!contentDocumentlinkToDeleteList.isEmpty()){
         delete contentDocumentlinkToDeleteList;
      } 
   }   
}