public class MSD_CORE_AERTBCaseJsonClass {
    //public final MSD_CORE_RTB_Pir_Request_Info__c  pirInfo = MSD_CORE_AwsApiIntegration.piRequestInfo();
    public static List<MSD_CORE_AERequest.ServiceCloudSafetyCase> getJSONWrap(List<String> caseIDs,List<Case> caseRecs,DateTime processedDateTime)
    {
        
        List<MSD_CORE_AERequest.ServiceCloudSafetyCase> jsonWrpList = new List<MSD_CORE_AERequest.ServiceCloudSafetyCase>();
        Map<String,List<MSD_CORE_AE_Contact__c>> caseConMap = new Map<String,List<MSD_CORE_AE_Contact__c>>();
        Map<String,List<MSD_CORE_AE_Product__c>> caseProdMap = new Map<String,List<MSD_CORE_AE_Product__c>>();
        Map<String,List<MSD_CORE_Note__c>> caseNoteMap = new Map<String,List<MSD_CORE_Note__c>>();
        Map<String,List<Attachment>> caseAttachMap = new Map<String,List<Attachment>>();
        Set<String> contentDocIDs = new Set<String>();
        Map<String,List<ContentDocumentLink>> contentDocLinkMap = new Map<String,List<ContentDocumentLink>>();
        Map<String,List<ContentVersion>> contentVersionMap = new Map<String,List<ContentVersion>>();
        
        for(MSD_CORE_AE_Contact__c con : [SELECT MSD_CORE_Primary_Contact__c,MSD_CORE_Correspondence_Contact__c,CreatedDate,Id,LastModifiedDate,MSD_CORE_First_Name__c,MSD_CORE_Last_Name__c,MSD_CORE_Permission_to_Contact__c,Name,MSD_CORE_Type__c,MSD_CORE_Credentials__c,MSD_CORE_Address_Line_1__c,MSD_CORE_Address_Line_2__c,MSD_CORE_Fax__c,MSD_CORE_Phone__c,MSD_Core_Email__c,MSD_CORE_Contact_Related_To__c,MSD_CORE_Adverse_Event__c,MSD_CORE_City__c,MSD_CORE_State_Province__c,MSD_CORE_Country__c,MSD_CORE_Postal_Code__c FROM MSD_CORE_AE_Contact__c WHERE MSD_CORE_Adverse_Event__c in :caseIDs order by CreatedDate desc])
        {
            if(caseConMap.containsKey(con.MSD_CORE_Adverse_Event__c))
            {
                caseConMap.get(con.MSD_CORE_Adverse_Event__c).add(con);
            }
            else
            {
                List<MSD_CORE_AE_Contact__c> conList = new  List<MSD_CORE_AE_Contact__c>();
                conList.add(con);
                caseConMap.put(con.MSD_CORE_Adverse_Event__c,conList);
            }
        }
        for(MSD_CORE_AE_Product__c p : [SELECT CreatedDate,Id,LastModifiedDate,MSD_CORE_Product_Name__c,MSD_CORE_Dose_Frequency__c,MSD_CORE_Expiration_Date__c,MSD_CORE_Lot_Number__c,MSD_CORE_Product_Circular__c,MSD_CORE_Related_to__c,MSD_CORE_Primary_Product__c,MSD_CORE_Obtain__c,MSD_CORE_Catalog_Number__c,MSD_CORE_Hazardous_Product__c,MSD_CORE_Model_Number__c, MSD_CORE_Product_Qty__c, MSD_CORE_Product_Return_Date__c,MSD_CORE_Serial_Number__c,MSD_Core_Product_Operator_of_Device__c,MSD_CORE_Unique_Identifier__c,MSD_CORE_Adverse_Event__c FROM MSD_CORE_AE_Product__c WHERE MSD_CORE_Adverse_Event__c in :caseIDs order by CreatedDate desc])
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
        for(MSD_CORE_Note__c n : [SELECT CreatedById,CreatedDate,Id,IsDeleted,IsLocked,LastModifiedById,LastModifiedDate,LastReferencedDate,LastViewedDate,MayEdit,MSD_CORE_Case__c,MSD_CORE_Country_Code__c,MSD_CORE_Create_Date_Time__c,MSD_CORE_Note__c,Name,SystemModstamp FROM MSD_CORE_Note__c WHERE MSD_CORE_Case__c in :caseIDs order by CreatedDate desc])
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
            List<MSD_CORE_AERequest.AdditionalContact> addConWrpList = new List<MSD_CORE_AERequest.AdditionalContact>();
            List<MSD_CORE_AERequest.Product> prodWrpList = new List<MSD_CORE_AERequest.Product>();
            List<MSD_CORE_AERequest.CaseNote> nWrpList = new List<MSD_CORE_AERequest.CaseNote>();
            List<MSD_CORE_AERequest.Attachment> attWrpList = new List<MSD_CORE_AERequest.Attachment>();
            List<MSD_CORE_AERequest.ChatTranscript> ctWrpList = new List<MSD_CORE_AERequest.ChatTranscript>();
            MSD_CORE_AERequest.ServiceCloudSafetyCase wrp = new MSD_CORE_AERequest.ServiceCloudSafetyCase();
            String dateString = Datetime.now().format('ddMMYYYYHHmmss');
            String randomInteger = String.valueOf(Crypto.getRandomInteger()).substring(1,5);
            String noteIDs = '';
            String attachmentIDs= '';
            String chatTranscriptIDs= '';
            String addContactIDs= '';
            String productIDs= '';
            // CaseInfo
            MSD_CORE_AERequest.CaseInfo caseInfoWrp = new MSD_CORE_AERequest.CaseInfo();
            caseInfoWrp.caseID = cs.Id;
            caseInfoWrp.caseStatus = cs.Status;
            caseInfoWrp.integrationLogUniqueID = cs.Id+'|'+dateString+'|'+randomInteger;
            caseInfoWrp.integrationLogDes = 'Data Sent to PV' ;
            caseInfoWrp.integrationLogDR = 'RTB/PV';
            caseInfoWrp.integrationLogCT = 'AE';
            caseInfoWrp.integrationLogTDT = processedDateTime;
            
            caseInfoWrp.createdDateTimeUtc = cs.CreatedDate;
            caseInfoWrp.lastModifiedDateTimeUtc = cs.LastModifiedDate;
            caseInfoWrp.interactionNumber = cs.Parent.CaseNumber;
            caseInfoWrp.caseNumber = cs.CaseNumber;
            caseInfoWrp.caseOwner = cs.Owner.Name;
            caseInfoWrp.companyAwarenessDateUtc = cs.MSD_CORE_AE_PQC_Company_Awareness_Date__c;
            caseInfoWrp.interactionChatUniqueIdentifierID = cs.Parent.MSD_CORE_ChatUniqueID__c;
            caseInfoWrp.eventCaseType = cs.MSD_CORE_Event_Case_Type__c;
            caseInfoWrp.alertSecurity = cs.MSD_CORE_Alert_Security__c;
            caseInfoWrp.alertLegal = cs.MSD_CORE_Legal_Alert__c;
            caseInfoWrp.marrS_CaseNumber = cs.MSD_CORE_MARRS_Number__c;
            caseInfoWrp.DHS_Number = cs.MSD_CORE_DHS_Number__c;  
            caseInfoWrp.multiplePatientsInvolved = cs.MSD_Core_Multiple_Patients_Involved__c; 
            caseInfoWrp.routeOfAdministration = cs.MSD_CORE_AE_Route_of_Administration__c;
            caseInfoWrp.caseLatestSubmittedDateUtc = cs.MSD_CORE_Submitted_Date__c;
            caseInfoWrp.caseLatestClosedsDateUtc = cs.ClosedDate;
            
            
            // CaseAdditionalInfo
            MSD_CORE_AERequest.CaseAdditionalInfo caseAdditionalInfoWrp = new MSD_CORE_AERequest.CaseAdditionalInfo();
            caseAdditionalInfoWrp.concomitantMedications = cs.MSD_CORE_AE_Concomitant_Medication__c;
            caseAdditionalInfoWrp.pertinentMedicalHistory = cs.MSD_CORE_AE_Pertinent_Medical_History__c;
            caseAdditionalInfoWrp.drugReactions_Allergies =cs.MSD_CORE_AE_Drug_Reactions_Allergies__c;
            caseAdditionalInfoWrp.labDiagnostics_StudiesPerformed = cs.MSD_CORE_AE_Lab_Diagnostics_Studies__c;
            
            wrp.x11caseAdditionalInfo = caseAdditionalInfoWrp;
            
            
            // AdverseEvent
            MSD_CORE_AERequest.AdverseEvent adverseEventWrp = new MSD_CORE_AERequest.AdverseEvent();
            adverseEventWrp.reactionDescription = cs.MSD_CORE_AE_Description__c;
            adverseEventWrp.onsetDate = cs.AE_Start_Date_MVN__c;
            adverseEventWrp.presentStatus =cs.MSD_CORE_AE_Present_Status__c;
            adverseEventWrp.therapyDiscontinued = cs.MSD_CORE_AE_Was_Therapy_Discontinued__c;
            adverseEventWrp.therapyStartDate = cs.MSD_CORE_AE_Therapy_Start_Date__c;
            adverseEventWrp.therapyEndDate = cs.MSD_CORE_AE_Therapy_End_Date__c;
            adverseEventWrp.recoveryDate =cs.MSD_CORE_AE_Recovery_Date__c;
            adverseEventWrp.indication = cs.MSD_CORE_AE_Indication__c;
            adverseEventWrp.wasTreatmentGivenForAE = cs.MSD_CORE_AE_Was_Treatment_Given_for_AE__c;
            adverseEventWrp.treatmentProvided = cs.MSD_CORE_AE_Treatment_Provided__c;
            adverseEventWrp.rechallenge =cs.MSD_CORE_AE_Rechallenge__c;
            adverseEventWrp.dechallenge = cs.MSD_CORE_AE_Dechallenge__c;
            adverseEventWrp.soughtMedicalAttention = cs.MSD_CORE_AE_Sought_Medical_Attention__c;
            adverseEventWrp.resultedInDeath =cs.MSD_CORE_AE_Did_the_Patient_Die__c;
            adverseEventWrp.causeOfDeath = cs.MSD_CORE_AE_Cause_of_Death__c;
            adverseEventWrp.dateOfDeath = cs.MSD_CORE_AE_Date_of_Death__c;
            adverseEventWrp.interventionToPreventSeriousCriteria = cs.MSD_CORE_AE_Intervention_Prevent_Serious__c;
            adverseEventWrp.isCancer =cs.MSD_CORE_AE_Is_Was_the_AE_Cancer__c;
            adverseEventWrp.isOverdose = cs.MSD_CORE_AE_Patient_Overdose__c;
            adverseEventWrp.isCongenitalAnomaly = cs.MSD_CORE_AE_Is_Was_AE_Congenital_Anomaly__c;
            adverseEventWrp.significantDisabilityIncapacity =cs.MSD_CORE_AE_Sig_Disability_or_Incapacity__c;
            adverseEventWrp.isHospitalizedOrProlonged = cs.MSD_CORE_AE_Hospitalization_or_Prolonged__c;
            adverseEventWrp.isLifeThreatening =cs.MSD_CORE_AE_Life_Threatening__c;
            
            wrp.x10adverseEvent = adverseEventWrp;
            
            // Paitent
            MSD_CORE_AERequest.Patient patientWrp = new MSD_CORE_AERequest.Patient();
            patientWrp.firstName = cs.Patient_First_Name_MVN__c;
            patientWrp.lastName = cs.Patient_Last_Name_MVN__c;
            patientWrp.dateOfBirthText =cs.MSD_CORE_AE_Patient_Date_of_Birth__c;
            patientWrp.patientAgeText = cs.MSD_CORE_AE_Patient_Age__c;
            patientWrp.patientGender = cs.MSD_CORE_AE_Patient_Gender__c;
            patientWrp.isPatientPregnant =cs.MSD_CORE_AE_Is_Patient_Pregnant__c;
            patientWrp.pregnancyGestationOrLMP = cs.MSD_CORE_AE_Pregnancy_Gestation_or_LMP__c;
            
            wrp.x09patient = patientWrp;
            
            // PatientSupportProgram
            MSD_CORE_AERequest.PatientSupportProgram patientSupportProgramWrp = new MSD_CORE_AERequest.PatientSupportProgram();
            patientSupportProgramWrp.programName = cs.MSD_CORE_PSP_Program_Name__c;
            patientSupportProgramWrp.programNameOther = cs.MSD_CORE_PSP_Program_Name_Other__c;
            patientSupportProgramWrp.company =cs.MSD_CORE_PSP_Company__c;
            patientSupportProgramWrp.companyOther = cs.MSD_CORE_PSP_Company_Other__c;
            patientSupportProgramWrp.psP_Number = cs.MSD_CORE_PSP_Number__c;
            patientSupportProgramWrp.psP_NumberOther =cs.MSD_CORE_PSP_Number_Other__c;
            patientSupportProgramWrp.agentName = cs.MSD_CORE_PSP_Agent_Name__c;
            
            wrp.x08patientSupportProgram = patientSupportProgramWrp;
            
            // ProductQualitycomplaint
            MSD_CORE_AERequest.ProductQualitycomplaint productQualitycomplaintWrp = new MSD_CORE_AERequest.ProductQualitycomplaint();
            productQualitycomplaintWrp.pqC_Present = cs.Parent.MSD_CORE_PQC_Present__c;
            productQualitycomplaintWrp.userExperience = cs.MSD_CORE_PQC_User_Experience__c;
          //  productQualitycomplaintWrp.operatorOfDevice =cs.MSD_CORE_Operator_of_Device__c;
            productQualitycomplaintWrp.priority = cs.MSD_CORE_PQC_Priority__c;
            productQualitycomplaintWrp.qiR_Requested = cs.MSD_CORE_PQC_QIR_Requested__c;
            productQualitycomplaintWrp.qiR_ReceivedDateUtc =cs.MSD_CORE_QIR_Received_Date__c;
            
            wrp.x07productQualitycomplaint = productQualitycomplaintWrp;
            
            // CustomerFeedback
            MSD_CORE_AERequest.CustomerFeedback customerFeedbackWrp = new MSD_CORE_AERequest.CustomerFeedback();
            customerFeedbackWrp.feedbackText = cs.MSD_CORE_Customer_Feedback__c;
            customerFeedbackWrp.feedbackClassification = cs.MSD_CORE_Customer_FeedbackClassification__c;
            customerFeedbackWrp.cdt =cs.MSD_CORE_CDT__c;
            
            wrp.x06customerFeedback = customerFeedbackWrp;
            
            // AdditionalContacts
            if(!caseConMap.isEmpty() && caseConMap.get(cs.id) != null)
            {
                List<MSD_CORE_AE_Contact__c> conList = caseConMap.get(cs.id);    
                caseInfoWrp.integrationLogAddConCount = conList.size();
                for(MSD_CORE_AE_Contact__c c : conList)
                {
                    addContactIDs += c.id + '|'; 
                    MSD_CORE_AERequest.AdditionalContact additionalContactWrp = new MSD_CORE_AERequest.AdditionalContact();
                    additionalContactWrp.type = c.MSD_CORE_Type__c;
                    additionalContactWrp.firstName = c.MSD_CORE_First_Name__c;
                    additionalContactWrp.lastName = c.MSD_CORE_Last_Name__c;
                    additionalContactWrp.contactNumber = c.Name;
                    additionalContactWrp.credentials = c.MSD_CORE_Credentials__c;
                    additionalContactWrp.addressLine1 = c.MSD_CORE_Address_Line_1__c;    
                    additionalContactWrp.addressLine2 = c.MSD_CORE_Address_Line_2__c;
                    additionalContactWrp.city = c.MSD_CORE_City__c;
                    additionalContactWrp.state = c.MSD_CORE_State_Province__c;
                    additionalContactWrp.country = c.MSD_CORE_Country__c;
                    additionalContactWrp.postalCode = c.MSD_CORE_Postal_Code__c; 
                    additionalContactWrp.phone = c.MSD_CORE_Phone__c;    
                    additionalContactWrp.fax = c.MSD_CORE_Fax__c;
                    additionalContactWrp.Email = c.MSD_Core_Email__c; //CEF2F-22189 added by Priyanka Tiwari
                    additionalContactWrp.contactRelatedTo = c.MSD_CORE_Contact_Related_To__c;
                    additionalContactWrp.hasPermissionToContact = c.MSD_CORE_Permission_to_Contact__c;
                    additionalContactWrp.isPrimaryContact = c.MSD_CORE_Primary_Contact__c;
                    additionalContactWrp.isCorrespondenceContact = c.MSD_CORE_Correspondence_Contact__c; 
                    addConWrpList.add(additionalContactWrp);
                }
                caseInfoWrp.integrationLogAddConIDs = addContactIDs;
                wrp.x05additionalContacts = addConWrpList;  
            }
            
            // Products
            if(!caseProdMap.isEmpty() && caseProdMap.get(cs.id) != null)
            {
                List<MSD_CORE_AE_Product__c> prodList = caseProdMap.get(cs.id);
                caseInfoWrp.integrationLogProdCount = prodList.size();
                for(MSD_CORE_AE_Product__c p : prodList)
                {
                    productIDs += p.id + '|'; 
                    MSD_CORE_AERequest.Product productWrp = new MSD_CORE_AERequest.Product();
                    productWrp.isPrimaryProduct =p.MSD_CORE_Primary_Product__c;
                    productWrp.productName = p.MSD_CORE_Product_Name__c;
                    productWrp.doseFrequency =p.MSD_CORE_Dose_Frequency__c ;
                    productWrp.expirationDate =p.MSD_CORE_Expiration_Date__c;
                    productWrp.relatedTo =p.MSD_CORE_Related_to__c;
                    productWrp.obtain =p.MSD_CORE_Obtain__c;
                    productWrp.isHazardousProduct =p.MSD_CORE_Hazardous_Product__c;
                    productWrp.productQuantity =p.MSD_CORE_Product_Qty__c;
                    productWrp.productReturnDateUtc =p.MSD_CORE_Product_Return_Date__c;
                    productWrp.lotNumber =p.MSD_CORE_Lot_Number__c;
                    productWrp.productCircularNumber =p.MSD_CORE_Product_Circular__c;
                    productWrp.catalogNumber =p.MSD_CORE_Catalog_Number__c;
                    productWrp.modelNumber =p.MSD_CORE_Model_Number__c;
                    productWrp.serialNumber =p.MSD_CORE_Serial_Number__c;
                    productWrp.uniqueIdentifier =p.MSD_CORE_Unique_Identifier__c;
                    productWrp.operatorOfDevice=p.MSD_Core_Product_Operator_of_Device__c;
                    prodWrpList.add(productWrp);  
                }
                caseInfoWrp.integrationLogProdIDs = productIDs;
                wrp.x04products = prodWrpList;  
            }
            
            // CaseNotes
            if(!caseNoteMap.isEmpty() &&  caseNoteMap.get(cs.id) != null)
            {
                List<MSD_CORE_Note__c> nList = caseNoteMap.get(cs.Id);
                caseInfoWrp.integrationLogNotesCount = nList.size();
                for(MSD_CORE_Note__c n : nList)
                {
                    noteIDs += n.Id + '|';
                    MSD_CORE_AERequest.CaseNote caseNoteWrp = new MSD_CORE_AERequest.CaseNote();
                    caseNoteWrp.noteID = n.Id;
                    caseNoteWrp.note = n.MSD_CORE_Note__c;
                    caseNoteWrp.createdDateTimeUtc = n.MSD_CORE_Create_Date_Time__c;    
                    nWrpList.add(caseNoteWrp);  
                }
                caseInfoWrp.integrationLogNotesIDs = noteIDs;
                wrp.x03caseNotes = nWrpList;
            } 
            
            // Attachments
            if(!caseAttachMap.isEmpty() && caseAttachMap.get(cs.id) != null)
            {
                List<Attachment> attList = caseAttachMap.get(cs.id); 
                caseInfoWrp.integrationLogAttCount = attList.size();
                for(Attachment a : attList)
                {
                    attachmentIDs += a.id + '|'; 
                    MSD_CORE_AERequest.Attachment attachmentWrp = new MSD_CORE_AERequest.Attachment();
                    attachmentWrp.id = a.Id;
                    attachmentWrp.name = a.Name;
                    attachmentWrp.bodyLength = a.BodyLength;
                    attachmentWrp.parentId = a.ParentId;
                    attachmentWrp.createdDateTimeUtc = a.CreatedDate;
                    attachmentWrp.lastModifiedDateTimeUtc = a.LastModifiedDate;
                    attachmentWrp.isDeleted = a.IsDeleted;
                    attWrpList.add(attachmentWrp);  
                }
                caseInfoWrp.integrationLogAttIDs = attachmentIDs;
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
                            MSD_CORE_AERequest.ChatTranscript chatTransWrp = new MSD_CORE_AERequest.ChatTranscript();
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
            wrp.x12caseInfo = caseInfoWrp;
            
            jsonWrpList.add(wrp);   
        }
        system.debug('@@@@@@jsonWrpList'+jsonWrpList);
        return jsonWrpList;
    }
    
    
    public static void submitAeToPv(List<object> scope,DateTime currentJobRunDateTime,MSD_CORE_SC_RTB_Request_Info__mdt  reqInfo,List<MSD_CORE_PIR_Request__c> aeRequests)
    {
        MSD_CORE_Aws_Api__c  awsApi = awsApiSettings();
        String requestId = generateNewRequestId();
        List<MSD_CORE_AERequest.ServiceCloudSafetyCase> lstWrap = (List<MSD_CORE_AERequest.ServiceCloudSafetyCase>)scope;
        MSD_CORE_AERequest aeRequest = new MSD_CORE_AERequest(reqInfo, lstWrap, requestId);
        System.debug('aeRequest>>>>>>>>+++'+aeRequest);  
        Http h = new Http();
        HttpRequest req; 
        HttpResponse res=null;        
        try{
            String aeDataJson = JSON.serialize(aeRequest,false);
            req = buildWebServiceRequest(aeDataJson, awsApi);
            res = invokeAwsApi(h,req); 
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
            {
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
        return  MSD_CORE_SC_RTB_Request_Info__mdt.getInstance('AE_AE_PQC');
    } 
    
    //builds request object 
    public static HttpRequest buildWebServiceRequest(String aeDataJson, MSD_CORE_Aws_Api__c awsApi) {
        
        HttpRequest req = new HttpRequest();
        system.debug('building webservice request..');
        system.debug('HostName:' + awsApi.Hostname__c);
        req.setHeader('x-api-key', awsApi.Api_Key__c);
        req.setEndpoint('https://' + awsApi.Hostname__c + awsApi.AE_Endpoint_Url__c);
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
    public static void saveCaseToIntegrationLog(MSD_CORE_AERequest aeRequest,DateTime processedDateTime){
        try
        {
            List<MSD_CORE_AERequest.ServiceCloudSafetyCase> caseList = aeRequest.x01ServiceCloudSafetyCase;
            List<MSD_CORE_Integration_Logs__c> integrationLog = new List<MSD_CORE_Integration_Logs__c>();
            String noteIDs;
            String attachmentIDs;
            for(MSD_CORE_AERequest.ServiceCloudSafetyCase c: caseList){
                system.debug('@@@@@@@@@@cLog'+c);
                MSD_CORE_Integration_Logs__c log = new MSD_CORE_Integration_Logs__c();
                log.MSD_CORE_Case__c = c.x12caseInfo.caseID;
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
    public static void updateCaseIntegrationStatus(MSD_CORE_AERequest aeRequest, DateTime processedDateTime)
    {
        system.debug('@@@@@processedDateTime'+processedDateTime);
        try{
            List<MSD_CORE_AERequest.ServiceCloudSafetyCase> caseList = aeRequest.x01ServiceCloudSafetyCase;
            List<Case> updateCase = new List<Case>();
            List<MSD_CORE_Note__c> updateCaseNotes = new List<MSD_CORE_Note__c>();
            for(MSD_CORE_AERequest.ServiceCloudSafetyCase ca: caseList)
            {
                if(ca.x12caseInfo != null)
                {
                    case c =  new case();
                    c.Id = ca.x12caseInfo.caseID;
                    c.MSD_CORE_Integration_Processed_Dt__c = processedDateTime;
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
    public static void saveRequestStatus(MSD_CORE_SC_RTB_Request_Info__mdt reqInfo,MSD_CORE_Aws_Api__c awsApi, String requestId,MSD_CORE_AERequest aeRequest, HttpResponse res,String sourceSystem, String error){
        List<String> caseIdList = new List<String>();
        List<MSD_CORE_AERequest.ServiceCloudSafetyCase> caseList =new List<MSD_CORE_AERequest.ServiceCloudSafetyCase>();
        if(aeRequest != null)
        {
            caseList = aeRequest.x01ServiceCloudSafetyCase;
        }
        for(MSD_CORE_AERequest.ServiceCloudSafetyCase ca: caseList)
        {
            if(ca.x12caseInfo != null)
            {
                caseIdList.add(ca.x12caseInfo.caseID);
            }
        }
        String status = '';
        String msg = '';
        if(res == null){
            status = reqInfo.Request_Error__c;// REQ_STATUS_ERROR;
            msg = 'Error submitting AE data to RTB/PV:-' + error;
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
            pirReq.Case_Id__c = srcId;
            pirReq.Request_Id__c = requestId;
            pirReq.Message__c = msg;
            pirReq.MSD_CORE_Case_Type__c = 'AE';
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
            msg = 'Error submitting AE data to RTB/PV:-' + error;
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