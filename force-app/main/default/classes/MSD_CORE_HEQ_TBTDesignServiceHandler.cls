global class MSD_CORE_HEQ_TBTDesignServiceHandler { 
    
    global static MSD_CORE_HEQ_DesignServiceDispatcher.ResponseWrapper getDesignByJobCode(Map<string, object> requestParamsMap) {
        
        MSD_CORE_HEQ_DesignServiceDispatcher.ResponseWrapper res;
        
        String jobCode = requestParamsMap.get('job_code') != NULL? (String)requestParamsMap.get('job_code'):'';
        String whereClause = '';
        
        if (String.isBlank(jobCode)) {            
            res = new MSD_CORE_HEQ_DesignServiceDispatcher.ResponseWrapper(400, JSON.serialize(new Map<String, Object>{'error' => 'Missing required parameter: job_code'}));
            return res;
        } else {
            try {                
                List<MSD_CORE_HEQ_Design_Metadata__c> lstOfDesigns = new List<MSD_CORE_HEQ_Design_Metadata__c>();
                List<MSD_CORE_HEQ_Design_File__c> lstOfDesignFiles = new List<MSD_CORE_HEQ_Design_File__c>();
                List<MSD_CORE_HEQ_Design_Link__c> lstOfDesignLinks = new List<MSD_CORE_HEQ_Design_Link__c>();
                List<MSD_CORE_HEQ_Template_Module__c> lstOfModules = new List<MSD_CORE_HEQ_Template_Module__c>();
                List<MSD_CORE_HEQ_Static_File__c> lstOfStaticFiles = new List<MSD_CORE_HEQ_Static_File__c>();
                List<MSD_CORE_HEQ_Asset__c> lstOfAssets = new List<MSD_CORE_HEQ_Asset__c>();
                
                lstOfDesigns = [SELECT Id, MSD_CORE_Job_Code__c, MSD_CORE_User_Id__c, Name, MSD_CORE_Thumbnail__c, 
                                MSD_CORE_mapping_guidelines_file__c, MSD_CORE_combined_pdf__c, 
                                MSD_CORE_HEQ_Template_Type__c, MSD_CORE_Status__c, MSD_CORE_HEQ_Language__c,
                                (SELECT Id, MSD_CORE_HEQ_Static_File_Id__c, Name, MSD_CORE_HEQ_URL__c, MSD_CORE_HEQ_Thumbnail__c,
                                 MSD_CORE_HEQ_Job_Code__c, MSD_CORE_HEQ_Order__c, MSD_CORE_HEQ_File_Type__c, MSD_CORE_HEQ_Is_Placeholder__c,
                                 MSD_CORE_HEQ_Properties__c, MSD_CORE_HEQ_Design_Metadata__c, 
                                 MSD_CORE_HEQ_Design_Metadata__r.MSD_CORE_Job_Code__c
                                 FROM Static_Files__r),
                                (SELECT Id, MSD_CORE_HEQ_IDML_Link__c, MSD_CORE_HEQ_INDD_Link__c, 
                                 MSD_CORE_HEQ_Design_Metadata__c, MSD_CORE_HEQ_Design_Metadata__r.MSD_CORE_Job_Code__c
                                 FROM Design_Files__r),
                                (SELECT Id, MSD_CORE_HEQ_Module_Id__c, Name, MSD_CORE_HEQ_Design_Metadata__c, 
                                 MSD_CORE_HEQ_Resource_Type__c, MSD_CORE_HEQ_Design_Metadata__r.MSD_CORE_Job_Code__c
                                 FROM Template_Modules__r)
                                FROM MSD_CORE_HEQ_Design_Metadata__c WHERE MSD_CORE_Job_Code__c =:jobCode];
                
                /*lstOfDesignFiles = [SELECT Id, MSD_CORE_HEQ_IDML_Link__c, MSD_CORE_HEQ_INDD_Link__c, 
                MSD_CORE_HEQ_Design_Metadata__c, MSD_CORE_HEQ_Design_Metadata__r.MSD_CORE_Status__c
                FROM MSD_CORE_HEQ_Design_File__c WHERE MSD_CORE_HEQ_Design_Metadata__r.MSD_CORE_Status__c =:status];
                */
                lstOfDesignLinks = [SELECT Id, MSD_CORE_HEQ_Link__c, MSD_CORE_HEQ_Type__c,
                                    MSD_CORE_HEQ_Design_File__c, MSD_CORE_HEQ_Design_File__r.MSD_CORE_HEQ_Design_Metadata__r.MSD_CORE_Job_Code__c 
                                    FROM MSD_CORE_HEQ_Design_Link__c WHERE MSD_CORE_HEQ_Design_File__r.MSD_CORE_HEQ_Design_Metadata__r.MSD_CORE_Job_Code__c =:jobCode];
                
                Map<Id, List<MSD_CORE_HEQ_Design_Link__c>> mapOfIdAndDesignLink = new Map<Id, List<MSD_CORE_HEQ_Design_Link__c>>();
                for(MSD_CORE_HEQ_Design_Link__c rec : lstOfDesignLinks) {
                    if(mapOfIdAndDesignLink.get(rec.MSD_CORE_HEQ_Design_File__c) != NULL) {
                        mapOfIdAndDesignLink.get(rec.MSD_CORE_HEQ_Design_File__c).add(rec);
                    } else {
                        mapOfIdAndDesignLink.put(rec.MSD_CORE_HEQ_Design_File__c, new List<MSD_CORE_HEQ_Design_Link__c> {rec});
                    }
                }
                
                /*lstOfModules = [SELECT Id, MSD_CORE_HEQ_Module_Id__c, Name, MSD_CORE_HEQ_Design_Metadata__c, 
                MSD_CORE_HEQ_Resource_Type__c, MSD_CORE_HEQ_Design_Metadata__r.MSD_CORE_Status__c
                FROM MSD_CORE_HEQ_Template_Module__c WHERE MSD_CORE_HEQ_Design_Metadata__r.MSD_CORE_Status__c =:status];
                
                lstOfStaticFiles = [SELECT Id, MSD_CORE_HEQ_Static_File_Id__c, Name, MSD_CORE_HEQ_URL__c, MSD_CORE_HEQ_Thumbnail__c,
                MSD_CORE_HEQ_Job_Code__c, MSD_CORE_HEQ_Order__c, MSD_CORE_HEQ_File_Type__c, MSD_CORE_HEQ_Is_Placeholder__c,
                MSD_CORE_HEQ_Properties__c, MSD_CORE_HEQ_Design_Metadata__c, 
                MSD_CORE_HEQ_Design_Metadata__r.MSD_CORE_Status__c
                FROM MSD_CORE_HEQ_Static_File__c WHERE MSD_CORE_HEQ_Design_Metadata__r.MSD_CORE_Status__c =:status];
                */
                lstOfAssets = [SELECT Id, MSD_CORE_HEQ_Link__c, MSD_CORE_HEQ_Template_Module__c,
                               MSD_CORE_HEQ_Template_Module__r.MSD_CORE_HEQ_Design_Metadata__r.MSD_CORE_Job_Code__c
                               FROM MSD_CORE_HEQ_Asset__c 
                               WHERE MSD_CORE_HEQ_Template_Module__r.MSD_CORE_HEQ_Design_Metadata__r.MSD_CORE_Job_Code__c =:jobCode];
                
                Map<Id, List<MSD_CORE_HEQ_Asset__c>> mapOfIdAndAssetLink = new Map<Id, List<MSD_CORE_HEQ_Asset__c>>();
                for(MSD_CORE_HEQ_Asset__c rec : lstOfAssets) {
                    if(mapOfIdAndAssetLink.get(rec.MSD_CORE_HEQ_Template_Module__c) != NULL) {
                        mapOfIdAndAssetLink.get(rec.MSD_CORE_HEQ_Template_Module__c).add(rec);
                    } else {
                        mapOfIdAndAssetLink.put(rec.MSD_CORE_HEQ_Template_Module__c, new List<MSD_CORE_HEQ_Asset__c> {rec});
                    }
                }
                
                if(lstOfDesigns.size()>0) {          
                    system.debug('### lstOfDesigns '+lstOfDesigns);
                    system.debug('### mapOfIdAndDesignLink '+mapOfIdAndDesignLink);
                    system.debug('### mapOfIdAndAssetLink '+mapOfIdAndAssetLink);
                    
                    res = new MSD_CORE_HEQ_DesignServiceDispatcher.ResponseWrapper(200, MSD_CORE_HEQ_DesignWrapper.createWrapper(lstOfDesigns, mapOfIdAndDesignLink, mapOfIdAndAssetLink));
                    
                } else {
                    res = new MSD_CORE_HEQ_DesignServiceDispatcher.ResponseWrapper(200, JSON.serialize(new Map<String, Object>{'error' => 'No records found'}));
                }
                
            } catch(Exception ex) {
                // Handle any exceptions and return error response
                res = new MSD_CORE_HEQ_DesignServiceDispatcher.ResponseWrapper(500, JSON.serialize(new Map<String, Object>{'error' => ex.getMessage()+'  '+ex.getStackTraceString()}));
            }
        }
        
        return res;
    }
    
    global static MSD_CORE_HEQ_DesignServiceDispatcher.ResponseWrapper getListOfDesigns(Map<string, object> requestParamsMap) {
        
        MSD_CORE_HEQ_DesignServiceDispatcher.ResponseWrapper res;
        
        String status = requestParamsMap.get('status') != NULL? (String)requestParamsMap.get('status'):'';
        
        if (String.isBlank(status)) {            
            res = new MSD_CORE_HEQ_DesignServiceDispatcher.ResponseWrapper(400, JSON.serialize(new Map<String, Object>{'error' => 'Missing required parameter: status'}));
            return res;
        } else {
            try {  
                List<String> lstOfString = new List<String>();
                if(status.contains(',')) {
                    for(String rec : status.split(',')) {
                        lstOfString.add(rec.trim());
                    }
                } else {
                    lstOfString.add(status);
                }
                
                List<MSD_CORE_HEQ_Design_Metadata__c> lstOfDesigns = new List<MSD_CORE_HEQ_Design_Metadata__c>();
                
                lstOfDesigns = [SELECT Id, MSD_CORE_Job_Code__c, MSD_CORE_User_Id__c, Name, MSD_CORE_Thumbnail__c, 
                                MSD_CORE_mapping_guidelines_file__c, MSD_CORE_combined_pdf__c, 
                                MSD_CORE_HEQ_Template_Type__c, MSD_CORE_Status__c, MSD_CORE_HEQ_Language__c
                                FROM MSD_CORE_HEQ_Design_Metadata__c WHERE MSD_CORE_Status__c IN:lstOfString];
                
                if(lstOfDesigns.size()>0) {
                    res = new MSD_CORE_HEQ_DesignServiceDispatcher.ResponseWrapper(200, MSD_CORE_HEQ_DesignWrapper.createSingleWrapper(lstOfDesigns));
                    
                } else {
                    res = new MSD_CORE_HEQ_DesignServiceDispatcher.ResponseWrapper(200, JSON.serialize(new Map<String, Object>{'error' => 'No records found'}));
                }
                
            } catch(Exception ex) {
                // Handle any exceptions and return error response
                res = new MSD_CORE_HEQ_DesignServiceDispatcher.ResponseWrapper(500, JSON.serialize(new Map<String, Object>{'error' => ex.getMessage()+'  '+ex.getStackTraceString()}));
            }
        }
        
        return res;
    }
    
    global static MSD_CORE_HEQ_DesignServiceDispatcher.ResponseWrapper upsertDesign(String requestJSON, Map<string, object> requestParamsMap) {
        
        MSD_CORE_HEQ_DesignServiceDispatcher.ResponseWrapper res;
        MSD_CORE_HEQ_DesignWrapper wrapperRec = MSD_CORE_HEQ_DesignWrapper.parse(requestJSON);
        String jobCode = requestParamsMap.get('job_Code') != NULL? (String)requestParamsMap.get('job_Code'):'';
        
        if(wrapperRec != NULL && jobCode!= NULL) {
            try {                
                
                MSD_CORE_HEQ_Design_Metadata__c recDesignMetadata = new MSD_CORE_HEQ_Design_Metadata__c();
                List<MSD_CORE_HEQ_Design_Metadata__c> lstOfDesignMetadata = new List<MSD_CORE_HEQ_Design_Metadata__c>();
                List<MSD_CORE_HEQ_Design_File__c> lstOfDesignFilesToBeInserted = new List<MSD_CORE_HEQ_Design_File__c>();
                List<MSD_CORE_HEQ_Static_File__c> lstOfStaticFilesToBeInserted = new List<MSD_CORE_HEQ_Static_File__c>();
                List<MSD_CORE_HEQ_Template_Module__c> lstOfTempModulesToBeInserted = new List<MSD_CORE_HEQ_Template_Module__c>();
                List<MSD_CORE_HEQ_Design_Link__c> lstOfDesignLinks = new List<MSD_CORE_HEQ_Design_Link__c>();
                List<MSD_CORE_HEQ_Asset__c> lstOfAssets = new List<MSD_CORE_HEQ_Asset__c>();
                List<MSD_CORE_HEQ_Design_File__c> lstOfDesignFilesToBeDeleted = new List<MSD_CORE_HEQ_Design_File__c>();
                List<MSD_CORE_HEQ_Design_Link__c> lstOfDesignLinksToBeDeleted = new List<MSD_CORE_HEQ_Design_Link__c>();
                List<MSD_CORE_HEQ_Asset__c> lstOfAssetsToBeDeleted = new List<MSD_CORE_HEQ_Asset__c>();
                List<MSD_CORE_HEQ_Static_File__c> lstOfStaticFilesToBeDeleted = new List<MSD_CORE_HEQ_Static_File__c>();
                List<MSD_CORE_HEQ_Template_Module__c> lstOfModulesFilesToBeDeleted = new List<MSD_CORE_HEQ_Template_Module__c>();
                
                
                
                Map<String, List<String>> mapOfDesignFileKeyAndLinks = new Map<String, List<String>>();
                Map<String, List<String>> mapOfDesignFileKeyAndFonts = new Map<String, List<String>>();
                Map<String, List<String>> mapOfModuleKeyAndAssets = new Map<String, List<String>>();
                
                lstOfDesignMetadata = [SELECT Id, MSD_CORE_Job_Code__c, MSD_CORE_User_Id__c, Name, MSD_CORE_Thumbnail__c,
                                       MSD_CORE_mapping_guidelines_file__c, MSD_CORE_combined_pdf__c, MSD_CORE_Status__c,
                                       MSD_CORE_HEQ_Template_Type__c, MSD_CORE_HEQ_Language__c
                                       FROM MSD_CORE_HEQ_Design_Metadata__c WHERE MSD_CORE_Job_Code__c =:jobCode];
                if(lstOfDesignMetadata.size()>0) {
                    recDesignMetadata = lstOfDesignMetadata[0];
                }
                
                recDesignMetadata.MSD_CORE_Job_Code__c = wrapperRec.job_code;
                recDesignMetadata.MSD_CORE_User_Id__c = wrapperRec.user_id;
                recDesignMetadata.Name = wrapperRec.design_name;
                recDesignMetadata.MSD_CORE_Thumbnail__c = wrapperRec.thumbnail;
                recDesignMetadata.MSD_CORE_mapping_guidelines_file__c = wrapperRec.mapping_guidelines_file;
                recDesignMetadata.MSD_CORE_combined_pdf__c = wrapperRec.combined_pdf;
                recDesignMetadata.MSD_CORE_Status__c = wrapperRec.status;
                recDesignMetadata.MSD_CORE_HEQ_Template_Type__c = wrapperRec.template_type;
                recDesignMetadata.MSD_CORE_HEQ_Language__c = wrapperRec.language;
                
                upsert recDesignMetadata MSD_CORE_HEQ_Design_Metadata__c.MSD_CORE_Job_Code__c;
                
                // Deleting all the design Files, as we are not having the external id to know which one to keep and which to delete
                
                lstOfDesignFilesToBeDeleted = [Select Id, MSD_CORE_HEQ_Design_Metadata__c FROM MSD_CORE_HEQ_Design_File__c WHERE MSD_CORE_HEQ_Design_Metadata__c =:recDesignMetadata.Id];
                if(lstOfDesignFilesToBeDeleted.size()>0) {
                    DELETE lstOfDesignFilesToBeDeleted;
                }
                
                lstOfDesignLinksToBeDeleted = [Select Id, MSD_CORE_HEQ_Design_File__r.MSD_CORE_HEQ_Design_Metadata__c FROM MSD_CORE_HEQ_Design_Link__c WHERE MSD_CORE_HEQ_Design_File__r.MSD_CORE_HEQ_Design_Metadata__c =:recDesignMetadata.Id];
                if(lstOfDesignLinksToBeDeleted.size()>0) {
                    DELETE lstOfDesignLinksToBeDeleted;
                }                
                
                for(MSD_CORE_HEQ_DesignWrapper.Design_file rec : wrapperRec.design_file) {
                    MSD_CORE_HEQ_Design_File__c recToBeCreated = new MSD_CORE_HEQ_Design_File__c();
                    recToBeCreated.MSD_CORE_HEQ_IDML_Link__c = rec.idml;
                    recToBeCreated.MSD_CORE_HEQ_INDD_Link__c = rec.indd;
                    recToBeCreated.MSD_CORE_HEQ_Design_Metadata__c = recDesignMetadata.Id;
                    mapOfDesignFileKeyAndLinks.put(rec.idml+rec.indd+recDesignMetadata.Id, rec.links);
                    mapOfDesignFileKeyAndFonts.put(rec.idml+rec.indd+recDesignMetadata.Id, rec.fonts);
                    lstOfDesignFilesToBeInserted.add(recToBeCreated);
                }
                
                INSERT lstOfDesignFilesToBeInserted;
                
                for(MSD_CORE_HEQ_Design_File__c rec : lstOfDesignFilesToBeInserted) {
                    for(String recLink : mapOfDesignFileKeyAndFonts.get(rec.MSD_CORE_HEQ_IDML_Link__c+rec.MSD_CORE_HEQ_INDD_Link__c+rec.MSD_CORE_HEQ_Design_Metadata__c)) {
                        MSD_CORE_HEQ_Design_Link__c designLinkToBeInserted = new MSD_CORE_HEQ_Design_Link__c();
                        designLinkToBeInserted.MSD_CORE_HEQ_Link__c = recLink;
                        designLinkToBeInserted.MSD_CORE_HEQ_Type__c = 'Font';
                        designLinkToBeInserted.MSD_CORE_HEQ_Design_File__c = rec.Id;
                        lstOfDesignLinks.add(designLinkToBeInserted);
                    }
                    for(String recLink : mapOfDesignFileKeyAndLinks.get(rec.MSD_CORE_HEQ_IDML_Link__c+rec.MSD_CORE_HEQ_INDD_Link__c+rec.MSD_CORE_HEQ_Design_Metadata__c)) {
                        MSD_CORE_HEQ_Design_Link__c designLinkToBeInserted = new MSD_CORE_HEQ_Design_Link__c();
                        designLinkToBeInserted.MSD_CORE_HEQ_Link__c = recLink;
                        designLinkToBeInserted.MSD_CORE_HEQ_Type__c = 'Link';
                        designLinkToBeInserted.MSD_CORE_HEQ_Design_File__c = rec.Id;
                        lstOfDesignLinks.add(designLinkToBeInserted);
                    }
                }
                
                INSERT lstOfDesignLinks;
                
                lstOfStaticFilesToBeDeleted = [Select Id, MSD_CORE_HEQ_Design_Metadata__c FROM MSD_CORE_HEQ_Static_File__c WHERE MSD_CORE_HEQ_Design_Metadata__c =:recDesignMetadata.Id];
                if(lstOfStaticFilesToBeDeleted.size()>0) {
                    DELETE lstOfStaticFilesToBeDeleted;
                }
                
                for(MSD_CORE_HEQ_DesignWrapper.Static_files rec : wrapperRec.static_files) {
                    MSD_CORE_HEQ_Static_File__c rectoBeInserted = new MSD_CORE_HEQ_Static_File__c();
                    rectoBeInserted.Name = rec.name ;
                    rectoBeInserted.MSD_CORE_HEQ_Static_File_Id__c = rec.id ;
                    rectoBeInserted.MSD_CORE_HEQ_URL__c = rec.url ;
                    rectoBeInserted.MSD_CORE_HEQ_Thumbnail__c = rec.thumbnail ;
                    rectoBeInserted.MSD_CORE_HEQ_Job_Code__c = rec.job_code ;
                    rectoBeInserted.MSD_CORE_HEQ_Order__c = rec.order ;
                    rectoBeInserted.MSD_CORE_HEQ_File_Type__c = rec.file_type ;
                    rectoBeInserted.MSD_CORE_HEQ_Is_Placeholder__c = rec.isPlaceholder ;
                    rectoBeInserted.MSD_CORE_HEQ_Properties__c = rec.properties ;
                    rectoBeInserted.MSD_CORE_HEQ_Design_Metadata__c = recDesignMetadata.Id;
                    lstOfStaticFilesToBeInserted.add(rectoBeInserted);
                }
                INSERT lstOfStaticFilesToBeInserted;
                
                lstOfModulesFilesToBeDeleted = [Select Id, MSD_CORE_HEQ_Design_Metadata__c FROM MSD_CORE_HEQ_Template_Module__c WHERE MSD_CORE_HEQ_Design_Metadata__c =:recDesignMetadata.Id];
                if(lstOfModulesFilesToBeDeleted.size()>0) {
                    DELETE lstOfModulesFilesToBeDeleted;
                }
                
                
                for(MSD_CORE_HEQ_DesignWrapper.Modules rec : wrapperRec.Modules) {
                    MSD_CORE_HEQ_Template_Module__c recToBeInserted = new MSD_CORE_HEQ_Template_Module__c();
                    recToBeInserted.MSD_CORE_HEQ_Module_Id__c = rec.Id;
                    recToBeInserted.Name = rec.Name;
                    recToBeInserted.MSD_CORE_HEQ_Resource_Type__c = rec.resource_type;
                    recToBeInserted.MSD_CORE_HEQ_Design_Metadata__c = recDesignMetadata.Id;
                    lstOfTempModulesToBeInserted.add(recToBeInserted);
                    mapOfModuleKeyAndAssets.put(rec.Id, rec.assets);
                }
                INSERT lstOfTempModulesToBeInserted;
                
                lstOfAssetsToBeDeleted = [Select Id, MSD_CORE_HEQ_Template_Module__r.MSD_CORE_HEQ_Design_Metadata__c FROM MSD_CORE_HEQ_Asset__c WHERE MSD_CORE_HEQ_Template_Module__r.MSD_CORE_HEQ_Design_Metadata__c =:recDesignMetadata.Id];
                if(lstOfAssetsToBeDeleted.size() > 0) {
                    DELETE lstOfAssetsToBeDeleted;
                }
                
                for(MSD_CORE_HEQ_Template_Module__c rec : lstOfTempModulesToBeInserted) {
                    for(String recLink : mapOfModuleKeyAndAssets.get(rec.MSD_CORE_HEQ_Module_Id__c)) {
                        MSD_CORE_HEQ_Asset__c assetToBeInserted = new MSD_CORE_HEQ_Asset__c();
                        assetToBeInserted.MSD_CORE_HEQ_Link__c = recLink;
                        assetToBeInserted.MSD_CORE_HEQ_Template_Module__c = rec.id; 
                        lstOfAssets.add(assetToBeInserted);
                    }
                }
                res = new MSD_CORE_HEQ_DesignServiceDispatcher.ResponseWrapper(201, JSON.serialize('Success'));
                INSERT lstOfAssets;  
            } catch (Exception e) {
                res = new MSD_CORE_HEQ_DesignServiceDispatcher.ResponseWrapper(500, JSON.serialize(new Map<String, Object>{'error' => e.getMessage()+'  '+e.getStackTraceString()}));
            }
        } else {
            res = new MSD_CORE_HEQ_DesignServiceDispatcher.ResponseWrapper(400, JSON.serialize(new Map<String, Object>{'error' => 'Missing required parameters: job_code'}));
        }
        return res;
    }
}