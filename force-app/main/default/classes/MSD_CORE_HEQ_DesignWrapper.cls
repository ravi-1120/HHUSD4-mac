public class MSD_CORE_HEQ_DesignWrapper {
     
    public String job_code;
    public String user_id;
    public String design_name;
    public String thumbnail;
    public String mapping_guidelines_file;
    public String combined_pdf;
    public String template_type;
    public String language;
    public String status;
    public List<Design_file> design_file;
    public List<Static_files> static_files;
    public List<Modules> Modules;
    
    public class Modules {
        public String id;
        public String name;
        public String resource_type;
        public List<String> assets;
    }
    
    public class Static_files {
        public String id;
        public String name;
        public String url;
        public String thumbnail;
        public String job_code;
        public Integer order;
        public String file_type;
        public Boolean isPlaceholder;
        public String properties;
    }
    
    public class Design_file {
        public String idml;
        public String indd;
        public List<String> links;
        public List<String> fonts;
    }
    
    
    public static MSD_CORE_HEQ_DesignWrapper parse(String json) {
        return (MSD_CORE_HEQ_DesignWrapper) System.JSON.deserialize(json, MSD_CORE_HEQ_DesignWrapper.class);
    }
    
    public static String createWrapper(List<MSD_CORE_HEQ_Design_Metadata__c> lstOfDesigns, Map<Id, List<MSD_CORE_HEQ_Design_Link__c>> mapOfIdAndDesignLink, Map<Id, List<MSD_CORE_HEQ_Asset__c>> mapOfIdAndAssetLink) {
        String res = '';
        List<MSD_CORE_HEQ_DesignWrapper> lstOfWrapper = new List<MSD_CORE_HEQ_DesignWrapper>();
        for(MSD_CORE_HEQ_Design_Metadata__c rec : lstOfDesigns) {
            MSD_CORE_HEQ_DesignWrapper recWrapper = new MSD_CORE_HEQ_DesignWrapper();
            recWrapper.job_code = rec.MSD_CORE_Job_Code__c;
            recWrapper.user_id = rec.MSD_CORE_User_Id__c;
            recWrapper.design_name = rec.Name;
            recWrapper.thumbnail = rec.MSD_CORE_Thumbnail__c;
            recWrapper.mapping_guidelines_file = rec.MSD_CORE_mapping_guidelines_file__c;
            recWrapper.combined_pdf = rec.MSD_CORE_combined_pdf__c;
            recWrapper.template_type = rec.MSD_CORE_HEQ_Template_Type__c;
            recWrapper.language = rec.MSD_CORE_Status__c;
            recWrapper.status = rec.MSD_CORE_Status__c;
            
            List<MSD_CORE_HEQ_DesignWrapper.Design_file> lstOfdesignfile = new List<MSD_CORE_HEQ_DesignWrapper.Design_file>();
            List<MSD_CORE_HEQ_DesignWrapper.Static_files> lstOfstaticfiles = new List<MSD_CORE_HEQ_DesignWrapper.Static_files>();
            List<MSD_CORE_HEQ_DesignWrapper.Modules> lstOfModules = new List<MSD_CORE_HEQ_DesignWrapper.Modules>();
            
            for(MSD_CORE_HEQ_Design_File__c recDesignFile : rec.Design_Files__r) {
                MSD_CORE_HEQ_DesignWrapper.Design_file recWrapper2 = new MSD_CORE_HEQ_DesignWrapper.Design_file();
                recWrapper2.indd = recDesignFile.MSD_CORE_HEQ_INDD_Link__c;
                recWrapper2.idml = recDesignFile.MSD_CORE_HEQ_IDML_Link__c;
                
                List<String> lstOfLinks = new List<String>();
                List<String> lstOfFonts = new List<String>();
                System.debug('### recDesignFile.Id '+recDesignFile.Id);
                System.debug('### mapOfIdAndDesignLink '+mapOfIdAndDesignLink);
                System.debug('### mapOfIdAndDesignLink '+mapOfIdAndDesignLink.get(recDesignFile.Id));
                if(mapOfIdAndDesignLink.get(recDesignFile.Id) != NULL) {
                    for(MSD_CORE_HEQ_Design_Link__c recInner : mapOfIdAndDesignLink.get(recDesignFile.Id)) {
                        if(recInner.MSD_CORE_HEQ_Type__c == 'Link') {
                            lstOfLinks.add(recInner.MSD_CORE_HEQ_Link__c);
                        } 
                        if(recInner.MSD_CORE_HEQ_Type__c == 'Font') {
                            lstOfFonts.add(recInner.MSD_CORE_HEQ_Link__c);
                        }
                    }
                }
                
                System.debug('### mapOfIdAndDesignLink '+mapOfIdAndDesignLink);
                System.debug('### recWrapper2 '+recWrapper2);
                
                recWrapper2.fonts = lstOfFonts;
                recWrapper2.links = lstOfLinks;
                lstOfdesignfile.add(recWrapper2);                
            }
            recWrapper.design_file = lstOfdesignfile;
            for(MSD_CORE_HEQ_Static_File__c recStaticFile : rec.Static_Files__r) {
                MSD_CORE_HEQ_DesignWrapper.Static_files recWrapper3 = new MSD_CORE_HEQ_DesignWrapper.Static_files();
                recWrapper3.file_type = recStaticFile.MSD_CORE_HEQ_File_Type__c;
                recWrapper3.id = recStaticFile.MSD_CORE_HEQ_Static_File_Id__c;
                recWrapper3.isPlaceholder = recStaticFile.MSD_CORE_HEQ_Is_Placeholder__c;
                recWrapper3.job_code = recStaticFile.MSD_CORE_HEQ_Job_Code__c;
                recWrapper3.name = recStaticFile.Name;
                recWrapper3.order = INTEGER.valueOf(recStaticFile.MSD_CORE_HEQ_Order__c);
                recWrapper3.properties = recStaticFile.MSD_CORE_HEQ_Properties__c;
                recWrapper3.thumbnail = recStaticFile.MSD_CORE_HEQ_Thumbnail__c;
                recWrapper3.url = recStaticFile.MSD_CORE_HEQ_URL__c;    
                lstOfstaticfiles.add(recWrapper3);                
            }
            recWrapper.static_files = lstOfstaticfiles;
            for(MSD_CORE_HEQ_Template_Module__c recModule : rec.Template_Modules__r) {
                MSD_CORE_HEQ_DesignWrapper.Modules recWrapper4 = new MSD_CORE_HEQ_DesignWrapper.Modules();
                recWrapper4.id = recModule.MSD_CORE_HEQ_Module_Id__c;
                recWrapper4.name = recModule.Name;
                recWrapper4.resource_type = recModule.MSD_CORE_HEQ_Resource_Type__c;
                System.debug('### mapOfIdAndAssetLink '+mapOfIdAndAssetLink);
                System.debug('### recModule.Id '+recModule.Id);
                List<String> lstOfAssets = new List<String>();
                if(mapOfIdAndAssetLink.get(recModule.Id) != NULL) {
                    for(MSD_CORE_HEQ_Asset__c recInner : mapOfIdAndAssetLink.get(recModule.Id)) {
                        lstOfAssets.add(recInner.MSD_CORE_HEQ_Link__c);
                    }
                }
                
                recWrapper4.assets = lstOfAssets;
                lstOfModules.add(recWrapper4);             
            }
            recWrapper.Modules = lstOfModules;
            lstOfWrapper.add(recWrapper);
        }
        if(lstOfWrapper.size() == 1) {
            res = JSON.serialize(lstOfWrapper[0]);
        } else {
            res = JSON.serialize(lstOfWrapper);
        }       
        
        return res;
    }
    
    public static String createSingleWrapper(List<MSD_CORE_HEQ_Design_Metadata__c> lstOfDesigns) {
        String res = '';
        List<MSD_CORE_HEQ_DesignWrapper> lstOfWrapper = new List<MSD_CORE_HEQ_DesignWrapper>();
        for(MSD_CORE_HEQ_Design_Metadata__c rec : lstOfDesigns) {
            MSD_CORE_HEQ_DesignWrapper recWrapper = new MSD_CORE_HEQ_DesignWrapper();
            recWrapper.job_code = rec.MSD_CORE_Job_Code__c;
            recWrapper.user_id = rec.MSD_CORE_User_Id__c;
            recWrapper.design_name = rec.Name;
            recWrapper.thumbnail = rec.MSD_CORE_Thumbnail__c;
            recWrapper.mapping_guidelines_file = rec.MSD_CORE_mapping_guidelines_file__c;
            recWrapper.combined_pdf = rec.MSD_CORE_combined_pdf__c;
            recWrapper.template_type = rec.MSD_CORE_HEQ_Template_Type__c;
            recWrapper.language = rec.MSD_CORE_Status__c;
            recWrapper.status = rec.MSD_CORE_Status__c;
            lstOfWrapper.add(recWrapper);
        }
        res = JSON.serialize(lstOfWrapper);
        return res;
    }
}