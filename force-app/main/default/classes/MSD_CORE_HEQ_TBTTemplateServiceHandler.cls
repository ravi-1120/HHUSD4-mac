global class MSD_CORE_HEQ_TBTTemplateServiceHandler { 
    
    global static void lockDesign(String jobCode) {
        List<MSD_CORE_HEQ_Design_Metadata__c> lstOfDesignUsed = new List<MSD_CORE_HEQ_Design_Metadata__c>();
        
        lstOfDesignUsed = [SELECT Id, MSD_CORE_Status__c FROM MSD_CORE_HEQ_Design_Metadata__c WHERE MSD_CORE_Job_Code__c =:jobCode];
        for(MSD_CORE_HEQ_Design_Metadata__c rec : lstOfDesignUsed ) {
            rec.MSD_CORE_Status__c = 'IN_USE';
        }
        UPDATE lstOfDesignUsed;
    }
    
    global static MSD_CORE_HEQ_TemplateServiceDispatcher.ResponseWrapper getTemplateById(Map<string, object> requestParamsMap) {
        
        Boolean breakOut = false;
        MSD_CORE_HEQ_TemplateServiceDispatcher.ResponseWrapper res;
        String userId = requestParamsMap.get('user_id') != NULL? (String)requestParamsMap.get('user_id'):'';
        String templateId = requestParamsMap.get('template_id') != NULL? (String)requestParamsMap.get('template_id'):'';
        String whereClause = '';
        
        System.debug('### userId '+userId);
        System.debug('### templateId '+templateId);
        
        
        if (String.isNotBlank(templateId)) {            
            whereClause = 'Id = : templateId ';            
        } else {
            res = new MSD_CORE_HEQ_TemplateServiceDispatcher.ResponseWrapper(400, JSON.serialize(new Map<String, Object>{'error' => 'Missing required parameter: templateId'}));
            breakOut = true;
        } 
        
        if (String.isNotBlank(userId) && !breakOut) {
            whereClause += ' AND MSD_CORE_User_Id__c = : userId ';
        }
        
        System.debug('### whereClause '+whereClause);
        System.debug('### breakout '+breakout);
        
        if(!breakout && String.isNotBlank(whereClause) ) {
            
            try {
                String soqlQuery = 'SELECT Id, MSD_CORE_Job_Code__c, MSD_CORE_User_Id__c, MSD_CORE_HEQ_Template_Id__c, MSD_CORE_Template_Author_Name__c, MSD_CORE_Template_Approver__c, Template_Approved_Date__c, MSD_CORE_HEQ_Template_Submitted_Date__c, ';
                soqlQuery += ' Name, MSD_CORE_HEQ_Template_Language__c, MSD_CORE_Status__c, MSD_CORE_HEQ_Comments__c, MSD_CORE_Thumbnail_URL__c ';
                soqlQuery += ' FROM MSD_CORE_HEQ_Template_File_Metadata__c WHERE ' +whereClause;
                
                Set<Id> setOfTempMetadataIds = new Set<Id>();
                Set<Id> setOfTempModuleIds = new Set<Id>();
                List<MSD_CORE_HEQ_Template_File_Metadata__c> lstOfFileMetadata = new List<MSD_CORE_HEQ_Template_File_Metadata__c>();
                List<MSD_CORE_HEQ_Template_File_Section__c> lstOfSections = new List<MSD_CORE_HEQ_Template_File_Section__c>();
                List<MSD_CORE_HEQ_Template_File_Mapping__c> lstOfSectionModules = new List<MSD_CORE_HEQ_Template_File_Mapping__c>();
                List<MSD_CORE_HEQ_Template_Module_Config__c> lstOfConfigs =  new List<MSD_CORE_HEQ_Template_Module_Config__c>();
                System.debug('### soqlQuery '+soqlQuery);
                lstOfFileMetadata = Database.query(soqlQuery);
                
                System.debug('### lstOfFileMetadata '+lstOfFileMetadata);
                
                for(MSD_CORE_HEQ_Template_File_Metadata__c rec : lstOfFileMetadata ) {
                    setOfTempMetadataIds.add(rec.Id);
                }
                System.debug('### setOfTempMetadataIds '+setOfTempMetadataIds);
                if(setOfTempMetadataIds.size()>0) {
                    lstOfSections = [SELECT Id, MSD_CORE_HEQ_Section_Id__c,MSD_CORE_HEQ_Type__c, MSD_COR_HEQ_Element_URL__c, MSD_CORE_HEQ_Original_Element_Url__c,
                                     MSD_CORE_HEQ_X_Coordinate__c, MSD_CORE_HEQ_Y_Coordinate__c, MSD_CORE_HEQ_Element_Name__c, 
                                     MSD_CORE_HEQ_Width__c, MSD_CORE_HEQ_Height__c, MSD_CORE_HEQ_Customizable__c, MSD_CORE_HEQ_Template_Module__c, MSD_CORE_Page_Number__c
                                     FROM MSD_CORE_HEQ_Template_File_Section__c
                                     WHERE MSD_CORE_HEQ_Template_File_Metadata__c IN: setOfTempMetadataIds];
                    
                    lstOfSectionModules = [SELECT Id, MSD_CORE_HEQ_Template_Module__c, MSD_CORE_HEQ_Zone_Id__c, 
                                           MSD_CORE_HEQ_Template_File_Section__r.MSD_CORE_HEQ_Template_File_Metadata__c, 
                                           MSD_CORE_HEQ_Module_Name__c, MSD_CORE_HEQ_Asset_Link__c,
                                           MSD_CORE_HEQ_Template_Module__r.MSD_CORE_HEQ_Module_Id__c 
                                           FROM MSD_CORE_HEQ_Template_File_Mapping__c
                                           WHERE MSD_CORE_HEQ_Template_File_Section__r.MSD_CORE_HEQ_Template_File_Metadata__c IN: setOfTempMetadataIds];
                    
                    lstOfConfigs = [SELECT MSD_CORE_Template_File_Metadata__c, MSD_CORE_Label__c, 
                                    MSD_CORE_Type__c, MSD_CORE_Has_Images__c, MSD_CORE_Help_Text__c, MSD_CORE_HEQ_Number_Of_Selection__c, 
                                    MSD_CORE_Validation_Error__c, Id, (SELECT Id, MSD_CORE_Checked__c, MSD_CORE_Label__c, 
                                                                       Order__c, MSD_CORE_HEQ_Option_Id__c, MSD_CORE_Thumbnail__c FROM 
                                                                       HEQ_Template_Module_Options__r), (SELECT Id, MSD_CORE_HEQ_Module_Id__c, MSD_CORE_HEQ_Resource_Type__c, Name, MSD_CORE_HEQ_Asset_Links__c  FROM Template_Modules__r) 
                                    FROM MSD_CORE_HEQ_Template_Module_Config__c 
                                    WHERE MSD_CORE_Template_File_Metadata__c IN: setOfTempMetadataIds]; 
                    System.debug('### lstOfFileMetadata '+lstOfFileMetadata);
                    System.debug('### lstOfSections '+lstOfSections);
                    System.debug('### lstOfSectionModules '+lstOfSectionModules);
                    System.debug('### lstOfConfigs '+lstOfConfigs);
                    res = new MSD_CORE_HEQ_TemplateServiceDispatcher.ResponseWrapper(200, TemplateConfigWrapper.createWrapper(lstOfFileMetadata, lstOfSections, lstOfSectionModules, lstOfConfigs));
                    
                } else {
                    res = new MSD_CORE_HEQ_TemplateServiceDispatcher.ResponseWrapper(200, JSON.serialize(new Map<String, Object>{'error' => 'No records found'}));
                }
                
            } catch(Exception ex) {
                // Handle any exceptions and return error response
                res = new MSD_CORE_HEQ_TemplateServiceDispatcher.ResponseWrapper(500, JSON.serialize(new Map<String, Object>{'error:' => ex.getMessage(),'\nerrorStackTrace:' => ex.getStackTraceString()}));
            }
        }        
        return res; 
    }
    
    global static MSD_CORE_HEQ_TemplateServiceDispatcher.ResponseWrapper createTemplate(Map<string, object> requestParamsMap) {
        
        // Parse the incoming request parameters
        
        MSD_CORE_HEQ_TemplateServiceDispatcher.ResponseWrapper res;
        
        String jobCode = requestParamsMap.get('job_code') != NULL? (String)requestParamsMap.get('job_code'):'';
        String userId  = requestParamsMap.get('user_id') != NULL? (String)requestParamsMap.get('user_id'):'';
        String templateName  = requestParamsMap.get('template_name' ) != NULL? (String)requestParamsMap.get('template_name'):'';
        
        if (String.isNotBlank(jobCode) && String.isNotBlank(userId)) {
            
            try {
                List<MSD_CORE_HEQ_Design_Metadata__c> lstOfDesignUsed = new List<MSD_CORE_HEQ_Design_Metadata__c>();
                lstOfDesignUsed = [SELECT Id, MSD_CORE_Status__c FROM MSD_CORE_HEQ_Design_Metadata__c WHERE MSD_CORE_Job_Code__c =:jobCode AND MSD_CORE_Status__c != 'EXPIRED'];
                if(lstOfDesignUsed.size()>0) {
                    MSD_CORE_HEQ_Template_File_Metadata__c newTemplate = new MSD_CORE_HEQ_Template_File_Metadata__c();
                    newTemplate.MSD_CORE_Job_Code__c = jobCode;
                    newTemplate.MSD_CORE_Status__c = 'DRAFT';
                    newTemplate.MSD_CORE_User_Id__c = userId;
                    newTemplate.MSD_CORE_HEQ_Design_Metadata__c = lstOfDesignUsed.size()>0?lstOfDesignUsed[0].Id:NULL;
                    newTemplate.Name = templateName;
                    newTemplate.MSD_CORE_HEQ_Type__c = 'MASTER';
                    INSERT newTemplate;
                    
                    MSD_CORE_HEQ_Template_File_Metadata__c templateRec = [SELECT Id, Name,
                                                                          MSD_CORE_Job_Code__c, 
                                                                          MSD_CORE_User_Id__c, 
                                                                          MSD_CORE_Status__c FROM MSD_CORE_HEQ_Template_File_Metadata__c
                                                                          WHERE Id=: newTemplate.Id]; 
                    
                    
                    Map<String, Object> response = new Map<String, Object>();
                    response.put('job_code', templateRec.MSD_CORE_Job_Code__c);
                    response.put('user_id', templateRec.MSD_CORE_User_Id__c);
                    response.put('template_id', templateRec.Id);                
                    response.put('template_status', templateRec.MSD_CORE_Status__c);
                    response.put('template_name', templateRec.Name);
                    
                    res = new MSD_CORE_HEQ_TemplateServiceDispatcher.ResponseWrapper(201, JSON.serialize(response));
                    lockDesign(jobCode);
                } else {
                    res = new MSD_CORE_HEQ_TemplateServiceDispatcher.ResponseWrapper(200, JSON.serialize(new Map<String, Object>{'error' => 'Please make sure the Design Job Code is Valid or if Valid then Design is not Expired!'}));
                }
                
                
            } catch (Exception e) {
                res = new MSD_CORE_HEQ_TemplateServiceDispatcher.ResponseWrapper(500, JSON.serialize(new Map<String, Object>{'error' => e.getMessage()}));
            }
        } else {
            // Return error if parameters are missing
            res = new MSD_CORE_HEQ_TemplateServiceDispatcher.ResponseWrapper(400, JSON.serialize(new Map<String, Object>{'error' => 'Missing required parameters: job_code and/or user_id'}));
        }
        
        return res;
    }
    
    global static MSD_CORE_HEQ_TemplateServiceDispatcher.ResponseWrapper getListOfTemplates(Map<string, object> requestParamsMap) {
        
        MSD_CORE_HEQ_TemplateServiceDispatcher.ResponseWrapper res;
        String userId  = requestParamsMap.get('user_id') != NULL? (String)requestParamsMap.get('user_id'):'';
        
        if (String.isNotBlank(userId)) {            
            try {
                
                List<MSD_CORE_HEQ_Template_File_Metadata__c> lstOfFileMetadata = new List<MSD_CORE_HEQ_Template_File_Metadata__c>();
                List<MSD_CORE_HEQ_Template_File_Mapping__c> lstOfMappings = new List<MSD_CORE_HEQ_Template_File_Mapping__c>();
                List<MSD_CORE_HEQ_Template_File_Section__c> lstOfSections = new List<MSD_CORE_HEQ_Template_File_Section__c>();
                List<MSD_CORE_HEQ_Template_Module_Config__c> lstOfConfigs = new List<MSD_CORE_HEQ_Template_Module_Config__c>();
                
                Set<Id> setOfTempMetadataIds = new Set<Id>();
                
                Map<Id, MSD_CORE_HEQ_Template_File_Metadata__c> mapOfFileMetadata = new Map<Id, MSD_CORE_HEQ_Template_File_Metadata__c>();
                Map<String, MSD_CORE_HEQ_Template_File_Section__c> mapOfSections = new Map<String, MSD_CORE_HEQ_Template_File_Section__c>();
                Map<String, MSD_CORE_HEQ_Template_File_Mapping__c> mapOfMappings = new Map<String, MSD_CORE_HEQ_Template_File_Mapping__c>();
                Map<String, MSD_CORE_HEQ_Template_Module_Config__c> mapOfConfigs = new Map<String, MSD_CORE_HEQ_Template_Module_Config__c>();
                
                lstOfFileMetadata = [SELECT Id, MSD_CORE_Job_Code__c, MSD_CORE_User_Id__c, MSD_CORE_HEQ_Template_Id__c,MSD_CORE_Thumbnail_URL__c,
                                     Name, MSD_CORE_HEQ_Template_Language__c, MSD_CORE_Status__c, 
                                     MSD_CORE_Template_Author_Name__c, MSD_CORE_Template_Approver__c, Template_Approved_Date__c, MSD_CORE_HEQ_Template_Submitted_Date__c 
                                     FROM MSD_CORE_HEQ_Template_File_Metadata__c WHERE MSD_CORE_User_Id__c = : userId ORDER BY LASTMODIFIEDDATE DESC];
                for(MSD_CORE_HEQ_Template_File_Metadata__c rec : lstOfFileMetadata) {
                    mapOfFileMetadata.put(rec.Id, rec);
                    setOfTempMetadataIds.add(rec.Id);
                }
                
                if(setOfTempMetadataIds.size()>0) {
                    lstOfSections = [SELECT Id, MSD_CORE_HEQ_Section_Id__c,MSD_CORE_HEQ_Type__c, MSD_COR_HEQ_Element_URL__c, MSD_CORE_HEQ_Original_Element_Url__c,
                                     MSD_CORE_HEQ_X_Coordinate__c, MSD_CORE_HEQ_Y_Coordinate__c, MSD_CORE_HEQ_Element_Name__c, MSD_CORE_HEQ_Template_File_Metadata__c,
                                     MSD_CORE_HEQ_Width__c, MSD_CORE_HEQ_Height__c, MSD_CORE_HEQ_Customizable__c, MSD_CORE_HEQ_Template_Module__c, MSD_CORE_Page_Number__c 
                                     FROM MSD_CORE_HEQ_Template_File_Section__c
                                     WHERE MSD_CORE_HEQ_Template_File_Metadata__c IN: setOfTempMetadataIds];
                    
                    lstOfMappings = [SELECT Id, MSD_CORE_HEQ_Template_Module__c, MSD_CORE_HEQ_Zone_Id__c, 
                                     MSD_CORE_HEQ_Template_File_Section__r.MSD_CORE_HEQ_Section_Id__c,
                                     MSD_CORE_HEQ_Template_File_Section__r.MSD_CORE_HEQ_Template_File_Metadata__c,
                                     MSD_CORE_HEQ_Module_Name__c, MSD_CORE_HEQ_Asset_Link__c,
                                     MSD_CORE_HEQ_Template_Module__r.MSD_CORE_HEQ_Module_Id__c 
                                     FROM MSD_CORE_HEQ_Template_File_Mapping__c
                                     WHERE MSD_CORE_HEQ_Template_File_Section__r.MSD_CORE_HEQ_Template_File_Metadata__c IN: setOfTempMetadataIds];
                    
                    for(MSD_CORE_HEQ_Template_File_Section__c rec : lstOfSections) {
                        mapOfSections.put(rec.MSD_CORE_HEQ_Section_Id__c, rec);
                    }
                    
                    for(MSD_CORE_HEQ_Template_File_Mapping__c rec : lstOfMappings) {
                        mapOfMappings.put(rec.MSD_CORE_HEQ_Template_File_Section__r.MSD_CORE_HEQ_Section_Id__c, rec);
                    }
                    
                    lstOfConfigs = [SELECT MSD_CORE_Template_File_Metadata__c, MSD_CORE_Label__c, 
                                    MSD_CORE_Type__c, MSD_CORE_Has_Images__c, MSD_CORE_Help_Text__c, MSD_CORE_HEQ_Number_Of_Selection__c,
                                    MSD_CORE_Validation_Error__c, Id, MSD_CORE_Template_File_Metadata__r.Id, 
                                    (SELECT Id, MSD_CORE_Checked__c, MSD_CORE_Label__c, Order__c, MSD_CORE_HEQ_Option_Id__c, 
                                     MSD_CORE_Thumbnail__c FROM HEQ_Template_Module_Options__r) 
                                    FROM MSD_CORE_HEQ_Template_Module_Config__c 
                                    WHERE MSD_CORE_Template_File_Metadata__c IN: setOfTempMetadataIds];     
                    
                    for(MSD_CORE_HEQ_Template_Module_Config__c rec : lstOfConfigs) {
                        mapOfConfigs.put(rec.MSD_CORE_Template_File_Metadata__r.Id, rec);
                    }
                    
                    res = new MSD_CORE_HEQ_TemplateServiceDispatcher.ResponseWrapper(200, TemplateConfigWrapper.createListOfWrapper(mapOfFileMetadata, mapOfSections, mapOfMappings, mapOfConfigs));
                    
                } else {
                    res = new MSD_CORE_HEQ_TemplateServiceDispatcher.ResponseWrapper(200, JSON.serialize(new Map<String, Object>{'error' => 'No records found'}));
                }
                
                
                
            } catch (Exception e) {
                res = new MSD_CORE_HEQ_TemplateServiceDispatcher.ResponseWrapper(500, JSON.serialize(new Map<String, Object>{'error' => e.getMessage()}));
            }
        } else {
            // Return error if parameters are missing
            res = new MSD_CORE_HEQ_TemplateServiceDispatcher.ResponseWrapper(400, JSON.serialize(new Map<String, Object>{'error' => 'Missing required parameters: job_code and/or user_id'}));
        }
        
        return res;
    }
    
    global static MSD_CORE_HEQ_TemplateServiceDispatcher.ResponseWrapper updateTemplate(String reqJSON) {
        
        MSD_CORE_HEQ_TemplateServiceDispatcher.ResponseWrapper res;
        TemplateConfigWrapper wrapperinstance = (TemplateConfigWrapper)JSON.deserialize(reqJSON, TemplateConfigWrapper.class);
        String sfTemplateId  = wrapperinstance.template_id!= NULL? wrapperinstance.template_id:'';
        
        if (String.isNotBlank(sfTemplateId)) {
            try {                
                List<MSD_CORE_HEQ_Template_File_Metadata__c> lstOfFileMetadata = new List<MSD_CORE_HEQ_Template_File_Metadata__c>();
                List<MSD_CORE_HEQ_Template_File_Mapping__c> lstOfMappings = new List<MSD_CORE_HEQ_Template_File_Mapping__c>();
                List<MSD_CORE_HEQ_Template_File_Section__c> lstOfSections = new List<MSD_CORE_HEQ_Template_File_Section__c>();
                List<MSD_CORE_HEQ_Template_Module_Config__c> lstModuleConfig = new List<MSD_CORE_HEQ_Template_Module_Config__c>();
                
                Set<String> setOfZoneIds = new Set<String>();
                Set<String> setOfModuleIds = new Set<String>();
                Set<String> setOfExistingSectionIds = new Set<String>();
                Map<String, String> mapOfZoneIdAndSectionIds = new Map<String, String>();
                Map<String, String> mapOfModuleIdAndModuleIds = new Map<String, String>();
                
                lstOfFileMetadata = [SELECT Id, MSD_CORE_Job_Code__c, MSD_CORE_User_Id__c, MSD_CORE_HEQ_Template_Id__c,
                                     Name, MSD_CORE_HEQ_Template_Language__c, MSD_CORE_Status__c, Template_Approved_Date__c, MSD_CORE_HEQ_Template_Submitted_Date__c,
                                     MSD_CORE_HEQ_Comments__c, MSD_CORE_Thumbnail_URL__c 
                                     FROM MSD_CORE_HEQ_Template_File_Metadata__c WHERE Id = :sfTemplateId ];
                
                System.debug('### sfTemplateId '+sfTemplateId);
                System.debug('### lstOfFileMetadata '+lstOfFileMetadata);
                
                if(lstOfFileMetadata.size()>0) {
                    
                    lstOfFileMetadata[0].MSD_CORE_Job_Code__c = wrapperinstance.job_code ;
                    lstOfFileMetadata[0].MSD_CORE_User_Id__c = wrapperinstance.user_id ;
                    lstOfFileMetadata[0].Name = wrapperinstance.design_name ;
                    lstOfFileMetadata[0].MSD_CORE_HEQ_Template_Language__c = wrapperinstance.template_language ;
                    lstOfFileMetadata[0].MSD_CORE_Status__c = wrapperinstance.status ;
                    lstOfFileMetadata[0].MSD_CORE_HEQ_Comments__c = wrapperinstance.comments ;
                    lstOfFileMetadata[0].MSD_CORE_Thumbnail_URL__c = wrapperinstance.thumbnail ;
                    lstOfFileMetadata[0].MSD_CORE_Template_Author_Name__c = wrapperinstance.template_author ;
                    lstOfFileMetadata[0].MSD_CORE_Template_Approver__c = wrapperinstance.template_approver ;
                    
                    if(wrapperinstance.status != NULL && wrapperinstance.status != '') {
                        lstOfFileMetadata[0].Template_Approved_Date__c =               (String.valueOf(wrapperinstance.status).toLowerCase() == 'approved'  && ( lstOfFileMetadata[0].Template_Approved_Date__c == ''|| lstOfFileMetadata[0].Template_Approved_Date__c == NULL)  )? String.valueOf((DateTime.now()).format('MM/dd/yy hh:mm a')): lstOfFileMetadata[0].Template_Approved_Date__c;
                        lstOfFileMetadata[0].MSD_CORE_HEQ_Template_Submitted_Date__c = (String.valueOf(wrapperinstance.status).toLowerCase() == 'submitted' && ( lstOfFileMetadata[0].MSD_CORE_HEQ_Template_Submitted_Date__c == ''|| lstOfFileMetadata[0].MSD_CORE_HEQ_Template_Submitted_Date__c == NULL))?String.valueOf((DateTime.now()).format('MM/dd/yy hh:mm a')): lstOfFileMetadata[0].MSD_CORE_HEQ_Template_Submitted_Date__c;
                    }                    
                    
                    UPDATE lstOfFileMetadata[0];
                    
                    List<MSD_CORE_HEQ_Template_File_Section__c> lstOfFileSectionsToBeDeleted = new List<MSD_CORE_HEQ_Template_File_Section__c>();
                    lstOfFileSectionsToBeDeleted = [SELECT Id, MSD_CORE_HEQ_Section_Id__c FROM MSD_CORE_HEQ_Template_File_Section__c where MSD_CORE_HEQ_Template_File_Metadata__c =:sfTemplateId];
                    System.debug('### wrapperinstance '+wrapperinstance);
                    System.debug('### wrapperinstance.canvas_configuration '+wrapperinstance.canvas_configuration);
                    if(wrapperinstance.canvas_configuration != NULL && wrapperinstance.canvas_configuration.size() > 0){
                        for(TemplateConfigWrapper.Canvas_configuration rec : wrapperinstance.canvas_configuration) {
                            MSD_CORE_HEQ_Template_File_Section__c recToBeCreated = new MSD_CORE_HEQ_Template_File_Section__c();
                            recToBeCreated.MSD_CORE_HEQ_Section_Id__c = String.ValueOf(rec.id);
                            recToBeCreated.MSD_CORE_HEQ_Type__c = String.ValueOf(rec.type);
                            recToBeCreated.MSD_CORE_HEQ_X_Coordinate__c = String.ValueOf(rec.x);
                            recToBeCreated.MSD_CORE_HEQ_Y_Coordinate__c = String.ValueOf(rec.y);
                            recToBeCreated.MSD_CORE_HEQ_Element_Name__c = String.ValueOf(rec.element_name);
                            recToBeCreated.MSD_COR_HEQ_Element_URL__c= String.ValueOf(rec.element_url);
                            recToBeCreated.MSD_CORE_HEQ_Width__c= String.ValueOf(rec.width);
                            recToBeCreated.MSD_CORE_HEQ_Height__c= String.ValueOf(rec.height);
                            recToBeCreated.MSD_CORE_HEQ_Customizable__c= String.ValueOf(rec.customizable).toLowerCase() == 'true'?true:false;
                            recToBeCreated.MSD_CORE_Page_Number__c= String.ValueOf(rec.page_number);
                            recToBeCreated.MSD_CORE_HEQ_Template_File_Metadata__c = sfTemplateId;
                            lstOfSections.add(recToBeCreated);
                        }
                        
                        INSERT lstOfSections;
                    }
                    
                    if(lstOfFileSectionsToBeDeleted.size() >0) {
                        DELETE lstOfFileSectionsToBeDeleted;
                    }                    
                    
                    System.debug('### wrapperinstance '+wrapperinstance);
                    System.debug('### wrapperinstance.module_configuration '+wrapperinstance.module_configuration);
                    Map<String, String> mapOfConfigIdAndRecordId = new Map<String, String>();
                    Map<String, String> mapOfTemplateModuleIdAndRecordId = new Map<String, String>();
                    Map<String, String> mapOfOptionIdAndConfigId = new Map<String, String>();
                    Map<String, String> mapOfTemplateModuleIdAndConfigId = new Map<String, String>();
                    Map<String, List<String>> mapOfTemplateModuleIdAndAssetsId = new Map<String, List<String>>();
                    List<MSD_CORE_HEQ_Template_Module_Options__c> lstOptions = new List<MSD_CORE_HEQ_Template_Module_Options__c>();
                    List<MSD_CORE_HEQ_Template_Module__c> lstOfModulesToBeCreated = new List<MSD_CORE_HEQ_Template_Module__c>();
                    List<MSD_CORE_HEQ_Template_Module_Config__c> lstOfModuleConfigToBeDeleted = new List<MSD_CORE_HEQ_Template_Module_Config__c>();
                    Set<Id> setOfModuleConfigIdsToBeDeleted = new Set<Id>();
                    lstOfModuleConfigToBeDeleted = [SELECT Id 
                                                    FROM MSD_CORE_HEQ_Template_Module_Config__c
                                                    WHERE MSD_CORE_Template_File_Metadata__c =: sfTemplateId ];
                    for(MSD_CORE_HEQ_Template_Module_Config__c rec : lstOfModuleConfigToBeDeleted) {
                        setOfModuleConfigIdsToBeDeleted.add(rec.Id);
                    }
                    List<MSD_CORE_HEQ_Template_Module_Options__c> lstOfModuleConfigSectionsToBeDeleted = new List<MSD_CORE_HEQ_Template_Module_Options__c>();
                    lstOfModuleConfigSectionsToBeDeleted = [SELECT Id 
                                                            FROM MSD_CORE_HEQ_Template_Module_Options__c
                                                            WHERE MSD_CORE_Template_Module_Configuration__c IN:setOfModuleConfigIdsToBeDeleted];
                    
                    
                    
                    if(wrapperinstance.module_configuration != NULL && wrapperinstance.module_configuration.size() > 0){
                        for(TemplateConfigWrapper.Module_Configuration moduleConfigRec : wrapperinstance.module_configuration) {
                            MSD_CORE_HEQ_Template_Module_Config__c recToBeCreated = new MSD_CORE_HEQ_Template_Module_Config__c();
                            recToBeCreated.MSD_CORE_Label__c = moduleConfigRec.label;
                            recToBeCreated.MSD_CORE_Type__c = moduleConfigRec.type;
                            recToBeCreated.MSD_CORE_Help_Text__c = moduleConfigRec.helpText;
                            recToBeCreated.MSD_CORE_Validation_Error__c = moduleConfigRec.validationError;
                            recToBeCreated.MSD_CORE_Has_Images__c = moduleConfigRec.hasImages;
                            recToBeCreated.MSD_CORE_Template_File_Metadata__c = sfTemplateId;
                            recToBeCreated.MSD_CORE_HEQ_Template_Module_Config_Id__c = moduleConfigRec.id;
                            recToBeCreated.MSD_CORE_HEQ_Number_Of_Selection__c = moduleConfigRec.noOfSelection;
                            lstModuleConfig.add(recToBeCreated);
                            for(TemplateConfigWrapper.Options optionWrapperRec : moduleConfigRec.options){
                                MSD_CORE_HEQ_Template_Module_Options__c optionRec = new MSD_CORE_HEQ_Template_Module_Options__c();
                                optionRec.MSD_CORE_Checked__c = Boolean.ValueOf(optionWrapperRec.checked);
                                optionRec.MSD_CORE_Label__c = optionWrapperRec.label;
                                optionRec.Order__c = optionWrapperRec.order;
                                optionRec.MSD_CORE_Thumbnail__c = optionWrapperRec.thumbnail;
                                optionRec.MSD_CORE_HEQ_Option_Id__c = optionWrapperRec.id;
                                mapOfOptionIdAndConfigId.put(optionWrapperRec.id, moduleConfigRec.id);
                                lstOptions.add(optionRec);
                            }
                            MSD_CORE_HEQ_Template_Module__c recModuleToBeCreated = new MSD_CORE_HEQ_Template_Module__c();
                            recModuleToBeCreated.Name = moduleConfigRec.Module.name;
                            recModuleToBeCreated.MSD_CORE_HEQ_Module_Id__c = moduleConfigRec.Module.id;
                            recModuleToBeCreated.MSD_CORE_HEQ_Resource_Type__c = moduleConfigRec.Module.resource_type;
                            recModuleToBeCreated.MSD_CORE_HEQ_Asset_Links__c = String.join(moduleConfigRec.Module.assets, ';;');
                            lstOfModulesToBeCreated.add(recModuleToBeCreated);
                            mapOfTemplateModuleIdAndConfigId.put(moduleConfigRec.Module.id,moduleConfigRec.id);
                            mapOfTemplateModuleIdAndAssetsId.put(moduleConfigRec.Module.id, moduleConfigRec.Module.assets);
                        }
                        
                        if(lstModuleConfig.size() >0) {
                            INSERT lstModuleConfig;
                            
                            for(MSD_CORE_HEQ_Template_Module_Config__c rec : lstModuleConfig) {
                                mapOfConfigIdAndRecordId.put(rec.MSD_CORE_HEQ_Template_Module_Config_Id__c, rec.Id);
                            }
                            for(MSD_CORE_HEQ_Template_Module_Options__c rec : lstOptions) {
                                rec.MSD_CORE_Template_Module_Configuration__c = mapOfConfigIdAndRecordId.get(mapOfOptionIdAndConfigId.get(rec.MSD_CORE_HEQ_Option_Id__c));
                            }
                            if(lstOptions.size()>0) {
                                INSERT lstOptions;
                            } 
                            
                            for(MSD_CORE_HEQ_Template_Module__c rec : lstOfModulesToBeCreated) {
                                rec.HEQ_Template_Module_Configuration__c = mapOfConfigIdAndRecordId.get(mapOfTemplateModuleIdAndConfigId.get(rec.MSD_CORE_HEQ_Module_Id__c));
                            }
                            
                            if(lstOfModulesToBeCreated.size()>0) {
                                INSERT lstOfModulesToBeCreated;
                            }
                            
                            for(MSD_CORE_HEQ_Template_Module__c rec : lstOfModulesToBeCreated) {
                                mapOfTemplateModuleIdAndRecordId.put(rec.MSD_CORE_HEQ_Module_Id__c, rec.Id);
                            }
                            List<MSD_CORE_HEQ_Asset__c> lstOfAssetsHEQToBeCreated = new List<MSD_CORE_HEQ_Asset__c>();
                            for(String assetWrapperRec : mapOfTemplateModuleIdAndAssetsId.keySet()) {
                                for(String recToBeCreatedAssets : mapOfTemplateModuleIdAndAssetsId.get(assetWrapperRec)) {
                                    MSD_CORE_HEQ_Asset__c assetRecToBeCreated = new MSD_CORE_HEQ_Asset__c();
                                    assetRecToBeCreated.MSD_CORE_HEQ_Link__c = recToBeCreatedAssets;
                                    assetRecToBeCreated.MSD_CORE_HEQ_Template_Module__c = mapOfTemplateModuleIdAndRecordId.get(assetWrapperRec);
                                    lstOfAssetsHEQToBeCreated.add(assetRecToBeCreated);
                                }
                            }
                            if(lstOfAssetsHEQToBeCreated.size()>0) {
                                UPSERT lstOfModulesToBeCreated;
                            }
                        }                        
                    }  
                    
                    if(lstOfModuleConfigToBeDeleted.size() >0) {
                        //DELETE lstOfModuleConfigToBeDeleted; Joshi: Need to discuss with Rohan. Commented for now to avoid an error in the process.
                    }   
                    
                    if(lstOfModuleConfigSectionsToBeDeleted.size() >0) {
                        DELETE lstOfModuleConfigSectionsToBeDeleted;
                    }
                    
                    if(wrapperinstance != NULL && wrapperinstance.mappings != NULL){
                        for(TemplateConfigWrapper.Mappings recInnerTemp2 : wrapperinstance.mappings) {
                            setOfZoneIds.add(recInnerTemp2.zone_id);
                            setOfModuleIds.add(recInnerTemp2.module_id);
                        }
                        
                    }
                    
                    for(MSD_CORE_HEQ_Template_File_Section__c rec : [SELECT id, MSD_CORE_HEQ_Section_Id__c FROM MSD_CORE_HEQ_Template_File_Section__c WHERE MSD_CORE_HEQ_Section_Id__c IN:setOfZoneIds ]) {
                        mapOfZoneIdAndSectionIds.put(rec.MSD_CORE_HEQ_Section_Id__c, rec.Id);
                    }
                    
                    for(MSD_CORE_HEQ_Template_Module__c rec : [SELECT id, MSD_CORE_HEQ_Module_Id__c FROM MSD_CORE_HEQ_Template_Module__c WHERE MSD_CORE_HEQ_Module_Id__c IN:setOfModuleIds ]) {
                        mapOfModuleIdAndModuleIds.put(rec.MSD_CORE_HEQ_Module_Id__c, rec.Id);
                    }                    
                    
                    List<MSD_CORE_HEQ_Template_File_Mapping__c> lstOfFileMappingsToBeDELETED = new List<MSD_CORE_HEQ_Template_File_Mapping__c>();
                    lstOfFileMappingsToBeDELETED = [SELECT Id, MSD_CORE_HEQ_Zone_Id__c, MSD_CORE_HEQ_Template_Module__c, 
                                                    MSD_CORE_HEQ_Module_Name__c, MSD_CORE_HEQ_Template_Module__r.MSD_CORE_HEQ_Module_Id__c
                                                    FROM MSD_CORE_HEQ_Template_File_Mapping__c 
                                                    WHERE MSD_CORE_HEQ_Template_File_Section__r.MSD_CORE_HEQ_Template_File_Metadata__c = :sfTemplateId];
                    
                    if(wrapperinstance != NULL && wrapperinstance.mappings != NULL){
                        for(TemplateConfigWrapper.Mappings recInnerTemp2 : wrapperinstance.mappings) {
                            
                            MSD_CORE_HEQ_Template_File_Mapping__c recTemp = new MSD_CORE_HEQ_Template_File_Mapping__c();
                            recTemp.MSD_CORE_HEQ_Template_File_Section__c = mapOfZoneIdAndSectionIds.get(recInnerTemp2.zone_id);
                            recTemp.MSD_CORE_HEQ_Zone_Id__c = recInnerTemp2.zone_id;
                            recTemp.MSD_CORE_HEQ_Template_Module__c = mapOfModuleIdAndModuleIds.get(recInnerTemp2.module_id);//recInnerTemp2.MSD_CORE_HEQ_Template_Module__r.MSD_CORE_HEQ_Module_Id__c;
                            recTemp.MSD_CORE_HEQ_Module_Name__c = recInnerTemp2.module_name;
                            lstOfMappings.add(recTemp);
                        }
                    }
                    
                    INSERT lstOfMappings;
                    if(lstOfFileMappingsToBeDELETED.size()>0) {
                        DELETE lstOfFileMappingsToBeDELETED;    
                    }
                    
                    res = new MSD_CORE_HEQ_TemplateServiceDispatcher.ResponseWrapper(201, JSON.serialize('Success'));
                    System.debug('### res '+res);
                }  else {
                    res = new MSD_CORE_HEQ_TemplateServiceDispatcher.ResponseWrapper(200, JSON.serialize(new Map<String, Object>{'error' => 'No records found'}));
                }              
                
            } catch(Exception ex) {
                res = new MSD_CORE_HEQ_TemplateServiceDispatcher.ResponseWrapper(500, JSON.serialize(new Map<String, Object>{'error:' => ex.getMessage(),'\nerrorStackTrace:' => ex.getStackTraceString()}));
            }
        } else {
            // Return error if parameters are missing
            res = new MSD_CORE_HEQ_TemplateServiceDispatcher.ResponseWrapper(400, JSON.serialize(new Map<String, Object>{'error' => 'Missing required parameters: Template_Id'}));
        }
        return res;
    }
    
    global static void cloneTemplate(Id masterTemplateId, Id userId) {
        try {
            List<MSD_CORE_HEQ_Template_File_Mapping__c> lstOfMappings = new List<MSD_CORE_HEQ_Template_File_Mapping__c>();
            List<MSD_CORE_HEQ_Template_File_Section__c> lstOfSections = new List<MSD_CORE_HEQ_Template_File_Section__c>();
            List<MSD_CORE_HEQ_Template_File_Metadata__c> lstofFileMetadataCloned = new List<MSD_CORE_HEQ_Template_File_Metadata__c>();
            Map<String, String> mapOfZoneIdAndSectionIds = new Map<String, String>();
            Map<String, String> mapOfModuleIdAndModuleIds = new Map<String, String>();
            Set<String> setOfZoneIds = new Set<String>();
            Set<String> setOfModuleIds = new Set<String>();
            
            lstofFileMetadataCloned = [SELECT Id, Name, MSD_CORE_HEQ_Design_Metadata__r.Id, MSD_CORE_Job_Code__c,
                                       MSD_CORE_HEQ_Template_Language__c, MSD_CORE_HEQ_Comments__c,MSD_CORE_Thumbnail_URL__c
                                       FROM MSD_CORE_HEQ_Template_File_Metadata__c WHERE Id =:masterTemplateId ];
            
            MSD_CORE_HEQ_Template_File_Metadata__c newTemplate = new MSD_CORE_HEQ_Template_File_Metadata__c();
            newTemplate.MSD_CORE_Job_Code__c = lstofFileMetadataCloned.size()>0?lstofFileMetadataCloned[0].MSD_CORE_Job_Code__c:'';
            newTemplate.MSD_CORE_HEQ_Cloned_User__c = userId;
            newTemplate.MSD_CORE_HEQ_Type__c = 'Cloned';
            newTemplate.MSD_CORE_HEQ_Design_Metadata__c = lstofFileMetadataCloned.size()>0?lstofFileMetadataCloned[0].MSD_CORE_HEQ_Design_Metadata__r.Id:NULL;
            newTemplate.Name = lstofFileMetadataCloned.size()>0?lstofFileMetadataCloned[0].Name:'';
            newTemplate.MSD_CORE_Parent_Template__c = masterTemplateId;
            newTemplate.MSD_CORE_HEQ_Resource_Status__c = 'DRAFT';
            newTemplate.MSD_CORE_HEQ_Template_Language__c = lstofFileMetadataCloned.size()>0?lstofFileMetadataCloned[0].MSD_CORE_HEQ_Template_Language__c:''; 
            newTemplate.MSD_CORE_HEQ_Comments__c = lstofFileMetadataCloned.size()>0?lstofFileMetadataCloned[0].MSD_CORE_HEQ_Comments__c:'';
            newTemplate.MSD_CORE_Thumbnail_URL__c = lstofFileMetadataCloned.size()>0?lstofFileMetadataCloned[0].MSD_CORE_Thumbnail_URL__c:'';
            
            INSERT newTemplate;
            Map<String, Object> mapToBeSent = new Map<String, Object>();
            Object objRec = masterTemplateId;
            Object objRec1 = '';
            mapToBeSent.put('template_id', objRec);
            mapToBeSent.put('user_id', objRec1);
            //String reqStr = '"{template_id: "'+masterTemplateId+'",user_id: ""}"';
            //System.debug('### 1 JSON.deserializeUnTyped(reqStr) '+(Map<string, object>)JSON.deserializeUnTyped(reqStr));
            //System.debug('### 2 Get Template By Id '+getTemplateById((Map<string, object>)JSON.deserializeUnTyped(reqStr)).responseBody);
            TemplateConfigWrapper wrapperinstance = (TemplateConfigWrapper)JSON.deserialize(getTemplateById(mapToBeSent).responseBody, TemplateConfigWrapper.class);//(TemplateConfigWrapper)JSON.deserialize(JSON.serialize(getTemplateById((Map<string, object>)JSON.deserializeUnTyped(reqStr)).responseBody), TemplateConfigWrapper.class);
            System.debug('### wrapperinstance '+wrapperinstance);
            if(wrapperinstance != NULL) {
                for(TemplateConfigWrapper.Canvas_configuration rec : wrapperinstance.canvas_configuration) {
                    System.debug('### rec '+rec);
                    MSD_CORE_HEQ_Template_File_Section__c recToBeCreated = new MSD_CORE_HEQ_Template_File_Section__c();
                    recToBeCreated.MSD_CORE_HEQ_Section_Id__c = String.ValueOf(rec.id);
                    recToBeCreated.MSD_CORE_HEQ_Type__c = String.ValueOf(rec.type);
                    recToBeCreated.MSD_CORE_HEQ_X_Coordinate__c = String.ValueOf(rec.x);
                    recToBeCreated.MSD_CORE_HEQ_Y_Coordinate__c = String.ValueOf(rec.y);
                    recToBeCreated.MSD_CORE_HEQ_Element_Name__c = String.ValueOf(rec.element_name);
                    recToBeCreated.MSD_COR_HEQ_Element_URL__c= String.ValueOf(rec.element_url);
                    recToBeCreated.MSD_CORE_HEQ_Width__c= String.ValueOf(rec.width);
                    recToBeCreated.MSD_CORE_HEQ_Height__c= String.ValueOf(rec.height);
                    recToBeCreated.MSD_CORE_HEQ_Customizable__c= String.ValueOf(rec.customizable).toLowerCase() == 'true'?true:false;
                    recToBeCreated.MSD_CORE_Page_Number__c= String.ValueOf(rec.page_number);
                    recToBeCreated.MSD_CORE_HEQ_Template_File_Metadata__c = newTemplate.Id;
                    lstOfSections.add(recToBeCreated);
                }
                INSERT lstOfSections;
                System.debug('### lstOfSections '+lstOfSections);
                
                for(MSD_CORE_HEQ_Template_File_Section__c rec : lstOfSections) {
                    mapOfZoneIdAndSectionIds.put(rec.MSD_CORE_HEQ_Section_Id__c, rec.Id);
                }
                
                System.debug('### mapOfZoneIdAndSectionIds '+mapOfZoneIdAndSectionIds);
                
                for(TemplateConfigWrapper.Mappings recInnerTemp2 : wrapperinstance.mappings) {
                    setOfModuleIds.add(recInnerTemp2.module_id);
                }
                
                System.debug('### setOfModuleIds '+setOfModuleIds);
                
                for(MSD_CORE_HEQ_Template_Module__c rec : [SELECT id, MSD_CORE_HEQ_Module_Id__c FROM MSD_CORE_HEQ_Template_Module__c WHERE MSD_CORE_HEQ_Module_Id__c IN:setOfModuleIds ]) {
                    mapOfModuleIdAndModuleIds.put(rec.MSD_CORE_HEQ_Module_Id__c, rec.Id);
                }
                
                System.debug('### mapOfModuleIdAndModuleIds '+mapOfModuleIdAndModuleIds);
                
                for(TemplateConfigWrapper.Mappings recInnerTemp2 : wrapperinstance.mappings) {                    
                    MSD_CORE_HEQ_Template_File_Mapping__c recTemp = new MSD_CORE_HEQ_Template_File_Mapping__c();
                    recTemp.MSD_CORE_HEQ_Zone_Id__c = recInnerTemp2.zone_id;
                    recTemp.MSD_CORE_HEQ_Template_Module__c = mapOfModuleIdAndModuleIds.get(recInnerTemp2.module_id);
                    recTemp.MSD_CORE_HEQ_Template_File_Section__c = mapOfZoneIdAndSectionIds.get(recInnerTemp2.zone_id);
                    recTemp.MSD_CORE_HEQ_Module_Name__c = recInnerTemp2.module_name;
                    lstOfMappings.add(recTemp);                    
                }
                INSERT lstOfMappings;
            }
            
        } catch (Exception e) {
            System.debug('### Exception Occured '+e.getMessage() + ' -- '+e.getLineNumber());
        }
    }
    
    global static MSD_CORE_HEQ_TemplateServiceDispatcher.ResponseWrapper updateTemplateResource(String reqJSON) {
        MSD_CORE_HEQ_TemplateServiceDispatcher.ResponseWrapper res;
        TemplateConfigWrapper wrapperinstance = (TemplateConfigWrapper)JSON.deserialize(reqJSON, TemplateConfigWrapper.class);
        String sfTemplateId  = wrapperinstance.template_id!= NULL? wrapperinstance.template_id:'';
        
        if (String.isNotBlank(sfTemplateId)) {
            try {
                List<MSD_CORE_HEQ_Template_File_Metadata__c> lstOfFileMetadata = new List<MSD_CORE_HEQ_Template_File_Metadata__c>();
                List<MSD_CORE_HEQ_Template_File_Mapping__c> lstOfMappings = new List<MSD_CORE_HEQ_Template_File_Mapping__c>();
                List<MSD_CORE_HEQ_Template_File_Section__c> lstOfSections = new List<MSD_CORE_HEQ_Template_File_Section__c>();
                Set<String> setOfZoneIds = new Set<String>();
                Set<String> setOfModuleIds = new Set<String>();
                Set<String> setOfExistingSectionIds = new Set<String>();
                Map<String, String> mapOfZoneIdAndSectionIds = new Map<String, String>();
                Map<String, String> mapOfModuleIdAndModuleIds = new Map<String, String>();
                
                lstOfFileMetadata = [SELECT Id, MSD_CORE_Job_Code__c, MSD_CORE_User_Id__c, MSD_CORE_HEQ_Template_Id__c,
                                     Name, MSD_CORE_HEQ_Template_Language__c, MSD_CORE_Status__c,
                                     MSD_CORE_HEQ_Comments__c, MSD_CORE_Thumbnail_URL__c 
                                     FROM MSD_CORE_HEQ_Template_File_Metadata__c WHERE Id = :sfTemplateId ];
                
                System.debug('### sfTemplateId '+sfTemplateId);
                System.debug('### lstOfFileMetadata '+lstOfFileMetadata);
                
                if(lstOfFileMetadata.size()>0) {
                    lstOfFileMetadata[0].MSD_CORE_Status__c = wrapperinstance.status;
                    lstOfFileMetadata[0].Name = wrapperinstance.design_name ;
                    lstOfFileMetadata[0].MSD_CORE_HEQ_Comments__c = wrapperinstance.comments ;
                    
                    UPDATE lstOfFileMetadata[0];
                    
                    List<MSD_CORE_HEQ_Template_File_Section__c> lstOfFileSectionsToBeUpdated = new List<MSD_CORE_HEQ_Template_File_Section__c>();
                    List<MSD_CORE_HEQ_Template_File_Section__c> lstOfFileSectionsMain = new List<MSD_CORE_HEQ_Template_File_Section__c>();
                    lstOfFileSectionsMain = [SELECT Id, MSD_CORE_HEQ_Section_Id__c, MSD_CORE_HEQ_Original_Element_Url__c  FROM MSD_CORE_HEQ_Template_File_Section__c where MSD_CORE_HEQ_Template_File_Metadata__c =:sfTemplateId];
                    
                    for(TemplateConfigWrapper.Canvas_configuration recInnerTemp3 : wrapperinstance.Canvas_configuration) {
                        for(MSD_CORE_HEQ_Template_File_Section__c recUpdate : lstOfFileSectionsMain) {
                            if(recUpdate.MSD_CORE_HEQ_Section_Id__c == recInnerTemp3.id) {
                                recUpdate.MSD_CORE_HEQ_Original_Element_Url__c = recInnerTemp3.placeholder;
                                recUpdate.MSD_COR_HEQ_Element_URL__c= String.ValueOf(recInnerTemp3.element_url);
                                lstOfFileSectionsToBeUpdated.add(recUpdate);
                                break;
                            }
                            
                        }
                    }
                    
                    if(lstOfFileSectionsToBeUpdated.size()>0) {
                        UPDATE lstOfFileSectionsToBeUpdated;
                    }
                    
                    List<MSD_CORE_HEQ_Template_File_Mapping__c> lstOfFileMappingsToBeUpdated = new List<MSD_CORE_HEQ_Template_File_Mapping__c>();
                    lstOfFileMappingsToBeUpdated = [SELECT Id, MSD_CORE_HEQ_Zone_Id__c, MSD_CORE_HEQ_Template_Module__c, 
                                                    MSD_CORE_HEQ_Module_Name__c, MSD_CORE_HEQ_Template_Module__r.MSD_CORE_HEQ_Module_Id__c
                                                    FROM MSD_CORE_HEQ_Template_File_Mapping__c 
                                                    WHERE MSD_CORE_HEQ_Template_File_Section__r.MSD_CORE_HEQ_Template_File_Metadata__c = :sfTemplateId];
                    
                    
                    Integer index=0;
                    for(TemplateConfigWrapper.Mappings recInnerTemp2 : wrapperinstance.mappings) {
                        for(;index<lstOfFileMappingsToBeUpdated.size();) {
                            if(lstOfFileMappingsToBeUpdated[index].MSD_CORE_HEQ_Template_Module__r.MSD_CORE_HEQ_Module_Id__c == recInnerTemp2.module_id) {
                                lstOfFileMappingsToBeUpdated[index].MSD_CORE_HEQ_Asset_Link__c = recInnerTemp2.asset_link;
                                index++;
                                break;
                            }
                            index++;
                        }                        
                    }
                    
                    UPDATE lstOfFileMappingsToBeUpdated;
                    
                    res = new MSD_CORE_HEQ_TemplateServiceDispatcher.ResponseWrapper(201, JSON.serialize('Success'));
                    System.debug('### res '+res);
                }  else {
                    res = new MSD_CORE_HEQ_TemplateServiceDispatcher.ResponseWrapper(200, JSON.serialize(new Map<String, Object>{'error' => 'No records found'}));
                }              
                
            } catch(Exception ex) {
                res = new MSD_CORE_HEQ_TemplateServiceDispatcher.ResponseWrapper(500, JSON.serialize(new Map<String, Object>{'error:' => ex.getMessage(),'\nerrorStackTrace:' => ex.getStackTraceString()}));
            }
        } else {
            // Return error if parameters are missing
            res = new MSD_CORE_HEQ_TemplateServiceDispatcher.ResponseWrapper(400, JSON.serialize(new Map<String, Object>{'error' => 'Missing required parameters: Template_Id'}));
        }
        return res;
    }    
}