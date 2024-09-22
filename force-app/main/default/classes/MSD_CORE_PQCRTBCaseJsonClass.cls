public class MSD_CORE_PQCRTBCaseJsonClass {
   
    public static List<MSD_CORE_PQCRequest.ServiceCloudSafetyCase> getJSONWrap(List<String> caseIDs,List<Case> caseRecs,DateTime processedDateTime)
    {
         MSD_CORE_SC_RTB_Request_Info__mdt  reqInfo = MSD_CORE_PQCRTBCaseJsonClass.scRTBAEPQCRequestInfo();
        List<MSD_CORE_PQCRequest.ServiceCloudSafetyCase> jsonWrpList = new List<MSD_CORE_PQCRequest.ServiceCloudSafetyCase>();
        Map<String,List<MSD_CORE_AE_Product__c>> caseProdMap = new Map<String,List<MSD_CORE_AE_Product__c>>();
        Map<String,List<MSD_CORE_Note__c>> caseNoteMap = new Map<String,List<MSD_CORE_Note__c>>();
        Map<String,List<Attachment>> caseAttachMap = new Map<String,List<Attachment>>();
        Set<String> contentDocIDs = new Set<String>();
        Map<String,List<ContentDocumentLink>> contentDocLinkMap = new Map<String,List<ContentDocumentLink>>();
        Map<String,List<ContentVersion>> contentVersionMap = new Map<String,List<ContentVersion>>();
       // Map<String,String> caseStatusMap = new Map<String,String>(); // To capture status when first time case Send to RTB
        
        for(MSD_CORE_AE_Product__c p : [SELECT CreatedDate,Id,MSD_CORE_AE_Product__c.Name,LastModifiedDate,MSD_CORE_Product_Name__c,MSD_CORE_Dose_Frequency__c,MSD_CORE_Expiration_Date__c,MSD_CORE_Lot_Number__c,MSD_CORE_Product_Circular__c,MSD_CORE_Related_to__c,MSD_CORE_Primary_Product__c,MSD_CORE_Obtain__c,MSD_CORE_Catalog_Number__c,MSD_CORE_Hazardous_Product__c,MSD_CORE_Model_Number__c, MSD_CORE_Product_Qty__c, MSD_CORE_Product_Return_Date__c,MSD_CORE_Serial_Number__c,MSD_Core_Product_Operator_of_Device__c,MSD_CORE_Unique_Identifier__c,MSD_CORE_Adverse_Event__c FROM MSD_CORE_AE_Product__c WHERE MSD_CORE_Primary_Product__c = true AND  MSD_CORE_Adverse_Event__c in :caseIDs order by CreatedDate desc])
        {
            if(caseProdMap.containsKey(p.MSD_CORE_Adverse_Event__c))
            {
                caseProdMap.get(p.MSD_CORE_Adverse_Event__c).add(p);
            }
            else
            {
                List<MSD_CORE_AE_Product__c> prodList = new  List<MSD_CORE_AE_Product__c>();
                prodList.add(p);
                caseProdMap.put(p.MSD_CORE_Adverse_Event__c,prodList);
            }
        }
        for(MSD_CORE_Note__c n : [SELECT CreatedById,CreatedDate,Id,IsDeleted,MSD_CORE_Note_Type__c,IsLocked,LastModifiedById,LastModifiedDate,LastReferencedDate,LastViewedDate,MayEdit,MSD_CORE_Case__c,MSD_CORE_Country_Code__c,MSD_CORE_Create_Date_Time__c,MSD_CORE_Note__c,Name,SystemModstamp FROM MSD_CORE_Note__c WHERE  MSD_CORE_Case__c in :caseIDs AND MSD_CORE_Note_Type__c != 'Response Message'AND MSD_CORE_Note_Type__c != 'Question' order by CreatedDate desc])
        {
            if(caseNoteMap.containsKey(n.MSD_CORE_Case__c))
            {
                caseNoteMap.get(n.MSD_CORE_Case__c).add(n);
            }
            else
            {
                List<MSD_CORE_Note__c> nList = new  List<MSD_CORE_Note__c>();
                nList.add(n);
                caseNoteMap.put(n.MSD_CORE_Case__c,nList);
            }
        }
        for(Attachment a : [SELECT Id,ContentType,Name,BodyLength,ParentId,CreatedDate,LastModifiedDate,IsDeleted FROM Attachment WHERE ParentId in :caseIDs order by CreatedDate desc])
        {
            if(caseAttachMap.containsKey(a.ParentId))
            {
                caseAttachMap.get(a.ParentId).add(a);
            }
            else
            {
                List<Attachment> aList = new  List<Attachment>();
               
                aList.add(a);
                System.debug('Attachment size : ' + aList.size());
                caseAttachMap.put(a.ParentId,aList);
            }
        }
        
        for(ContentDocumentLink a : [SELECT ContentDocumentId,Id,IsDeleted,LinkedEntityId,ShareType,SystemModstamp,Visibility FROM ContentDocumentLink where LinkedEntityId in :caseIDs])
        {
            contentDocIDs.add(a.ContentDocumentId);
            if(contentDocLinkMap.containsKey(a.LinkedEntityId))
            {
                contentDocLinkMap.get(a.LinkedEntityId).add(a);
            }
            else
            {
                List<ContentDocumentLink> aList = new  List<ContentDocumentLink>();
                aList.add(a);
                contentDocLinkMap.put(a.LinkedEntityId,aList);
            }
            
        }
        system.debug('@@@@contentDocLinkMap'+contentDocLinkMap);
        for(ContentVersion cv : [SELECT Id,IsLatest,ContentSize,FileExtension,Title,VersionData,ContentDocumentId,IsDeleted FROM ContentVersion WHERE ContentDocumentId in : contentDocIDs order by CreatedDate desc])
        {
            if(contentVersionMap.containsKey(cv.ContentDocumentId))
            {
                contentVersionMap.get(cv.ContentDocumentId).add(cv);
            }
            else
            {
                List<ContentVersion> cvList = new  List<ContentVersion>();
                cvList.add(cv);
                contentVersionMap.put(cv.ContentDocumentId,cvList);
            }
            
        }
        
        system.debug('@@@@contentVersionMap'+contentVersionMap);
        // List Creation
        for(Case cs : caseRecs)
        {
         
            List<MSD_CORE_PQCRequest.CaseNote> nWrpList = new List<MSD_CORE_PQCRequest.CaseNote>();
            List<MSD_CORE_PQCRequest.Attachment> attWrpList = new List<MSD_CORE_PQCRequest.Attachment>();
            List<MSD_CORE_PQCRequest.ChatTranscript> ctWrpList = new List<MSD_CORE_PQCRequest.ChatTranscript>();
            MSD_CORE_PQCRequest.ServiceCloudSafetyCase wrp = new MSD_CORE_PQCRequest.ServiceCloudSafetyCase();
            Map<String,String> caseStatusMap = new Map<String,String>();
            String dateString = Datetime.now().format('ddMMYYYYHHmmss');
            String randomInteger = String.valueOf(Crypto.getRandomInteger()).substring(1,5);
            String noteIDs = '';
            String attachmentIDs= '';
            String chatTranscriptIDs= '';
            String addContactIDs= '';
            String productIDs= '';
            // CaseInfo
            MSD_CORE_PQCRequest.CaseInfo caseInfoWrp = new MSD_CORE_PQCRequest.CaseInfo();
             MSD_CORE_PQCRequest.CaseNote caseNoteWrp = new MSD_CORE_PQCRequest.CaseNote(); // Notes Followup Wapper
           	caseInfoWrp.caseEventType = cs.MSD_CORE_Event_Case_Type__c;
			caseInfoWrp.reporter_zippostal_code = cs.case_Postal_Code_MVN__c;
            caseInfoWrp.case_Status = cs.Status;
            if(cs.MSD_CORE_Event_Case_Type__c =='AE and PQC')
            {
                caseInfoWrp.adverse_event = 'true';
            }else
            {
                caseInfoWrp.adverse_event = 'false';
            }
			
           caseInfoWrp.Veeva_ID= cs.MSD_CORE_COVE_Veeva_ID__c;
          
            String caseTypeAll = ' ';
          if(cs.MSD_CORE_Event_Case_Type__c=='AE and PQC')
          { System.debug('inside AE and PQC : ');
              caseTypeAll = caseTypeAll+'ae__c'+',';
             
          }
           
           if(cs.MSD_CORE_CDT__c!= null)
          {System.debug('inside cdt : ');
			caseTypeAll = caseTypeAll+'cdt__c'+','; 
			            
          }
           if(cs.MSD_CORE_Customer_Feedback__c!= null)
          {System.debug('inside cf : ');
			caseTypeAll = caseTypeAll+'cf__c'+','; 
            
          }
            
          
          String strfinal = CaseTypeAll.removeEnd(',');
             caseInfoWrp.case_type = strfinal;
             System.debug('caseInfoWrp.case_type : ' +caseInfoWrp.case_type);
            caseInfoWrp.awareness_date= cs.MSD_CORE_AE_PQC_Company_Awareness_Date__c; 
            
            caseInfoWrp.description_normal=  'Description: '+cs.MSD_CORE_AE_Description__c+'<br>'+' Date PQC Observed: '+cs.AE_Start_Date_MVN__c;
            
         // Logic for External response required Start
         System.debug('External value '+cs.MSD_CORE_External_Response_value__c);
            caseInfoWrp.externalInitialValue=cs.MSD_CORE_External_Response_value__c;
          String Casealready = cs.MSD_CORE_Status_List__c;
            List<string> CaseAlreadyList = new  List<string>();
            caseInfoWrp.CaseProcessedFirstTime = true;
            if(Casealready!= null)
            {
                CaseAlreadyList = Casealready.split(',');
            }
            
            System.debug('Casealready : '+Casealready);
            System.debug('CaseSlreadyList : '+CaseAlreadyList);
              if(CaseAlreadyList.size()>0)
            {
                CaseAlreadyList = Casealready.split(',');
            
            for(String s : CaseAlreadyList)
             {
                
                 caseStatusMap.put(s,s);
             }
            }
            if(caseStatusMap.containsKey(cs.Status))
            {
				System.debug('Status already present : '+cs.Status);
               if(cs.Status =='Submitted' ||cs.Status =='Closed')
               { caseInfoWrp.CaseProcessedFirstTime = false;
               	
               }
                System.debug(' caseInfoWrp.CaseProcessedFirstTime '+ caseInfoWrp.CaseProcessedFirstTime);
                if(Casealready!= null)
                 {
                     caseInfoWrp.case_Status_List = Casealready;
                 }
            }
            else
            {
                if(caseStatusMap.containsKey('Submitted') && cs.Status == 'Closed' )
                {System.debug('Status First Time comming close but submitted present	: '+cs.Status);
                    caseInfoWrp.CaseProcessedFirstTime = false;
                }
                else  if(caseStatusMap.containsKey('Closed') && cs.Status == 'Submitted' )
                {System.debug('Status First Time comming Submitted but Close  present	: '+cs.Status);
                    caseInfoWrp.CaseProcessedFirstTime = false;
                }
                System.debug('Status First Time comming	: '+cs.Status);
				caseStatusMap.put(cs.Status,cs.Status);
                
              //  System.debug('FirstTimeOpenDate	: '+caseInfoWrp.FirstTimeOpenDate);
                 if(Casealready!= null)
                 {
                     caseInfoWrp.case_Status_List = Casealready + cs.Status+',';
                 }else
                 {
                     caseInfoWrp.case_Status_List = cs.Status+',';
                 }
                
            }
            
            System.debug('Final map : '+caseStatusMap);
            if(caseInfoWrp.CaseProcessedFirstTime == true)
            {
               // external_response_required logic will be updated only for the first time
         		if(cs.MSD_CORE_PQC_QIR_Requested__c == True)
                {
                   caseInfoWrp.external_response_required ='true'; 
                    System.debug('caseInfoWrp.external_response_required First true: '+caseInfoWrp.external_response_required);
                }
                else
                {
                    caseInfoWrp.external_response_required ='false';
                    System.debug('caseInfoWrp.external_response_required First false: '+caseInfoWrp.external_response_required);
           
                }
                    
            } else if(caseInfoWrp.CaseProcessedFirstTime == false)
            {
                caseInfoWrp.external_response_required = cs.MSD_CORE_External_Response_value__c;
                System.debug('cs.MSD_CORE_External_Response_value__c: '+cs.MSD_CORE_External_Response_value__c);
                
                System.debug('caseInfoWrp.external_response_required: '+caseInfoWrp.external_response_required);
           
            }
                
            System.debug('value sent to rtb .external_response_required: '+caseInfoWrp.external_response_required);
           
            
            
           // Logic for External response required End
          
            caseInfoWrp.reported_batch_number = cs.MSD_CORE_PQC_Lot_Numbers__c;
           // Sample expected indictor logic 
           if(cs.MSD_CORE_PQC_Sample_Expected_Indicator__c>0 && cs.MSD_CORE_PQC_To_Be_Processed__c == True)
           {System.debug('sample_expected yes');
               caseInfoWrp.sample_expected = 'yes__c';
           }
             else if (cs.MSD_CORE_PQC_Sample_Expected_Indicator__c <=0 && cs.MSD_CORE_PQC_To_Be_Processed__c == True)
            {System.debug(' sample_expected no');
                caseInfoWrp.sample_expected = 'no__c';
            }
           else if (cs.PQC_ATN_To_be_Processed__c == True && cs.MSD_CORE_PQC_To_Be_Processed__c == False)
            {System.debug('inside line 181 ');             
                if(cs.MSD_CORE_Sample_Expected_Initial_Value__c == null && cs.MSD_CORE_PQC_Sample_Expected_Indicator__c<=0)
                {
                    caseInfoWrp.sample_expected = 'no__c';
                }
                else if(cs.MSD_CORE_Sample_Expected_Initial_Value__c == null && cs.MSD_CORE_PQC_Sample_Expected_Indicator__c>0){
                    caseInfoWrp.sample_expected = 'yes__c';
                }
                else{
                    caseInfoWrp.sample_expected = cs.MSD_CORE_Sample_Expected_Initial_Value__c;
                }              
            }
            
            caseInfoWrp.case_id = cs.Parent.CaseNumber;
           //caseInfoWrp.case_id = cs.id;
            caseInfoWrp.reporter_country=System.Label.reporter_country;
           
            caseInfoWrp.date_of_event = cs.AE_Start_Date_MVN__c;
            caseInfoWrp.model = cs.MSD_CORE_Model_Number__c;

            // CaseNotes
           if(!caseNoteMap.isEmpty() &&  caseNoteMap.get(cs.id) != null && cs.MSD_CORE_PQC_To_Be_Processed__c == true && cs.PQC_Integration_Processed_Date_Time__c == null)// first time processing
            {
                List<MSD_CORE_Note__c> nList = caseNoteMap.get(cs.Id);
                System.debug(' First time notes size : '+ nList.size());
                caseInfoWrp.integrationLogNotesCount = nList.size();
                String AllNotesPerCase = '';
                DateTime NoteCreateddate;
                for(MSD_CORE_Note__c n : nList)
                { 
                    if(n.MSD_CORE_Note_Type__c == null)
                    {
                    System.debug(' first time sending notes to RTB : '+ n.name);
                    noteIDs += n.Id + '|';
                        NoteCreateddate = n.CreatedDate;
                 String notes =  n.Name +': '+ n.MSD_CORE_Note__c+'\n';

                    AllNotesPerCase = AllNotesPerCase + notes;
                    }
                  }
                //String jsonNotes = JSON.serializePretty(AllNotesPerCase);
                String jsonNotes = (AllNotesPerCase);
                System.debug('JSON Notes  : '+jsonNotes);
                Integer noteslenght = jsonNotes.length();
                if(noteslenght<32000)
                {System.debug('notes size less than : '+noteslenght);
                     caseInfoWrp.case_notes = jsonNotes ;
                }
                else{
                    System.debug('notes size greater : '+noteslenght);
                    String resleft = jsonNotes.left(32000);
					Integer rightnotelength = noteslenght-32000;
 					String resright = jsonNotes.right(rightnotelength);
                   // System.debug(' resleft : '+resleft);
                      System.debug(' resright : '+resright);
                     caseInfoWrp.case_notes  = resleft ; // Adding left part to casenotes string
                 //  MSD_CORE_PQCRequest.CaseNote caseNoteWrp1 = new MSD_CORE_PQCRequest.CaseNote();
                     caseNoteWrp.followUpQuestion  = 'Follow Up Question = New information received from US SC'+'_'+ NoteCreateddate;               
                     caseNoteWrp.followUpAnswer  = resright; // Adding right part to Follow up answer 
                     caseNoteWrp.Is_followup_Answer_record = 'true';
                    System.debug(' caseNoteWrp greater : '+caseNoteWrp);
 				  		nWrpList.add(caseNoteWrp);
                     wrp.x03caseNotes = nWrpList;
                    System.debug(' nWrpList1111 : '+nWrpList);
                    
                    
					
                }
                
                    System.debug(' caseInfoWrp.case_notes : '+  caseInfoWrp.case_notes);
             
            } else if(!caseNoteMap.isEmpty() &&  caseNoteMap.get(cs.id) != null && (cs.PQC_ATN_To_be_Processed__c == true || cs.MSD_CORE_PQC_To_Be_Processed__c == true) && cs.PQC_Integration_Processed_Date_Time__c != null)
            {
                List<MSD_CORE_Note__c> nList = caseNoteMap.get(cs.Id);
                System.debug(' Second time notes size : '+ nList.size());
               // MSD_CORE_PQCRequest.CaseNote caseNoteWrp = new MSD_CORE_PQCRequest.CaseNote();
                caseInfoWrp.integrationLogNotesCount = nList.size();
                caseInfoWrp.case_notes = cs.MSD_CORE_Initial_Notes__c;
                System.debug('Notes 316'+ caseInfoWrp.case_notes);
                for(MSD_CORE_Note__c n : nList)
                {
                    if(n.CreatedDate > cs.PQC_Integration_Processed_Date_Time__c)// To check old notes should not go again.
                    {System.debug('Inside follow up old notes should not go'+ n.name);
                     MSD_CORE_PQCRequest.CaseNote caseNoteWrp1 = new MSD_CORE_PQCRequest.CaseNote();
                     System.debug('Initial Notes 320'+ cs.MSD_CORE_Initial_Notes__c);
                      //caseInfoWrp.case_notes = cs.MSD_CORE_Initial_Notes__c;
                       System.debug('Notes 322'+ caseInfoWrp.case_notes);
                    
                        noteIDs += n.Id + '|';
                   caseNoteWrp1.noteID = n.Id;
                     caseNoteWrp1.followUpQuestion  = 'Follow Up Question = New information received from US SC'+'_'+ n.CreatedDate;               
                     caseNoteWrp1.followUpAnswer  = n.MSD_CORE_Note__c;
                     caseNoteWrp1.Is_followup_Answer_record = 'true';
 				  		nWrpList.add(caseNoteWrp1); 
                    }
                    
                }
               caseInfoWrp.integrationLogNotesIDs = noteIDs;
               
                wrp.x03caseNotes = nWrpList;
            } 


           
           // caseInfoWrp.operator_of_device =cs.MSD_CORE_Operator_of_Device__c;
            
            if( cs.case_AddressLine2_MVN__c!= null)
            {
                 caseInfoWrp.reporter_address = cs.case_AddressLine1_MVN__c + cs.case_AddressLine2_MVN__c;    
            }else
            {
                caseInfoWrp.reporter_address = cs.case_AddressLine1_MVN__c;     
            }
           
            caseInfoWrp.Date_PQC_Observed = cs.MSD_CORE_Date_PQC_first_identified__c;
            caseInfoWrp.reporter_city = cs.case_City_MVN__c;
            caseInfoWrp.reporter_email = cs.case_Account_Email_MVN__c;
            caseInfoWrp.reporter_first_name = cs.MSD_CORE_Customer_Contact_First_Name__c;
            caseInfoWrp.reporter_last_name = cs.MSD_CORE_Customer_Contact_Last_Name__c;
            caseInfoWrp.reporter_contact_number = cs.case_Account_Phone_MVN__c;
            caseInfoWrp.serial = cs.MSD_CORE_Serial_Number__c;
            caseInfoWrp.udi = cs.MSD_CORE_Unique_Identifier__c;
           // caseInfoWrp.defective_quantity_text = cs.MSD_CORE_Product_Quantity__c;
            caseInfoWrp.reporter_stateregionprovince = cs.case_State_MVN__c;
            // added by chetan as a part of UAT enhancement request for COVE 
            if(cs.MSD_CORE_Customer_Contact_Sub_Type__c != null){
                    caseInfoWrp.complainant_type = cs.MSD_CORE_Customer_Contact_Sub_Type__c;
            }else{
                    if(cs.MSD_CORE_Customer_Contact_Type__c != null)
                    {
                        caseInfoWrp.complainant_type = cs.MSD_CORE_Customer_Contact_Type__c;
                    }else
                    {
                         caseInfoWrp.complainant_type = 'null';
                    } 
                    //caseInfoWrp.complainant_type = cs.MSD_CORE_Customer_Contact_Type__c;
            }
            
             if(!caseProdMap.isEmpty() && caseProdMap.get(cs.id) != null)
            {
                List<MSD_CORE_AE_Product__c> prodList = caseProdMap.get(cs.id);
               // caseInfoWrp.integrationLogProdCount = prodList.size();
                for(MSD_CORE_AE_Product__c p : prodList)
                {
                    caseInfoWrp.operator_of_device = p.MSD_Core_Product_Operator_of_Device__c; // added by chetan as a part of UAT enhancements of COVE
                    caseInfoWrp.expiration_date = p.MSD_CORE_Expiration_Date__c;
                    caseInfoWrp.modelNumber = p.MSD_CORE_Model_Number__c;
                    caseInfoWrp.productName = p.MSD_CORE_Product_Name__c;
                    caseInfoWrp.defective_quantity_text = p.MSD_CORE_Product_Qty__c;
                    caseInfoWrp.serialNumber = p.MSD_CORE_Serial_Number__c;
                    caseInfoWrp.uniqueIdentifier = p.MSD_CORE_Unique_Identifier__c;
                     caseInfoWrp.catalog = p.MSD_CORE_Catalog_Number__c;

                    productIDs += p.id + '|'; 
                   caseInfoWrp.title = p.MSD_CORE_Product_Name__c +' '+'US PQC';
                    
                    if(p.MSD_CORE_Hazardous_Product__c == True)
                    {
                         caseInfoWrp.biohazard = 'yes__c';  
                    }else
                    {
                         caseInfoWrp.biohazard = 'no__c';  
                        
                    }
                     caseInfoWrp.reported_product_description = p.MSD_CORE_Product_Name__c +' (Exp.Date = '+p.MSD_CORE_Expiration_Date__c+')';
                }
                
            }
           
            caseInfoWrp.system_salesforce_id = cs.Id;
                    if(cs.Account.Class_of_Trade_MRK__C != null)
                    {
                        caseInfoWrp.ComplainantRole = cs.Account.Class_of_Trade_MRK__C; 
                    }else
                    {
                         caseInfoWrp.ComplainantRole = 'null';
                    } 
             //caseInfoWrp.ComplainantRole = cs.Account.Class_of_Trade_MRK__C; // changed by Chetan 
            caseInfoWrp.dpoc_child_pqc_event_id = cs.CaseNumber;
            if(cs.MSD_CORE_COVE_Veeva_ID__c == null){
			    caseInfoWrp.complaint_type = 'pqc__c'; // changed by Chetan as a part of hypercare release for COVE
			   }
           //caseInfoWrp.complaint_type = 'pqc__c'; // hardcoded PQC__C
            caseInfoWrp.intake_source = System.Label.intakesourcePQC; // hardcoded
            caseInfoWrp.country_of_incident = System.Label.countryofincident;// hard coded
            caseInfoWrp.photo_available = System.Label.photoavailable;// hard coded
             caseInfoWrp.integrationLogUniqueID = cs.Id+'|'+dateString+'|'+randomInteger;

             //added by c on 13/10/2023: start
            caseInfoWrp.integrationLogDes = 'Data sent to Vault QMS' ;
            caseInfoWrp.integrationLogDR = 'RTB/VaultQMS';
            caseInfoWrp.integrationLogCT = 'PQC';
            caseInfoWrp.integrationLogTDT = processedDateTime;
            
            caseInfoWrp.createdDateTimeUtc = cs.CreatedDate;
            caseInfoWrp.lastModifiedDateTimeUtc = cs.LastModifiedDate;
            caseInfoWrp.interactionNumber = cs.Parent.CaseNumber;
            caseInfoWrp.caseNumber = cs.CaseNumber;
            caseInfoWrp.caseOwner = cs.Owner.Name;
          
            

            // Attachments
            if(!caseAttachMap.isEmpty() && caseAttachMap.get(cs.id) != null )
            {
                List<Attachment> attList = caseAttachMap.get(cs.id); 
               caseInfoWrp.integrationLogAttCount = attList.size();
                for(Attachment a : attList)
                {	
                     if(a.CreatedDate > cs.PQC_Integration_Processed_Date_Time__c || cs.PQC_Integration_Processed_Date_Time__c == null )// To check old Attachment should not go again.
                     {
                        attachmentIDs += a.id + '|'; 
                    MSD_CORE_PQCRequest.Attachment attachmentWrp = new MSD_CORE_PQCRequest.Attachment();
                    attachmentWrp.id = a.Id;
                   
                    attWrpList.add(attachmentWrp);  
                     }
                   
                      
                }
                 wrp.x02attachments = attWrpList;
            } 
             
           //ChatTranscripts
            if(!contentDocLinkMap.isEmpty() && contentDocLinkMap.get(cs.id) != null)
            {
                List<ContentDocumentLink> cdlList = contentDocLinkMap.get(cs.id);                  
                for(ContentDocumentLink cdl : cdlList)
                {
                    if(!contentVersionMap.isEmpty() && contentVersionMap.get(cdl.ContentDocumentId) != null)
                    {
                        List<ContentVersion> cvList = contentVersionMap.get(cdl.ContentDocumentId);
                        caseInfoWrp.integrationLogCTCount = cvList.size();
                        for(ContentVersion cv :cvList)
                        {
                            chatTranscriptIDs += cv.id + '|'; 
                            MSD_CORE_PQCRequest.ChatTranscript chatTransWrp = new MSD_CORE_PQCRequest.ChatTranscript();
                            chatTransWrp.id = cv.id;
                            chatTransWrp.isLatest = cv.IsLatest;
                            chatTransWrp.contentSize = cv.ContentSize;
                            chatTransWrp.fileExtension = cv.FileExtension;
                            chatTransWrp.title = cv.Title;
                            chatTransWrp.isDeleted = cv.IsDeleted;
                            chatTransWrp.contentDocumentId = cv.ContentDocumentId;
                            chatTransWrp.linkedEntityId = cdl.LinkedEntityId;
                            chatTransWrp.fileAvailability = cdl.Visibility;
                            ctWrpList.add(chatTransWrp); 
                        }
                    }
                }
                caseInfoWrp.integrationLogCTIDs = chatTranscriptIDs;
                wrp.x01chatTranscripts = ctWrpList;    
            } 
             system.debug('@@@@@@ caseInfoWrp test '+ caseInfoWrp);
            wrp.x12caseInfo = caseInfoWrp;
            system.debug('@@@@@@ wrp.x12caseInfo  testing  '+  wrp.x12caseInfo );
        
            jsonWrpList.add(wrp);   
        }
        system.debug('@@@@@@jsonWrpList'+jsonWrpList);
        return jsonWrpList;
       
    }
    
    
    public static void submitPqcToRtb(List<object> scope,DateTime currentJobRunDateTime,MSD_CORE_SC_RTB_Request_Info__mdt  reqInfo,List<MSD_CORE_PIR_Request__c> aeRequests)
    {
        MSD_CORE_Aws_Api__c  awsApi = awsApiSettings();
        String requestId = generateNewRequestId();
        List<MSD_CORE_PQCRequest.ServiceCloudSafetyCase> lstWrap = (List<MSD_CORE_PQCRequest.ServiceCloudSafetyCase>)scope;
       system.debug('test IstWrap : '+ lstWrap);
        MSD_CORE_PQCRequest aeRequest = new MSD_CORE_PQCRequest(reqInfo, lstWrap, requestId);
        System.debug('aeRequest>>>>>>>>+++'+aeRequest);  
        Http h = new Http();
        HttpRequest req; 
        HttpResponse res=null;        
        try{
            String aeDataJson = JSON.serialize(aeRequest,false);
             System.debug('aeDataJson Rakesh test >>>>>>>>+++'+aeDataJson);
            req = buildWebServiceRequest(aeDataJson, awsApi);
            res = invokeAwsApi(h,req); 
            System.debug('response' + res.getStatusCode());
            if(res.getStatusCode() == 200)
            {
                system.debug('response from RTB is successful'+currentJobRunDateTime);
                updateCaseIntegrationStatus(aeRequest,currentJobRunDateTime);
                saveCaseToIntegrationLog(aeRequest,currentJobRunDateTime);
                if(aeRequests.size() == 0)
                {
                    saveRequestStatus(reqInfo,awsApi,requestId,aeRequest, res,reqInfo.FS_Source_System__c, 'Success');
                }
                else
                {
                    updateRequestStatus(aeRequests,reqInfo,requestId,res, 'Success');   
                }
            }
            else
            { system.debug('not sucess 200  ');
                //Insert a record into MSD_CORE_PIR_Request__c
                if(aeRequests.size() == 0)
                {
                    saveRequestStatus(reqInfo,awsApi,requestId,aeRequest, res,reqInfo.FS_Source_System__c, String.valueof(res.getStatusCode()));
                }
                else
                {
                    updateRequestStatus(aeRequests,reqInfo,requestId,res, String.valueof(res.getStatusCode()));  
                }
            }
        }
        catch(System.Exception e)
        {
            System.debug('Error submitting PIR Request:'+ e.getLineNumber());
            
            if(aeRequests.size() == 0)
            {
                saveRequestStatus(reqInfo,awsApi,requestId,aeRequest, res,reqInfo.FS_Source_System__c, e.getMessage());
            }
            else
            {
                updateRequestStatus(aeRequests,reqInfo,requestId,res,e.getMessage());    
            }
        }  
    }
    
    public static MSD_CORE_Aws_Api__c awsApiSettings(){
        return MSD_CORE_Aws_Api__c.getOrgDefaults();
    }
    public static MSD_CORE_SC_RTB_Request_Info__mdt  scRTBAEPQCRequestInfo() {
        return  MSD_CORE_SC_RTB_Request_Info__mdt.getInstance('AE_PQC_PQC_Only');
    } 
    
    //builds request object 
    public static HttpRequest buildWebServiceRequest(String aeDataJson, MSD_CORE_Aws_Api__c awsApi) {
        
        HttpRequest req = new HttpRequest();
        system.debug('building webservice request..');
        system.debug('HostName:' + awsApi.Hostname__c);
        req.setHeader('x-api-key', awsApi.Api_Key__c);
        req.setEndpoint('https://' + awsApi.Hostname__c + awsApi.PQC_Endpoint_Url__c);
        
        req.setMethod('POST');
        req.setBody(aeDataJson);
        system.debug('req:'+ req);
        return req;
    }
    
    public static HttpResponse invokeAwsApi(Http h, HttpRequest req) {
        
        HttpResponse  res = h.send(req);
        return res;
    }
    
    //Generates a unique requestid for each PIR request submitted to IRMS
    public static String generateNewRequestId(){
        
        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        //UUID format xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
        String requestid = h.SubString(0,8)+ '-' + h.SubString(8,12) + '-' + h.SubString(12,16) + '-' + h.SubString(16,20) + '-' + h.substring(20);
        
        system.debug(requestid);
        
        return requestid;
    } 
    
    /*
* Method: saveIntegrationLog
* Description: Inserts a record into IntegrationLog object once pir case is submitted to RTB
*/
    public static void saveCaseToIntegrationLog(MSD_CORE_PQCRequest aeRequest,DateTime processedDateTime){
        try
        {
            List<MSD_CORE_PQCRequest.ServiceCloudSafetyCase> caseList = aeRequest.x01ServiceCloudSafetyCase;
            List<MSD_CORE_Integration_Logs__c> integrationLog = new List<MSD_CORE_Integration_Logs__c>();
            String noteIDs;
            String attachmentIDs;
            for(MSD_CORE_PQCRequest.ServiceCloudSafetyCase c: caseList){
                system.debug('@@@@@@@@@@cLog'+c);
                MSD_CORE_Integration_Logs__c log = new MSD_CORE_Integration_Logs__c();
                log.MSD_CORE_Case__c = c.x12caseInfo.system_salesforce_id;
                log.MSD_CORE_Description__c = c.x12caseInfo.integrationLogDes;
                log.MSD_CORE_Destination_Recipient__c = c.x12caseInfo.integrationLogDR;
                log.MSD_CORE_Case_Type__c = c.x12caseInfo.integrationLogCT;
                log.MSD_CORE_Transmission_Date__c = c.x12caseInfo.integrationLogTDT;
                log.MSD_CORE_IL_Unique_ID__c = c.x12caseInfo.integrationLogUniqueID;
                log.MSD_CORE_No_of_Notes__c = c.x12caseInfo.integrationLogNotesCount;
                log.MSD_CORE_Note_IDs__c = c.x12caseInfo.integrationLogNotesIDs;
                log.MSD_CORE_No_of_Attachments__c = c.x12caseInfo.integrationLogAttCount;
                log.MSD_CORE_Attachment_Ids__c = c.x12caseInfo.integrationLogAttIDs;
                log.MSD_CORE_Add_Con_Ids__c = c.x12caseInfo.integrationLogAddConIDs;
                log.MSD_CORE_No_of_Add_Contacts__c = c.x12caseInfo.integrationLogAddConCount;
                log.MSD_CORE_No_of_Products__c = c.x12caseInfo.integrationLogProdCount;
                log.MSD_CORE_Product_Ids__c = c.x12caseInfo.integrationLogProdIDs;
                log.MSD_CORE_Files_Ids__c = c.x12caseInfo.integrationLogCTIDs;
                log.MSD_CORE_No_of_Files__c = c.x12caseInfo.integrationLogCTCount;
                integrationLog.add(log);
				
            }
            Database.SaveResult[] inLogList = Database.insert(integrationLog, false);
            for (Database.SaveResult sr : inLogList) {
                if (sr.isSuccess()) {
                    System.debug('Successfully inserted Invoice. Invoice ID: ' + sr.getId());
                } else {
                    for(Database.Error objErr : sr.getErrors()) {
                        System.debug('The following error has occurred.');
                        System.debug(objErr.getStatusCode() + ': ' + objErr.getMessage());
                        System.debug('Invoice oject field which are affected by the error:' 
                                     + objErr.getFields());
                    }
                }
            }
            
            
        } catch(System.Exception e){
            throw e;
        }
    } 
    /*
* Method: updateCaseIntegrationStatus
* Description: Updates Case Integration Status after submitting it to RTB.
*/
    public static void updateCaseIntegrationStatus(MSD_CORE_PQCRequest aeRequest, DateTime processedDateTime)
    {
        system.debug('@@@@@processedDateTime'+processedDateTime);
        try{
            List<MSD_CORE_PQCRequest.ServiceCloudSafetyCase> caseList = aeRequest.x01ServiceCloudSafetyCase;
            List<Case> updateCase = new List<Case>();
            List<MSD_CORE_Note__c> updateCaseNotes = new List<MSD_CORE_Note__c>();
            for(MSD_CORE_PQCRequest.ServiceCloudSafetyCase ca: caseList)
            {
                if(ca.x12caseInfo != null)
                {System.debug('out side external response logic');
                    case c =  new case();
                    c.Id = ca.x12caseInfo.system_salesforce_id;
                    c.PQC_Integration_Processed_Date_Time__c = processedDateTime;
                    c.MSD_CORE_COVE_Veeva_ID__c=ca.x12caseInfo.Veeva_ID;
                    c.MSD_CORE_Initial_Notes__c=ca.x12caseInfo.case_notes;
                    System.debug('Case notes 654 '+ca.x12caseInfo.case_notes);
                 System.debug('out side external response logic'+ca.x12caseInfo.case_Status_List);
                 if(ca.x12caseInfo.case_Status !='Open'){
                     c.MSD_CORE_Status_List__c=ca.x12caseInfo.case_Status_List;// Updating case statuses
                 }
                    c.MSD_CORE_Sample_Expected_Initial_Value__c=ca.x12caseInfo.sample_expected;
                    // Added first time value store logic
                     System.debug(' before ca.x12caseInfo.CaseProcessedFirstTime'+ca.x12caseInfo.CaseProcessedFirstTime);
                      if(ca.x12caseInfo.CaseProcessedFirstTime == true && ca.x12caseInfo.case_Status !='Open' && ca.x12caseInfo.externalInitialValue == null)
                         {
                              c.MSD_CORE_External_Response_value__c =ca.x12caseInfo.external_response_required;
                         }
                        
                                       
                    updateCase.add(c);
                }
            }
            if(updateCase.size() > 0)
            {
                Database.SaveResult[] upcList = Database.update(updateCase, false);
                for (Database.SaveResult sr : upcList) {
                    if (sr.isSuccess()) {
                        System.debug('Successfully inserted Invoice. Invoice ID: ' + sr.getId());
                    } else {
                        for(Database.Error objErr : sr.getErrors()) {
                            System.debug('The following error has occurred.');
                            System.debug(objErr.getStatusCode() + ': ' + objErr.getMessage());
                            System.debug('Invoice oject field which are affected by the error:' 
                                         + objErr.getFields());
                        }
                    }
                }
            }
        } catch(System.Exception e){
            throw e;
        }
    }
    
    
    /*Method: saveRequestStatus
*Description: Saves the response of a request to Real-time-bus.
*Possible Status values:
- REQ_STATUS_COMPLETED: Successful completion of request to Real-time-bus
- REQ_STATUS_RETRY: When a response to the request submitted to RTB is one of the following values
-> 408: Request Timeout
-> 503: Service Unavailable
-> 504: Gateway Timeout
- REQ_STATUS_ERROR: When a response to the request submitted to RTB returns an error.
*/
    public static void saveRequestStatus(MSD_CORE_SC_RTB_Request_Info__mdt reqInfo,MSD_CORE_Aws_Api__c awsApi, String requestId,MSD_CORE_PQCRequest aeRequest, HttpResponse res,String sourceSystem, String error){
        List<String> caseIdList = new List<String>();
        String caseEventType = '';
        List<MSD_CORE_PQCRequest.ServiceCloudSafetyCase> caseList =new List<MSD_CORE_PQCRequest.ServiceCloudSafetyCase>();
        if(aeRequest != null)
        {
            caseList = aeRequest.x01ServiceCloudSafetyCase;
        }
        for(MSD_CORE_PQCRequest.ServiceCloudSafetyCase ca: caseList)
        {
            if(ca.x12caseInfo != null)
            {
               caseIdList.add(ca.x12caseInfo.system_salesforce_id);
               caseEventType = ca.x12caseInfo.caseEventType;
            }
        }
        System.debug('caseIdList values'+caseIdList);
        String status = '';
        String msg = '';
        if(res == null){
            status = reqInfo.Request_Error__c;// REQ_STATUS_ERROR;
            msg = 'Error submitting AE&PQC AND PQC only data to RTB/Cove:-' + error;
        }
        else if(res.getStatusCode() == 200){
            status = reqInfo.Request_Completed__c; //REQ_STATUS_COMPLETED;
            msg = 'Status Code:' + res.getStatusCode() +'  Message:'+  res.getStatus();
        }
        else if(res.getStatusCode() == 408 || res.getStatusCode() == 504 || res.getStatusCode()==503 ){
            status = reqInfo.Request_Retry__c; //REQ_STATUS_RETRY;
            msg = 'Status Code:' + res.getStatusCode() +'  Message:'+  res.getBody() + error;
        }else{
            status = reqInfo.Request_Error__c; //REQ_STATUS_ERROR;
            msg = 'Status Code:' + res.getStatusCode() +'  Message:'+  res.getBody() + error;
        }
        
        List<MSD_CORE_PIR_Request__c> requests = new List<MSD_CORE_PIR_Request__c>();
        for(String srcId : caseIdList){
            
            MSD_CORE_PIR_Request__c pirReq = new MSD_CORE_PIR_Request__c();
             System.debug(' pirReq.Case_Id__c  : '+srcId);
            pirReq.Case_Id__c = srcId;
            pirReq.Request_Id__c = requestId;
            pirReq.Message__c = msg;
            pirReq.MSD_CORE_Case_Type__c = caseEventType;
            System.debug('event case type: '+caseEventType);
            if(res != null)
            {
                pirReq.MSD_CORE_RTB_Status_Code__c = String.valueof(res.getStatusCode());
            }
            pirReq.Status__c = status;
            pirReq.Source_System__c = sourceSystem;
            pirReq.Timestamp__c = System.now();
            requests.add(pirReq);
        } 
        insert requests;
    }       
    
    public static void updateRequestStatus(List<MSD_CORE_PIR_Request__c> aeRequests,MSD_CORE_SC_RTB_Request_Info__mdt reqInfo, String requestId, HttpResponse res, String error){
        String status = '';
        String msg = '';
        if(res == null)
        {
            status = reqInfo.Request_Error__c;// REQ_STATUS_ERROR;
            msg = 'Error submitting AE&PQC And PQC only data to RTB/Cove:-' + error;
        }
        else if(res.getStatusCode() == 200)
        {
            status = reqInfo.Request_Completed__c; //REQ_STATUS_COMPLETED;
            msg = 'Status Code:' + res.getStatusCode() +'  Message:'+  res.getStatus();
        }
        else if(res.getStatusCode() == 408 || res.getStatusCode() == 504 || res.getStatusCode() == 503)
        {
            status = reqInfo.Request_Retry__c; //REQ_STATUS_RETRY;
            msg = 'Status Code:' + res.getStatusCode() +'  Message:'+  res.getBody() + error;
        }
        else
        {
            status = reqInfo.Request_Error__c; //REQ_STATUS_ERROR;
            msg = 'Status Code:' + res.getStatusCode() +'  Message:'+  res.getBody() + error;
        }
        
        List<MSD_CORE_PIR_Request__c> upAeRequests = new List<MSD_CORE_PIR_Request__c>();
        
        for(MSD_CORE_PIR_Request__c rtb : aeRequests)
        {
            MSD_CORE_PIR_Request__c ae = new MSD_CORE_PIR_Request__c();
            ae.id = rtb.id;
            ae.Request_Id__c =  requestId;
            ae.Message__c = rtb.Message__c+' \n '+msg;
            if( rtb.MSD_CORE_Retry_Count__c != null)
            {
                ae.MSD_CORE_Retry_Count__c = rtb.MSD_CORE_Retry_Count__c+1;  
            }
            else
            {
                ae.MSD_CORE_Retry_Count__c = 1; 
            }
            ae.Status__c = status;
            if(res != null)
            {
                ae.MSD_CORE_RTB_Status_Code__c = String.valueof(res.getStatusCode());
            }
            else
            {
                ae.MSD_CORE_RTB_Status_Code__c = '';    
            }
            if(ae.MSD_CORE_Retry_Count__c >= reqInfo.Max_Retry_Count__c)
            {
                if(ae.Status__c == reqInfo.Request_Retry__c)
                {
                    ae.Status__c = reqInfo.Request_Failed__c;
                }
            }
            upAeRequests.add(ae);
        } 
        update upAeRequests;
    }       
    
}