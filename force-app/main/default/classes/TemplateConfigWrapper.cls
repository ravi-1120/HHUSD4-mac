public class TemplateConfigWrapper {
    public static String createWrapper(List<MSD_CORE_HEQ_Template_File_Metadata__c> lstOfFileMetadata, List<MSD_CORE_HEQ_Template_File_Section__c> lstOfSections, List<MSD_CORE_HEQ_Template_File_Mapping__c> lstOfSectionModules, List<MSD_CORE_HEQ_Template_Module_Config__c> lstOfConfigs) {
        TemplateConfigWrapper rec = new TemplateConfigWrapper();
        rec.job_code = lstOfFileMetadata[0].MSD_CORE_Job_Code__c;
        rec.user_id = lstOfFileMetadata[0].MSD_CORE_User_Id__c;
        rec.template_id = lstOfFileMetadata[0].Id;
        rec.design_name = lstOfFileMetadata[0].Name;
        rec.template_language = lstOfFileMetadata[0].MSD_CORE_HEQ_Template_Language__c;
        rec.status = lstOfFileMetadata[0].MSD_CORE_Status__c;
        rec.comments = lstOfFileMetadata[0].MSD_CORE_HEQ_Comments__c;
        rec.thumbnail = lstOfFileMetadata[0].MSD_CORE_Thumbnail_URL__c;
        rec.template_name = lstOfFileMetadata[0].Name;
        rec.template_author = lstOfFileMetadata[0].MSD_CORE_Template_Author_Name__c;
        rec.template_approver = lstOfFileMetadata[0].MSD_CORE_Template_Approver__c;
        rec.template_approved_date = lstOfFileMetadata[0].Template_Approved_Date__c;
        rec.template_submitted_date = lstOfFileMetadata[0].MSD_CORE_HEQ_Template_Submitted_Date__c;
        List<TemplateConfigWrapper.Canvas_configuration> recInner1 = new List<TemplateConfigWrapper.Canvas_configuration>();
        List<TemplateConfigWrapper.Mappings> recInner2 = new List<TemplateConfigWrapper.Mappings>();
        
        for(MSD_CORE_HEQ_Template_File_Section__c recInnerTemp1 : lstOfSections) {
            TemplateConfigWrapper.Canvas_configuration recTemp = new TemplateConfigWrapper.Canvas_configuration();
            recTemp.id = recInnerTemp1.MSD_CORE_HEQ_Section_Id__c;
            recTemp.type = recInnerTemp1.MSD_CORE_HEQ_Type__c;
            recTemp.x = Double.ValueOf(recInnerTemp1.MSD_CORE_HEQ_X_Coordinate__c);
            recTemp.y = Double.ValueOf(recInnerTemp1.MSD_CORE_HEQ_Y_Coordinate__c);
            recTemp.element_name = recInnerTemp1.MSD_CORE_HEQ_Element_Name__c;
            recTemp.element_url = recInnerTemp1.MSD_COR_HEQ_Element_URL__c;
            recTemp.width = Double.ValueOf(recInnerTemp1.MSD_CORE_HEQ_Width__c);
            recTemp.height = Double.ValueOf(recInnerTemp1.MSD_CORE_HEQ_Height__c);
            recTemp.customizable = recInnerTemp1.MSD_CORE_HEQ_Customizable__c;
            recTemp.page_number = Integer.valueOf(recInnerTemp1.MSD_CORE_Page_Number__c != NULL?recInnerTemp1.MSD_CORE_Page_Number__c:'0');
            recTemp.placeholder = recInnerTemp1.MSD_CORE_HEQ_Original_Element_Url__c;
            recInner1.add(recTemp);
        }
        rec.canvas_configuration = recInner1;
        
        for(MSD_CORE_HEQ_Template_File_Mapping__c recInnerTemp2 : lstOfSectionModules) {
            TemplateConfigWrapper.Mappings recTemp = new TemplateConfigWrapper.Mappings();
            recTemp.zone_id = recInnerTemp2.MSD_CORE_HEQ_Zone_Id__c;
            recTemp.module_id = recInnerTemp2.MSD_CORE_HEQ_Template_Module__r.MSD_CORE_HEQ_Module_Id__c;
            recTemp.module_name = recInnerTemp2.MSD_CORE_HEQ_Module_Name__c;
            recTemp.asset_link = recInnerTemp2.MSD_CORE_HEQ_Asset_Link__c;
            recInner2.add(recTemp);
        }
        rec.mappings = recInner2;
        //FOR LOOP for module config
        for( MSD_CORE_HEQ_Template_Module_Config__c config : lstOfConfigs) {
            
            Module_Configuration recTemp = new TemplateConfigWrapper.Module_Configuration();
            recTemp.id = config.Id;
            recTemp.label = config.MSD_CORE_Label__c;
            recTemp.type = config.MSD_CORE_Type__c;
            
            System.debug('### config '+config);
            System.debug('### config Options '+config.HEQ_Template_Module_Options__r);
            
            if(config.HEQ_Template_Module_Options__r != NULL &&  config.HEQ_Template_Module_Options__r.size() > 0){
                for(MSD_CORE_HEQ_Template_Module_Options__c optionRec : config.HEQ_Template_Module_Options__r){
                    TemplateConfigWrapper.Options optionWrapperRec = new TemplateConfigWrapper.Options();
                    optionWrapperRec.checked = optionRec.MSD_CORE_Checked__c;
                    optionWrapperRec.label = optionRec.MSD_CORE_Label__c;
                    optionWrapperRec.order = optionRec.Order__c;
                    optionWrapperRec.thumbnail = optionRec.MSD_CORE_Thumbnail__c;
                    optionWrapperRec.id = optionRec.MSD_CORE_HEQ_Option_Id__c;
                    if(recTemp.options != NULL && recTemp.options.size() > 0){
                        recTemp.options.add(optionWrapperRec);
                    } 
                    else{
                        recTemp.options = new List<TemplateConfigWrapper.options>();
                        recTemp.options.add(optionWrapperRec);
                    }
                }
                for(MSD_CORE_HEQ_Template_Module__c optionRec1 : config.Template_Modules__r) {
                    TemplateConfigWrapper.Module moduleWrapperRec = new TemplateConfigWrapper.Module();
                    moduleWrapperRec.resource_type = optionRec1.MSD_CORE_HEQ_Resource_Type__c;
                    moduleWrapperRec.name = optionRec1.Name;
                    moduleWrapperRec.id = optionRec1.MSD_CORE_HEQ_Module_Id__c;
                    List<String> lstOfStringTemp = new List<String>();
                    for(String recLink :(optionRec1.MSD_CORE_HEQ_Asset_Links__c).split(';;') ) {
                        lstOfStringTemp.add(recLink);
                    }
                    moduleWrapperRec.assets = lstOfStringTemp;
                    recTemp.module = moduleWrapperRec;
                    
                }
            }
            recTemp.helpText = config.MSD_CORE_Help_Text__c;
            recTemp.validationError = config.MSD_CORE_Validation_Error__c;
            recTemp.hasImages = config.MSD_CORE_Has_Images__c;
			recTemp.noOfSelection = config.MSD_CORE_HEQ_Number_Of_Selection__c;
            
            if(rec.Module_Configuration != NULL && rec.Module_Configuration.size() > 0){
                rec.Module_Configuration.add(recTemp);
            }
            else{
                rec.Module_Configuration = new List<TemplateConfigWrapper.Module_Configuration>{recTemp};
            }
        
        }
        
        System.debug('### JSON.serialize(rec) '+JSON.serialize(rec));
        return (JSON.serialize(rec));
    }
    
    public static String createListOfWrapper(Map<Id, MSD_CORE_HEQ_Template_File_Metadata__c> mapOfFileMetadata, Map<String, MSD_CORE_HEQ_Template_File_Section__c> mapOfSections, Map<String, MSD_CORE_HEQ_Template_File_Mapping__c> mapOfMappings, Map<String, MSD_CORE_HEQ_Template_Module_Config__c> mapOfConfigs) {
		
        Map<Id, TemplateConfigWrapper> mapOfTemplateConfigWrapper = new Map<Id, TemplateConfigWrapper>();
        
        for( MSD_CORE_HEQ_Template_File_Metadata__c recTempFile : mapOfFileMetadata.values()) {
            TemplateConfigWrapper rec = new TemplateConfigWrapper();
            rec.job_code = recTempFile.MSD_CORE_Job_Code__c;
            rec.user_id = recTempFile.MSD_CORE_User_Id__c;
            rec.template_id = recTempFile.Id;
            rec.template_name = recTempFile.Name;
            rec.template_language = recTempFile.MSD_CORE_HEQ_Template_Language__c;
            rec.status = recTempFile.MSD_CORE_Status__c;
            rec.canvas_configuration = new List<TemplateConfigWrapper.Canvas_configuration>() ;
            rec.mappings = new List<TemplateConfigWrapper.Mappings>();
        	rec.thumbnail = recTempFile.MSD_CORE_Thumbnail_URL__c;
            rec.template_author = recTempFile.MSD_CORE_Template_Author_Name__c;
            rec.template_approver = recTempFile.MSD_CORE_Template_Approver__c;
            rec.template_approved_date = recTempFile.Template_Approved_Date__c;
            rec.template_submitted_date = recTempFile.MSD_CORE_HEQ_Template_Submitted_Date__c;
            mapOfTemplateConfigWrapper.put(recTempFile.id, rec);
        }
        
        for( MSD_CORE_HEQ_Template_File_Section__c recInnerTemp1 : mapOfSections.values()) {
            
            TemplateConfigWrapper rec = mapOfTemplateConfigWrapper.get(recInnerTemp1.MSD_CORE_HEQ_Template_File_Metadata__c);
            TemplateConfigWrapper.Canvas_configuration recTemp = new TemplateConfigWrapper.Canvas_configuration();
            TemplateConfigWrapper.Module_Configuration configRec = new TemplateConfigWrapper.Module_Configuration();
            
            recTemp.id = recInnerTemp1.MSD_CORE_HEQ_Section_Id__c;
            recTemp.type = recInnerTemp1.MSD_CORE_HEQ_Type__c;
            recTemp.x = Double.ValueOf(recInnerTemp1.MSD_CORE_HEQ_X_Coordinate__c);
            recTemp.y = Double.ValueOf(recInnerTemp1.MSD_CORE_HEQ_Y_Coordinate__c);
            recTemp.element_name = recInnerTemp1.MSD_CORE_HEQ_Element_Name__c;
            recTemp.element_url = recInnerTemp1.MSD_COR_HEQ_Element_URL__c;
            recTemp.width = Double.ValueOf(recInnerTemp1.MSD_CORE_HEQ_Width__c);
            recTemp.height = Double.ValueOf(recInnerTemp1.MSD_CORE_HEQ_Height__c);
            recTemp.customizable = recInnerTemp1.MSD_CORE_HEQ_Customizable__c;
            recTemp.page_number = Integer.valueOf(recInnerTemp1.MSD_CORE_Page_Number__c != NULL ?recInnerTemp1.MSD_CORE_Page_Number__c:'0');
            recTemp.placeholder = recInnerTemp1.MSD_CORE_HEQ_Original_Element_Url__c;
            if(rec.canvas_configuration.size()>0) {
                rec.canvas_configuration.add(recTemp);
            } else {
                rec.canvas_configuration = new List<TemplateConfigWrapper.Canvas_configuration> {recTemp};
            }
            
        }      
        
        for(MSD_CORE_HEQ_Template_File_Mapping__c recInnerTemp2 : mapOfMappings.values()) {
            
            TemplateConfigWrapper rec = mapOfTemplateConfigWrapper.get(recInnerTemp2.MSD_CORE_HEQ_Template_File_Section__r.MSD_CORE_HEQ_Template_File_Metadata__c);
            TemplateConfigWrapper.Mappings recTemp = new TemplateConfigWrapper.Mappings();
            
            recTemp.zone_id = recInnerTemp2.MSD_CORE_HEQ_Zone_Id__c;
            recTemp.module_id = recInnerTemp2.MSD_CORE_HEQ_Template_Module__r.MSD_CORE_HEQ_Module_Id__c;
            recTemp.module_name = recInnerTemp2.MSD_CORE_HEQ_Module_Name__c;
            recTemp.asset_link = recInnerTemp2.MSD_CORE_HEQ_Asset_Link__c;
            
            if(rec.mappings.size()>0) {
                rec.mappings.add(recTemp);
            } else {
                rec.mappings = new List<TemplateConfigWrapper.mappings> {recTemp};
            }    
        }

        System.debug('### mapOfConfigs ### '+JSON.serialize(mapOfConfigs.values()));
        
        for( MSD_CORE_HEQ_Template_Module_Config__c config : mapOfConfigs.values()) {
            TemplateConfigWrapper rec = mapOfTemplateConfigWrapper.get(config.MSD_CORE_Template_File_Metadata__c);
            Module_Configuration recTemp = new TemplateConfigWrapper.Module_Configuration();
            recTemp.id = config.Id;
            recTemp.label = config.MSD_CORE_Label__c;
            recTemp.type = config.MSD_CORE_Type__c;
            for(MSD_CORE_HEQ_Template_Module_Options__c optionRec : config.HEQ_Template_Module_Options__r){
                TemplateConfigWrapper.Options optionWrapperRec = new TemplateConfigWrapper.Options();
                optionWrapperRec.checked = optionRec.MSD_CORE_Checked__c;
                optionWrapperRec.label = optionRec.MSD_CORE_Label__c;
                optionWrapperRec.order = optionRec.Order__c;
                optionWrapperRec.thumbnail = optionRec.MSD_CORE_Thumbnail__c;
                optionWrapperRec.id = optionRec.MSD_CORE_HEQ_Option_Id__c;
                if(recTemp.options != NULL && recTemp.options.size() > 0){
                    recTemp.options.add(optionWrapperRec);
                } 
                else{
                    recTemp.options = new List<TemplateConfigWrapper.options>();
                    recTemp.options.add(optionWrapperRec);
                }
            }
            
            recTemp.helpText = config.MSD_CORE_Help_Text__c;
            recTemp.validationError = config.MSD_CORE_Validation_Error__c;
            recTemp.hasImages = config.MSD_CORE_Has_Images__c;
            recTemp.noOfSelection = config.MSD_CORE_HEQ_Number_Of_Selection__c;

            if(rec.Module_Configuration != NULL && rec.Module_Configuration.size() > 0){
                rec.Module_Configuration.add(recTemp);
            }
            else{
                rec.Module_Configuration = new List<TemplateConfigWrapper.Module_Configuration>{recTemp};
            }
        
        }
        
        System.debug('### JSON.serialize(rec) '+JSON.serialize(mapOfTemplateConfigWrapper.values()));
        return (JSON.serialize(mapOfTemplateConfigWrapper.values()));        
    }
    
    public class Canvas_configuration {
        public String id;
        public String type;
        public Double x;
        public Double y;
        public String element_name;
        public String element_url;
        public Double width;
        public Double height;
        public Boolean customizable;
        public Integer page_number;
        public String placeholder;
    }
    
    public String job_code;
    public String user_id;
    public String template_id;
    public String design_name;
    public String template_language;
    public String status;
    public String thumbnail;
    public String comments;
    public String template_name;
    public String template_approver;
    public String template_author;
    public String template_approved_date;
    public String template_submitted_date;
    public List<Canvas_configuration> canvas_configuration;
    public List<Mappings> mappings;
    public List<Module_Configuration> module_configuration;
    
    
    public class Mappings {
        public String zone_id;
        public String module_id;
        public String module_name;
        public String asset_link;
    }
    
    public class Module_Configuration {
		public String id;	
		public String label;
		public String type;
		public Options[] options;
		public String helpText;
		public String validationError;
		public boolean hasImages;
        public String noOfSelection;
        public Module module;
	}
    
	public class Options {
		public String id;
		public String label;
		public String thumbnail;
		public boolean checked;
		public String order;
	}
    
    public class Module {
        public String resource_type;
		public String name;
		public String id;
		public List<String> assets;
    }
    
}