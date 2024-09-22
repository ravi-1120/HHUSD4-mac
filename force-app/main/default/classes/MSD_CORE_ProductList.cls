/**
 * Component Name:      MSD_CORE_ProductList
 * Created By:          Focal CXM
 * Description:         Server side controller for mSD_CORE_ProductList LWC component
 * Test Class:          MSD_CORE_ProductListTest
 * @description MSD_CORE_ProductList
 */
public without sharing class MSD_CORE_ProductList {
    /**
        * @description getUserInfo
        * @return user
        * @param userId
    */
    @AuraEnabled(cacheable=true)
    public static User getUserInfo(id userId) {
        return [SELECT Id,TimeZoneSidKey FROM User WHERE Id =:userId];
    }
    
    /**
        * @description getPending
        * @return productlist
        * @param recId
        * @param userId
            */
    @AuraEnabled(cacheable=true)
    public static List<Meeting_Request_vod__c> getPending(String recId,String userId){   
        system.debug(LoggingLevel.WARN, 'recId'+recId);   
        system.debug(LoggingLevel.WARN, 'userId'+userId);  
        List<Meeting_Request_vod__c> productlist = [SELECT id from Meeting_Request_vod__c WHERE MSD_CORE_Status__c='Pending' AND MSD_CORE_Product_Payor__c=:recId AND MSD_CORE_Payor__c =: userId];
        System.debug(LoggingLevel.WARN, 'test'+productlist);
        return productlist;
    }

    /**
        * @description getAppointments
        * @param recId
        * @param userId
        * @return productlist
    */
    @AuraEnabled(cacheable=true)
    public static List<Meeting_Request_vod__c> getAppointments(String recId,String userId){
        List<Meeting_Request_vod__c> productlst = [SELECT id FROM Meeting_Request_vod__c WHERE MSD_CORE_Status__c='Approved' AND MSD_CORE_Product_Payor__c=:recId AND MSD_CORE_Payor__c =: userId];
        System.debug(LoggingLevel.WARN, 'test'+productlst);
        return productlst;
    }
    
    /**
        * @description getmfeeFilter
        * @return null
        * @param type
    */
    @AuraEnabled(cacheable=true)
    public static List<Sobject> getmfeeFilter(String type){
        if(type=='oncology') {
            return [select Name,MSD_CORE_Parent_Tumor__r.name from MSD_CORE_Tumor__c ORDER BY MSD_CORE_Sort_Order__c asc];
        }
        if(type=='nononcology') {
            return [select MSD_CORE_Phase__c,Name from MSD_CORE_Study_detail__c WHERE MSD_CORE_Medical_Therapeutic_Area__r.Name != 'Oncology' ORDER BY MSD_CORE_Phase__c ASC];
        }else {
            return null;
        }
    }

    /**
        * @description getActiveRequestsTest
        * @return activitylist
    */ 
    @AuraEnabled(cacheable=true)
    public static List<Meeting_Request_vod__c> getActiveRequestsTest(){
        List<Meeting_Request_vod__c> activitylist = new List<Meeting_Request_vod__c>();
        //string payorid = UserInfo.getUserID();
        try {
            activitylist = [ SELECT Id, Name, MHEE_Name__c, MSD_CORE_Resource__c, MSD_CORE_Resource__r.Name, MSD_CORE_Resource__r.MSD_CORE_Resource_Title__c, MSD_CORE_attendee__c, MSD_CORE_Resource_Type__c, CreatedDate, MSD_CORE_Source__c, ScheduleFilter__c FROM Meeting_Request_vod__c WHERE MSD_CORE_Source__c = 'MHEE' AND MSD_CORE_Status__c = 'pending' AND MSD_CORE_Payor__c =: UserInfo.getUserID()  ORDER BY CreatedDate DESC LIMIT 5];
            return activitylist;
        }catch (Exception e){
            System.debug(LoggingLevel.WARN, e.getLineNumber());
            System.debug(LoggingLevel.WARN, e.getMessage());
            return null;
        }
    }

    /**
        * @description getupcomingappointments
        * @return productlst
    */ 
    @AuraEnabled(cacheable=true)
    public static List<Meeting_Request_vod__c> getupcomingappointments(){   
        try {
            datetime dt = System.now();
            List<Meeting_Request_vod__c> productlst = [SELECT Name,id, Start_DateTime_vod__c, Invitee_Display_Name_vod__c,Assignee_vod__r.name, Assignee_vod__r.FirstName, Assignee_vod__r.LastName, MSD_CORE_Product_Payor__r.name, MSD_CORE_Product_Payor__r.MSD_CORE_Generic_Name__c, MSD_CORE_Product_Payor__c,createddate FROM Meeting_Request_vod__c WHERE Start_DateTime_vod__c != null ORDER BY Start_DateTime_vod__c asc limit 6];
            // where MSD_CORE_Status__c='Approved' and MSD_CORE_Source__c ='MFR' and MSD_CORE_Payor__c =: userId and Start_DateTime_vod__c>:dt
            System.debug(LoggingLevel.WARN, 'test'+productlst);
            return productlst;
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, e.getLineNumber());
            System.debug(LoggingLevel.WARN, e.getMessage());
            return null;
        }
    }

    /**
        * @description getCatalogPerProdSaved
        * @return cataloglst
        * @param recId
        * @param userId
    */    
    @AuraEnabled(cacheable=true) //Used cacheble for Wire by Tausif to solve save count issue
    public static List<MSD_CORE_Catalog__c> getCatalogPerProdSaved(String recId,String userId){   
        MSD_CORE_Eligibility__c eligibility = [SELECT Id ,Name,MSD_CORE_Organization_Type__c FROM MSD_CORE_Eligibility__c WHERE MSD_CORE_Payor__c =: userId];
        List<MSD_CORE_Content_Permission_Mapping__c> mappings = new List<MSD_CORE_Content_Permission_Mapping__c>();
        mappings = [SELECT MSD_CORE_Content_Type__c FROM MSD_CORE_Content_Permission_Mapping__c WHERE MSD_CORE_Organization_Type__c =: eligibility.MSD_CORE_Organization_Type__c AND MSD_CORE_Active__c = TRUE];
        
        List<String> contenttypes = new List<String>();
        For(MSD_CORE_Content_Permission_Mapping__c mapping : mappings){
            contenttypes.add(mapping.MSD_CORE_Content_Type__c);
        }

        system.debug(LoggingLevel.WARN, 'recId'+recId);   
        List<MSD_CORE_Library__c> libraryList = [SELECT Id, MSD_CORE_Catalog__c, MSD_CORE_Payor__c, MSD_CORE_Catalog__r.MSD_CORE_Content_Type__c ,MSD_CORE_Catalog__r.MSD_CORE_Leave_Behind__c, MSD_CORE_Catalog__r.Parent_Resource__c FROM MSD_CORE_Library__c 
                            WHERE MSD_CORE_Product_Payor__c != Null AND MSD_CORE_Payor__c =: userId AND MSD_CORE_Product_Payor__c =: recId AND 
                            MSD_CORE_Catalog__r.MSD_CORE_Document_Status__c !='Expired' AND 
                            MSD_CORE_Catalog__r.MSD_CORE_Resource_Status__c = 'Published' AND
                            MSD_CORE_Catalog__r.MSD_CORE_Content_Type__c in: contenttypes AND
                            MSD_CORE_Catalog__r.MSD_CORE_Expiration_Date__c >= TODAY];
        
        /** Find if any static leave behind post presenttion resource exists for payor. If exist remove original resource from the list */
        Set<Id> parentCatalogIds = new Set<Id>();
        for (MSD_CORE_Library__c c : libraryList){
            if(c.MSD_CORE_Catalog__r.MSD_CORE_Leave_Behind__c == 'Static Leave Behind' && c.MSD_CORE_Catalog__r.Parent_Resource__c != null){
                parentCatalogIds.add(c.MSD_CORE_Catalog__r.Parent_Resource__c);
            }
        }
        
        Set<Id> catalogid = new Set<Id>();
        for (MSD_CORE_Library__c c :libraryList){
            if(!parentCatalogIds.contains(c.MSD_CORE_catalog__c)){
                catalogid.add(c.MSD_CORE_catalog__c);
            }
        }

        List<MSD_CORE_Catalog__c> cataloglst = [SELECT Id FROM MSD_CORE_Catalog__c WHERE Id IN : catalogid];
        System.debug(LoggingLevel.WARN, 'test-->'+cataloglst);
        return cataloglst;
    }

    /**
        * @description getCatalogPerProd
        * @return cataloglst
        * @param recId
    */
    @AuraEnabled(cacheable=true)
    public static List<MSD_CORE_Catalog__c> getCatalogPerProd(String recId){
        system.debug(LoggingLevel.WARN, 'recId'+recId);   

        List<MSD_CORE_Catalog__c> cataloglst = [SELECT Id, MSD_CORE_Filter__c, name, MSD_CORE_Resource_Title__c, MSD_CORE_description__c,MSD_CORE_Product_Payor__r.name,MSD_CORE_Product_Payor__r.MSD_CORE_Product_Description__c,MSD_CORE_Product_Payor__c FROM MSD_CORE_Catalog__c WHERE MSD_CORE_Product_Payor__c =: recId AND MSD_CORE_Content_Type__c != 'Coming Soon'];
        System.debug(LoggingLevel.WARN, 'test-->'+cataloglst);
        return cataloglst;
    }

    /**
        * @description getActiveRequests
        * @return productlst
        * @param recId
        * @param userId
    */
    @AuraEnabled(cacheable=true)
    public static List<Meeting_Request_vod__c> getActiveRequests(String recId,String userId){   
        system.debug(LoggingLevel.WARN, 'recId'+recId);   
         system.debug(LoggingLevel.WARN, 'userId'+userId);  
        List<Meeting_Request_vod__c> productlst = [SELECT id FROM Meeting_Request_vod__c WHERE MSD_CORE_Status__c = 'Pending' AND MSD_CORE_Product_Payor__c =: recId AND MSD_CORE_Payor__c =: userId];
        System.debug(LoggingLevel.WARN, 'test'+productlst);
        return productlst;
    }

    /**
        * @description getCatalogRecord
        * @return cataloglst
        * @param recId
        * @param userId
    */
    @AuraEnabled(cacheable=true)
    public static MSD_CORE_Catalog__c getCatalogRecord(String recId,String userId){   
        system.debug(LoggingLevel.WARN, 'recId'+recId);
        List<MSD_CORE_Catalog__c> cataloglst = [SELECT Id,MSD_CORE_Content_Type__c,MSD_CORE_Delivery_Framework__c,MSD_CORE_Filter__c, name, MSD_CORE_Resource_Title__c, MSD_CORE_description__c, MSD_CORE_Show_Read_More__c,MSD_CORE_Product_Payor__r.MSD_CORE_Remove_Title_Description__c ,MSD_CORE_Product_Payor__r.name,MSD_CORE_Product_Payor__r.MSD_CORE_Product_Labeling__c,MSD_CORE_Product_Payor__r.MSD_CORE_Job_code__c ,MSD_CORE_Product_Payor__r.MSD_CORE_Instructions_For_Use_Link__c,MSD_CORE_Product_Payor__r.MSD_CORE_Instructions_For_Use_Label__c ,MSD_CORE_Product_Payor__r.MSD_CORE_Product_Description__c, MSD_CORE_Product_Payor__r.MSD_CORE_Medication_Guide__c,MSD_CORE_Product_Payor__c,MSD_CORE_Product_Payor__r.MSD_CORE_Prescribing_Information__c,MSD_CORE_Product_Payor__r.MSD_CORE_HCP_site__c,  MSD_CORE_Product_Payor__r.MSD_CORE_Generic_Name__c, MSD_CORE_Product_Payor__r.MSD_CORE_Dosage_Form_and_Strength__c,MSD_CORE_Leave_Behind__c, MSD_CORE_Product_Payor__r.MSD_CORE_Patient_information__c,
                                                (SELECT Id FROM Libraries__r where MSD_CORE_Payor__c =: userId) 
                                                FROM MSD_CORE_Catalog__c WHERE id =: recId];
        System.debug(LoggingLevel.WARN, 'test-->'+cataloglst);
        if(cataloglst.size() >= 1){
            return cataloglst[0];
        }
        return null;
    }

    /**
        * @description getAppointmentPerUser
        * @return productlst
        * @param userId
    */
    @AuraEnabled(cacheable=true)
    public static List<Meeting_Request_vod__c> getAppointmentPerUser(String userId){   
        try {
            system.debug(LoggingLevel.WARN, 'userId'+userId);  
            datetime dt = System.now();
            List<Meeting_Request_vod__c> productlst = [SELECT Name,id,Start_DateTime_vod__c,Invitee_Display_Name_vod__c,Assignee_vod__r.name, Assignee_vod__r.FirstName, Assignee_vod__r.LastName, MSD_CORE_Product_Payor__r.name, MSD_CORE_Product_Payor__r.MSD_CORE_Generic_Name__c, MSD_CORE_Product_Payor__c,createddate 
                                                        FROM Meeting_Request_vod__c WHERE MSD_CORE_Status__c='Approved' and MSD_CORE_Source__c ='MFR' and MSD_CORE_Payor__c =: userId and Start_DateTime_vod__c>:dt order by Start_DateTime_vod__c asc limit 6];
            System.debug(LoggingLevel.WARN, 'test'+productlst);
            return productlst;
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, e.getLineNumber());
            System.debug(LoggingLevel.WARN, e.getMessage());
            return null;
        }
    }

    /**
        * @description getAppointmentDetails
        * @return productlst
        * @param appointmentID
    */
    @AuraEnabled(cacheable=true)
    public static List<Meeting_Request_vod__c> getAppointmentDetails(String appointmentID){   
        List<Meeting_Request_vod__c> productlst = [SELECT MSD_CORE_Request_Resolution__c,MSD_CORE_Product_Payor__c, MSD_CORE_Resolution__c,
                                                    MSD_CORE_Product_Payor__r.MSD_CORE_Product_Description__c,Name,id,MSD_CORE_Resource__c,MSD_CORE_Resource__r.Name, MSD_CORE_Resource__r.MSD_CORE_Resource_Title__c,
                                                    MSD_CORE_Resource__r.MSD_CORE_Description__c, MSD_CORE_Resource__r.MSD_CORE_Show_Read_More__c, MSD_CORE_attendee__c, MSD_CORE_Meeting_preference__c,Start_DateTime_vod__c,
                                                    Invitee_Display_Name_vod__c,Assignee_vod__r.name, MSD_CORE_Product_Payor__r.MSD_CORE_Remove_Title_Description__c, MSD_CORE_Product_Payor__r.MSD_CORE_Patient_information__c, MSD_CORE_Product_Payor__r.MSD_CORE_Instructions_For_Use_Label__c, MSD_CORE_Product_Payor__r.MSD_CORE_Instructions_For_Use_Link__c, MSD_CORE_Product_Payor__r.name,MSD_CORE_Product_Payor__r.MSD_CORE_Product_Labeling__c, createddate,MSD_CORE_Product_Payor__r.MSD_CORE_Prescribing_Information__c,MSD_CORE_Product_Payor__r.MSD_CORE_HCP_site__c,MSD_CORE_Product_Payor__r.MSD_CORE_Medication_Guide__c,
                                                    MSD_CORE_Status__c, MSD_CORE_Request_Progress__c, MSD_CORE_Product_Payor__r.MSD_CORE_Job_code__c, MSD_CORE_Completion_Date__c, MSD_CORE_Shared_Date__c, MSD_CORE_Product_Payor__r.MSD_CORE_Generic_Name__c, MSD_CORE_Product_Payor__r.MSD_CORE_Dosage_Form_and_Strength__c 
                                                    FROM Meeting_Request_vod__c WHERE id =: appointmentID];
        System.debug(LoggingLevel.WARN, 'test'+productlst);
        return productlst;
    }

    /**
        * @description getmeetingtime
        * @return meettime
        * @param appointmentID
    */
    @AuraEnabled(cacheable=true)
    public static List<meetingtimeswrapper> getmeetingtime(String appointmentID){
        try {
            List<MSD_CORE_Meeting_Time__c> meettime = [SELECT Id, NAME, MSD_CORE_Meeting_Date__c, MSD_CORE_Time_Slot__c, MSD_CORE_TimeSlot__c, MSD_CORE_Meeting_Request__c FROM MSD_CORE_Meeting_Time__c WHERE MSD_CORE_Meeting_Request__c =: appointmentID];
            List<meetingtimeswrapper> meetwraplist = new List<meetingtimeswrapper>();
            for(MSD_CORE_Meeting_Time__c meet : meettime){
                meetingtimeswrapper wrap = new meetingtimeswrapper();
                wrap.meetingdate = formattedate(meet.MSD_CORE_Meeting_Date__c);
                wrap.timeslot = meet.MSD_CORE_TimeSlot__c;
                meetwraplist.add(wrap);   
            }

            return meetwraplist;    
        }
        catch(Exception e){
            System.debug(LoggingLevel.WARN, e.getLineNumber());
            System.debug(LoggingLevel.WARN, e.getMessage());
            return null;
        }
    }

    public static String formattedate(Date dateval){
        String returnval;
        try{
            // Tuesday, September 19, 2023
            DateTime DT = DateTime.newInstance(dateval.year(), dateval.month(), dateval.day());
            returnval = DT.format('EEEE')+', '+ DT.format('MMMM')+ ' '+ DT.day()+', '+DT.year();
        }catch(Exception e){
            System.debug('Error->'+e.getMessage());
            returnval = e.getMessage();
        }
        return returnval;
    }

    /**
        * @description getproductlist
        * @return productlst
        * @param userid
    */
    @AuraEnabled(cacheable=true)
    public static List<MSD_CORE_Product_Payor__c> getproductlist(String userid){
        try {
            Id loggedinuserid = [SELECT Id,ContactId FROM User where Id = :userid].ContactId;
            Contact con;
            if( loggedinuserid!=null ){
                con = [SELECT Id, Name,MSD_CORE_Health_Care_Decision_Maker__c  FROM Contact WHERE Id = :loggedinuserid AND MSD_CORE_Health_Care_Decision_Maker__c = TRUE];
            }
            
            if(con!=null){
                List<MSD_CORE_Product_Payor__c> productlst = [SELECT Id, Name, MSD_CORE_Colourcode__c, MSD_CORE_Product_Description__c, MSD_CORE_Prescribing_Information__c, MSD_CORE_Medication_Guide__c, 
                                                                MSD_CORE_Patient_information__c, MSD_CORE_Instructions_For_Use_Label__c, MSD_CORE_Instructions_For_Use_Link__c, MSD_CORE_Generic_Name__c,MSD_CORE_Dosage_Form_and_Strength__c,
                                                                (SELECT Id FROM Catalogs__r WHERE MSD_CORE_Content_Type__c != 'Coming Soon' AND MSD_CORE_Resource_Status__c = 'Published' AND MSD_CORE_Document_Status__c != 'Expired' AND MSD_CORE_Expiration_Date__c >= TODAY) 
                                                                FROM MSD_CORE_Product_Payor__c 
                                                                WHERE Related_System__c = 'MFR'
                                                                ORDER BY Name ASC];

                System.debug(LoggingLevel.WARN, 'productlst==>'+productlst);
                return productlst;
            }else{
                return null;
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, e.getLineNumber());
            System.debug(LoggingLevel.WARN, e.getMessage());
            return null;
        }
    }

    /**
        * @description newgetproductlist
        * @return conwrapper
        * @param userId
    */
    @AuraEnabled(cacheable=true)
    // public static ConWrap newgetRoleProductMapping(String roleId, String userId){       
    public static ConWrap newgetproductlist(String userId){       
        try {
            System.debug(LoggingLevel.WARN, 'NEw Product');
            
            Id loggedinuserid = [SELECT Id,ContactId FROM User WHERE Id = :userId].ContactId;
            System.debug(LoggingLevel.WARN, 'loggedinuser>'+loggedinuserid);
            Contact con;
            if( loggedinuserid!=null ){
                System.debug(LoggingLevel.WARN, 'Not null');
                con = [SELECT Id, Name, MSD_CORE_Health_Care_Decision_Maker__c FROM Contact WHERE Id =: loggedinuserid AND MSD_CORE_Health_Care_Decision_Maker__c = TRUE LIMIT 1];
                System.debug(LoggingLevel.WARN, 'con==>'+con);
            }
            
            if(con != null){
                System.debug(LoggingLevel.WARN, 'Contact not null');
                List<MSD_CORE_Product_Payor__c> productDataLst = new List<MSD_CORE_Product_Payor__c>();
                ConWrap conwrapper = new ConWrap();

                List<MSD_CORE_Product_Payor__c> productlst = [SELECT Id, Name, MSD_CORE_Colourcode__c, MSD_CORE_Generic_Name__c, MSD_CORE_Dosage_Form_and_Strength__c, MSD_CORE_Product_Description__c, MSD_CORE_Prescribing_Information__c, MSD_CORE_Medication_Guide__c, MSD_CORE_Instructions_For_Use_Label__c, MSD_CORE_Instructions_For_Use_Link__c, MSD_CORE_Patient_information__c, 
                                                             (SELECT Id FROM Libraries__r where MSD_CORE_Payor__c =: userId),  
                                                             (SELECT Id FROM Meeting_Requests__r WHERE MSD_CORE_Payor__c =: userId AND (MSD_CORE_Status__c='Approved' OR MSD_CORE_Status__c='Pending'))
                                                              FROM MSD_CORE_Product_Payor__c WHERE Related_System__c = 'MFR' ORDER BY Name ASC];
                
                List<MSD_CORE_Product_Payor__c> prodapp = [SELECT Id, Name, MSD_CORE_Colourcode__c, MSD_CORE_Generic_Name__c, MSD_CORE_Dosage_Form_and_Strength__c,  MSD_CORE_Product_Description__c, MSD_CORE_Prescribing_Information__c, MSD_CORE_Medication_Guide__c, MSD_CORE_Instructions_For_Use_Label__c, MSD_CORE_Instructions_For_Use_Link__c, MSD_CORE_Patient_information__c, 
                                                            (SELECT Id, Name FROM Meeting_Requests__r WHERE MSD_CORE_Status__c='Approved' AND MSD_CORE_Payor__c =: userId) 
                                                            FROM MSD_CORE_Product_Payor__c WHERE Related_System__c = 'MFR'];
                
                List<MSD_CORE_Product_Payor__c> newlst = new List<MSD_CORE_Product_Payor__c>();

                for(MSD_CORE_Product_Payor__c rec : productlst) {
                    if(rec.Libraries__r.size() > 0) {
                        productDataLst.add(rec);
                    }
                    else if(rec.Meeting_Requests__r.size() > 0) {
                        productDataLst.add(rec);
                    }
                }

                conwrapper.condata = productDataLst;
                conwrapper.savedcount = [SELECT Id, Name, MSD_CORE_Payor__c,MSD_CORE_Catalog__c FROM MSD_CORE_Library__c WHERE MSD_CORE_Payor__c =: userId].size() ;
                return conwrapper;
            }else {
                System.debug(LoggingLevel.WARN, 'Null');
                return null;
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, e.getLineNumber());
            System.debug(LoggingLevel.WARN, e.getMessage());
            return null;
        }
    }

    /**
        * @description newgetproductlistActive
        * @return conwrapper
        * @param userId
    */
    @AuraEnabled(cacheable=true)
    // public static ConWrap newgetRoleProductMapping(String roleId, String userId){       
    public static ConWrap newgetproductlistActive(String userId){       
        try {
            Id loggedinuserid = [SELECT Id,ContactId FROM User where Id = :userId].ContactId;
            System.debug(LoggingLevel.WARN, 'loggedinuser>'+loggedinuserid);
            Contact con;
            if( loggedinuserid!=null ){
                System.debug(LoggingLevel.WARN, 'Not null');
                con = [SELECT Id, Name, MSD_CORE_Health_Care_Decision_Maker__c  FROM Contact WHERE Id =: loggedinuserid AND MSD_CORE_Health_Care_Decision_Maker__c = TRUE LIMIT 1];
                System.debug(LoggingLevel.WARN, 'con==>'+con);
            }
            
            if(con != null){
                System.debug(LoggingLevel.WARN, 'Contact not null');
                ConWrap conwrapper = new ConWrap();
                
                List<MSD_CORE_Product_Payor__c> productlst = [SELECT Id, Name, MSD_CORE_Colourcode__c, MSD_CORE_Generic_Name__c, MSD_CORE_Dosage_Form_and_Strength__c, MSD_CORE_Product_Description__c, MSD_CORE_Prescribing_Information__c, MSD_CORE_Medication_Guide__c, 
                                                                MSD_CORE_Patient_information__c,(SELECT Id, MSD_CORE_Status__c FROM Meeting_Requests__r WHERE MSD_CORE_Status__c='Pending' AND MSD_CORE_Payor__c =: userId) 
                                                                FROM MSD_CORE_Product_Payor__c WHERE Related_System__c = 'MFR' ORDER BY Name ASC];                

                conwrapper.condata = productlst;
                conwrapper.savedcount = [SELECT Id, Name, MSD_CORE_Payor__c,MSD_CORE_Catalog__c FROM MSD_CORE_Library__c WHERE MSD_CORE_Payor__c =: userId].size() ;
                return conwrapper;
            }else {
                System.debug(LoggingLevel.WARN, 'Null');
                return null;
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, e.getLineNumber());
            System.debug(LoggingLevel.WARN, e.getMessage());
            return null;
        }
    }

    /**
        * @description getstudyDetail
        * @return studydetail
        * @param prodId
    */
    @AuraEnabled(cacheable = true)
    public static List<MSD_CORE_Study_detail__c> getstudyDetail(String prodId){
        try {
            List<MSD_CORE_Study_detail__c> studydetail = [SELECT Id, MSD_CORE_Compound__c, MSD_CORE_Compound_Warning__c, MSD_CORE_Related_Presentation__c, MSD_CORE_Therapeutic__c, Name, 
                                                            (SELECT Id,Name FROM Medical_Therapeutic_Areas__r) 
                                                            FROM MSD_CORE_Study_detail__c WHERE Id =: prodId];
            return studydetail;            
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, e.getLineNumber());
            System.debug(LoggingLevel.WARN, e.getMessage());
            return null;
        }
    }

    /**
        * @description getAEdetail
        * @return newusrwrp
        * @param userId
    */
    @AuraEnabled(cacheable = true)
    public static List<UserWrap> getAEdetail(String userId){
        try {
            User usr = [SELECT Id, ContactId from User WHERE  Id=: userId LIMIT 1];
            Contact con = [SELECT Id, Name, MSD_CORE_Medical_AE__c, MSD_CORE_Oncology_AE__c FROM Contact WHERE Id =: usr.ContactId LIMIT 1];
            List<UserWrap> newusrwrp = new List<UserWrap>();

            if (con != null) {
                Id idoncology = [SELECT Id, Name, FirstName, LastName, Phone, CommunityNickname, FullPhotoUrl,MediumPhotoUrl, Email, Title FROM User where Id=: con.MSD_CORE_Oncology_AE__c LIMIT 1].Id;
                if(idoncology != null){
                    UserWrap usrwr1 = new UserWrap();
                    usrwr1.type = 'Oncology';
                    usrwr1.usridval = idoncology;
                    newusrwrp.add(usrwr1);
                }
                Id idnononcology = [SELECT Id, Name, FirstName, LastName, Phone, CommunityNickname, FullPhotoUrl,MediumPhotoUrl, Email, Title FROM User where Id=:con.MSD_CORE_Medical_AE__c LIMIT 1].Id;
                if(idnononcology != null){
                    UserWrap usrwr2 = new UserWrap();
                    usrwr2.type = 'NonOncology';
                    usrwr2.usridval = idnononcology;
                    newusrwrp.add(usrwr2);
                }
                return newusrwrp;
            }
            return null;
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, e.getMessage());
            return  null;
        }
    }

    // Added method for Removing parent resource library record as well ============ RM ========== 01/03/2023
    /**
        * @description removeCatalogswithParent
        * @param recId
        * @param userId
    */
    @AuraEnabled
    public static void removeCatalogswithParent(String recId,String userId){
        try {
            String deletedId = '';
            MSD_CORE_Catalog__c cata = [SELECT Id, Parent_Resource__c FROM MSD_CORE_Catalog__c WHERE Id =: recId];
            deletedId = cata.Parent_Resource__c;

            List<MSD_CORE_Library__c> deleteLibratyLst = [SELECT Id, MSD_CORE_catalog__c,MSD_CORE_Product_Payor__c, MSD_CORE_catalog__r.MSD_CORE_Resource_Title__c, MSD_CORE_Payor__c FROM MSD_CORE_Library__c WHERE (MSD_CORE_catalog__c =: deletedId OR MSD_CORE_catalog__c =: recId) AND MSD_CORE_Payor__c =: userId];
			delete deleteLibratyLst;

            MSD_CORE_Notification__c mfrn = new MSD_CORE_Notification__c();
            mfrn.MSD_CORE_Read__c = false;
            Mfrn.MSD_CORE_Payor__c = userId;
            mfrn.MSD_CORE_Resource__c = recId;
            mfrn.MSD_CORE_Product_Payor__c = deleteLibratyLst[0].MSD_CORE_Product_Payor__c;
            mfrn.MSD_CORE_Activity__c = '<p style="font-size: 18px; color: #333333; font-family: Invention;font-weight: 700; line-height: 27px;font-style: normal;">You have removed <a  href='+ System.Label.MerckProductDetail+ deleteLibratyLst[0].MSD_CORE_Product_Payor__c+' target="_self" style="color: rgb(0, 133, 124);text-decoration: underline;text-decoration-color: rgb(0, 133, 124); font-size: 18px;font-weight: 700; line-height: 27px;font-style: normal;"><style="font-size: 18px;font-family: Invention; color: rgb(0, 133, 124); font-family: Invention;font-weight: 700; line-height: 27px;font-style: normal;">'+deleteLibratyLst[0].MSD_CORE_catalog__r.MSD_CORE_Resource_Title__c+'</a><style="font-size: 18px; color: #333333; font-family: Invention;font-weight: 700; line-height: 27px;font-style: normal;"> for your library.</p>';
            insert mfrn;
            
            
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Errror--->'+e.getMessage());
        }
    }

    /**
        * @description removeCatalogs
        * @param recId
        * @param userId
    */
    @AuraEnabled
    public static void removeCatalogs(String recId,String userId){
        List<MSD_CORE_Library__c> deleteLibratyLst = [SELECT Id, MSD_CORE_catalog__c, MSD_CORE_catalog__r.Name, MSD_CORE_catalog__r.MSD_CORE_Resource_Title__c, MSD_CORE_Product_Payor__c, MSD_CORE_Product_Payor__r.Name FROM MSD_CORE_Library__c WHERE MSD_CORE_catalog__c=: recId AND MSD_CORE_Payor__c =: userId];
        system.debug(LoggingLevel.WARN, 'deleteLibratyLst==>'+deleteLibratyLst);
        delete deleteLibratyLst;

        MSD_CORE_Notification__c mfrn = new MSD_CORE_Notification__c();
        mfrn.MSD_CORE_Read__c = false;
        Mfrn.MSD_CORE_Payor__c = userId;
        mfrn.MSD_CORE_Resource__c = recId;
        mfrn.MSD_CORE_Product_Payor__c = deleteLibratyLst[0].MSD_CORE_Product_Payor__c;
        mfrn.MSD_CORE_Activity__c = '<p style="font-size: 18px; color: #333333; font-family: Invention;font-weight: 700; line-height: 27px;font-style: normal;">You have removed <a  href='+ System.Label.MerckProductDetail+ deleteLibratyLst[0].MSD_CORE_Product_Payor__c+' target="_self" style="color: rgb(0, 133, 124);text-decoration: underline;text-decoration-color: rgb(0, 133, 124); font-size: 18px;font-weight: 700; line-height: 27px;font-style: normal;"><style="font-size: 18px;font-family: Invention; color: rgb(0, 133, 124); font-family: Invention;font-weight: 700; line-height: 27px;font-style: normal;">'+deleteLibratyLst[0].MSD_CORE_catalog__r.MSD_CORE_Resource_Title__c+'</a><style="font-size: 18px; color: #333333; font-family: Invention;font-weight: 700; line-height: 27px;font-style: normal;"> for your library.</p>';
        insert mfrn;
    }

    /**
        * @description getCatalogs
        * @return cataloglst
        * @param prodId
    */
    @AuraEnabled(cacheable=true)
    public static List<MSD_CORE_Catalog__c> getCatalogs(String prodId){
        if(prodId!=null ){
            prodId = prodId;
        }else{
            prodId = 'a015i00000BfS6IAAV';
        }
        
        List<MSD_CORE_Catalog__c> catalogslst =[SELECT Id,MSD_CORE_Filter__c,Name, MSD_CORE_Resource_Title__c, MSD_CORE_Description__c,MSD_CORE_Product_Payor__c, MSD_CORE_Product_Payor__r.MSD_CORE_Product_Description__c, MSD_CORE_Product_Payor__r.MSD_CORE_Generic_Name__c, MSD_CORE_Product_Payor__r.MSD_CORE_Dosage_Form_and_Strength__c, MSD_CORE_Product_Payor__r.MSD_CORE_HCP_site__c,
                                                MSD_CORE_Product_Payor__r.Name,MSD_CORE_Product_Payor__r.MSD_CORE_Product_Labeling__c,MSD_CORE_Product_Payor__r.MSD_CORE_Information_About_Product__c,MSD_CORE_Row_Order__c, MSD_CORE_Delivery_Framework__c,MSD_CORE_Product_Payor__r.MSD_CORE_Medication_Guide__c,
                                                (SELECT id FROM Libraries__r)
                                                FROM MSD_CORE_Catalog__c 
                                                WHERE MSD_CORE_Product_Payor__c != Null AND MSD_CORE_Product_Payor__c =: prodId AND MSD_CORE_Resource_Status__c = 'Published' AND MSD_CORE_Content_Type__c != 'Coming Soon' 
                                                ORDER BY MSD_CORE_Row_Order__c ASC];
        System.debug(LoggingLevel.WARN, catalogslst);
        return catalogslst;
    }

    /**
        * @description getTotalCatalogCount
        * @return catalogslst
        * @param prodId
        * @param userId
    */
    @AuraEnabled(cacheable=true)
    public static Integer getTotalCatalogCount(String prodId, String userId){
        try {
            if(prodId!=null ){
                prodId = prodId;
            }else{
                prodId = 'a015i00000BfS6IAAV';
            }
            
            Id loggedinuserid = [SELECT Id,ContactId FROM User WHERE Id = :userId].ContactId;
            
            Contact con;
            if( loggedinuserid!=null ){
                con = [SELECT Id, Name, MSD_CORE_Health_Care_Decision_Maker__c FROM Contact WHERE Id = :loggedinuserid AND MSD_CORE_Health_Care_Decision_Maker__c = TRUE];
            }
            
            if(con!=null){
                List<MSD_CORE_Catalog__c> catalogslst = [SELECT Id, (SELECT Id FROM Libraries__r WHERE MSD_CORE_Payor__c =: userId) FROM MSD_CORE_Catalog__c 
                                                        WHERE (MSD_CORE_Product_Payor__c != Null AND MSD_CORE_Product_Payor__c =: prodId AND MSD_CORE_Resource_Status__c = 'Published' 
                                                        AND MSD_CORE_Document_Status__c !='Expired' AND MSD_CORE_Post_Presentation__c = false AND MSD_CORE_Content_Type__c != 'Coming Soon') OR (MSD_CORE_Product_Payor__c != Null AND MSD_CORE_Product_Payor__c =: prodId 
                                                        AND MSD_CORE_Resource_Status__c = 'Published' AND MSD_CORE_Document_Status__c !='Expired' AND MSD_CORE_Post_Presentation__c = true AND MSD_CORE_Payor__c =:userId AND MSD_CORE_Content_Type__c != 'Coming Soon')];
                System.debug(LoggingLevel.WARN, catalogslst);
                return catalogslst.size();  
            }
            else{
                return 0;
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, e.getLineNumber());
            System.debug(LoggingLevel.WARN, e.getMessage());
            return 0;
        }
    }

    /**
        * @description getLibraryCatalogCount
        * @return recCount
        * @param prodId
        * @param userId
    */
    @AuraEnabled(cacheable=true)
    public static Integer getLibraryCatalogCount(String prodId, String userId){
        Integer recCount = 0;
        try{
            List<MSD_CORE_Library__c> libraryList = [SELECT Id, MSD_CORE_Catalog__c, MSD_CORE_Payor__c, MSD_CORE_Catalog__r.MSD_CORE_Leave_Behind__c, MSD_CORE_Catalog__r.Parent_Resource__c FROM MSD_CORE_Library__c 
                                                    WHERE MSD_CORE_Product_Payor__c != Null AND MSD_CORE_Payor__c =: userId AND MSD_CORE_Product_Payor__c =: prodId AND 
                                                    MSD_CORE_Catalog__r.MSD_CORE_Document_Status__c !='Expired' AND 
                                                    MSD_CORE_Catalog__r.MSD_CORE_Resource_Status__c = 'Published' AND
                                                    MSD_CORE_Catalog__r.MSD_CORE_Expiration_Date__c >= TODAY];
            
            /** Find if any static leave behind post presenttion resource exists for payor. If exist remove original resource from the list */
            Set<Id> parentCatalogIds = new Set<Id>();
            for (MSD_CORE_Library__c c : libraryList){
                if((c.MSD_CORE_Catalog__r.MSD_CORE_Leave_Behind__c == 'Static Leave Behind' && c.MSD_CORE_Catalog__r.Parent_Resource__c != null) || c.MSD_CORE_Catalog__r.MSD_CORE_Delivery_Framework__c == 'View upon Request'){
                    parentCatalogIds.add(c.MSD_CORE_Catalog__r.Parent_Resource__c);
                }
            }
            Set<Id> catalogid = new Set<Id>();
            for (MSD_CORE_Library__c c : libraryList){
                if(!parentCatalogIds.contains(c.MSD_CORE_catalog__c)){
                    catalogid.add(c.MSD_CORE_catalog__c);
                }
            }
            recCount = [SELECT count() FROM MSD_CORE_Catalog__c WHERE Id IN : catalogid];
        }catch(Exception ex){
            System.debug(LoggingLevel.WARN, ex);
        }
        return recCount;
    }
     
    /**
        * @description getCatalogsByOffset
        * @return catalogslst
        * @param prodId
        * @param userId
        * @param  pageSize
        * @param  pageNumber
    */
    @AuraEnabled(cacheable=true)
    public static List<MSD_CORE_Catalog__c> getCatalogsByOffset(String prodId, String userId,String pageSize,String pageNumber){
        Integer ps = Integer.valueOf(pageSize);
        Integer pn = Integer.valueOf(pageNumber) - 1;
        Integer offsetValue = ps * pn;

        try {
            if(prodId!=null ){
                prodId = prodId;
            }else{
                prodId = 'a015i00000BfS6IAAV';
                prodId = 'a8M7X0000004V6VUAU';
            }
            
            Id loggedinuserid = [Select Id,ContactId from User where Id = :userId].ContactId;
            
            Contact con;
            if( loggedinuserid!=null ){
                con = [SELECT Id, Name, MSD_CORE_Health_Care_Decision_Maker__c  FROM Contact WHERE Id = :loggedinuserid AND MSD_CORE_Health_Care_Decision_Maker__c = TRUE];
            }
            
            if(con!=null){
                List<MSD_CORE_Catalog__c> catalogslst = [SELECT Id,MSD_CORE_Filter__c, Name, MSD_CORE_Resource_Title__c, MSD_CORE_Description__c, MSD_CORE_Product_Payor__c, MSD_CORE_Product_Payor__r.MSD_CORE_Product_Description__c, MSD_CORE_Product_Payor__r.MSD_CORE_Prescribing_Information__c,
                                                        MSD_CORE_Product_Payor__r.MSD_CORE_HCP_site__c,MSD_CORE_Product_Payor__r.Name, MSD_CORE_Product_Payor__r.MSD_CORE_Information_About_Product__c, MSD_CORE_Row_Order__c,MSD_CORE_Product_Payor__r.MSD_CORE_Generic_Name__c, MSD_CORE_Product_Payor__r.MSD_CORE_Dosage_Form_and_Strength__c, MSD_CORE_Product_Payor__r.MSD_CORE_Medication_Guide__c,
                                                        MSD_CORE_Delivery_Framework__c,MSD_CORE_Document_Rendition__c, MSD_CORE_Post_Presentation__c, (SELECT Id FROM Libraries__r WHERE MSD_CORE_Payor__c =: userId) 
                                                        FROM MSD_CORE_Catalog__c 
                                                        WHERE (MSD_CORE_Product_Payor__c != Null AND MSD_CORE_Product_Payor__c =: prodId  AND MSD_CORE_Resource_Status__c = 'Published' AND MSD_CORE_Document_Status__c !='Expired' AND MSD_CORE_Post_Presentation__c = false AND MSD_CORE_Content_Type__c != 'Coming Soon') 
                                                        OR (MSD_CORE_Product_Payor__c != Null AND MSD_CORE_Product_Payor__c =: prodId  AND MSD_CORE_Resource_Status__c = 'Published' AND MSD_CORE_Document_Status__c !='Expired' AND MSD_CORE_Post_Presentation__c = true AND MSD_CORE_Payor__c =:userId AND MSD_CORE_Content_Type__c != 'Coming Soon') 
                                                        ORDER BY MSD_CORE_Row_Order__c ASC LIMIT :ps OFFSET :offsetValue];
                System.debug(LoggingLevel.WARN, 'catalogslst-->'+catalogslst);
                System.debug(LoggingLevel.WARN, 'catalogslst-->'+catalogslst.size());
                return catalogslst;  
            }else{
                return null;
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, e.getLineNumber());
            System.debug(LoggingLevel.WARN, e.getMessage());
            return null;
        }
    }

    /**
        * @description getCatalogs
        * @return catalogslst
        * @param prodId
        * @param userId
    */
    @AuraEnabled
    public static List<MSD_CORE_Catalog__c> getCatalogs(String prodId, String userId){
        try {
            if(prodId!=null ){
                prodId = prodId;
            }else{
                prodId = 'a015i00000BfS6IAAV';
            }
            
            Id loggedinuserid = [Select Id,ContactId from User where Id = :userId].ContactId;
            
            Contact con;
            if( loggedinuserid!=null ){
                con = [SELECT Id, Name, MSD_CORE_Health_Care_Decision_Maker__c FROM Contact WHERE Id = :loggedinuserid AND MSD_CORE_Health_Care_Decision_Maker__c = TRUE];
            }
            
            if(con != null){
                List<MSD_CORE_Catalog__c> catalogslst = [SELECT Id,MSD_CORE_Filter__c, Name, MSD_CORE_Resource_Title__c, MSD_CORE_Description__c, MSD_CORE_Product_Payor__c, MSD_CORE_Product_Payor__r.MSD_CORE_Product_Description__c, MSD_CORE_Product_Payor__r.MSD_CORE_Prescribing_Information__c,
                                                        MSD_CORE_Product_Payor__r.MSD_CORE_HCP_site__c,MSD_CORE_Product_Payor__r.Name, MSD_CORE_Product_Payor__r.MSD_CORE_Information_About_Product__c, MSD_CORE_Row_Order__c,
                                                        MSD_CORE_Delivery_Framework__c, (SELECT Id FROM Libraries__r WHERE MSD_CORE_Payor__c =: userId) 
                                                        FROM MSD_CORE_Catalog__c 
                                                        WHERE MSD_CORE_Product_Payor__c != Null AND MSD_CORE_Product_Payor__c =: prodId AND MSD_CORE_Content_Type__c != 'Coming Soon'
                                                        ORDER BY MSD_CORE_Row_Order__c ASC];
                
                System.debug(LoggingLevel.WARN, catalogslst);
                return catalogslst;  
            }
            else{
                return null;
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, e.getLineNumber());
            System.debug(LoggingLevel.WARN, e.getMessage());
            return null;
        }
    }

    /**
        * @description getproductFilter
        * @return filter
        * @param prodId
    */
    @AuraEnabled
    public static List<MSD_CORE_Filter__c> getproductFilter(String prodId ){
        try {
            List<MSD_CORE_Filter__c> filter = new List<MSD_CORE_Filter__c>();
            filter = [SELECT name,MSD_CORE_description__c FROM MSD_CORE_Filter__c WHERE MSD_CORE_Product_Payor__c =: prodId];
            return filter;
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, e.getLineNumber());
            System.debug(LoggingLevel.WARN, e.getMessage());
            return null;
        }
    }

    /**
        * @description getProducts
        * @return productlst
        * @param prodId
    */
    @AuraEnabled(cacheable=true)
    public static List<MSD_CORE_Product_Payor__c> getProducts(String prodId){
        try {
            List<MSD_CORE_Product_Payor__c> productlst =[SELECT Id, Name, MSD_CORE_Product_Labeling__c, MSD_CORE_Product_Description__c, MSD_CORE_Job_code__c, MSD_CORE_Instructions_For_Use_Label__c, MSD_CORE_Instructions_For_Use_Link__c, MSD_CORE_Medication_Guide__c, MSD_CORE_Prescribing_Information__c,MSD_CORE_HCP_site__c ,MSD_CORE_Information_About_Product__c, MSD_CORE_Generic_Name__c, MSD_CORE_Patient_information__c, MSD_CORE_Dosage_Form_and_Strength__c
                                                        FROM MSD_CORE_Product_Payor__c WHERE Id =:prodId AND Related_System__c = 'MFR' 
                                                        ORDER BY Name ASC];
            return productlst;             
        } catch (Exception e) {
            return null;
        }
    }
   
    /**
        * @description getProductsprodId
        * @return productlst
        * @param prodId
    */
    @AuraEnabled(cacheable=true)
    public static List<MSD_CORE_Product_Payor__c> getProductsprodId(String prodId){
        try {
            List<MSD_CORE_Product_Payor__c> productlst = [SELECT Id, Name, MSD_CORE_Product_Description__c, MSD_CORE_Prescribing_Information__c,MSD_CORE_HCP_site__c ,MSD_CORE_Information_About_Product__c
                                                          FROM MSD_CORE_Product_Payor__c WHERE Id =:prodId AND Related_System__c = 'MFR' ORDER BY Name ASC];
            return productlst; 
        } catch (Exception e) {
            return null;
        }
    }

    /**
        * @description getCatalogsFilter
        * @return catalogslst
        * @param prodId
        * @param userId
        * @param criteria
    */
    @AuraEnabled
    public static List<MSD_CORE_Catalog__c> getCatalogsFilter(String prodId, String userId, List<String> criteria ){
        try {
            if(prodId!=null ){
                prodId = prodId;
            }else{
                prodId = 'a015i00000BfS6IAAV';
            }
            
            Id loggedinuserid = [SELECT Id,ContactId FROM User WHERE Id = :userId].ContactId;
            
            Contact con;
            if( loggedinuserid!=null ){
                con = [SELECT Id, Name, MSD_CORE_Health_Care_Decision_Maker__c FROM Contact WHERE Id = :loggedinuserid ];
            }
            
            if(con!=null){
                List<Id> catalogIds = new List<Id>();
                for( MSD_CORE_Catalog__c objCatalog: [SELECT Id, MSD_CORE_Filter__c FROM MSD_CORE_Catalog__c WHERE MSD_CORE_Product_Payor__c != Null AND MSD_CORE_Product_Payor__c =: prodId AND MSD_CORE_Content_Type__c != 'Coming Soon']){
                    for(String cval: criteria ){
                        if((objCatalog.MSD_CORE_Filter__c!=null)){
                            String[] filters = objCatalog.MSD_CORE_Filter__c.split(';');
                            if(filters.contains( cval)){
                                catalogIds.add(objCatalog.Id);
                            }
                        }
                    }
                }

                List<MSD_CORE_Catalog__c> catalogslst =[SELECT Id,MSD_CORE_Filter__c, Name, MSD_CORE_Resource_Title__c, MSD_CORE_Description__c, MSD_CORE_Product_Payor__c, MSD_CORE_Product_Payor__r.MSD_CORE_Product_Description__c, MSD_CORE_Product_Payor__r.MSD_CORE_Prescribing_Information__c,
                                                        MSD_CORE_Product_Payor__r.Name, MSD_CORE_Product_Payor__r.MSD_CORE_Information_About_Product__c,MSD_CORE_Product_Payor__r.MSD_CORE_HCP_site__c,MSD_CORE_Row_Order__c, MSD_CORE_Product_Payor__r.MSD_CORE_Medication_Guide__c,
                                                        MSD_CORE_Delivery_Framework__c, (SELECT Id FROM Libraries__r WHERE MSD_CORE_Payor__c =: userId) 
                                                        FROM MSD_CORE_Catalog__c 
                                                        WHERE MSD_CORE_Product_Payor__c != Null AND MSD_CORE_Product_Payor__c =: prodId AND Id IN : catalogIds
                                                        ORDER BY MSD_CORE_Row_Order__c ASC];
                
                System.debug(LoggingLevel.WARN, catalogslst);
                return catalogslst;  
            }else{
                return null;
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, e.getLineNumber());
            System.debug(LoggingLevel.WARN, e.getMessage());
            throw new AuraHandledException('Error message to display in component'+ e.getMessage());
        }
    }

    /**
        * @description getLibraryCatalogs
        * @return MSD_CORE_Catalog
        * @param prodId
        * @param userId
        * @param pageSize
        * @param pageNumber
    */
    @AuraEnabled(Cacheable=true)
    public static List<MSD_CORE_Catalog__c> getLibraryCatalogs(String prodId, String userId, String pageSize, String pageNumber){
        try {
            System.debug(LoggingLevel.WARN, 'user');
            System.debug(LoggingLevel.WARN, userId);
            MSD_CORE_Eligibility__c eligibility = [SELECT Id ,Name,MSD_CORE_Organization_Type__c FROM MSD_CORE_Eligibility__c WHERE MSD_CORE_Payor__c =: userId];
            List<MSD_CORE_Content_Permission_Mapping__c> mappings = new List<MSD_CORE_Content_Permission_Mapping__c>();
            mappings = [SELECT MSD_CORE_Content_Type__c FROM MSD_CORE_Content_Permission_Mapping__c WHERE MSD_CORE_Organization_Type__c  =: eligibility.MSD_CORE_Organization_Type__c AND MSD_CORE_Active__c = TRUE];
            
            List<String> contenttypes = new List<String>();
            For(MSD_CORE_Content_Permission_Mapping__c mapping : mappings){
            	Contenttypes.add(mapping.MSD_CORE_Content_Type__c);
            }
            Integer ps = Integer.valueOf(pageSize);
            Integer pn = Integer.valueOf(pageNumber) - 1;
            Integer offsetValue = ps * pn;

            if(prodId!=null ){
                prodId = prodId;
            }
            List<MSD_CORE_Library__c> libraryList = [SELECT Id, MSD_CORE_Catalog__c,MSD_CORE_catalog__r.MSD_CORE_Resource_Title__c, MSD_CORE_catalog__r.MSD_CORE_Show_Read_More__c, MSD_CORE_Catalog__r.MSD_CORE_Content_Type__c, MSD_CORE_Payor__c, MSD_CORE_Catalog__r.MSD_CORE_Leave_Behind__c, MSD_CORE_Catalog__r.Parent_Resource__c FROM MSD_CORE_Library__c 
                                                    WHERE MSD_CORE_Product_Payor__c != Null AND MSD_CORE_Payor__c =: userId AND MSD_CORE_Product_Payor__c =: prodId AND
                                                    MSD_CORE_Catalog__r.MSD_CORE_Content_Type__c IN: Contenttypes AND
                                                    MSD_CORE_Catalog__r.MSD_CORE_Document_Status__c !='Expired' AND 
                                                    MSD_CORE_Catalog__r.MSD_CORE_Resource_Status__c = 'Published' AND
                                                    MSD_CORE_Catalog__r.MSD_CORE_Expiration_Date__c >= TODAY];
            
            /** Find if any static leave behind post presenttion resource exists for payor. If exist remove original resource from the list */
            Set<Id> parentCatalogIds = new Set<Id>();
            for (MSD_CORE_Library__c c : libraryList){
                if(c.MSD_CORE_Catalog__r.MSD_CORE_Leave_Behind__c == 'Static Leave Behind' && c.MSD_CORE_Catalog__r.Parent_Resource__c != null){
                    parentCatalogIds.add(c.MSD_CORE_Catalog__r.Parent_Resource__c);
                }
            }
            Set<Id> catalogid = new Set<Id>();
            for (MSD_CORE_Library__c c : libraryList){
                if(!parentCatalogIds.contains(c.MSD_CORE_catalog__c)){
                    catalogid.add(c.MSD_CORE_catalog__c);
                }
            }
            
            User commUser = [SELECT Id, ContactId FROM User WHERE Id =: userId];
            Contact con;
      
            return [SELECT Id,MSD_CORE_Filter__c, Name, MSD_CORE_Resource_Title__c, MSD_CORE_Description__c, MSD_CORE_Show_Read_More__c, MSD_CORE_Product_Payor__c, MSD_CORE_Product_Payor__r.MSD_CORE_Product_Description__c,MSD_CORE_Expiration_Date__c,Parent_Resource__c,MSD_CORE_Read__c,
                    MSD_CORE_Product_Payor__r.Name,MSD_CORE_Product_Payor__r.MSD_CORE_Information_About_Product__c,MSD_CORE_Row_Order__c,MSD_CORE_Product_Payor__r.MSD_CORE_HCP_site__c,MSD_CORE_Product_Payor__r.MSD_CORE_Generic_Name__c,
                    MSD_CORE_Delivery_Framework__c,(Select id from Libraries__r), MSD_CORE_Document_Rendition__c, MSD_CORE_Post_Presentation__c
                    FROM MSD_CORE_Catalog__c WHERE Id IN : catalogid 
                    ORDER BY MSD_CORE_Row_Order__c ASC LIMIT :ps OFFSET : offsetValue];
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, e.getLineNumber());
            System.debug(LoggingLevel.WARN, e.getMessage());
            return null;
        }
    }

    /**
        * @description getLibraryCatalogs1
        * @return productListWrapperobj
        * @param prodId
        * @param userId
        * @param pageSize
        * @param pageNumber
    */
    @AuraEnabled(Cacheable=true)
    public static ProductListWrapper getLibraryCatalogs1(String prodId, String userId,String pageSize,String pageNumber){
        try {
            System.debug(LoggingLevel.WARN, 'user');
            System.debug(LoggingLevel.WARN, userId);

            Integer ps = Integer.valueOf(pageSize);
            Integer pn = Integer.valueOf(pageNumber) - 1;
            Integer offsetValue = ps * pn;

            if(prodId!=null ){
                prodId = prodId;
            }
            List<MSD_CORE_Library__c> catalogList = [SELECT Id,MSD_CORE_Catalog__c, MSD_CORE_Payor__c FROM MSD_CORE_Library__c WHERE MSD_CORE_Payor__c =:userId AND MSD_CORE_Product_Payor__c =:prodId];
            Set<Id> catalogid = new Set<Id>();
            for (MSD_CORE_Library__c c : catalogList){
                catalogid.add(c.MSD_CORE_catalog__c);
            }
            
            User commUser = [Select Id,ContactId from User where Id = :userId];
            Contact con;
      
            ProductListWrapper productListWrapperobj = new ProductListWrapper();
            productListWrapperobj.totalRecords = [SELECT count() FROM MSD_CORE_Catalog__c 
                                                WHERE MSD_CORE_Product_Payor__c != Null AND MSD_CORE_Product_Payor__c =: prodId AND MSD_CORE_Resource_Status__c = 'Published' AND Id IN : catalogid];
            
            productListWrapperobj.productList = [SELECT Id,MSD_CORE_Filter__c, Name, MSD_CORE_Resource_Title__c, MSD_CORE_Description__c, MSD_CORE_Show_Read_More__c, MSD_CORE_Product_Payor__c, MSD_CORE_Product_Payor__r.MSD_CORE_Product_Description__c,
                                                    MSD_CORE_Product_Payor__r.Name,MSD_CORE_Product_Payor__r.MSD_CORE_Information_About_Product__c,MSD_CORE_Row_Order__c,MSD_CORE_Product_Payor__r.MSD_CORE_HCP_site__c,
                                                    MSD_CORE_Delivery_Framework__c,(Select id from Libraries__r)
                                                    FROM MSD_CORE_Catalog__c 
                                                    WHERE MSD_CORE_Product_Payor__c != Null AND MSD_CORE_Product_Payor__c =: prodId AND MSD_CORE_Resource_Status__c = 'Published' AND Id IN : catalogid 
                                                    ORDER BY MSD_CORE_Row_Order__c ASC LIMIT :ps OFFSET :offsetValue];

            return productListWrapperobj;
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, e.getLineNumber());
            System.debug(LoggingLevel.WARN, e.getMessage());
            return null;
        }
    }

     /**
        * @description getPdfDownloadLink
        * @return contentDistributions
    */
    @AuraEnabled(Cacheable=true)
    public static String getPdfDownloadLink(){
        try {
            String contentDocumentId = '0695i000004RmlKAAS';

            List<ContentDistribution> contentDistributions = [SELECT Id, ContentDownloadUrl, DistributionPublicUrl FROM ContentDistribution
                                                              WHERE ContentDocumentId =: contentDocumentId LIMIT 1 ];
            System.debug(LoggingLevel.WARN, 'contentDistributions===>'+contentDistributions);
            if( !contentDistributions.isEmpty() && String.isNotBlank(contentDistributions[0].ContentDownloadUrl) ){
                return contentDistributions[0].ContentDownloadUrl;
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Some excellent error messaging');
        }
        return null;
    }

    /**
        * @description createRelatedLibrary
        * @param lib
    */
    @AuraEnabled
    public static void createRelatedLibrary(MSD_CORE_Library__c lib ){
        try{
            insert lib;
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
        * @description createMeetingRequest
        * @return objres
        * @param request
    */
    @AuraEnabled
    public static Response createMeetingRequest(String request){   
        try {
            system.debug(LoggingLevel.WARN, 'request-->'+request);
            List<Meeting_Request_vod__c> lstMeetingRequest = (List<Meeting_Request_vod__c>)System.JSON.deserializeStrict(request, List<Meeting_Request_vod__c>.class); 
            System.debug(LoggingLevel.WARN, 'lstMeetingRequest===>'+lstMeetingRequest);
            upsert lstMeetingRequest;
            System.debug(LoggingLevel.WARN, lstMeetingRequest);
            Response objres = new Response();
            objres.status = 'SUCCESS';
            Meeting_Request_vod__c meetingReq = [select Id, Name, MHEE_Name__c from Meeting_Request_vod__c where Id=:lstMeetingRequest[0].Id ];
            objres.message = meetingReq.Name;
            objres.data = meetingReq;
            System.debug(LoggingLevel.WARN, 'objres-->'+objres);
            return objres;
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, e.getLineNumber());
            System.debug(LoggingLevel.WARN, e.getMessage());
            Response objres = new Response();
            objres.status = String.valueOf(e.getLineNumber());
            objres.message = 'ERROR';
            objres.data = e.getMessage();
            return objres;
        }
    }

    //RT
    /**
        * @description getschedulefilter
        * @return Meeting_Request_vod__c
        * @param requestID
    */
    @AuraEnabled(cacheable = true)
    public static List<Meeting_Request_vod__c> getschedulefilter(String requestID) {
        return [SELECT id,Name,	ScheduleFilter__c FROM Meeting_Request_vod__c WHERE id =: requestID];
    }

    // FOR MHEE Portal
    /**
        * @description getPdfDownloadLink
        * @return contentDistributions
        * @param request
    */
    @AuraEnabled
    public static Response createMeetingRequestMHEE(String request){   
        try {
            system.debug(LoggingLevel.WARN, 'request-->'+request);
            List<Meeting_Request_vod__c> lstMeetingRequest = (List<Meeting_Request_vod__c>)System.JSON.deserializeStrict(request, List<Meeting_Request_vod__c>.class); 
            System.debug(LoggingLevel.WARN, 'lstMeetingRequest===>'+lstMeetingRequest);
            upsert lstMeetingRequest;
            System.debug(LoggingLevel.WARN, lstMeetingRequest);
            Response objres = new Response();
            objres.status = 'SUCCESS';
            Meeting_Request_vod__c meetingReq = [select Id, Name, MHEE_Name__c from Meeting_Request_vod__c where Id=:lstMeetingRequest[0].Id ];
            objres.message = meetingReq.MHEE_Name__c;
            objres.data = meetingReq;
            System.debug(LoggingLevel.WARN, 'objres-->'+objres);
            return objres;
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, e.getLineNumber());
            System.debug(LoggingLevel.WARN, e.getMessage());
            Response objres = new Response();
            objres.status = String.valueOf(e.getLineNumber());
            objres.message = 'ERROR';
            objres.data = e.getMessage();
            return objres;
        }
    }

    /**
        * @description updatemeetstatus
        * @return meettimeids
        * @param request
    */
    @AuraEnabled
    public static List<MSD_CORE_Meeting_Time__c> updatemeetstatus(String request){
        try {
            System.debug(LoggingLevel.WARN, 'reques==>'+request);
            Requestobj wrapdata = (Requestobj)JSON.deserialize(request,Requestobj.class);
            System.debug(LoggingLevel.WARN, 'wrapdata==>'+wrapdata);

            Meeting_Request_vod__c meetreqls = [SELECT Id, Name, MSD_CORE_Payor__c, MSD_CORE_Status__c, MSD_CORE_attendee__c, MSD_CORE_Meeting_preference__c FROM Meeting_Request_vod__c WHERE Id=:wrapdata.recordId LIMIT 1];
            meetreqls.MSD_CORE_attendee__c = wrapdata.attendee;
            meetreqls.MSD_CORE_Meeting_preference__c = wrapdata.meetingPreference;
            meetreqls.MSD_CORE_Status__c = 'Pending';
            System.debug(LoggingLevel.WARN, 'meetreqls==>'+meetreqls);
            update meetreqls;

            List<MSD_CORE_Meeting_Time__c> meettimeids = [SELECT Id, Name, MSD_CORE_Meeting_Date__c, MSD_CORE_Selected__c, MSD_CORE_Time_Slot__c, MSD_CORE_Meeting_Request__c FROM MSD_CORE_Meeting_Time__c WHERE MSD_CORE_Meeting_Request__c =: meetreqls.Id];
            System.debug(LoggingLevel.WARN, 'meettimeids==>'+meettimeids);
            System.debug(LoggingLevel.WARN, 'meettimeids==>'+meettimeids.size());
            return meettimeids;
            // return null;
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, e.getLineNumber());
            System.debug(LoggingLevel.WARN, e.getMessage());
            // return e.getMessage();
            return null;
        }
    }

    /**
        * @description createtimemeet
        * @return getmessage
        * @param meetreq
        * @param datevalue
        * @param timevalue
    */
    @AuraEnabled
    public static string createtimemeet(String meetreq, Date datevalue, String timevalue){
        try {
            System.debug(LoggingLevel.WARN, 'meetreq-->'+meetreq);
            System.debug(LoggingLevel.WARN, 'datevalue-->'+datevalue);
            System.debug(LoggingLevel.WARN, 'timevalue-->'+timevalue);

            MSD_CORE_Meeting_Time__c meettime = new MSD_CORE_Meeting_Time__c();
            meettime.MSD_CORE_Meeting_Date__c = datevalue;
            meettime.MSD_CORE_Time_Slot__c = timevalue;
            meettime.MSD_CORE_Meeting_Request__c = meetreq;
            upsert meettime;
            return 'Success';
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, e);
            System.debug(LoggingLevel.WARN, e.getLineNumber());
            System.debug(LoggingLevel.WARN, e.getMessage());
            return e.getMessage();
        }
    }
    
    /**
        * @description deleteMeetingTimes
        * @return integer
        * @param requestID
    */
    @AuraEnabled
    public static Integer deleteMeetingTimes(String requestID){  
        List<MSD_CORE_Meeting_Time__c> toBeDeletedMeetingTimes = [SELECT ID,NAME FROM MSD_CORE_Meeting_Time__c WHERE MSD_CORE_Meeting_Request__c=:requestID];
        try{
            delete toBeDeletedMeetingTimes;
            return 1;
        }catch (Exception e) {
            return 0;
        }
    }

    /**
        * @description createMeetingTimes
        * @return objres
        * @param request
    */
    @AuraEnabled
    public static Response createMeetingTimes(String request){   
        System.debug('request-->'+request);
        List<MSD_CORE_Meeting_Time__c> lstMeetingTimes = (List<MSD_CORE_Meeting_Time__c>)System.JSON.deserializeStrict(request, List<MSD_CORE_Meeting_Time__c>.class); 
        System.debug('lstMeetingTimes->'+lstMeetingTimes);
        Response objres = new Response();
        objres.status = 'SUCCESS';
        try{
            upsert lstMeetingTimes;
            System.debug(LoggingLevel.WARN, lstMeetingTimes);
        }
        catch(Exception e){
            objres.status = 'FAIL';
        }
        return objres;
    }

    /**
        * @description getMeetingRequest
        * @return objres
        * @param mId
    */
    @AuraEnabled
    public static Response getMeetingRequest(String mId){   
        List<Meeting_Request_vod__c> lstMeetingRequest = [SELECT Id, MSD_CORE_attendee__c, MSD_CORE_Status__c, MSD_CORE_Meeting_preference__c, 
                                                            (Select Id, MSD_CORE_Meeting_Date__c, MSD_CORE_Time_Slot__c,MSD_CORE_TimeSlot__c from Meeting_Times__r ) 
                                                            FROM Meeting_Request_vod__c WHERE Id=: mId];
        Response objres = new Response();
        objres.data = lstMeetingRequest[0];
        return objres;
    }

    /**
     * Name         :   getBrandInformations
     * Param1       :   Parent Record Id
     * Param 2      :   Parent Object Name
     * Return       :   List of Brand_Information
     * Description  :   Method to fetch brand information configuration for a brand
     */
    @AuraEnabled(cacheable=true)
    public static Map<String,Brand_Information__c> getBrandInformations(String prodId, String objectName){
        Map<String,Brand_Information__c> result = new Map<String,Brand_Information__c>();
        try {
            String parentId = prodId;
            if(objectName == 'Catalog'){
                MSD_CORE_Catalog__c catalog = [SELECT MSD_CORE_Product_Payor__c FROM MSD_CORE_Catalog__c WHERE id =: prodId];
                parentId = catalog.MSD_CORE_Product_Payor__c;
            }
            if(objectName == 'Meeting Request'){
                Meeting_Request_vod__c meetReq = [SELECT MSD_CORE_Product_Payor__c FROM Meeting_Request_vod__c WHERE Id =: prodId];
                parentId = meetReq.MSD_CORE_Product_Payor__c;
            }
            List<Brand_Information__c> brandIndoList = [SELECT Id, Name, Section_Label__c, Label_Accordion_Collapsed__c, Label_Accordion_Expanded__c, Accordion_Preview_Desktop__c, Accordion_Preview_Mobile__c, Section_Details__c, Product_Payor__r.MSD_CORE_Product_Family__c, Show_Read_More__c, Show_Read_More_Mobile__c
                                                        FROM Brand_Information__c WHERE Product_Payor__c =: parentId];
            for(Brand_Information__c info : brandIndoList){
                result.put(info.Name, info);
            }
            return result;
        } catch (Exception e) {
            return null;
        }
    }

    // GET Indication Value FROM Product Payor Object
    /**
        * @description getProdIndication
        * @return prodp
        * @param prodId
    */
    /*
    @AuraEnabled(cacheable=true)
    public static MSD_CORE_Product_Payor__c getProdIndication(String prodId){
        try {
            MSD_CORE_Product_Payor__c prodp = [SELECT Id, Name,MSD_CORE_Indication__c,MSD_CORE_Indication_label__c,Indication_label_Expanded__c,MSD_CORE_Selected_Safety_Info_Label__c,Selected_Safety_Info_Label_Expanded__c,MSD_CORE_Information_About_Product__c,Indication_short__c,Selected_Safety_Information_short__c, MSD_CORE_Selected_Safety_Information__c, MSD_CORE_Product_Family__c, MSD_CORE_Generic_Name__c 
                                                FROM MSD_CORE_Product_Payor__c WHERE Id =: prodId AND Related_System__c = 'MFR' LIMIT 1];
            return prodp;
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Error Line Number->'+e.getLineNumber());
            System.debug(LoggingLevel.WARN, 'Error Message->'+e.getMessage());
            return null;
        }
    }
    */

    // GET Indication Value FROM Product Payor Object SAMPLE NEW COMPONENT
    /**
        * @description getProdIndication1
        * @return meetreq
        * @param prodId
    */
    /*
    @AuraEnabled(cacheable=true)
    public static Meeting_Request_vod__c getProdIndication1(String prodId){
        try {
            Meeting_Request_vod__c meetreq = [SELECT Id, Name, MSD_CORE_Product_Payor__c, MSD_CORE_Product_Payor__r.MSD_CORE_Indication__c, MSD_CORE_Product_Payor__r.Indication_short__c,MSD_CORE_Product_Payor__r.Selected_Safety_Information_short__c, MSD_CORE_Product_Payor__r.MSD_CORE_Information_About_Product__c, MSD_CORE_Product_Payor__r.MSD_CORE_Selected_Safety_Information__c,MSD_CORE_Product_Payor__r.MSD_CORE_Generic_Name__c,MSD_CORE_Product_Payor__r.MSD_CORE_Product_Family__c 
                                              FROM Meeting_Request_vod__c WHERE Id =: prodId];
            return meetreq;
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Error Line Number->'+e.getLineNumber());
            System.debug(LoggingLevel.WARN, 'Error Message->'+e.getMessage());
            return null;
        }
    }
    */
    // GET Indication Value FROM Product Payor Object SAMPLE NEW COMPONENT
    /**
        * @description getProdIndication2
        * @return cataloglst
        * @param prodId
    */
    /*
    @AuraEnabled(cacheable=true)
    public static MSD_CORE_Catalog__c getProdIndication2(String prodId){
        try {
            MSD_CORE_Catalog__c cataloglst = [SELECT id,MSD_CORE_Product_Payor__r.MSD_CORE_Indication__c,MSD_CORE_Product_Payor__r.MSD_CORE_Product_Family__c,MSD_CORE_Product_Payor__r.MSD_CORE_Generic_Name__c, MSD_CORE_Product_Payor__r.Indication_short__c,MSD_CORE_Product_Payor__r.Selected_Safety_Information_short__c, MSD_CORE_Product_Payor__r.MSD_CORE_Information_About_Product__c, MSD_CORE_Product_Payor__r.MSD_CORE_Selected_Safety_Information__c 
                                              FROM MSD_CORE_Catalog__c WHERE id =: prodId];
            return cataloglst;
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Error Line Number->'+e.getLineNumber());
            System.debug(LoggingLevel.WARN, 'Error Message->'+e.getMessage());
            return null;
        }
    }
    */
    /**
        * @description getExecutiveContacts
        * @return Contact
    */
    @AuraEnabled(cacheable=true)
    public static List<Contact> getExecutiveContacts(){
        return [SELECT Id, Name, MailingState, Phone, Email FROM Contact LIMIT 5];
    }
    
    /**
        * @description getPrimaryExecutive
        * @return User
        * @param userId
    */
    @AuraEnabled(cacheable=true)
    public static List<User> getPrimaryExecutive(String userId){
        User usr = [SELECT Id, ContactId FROM User WHERE Id=: userId LIMIT 1];
        Contact con = [SELECT Id, Primary_Executive__c FROM Contact WHERE Id=: usr.ContactId LIMIT 1];
        if(con != null){
            return [SELECT Id, Name, FirstName, LastName,  Phone, Email, Title,FullPhotoUrl, MediumPhotoUrl FROM User WHERE Id=:con.Primary_Executive__c Limit 1];
        }
        return null;
    }

    /**
        * @description getUserDetails
        * @return User
        * @param userId
    */
    @AuraEnabled(cacheable=true)
    public static List<User> getUserDetails(String userId){
        return [SELECT Id, Name, Phone, Email, AccountId FROM User WHERE Id=:userId Limit 1];
    }

    /**
        * @description getLicenses
        * @return License__c
        * @param contactId
    */
    @AuraEnabled(cacheable=true)
    public static List<License__c> getLicenses(String contactId){
        return [SELECT Id, MSD_CORE_Consultation_on_behalf__c, MSD_CORE_Organization_Type__c, Contact__c, MSD_CORE_Email_Address__c, MSD_CORE_License_Number__c, MSD_CORE_License_State__c, Name, MSD_CORE_Type_of_license__c FROM License__c WHERE Contact__c=:contactId];
    }

    /**
        * @description getcontentconnector
        * @return strval
        * @param docurl
    */
    @AuraEnabled
    public static string getcontentconnector(String docurl){
        try {
            String strval = MSD_CORE_MFR_AWSController.generateSingedURL(docurl);
            return strval;
        } catch (Exception e) {
            return e.getMessage();
        }
    }

    /**
        * @description getContactRole
        * @return contactrole
        * @param userId
    */
    @AuraEnabled(cacheable=true)
    public static string getContactRole(String userId) {
        try {
            Id contactid = [SELECT Id, ContactID FROM User WHERE Id =: userId].ContactId;
            String contactrole = [SELECT Id, MSD_CORE_Role__c FROM Contact WHERE Id =: contactid].MSD_CORE_Role__c;
            return contactrole;
        } catch (Exception e) {
            return e.getMessage();
        }
    }
    
    /**
        * @description ConWrap class
    */
    public class ConWrap{
        /**
         * @description condata
         * @return condata
         */
        @AuraEnabled public List<MSD_CORE_Product_Payor__c> condata{get;set;}
        
        /**
         * @description savedcount
         * @return savedcount
         */
        @AuraEnabled public Integer savedcount{get;set;}
    }

    /**
        * @description getDiseaseTopics
        * @return lstDiseaseTopic
        * @param meetingID
    */
    @InvocableMethod(label = 'Get GetDiseaseTopics with More' description = 'Get GetDiseaseTopics with More')
    public static list<String> getDiseaseTopics(List<String> meetingID){
        Meeting_Request_vod__c  meetingRequest = [Select ID,ScheduleFilter__c from Meeting_Request_vod__c where id =: meetingID[0]];
        String schedulefilter =meetingRequest.ScheduleFilter__c;
        String diseaseTopic = '';
        list<String> lstDiseaseTopic= new list<String>();
        Integer counterval = 0;
        if(!String.isEmpty(schedulefilter)){
            String[] schedulefilterObj = schedulefilter.split(',');
            System.debug(LoggingLevel.WARN, 'schedulefilterObj ' + schedulefilterObj);
            if (schedulefilterObj!=null) {
                if (schedulefilterObj.size() == 1) {
                    diseaseTopic = schedulefilterObj[0];
                } else {
                    for (String sFilter : schedulefilterObj) {
                        if (diseaseTopic.length() == 0) {
                            diseaseTopic = sFilter;
                        } else {
                            counterval += 1;
                        }
                    }
                
                    diseaseTopic = diseaseTopic + ' (+' + counterval + ' more)';
                }
            }
        }
        System.debug(LoggingLevel.WARN, 'diseaseTopic ' + diseaseTopic);
        lstDiseaseTopic.add(diseaseTopic);
        return lstDiseaseTopic;
    }

    /**
        * @description Response class
    */
    public class Response{
        /**
         * @description status
         * @return status
         */
        @AuraEnabled public String status {get;set;}

        /**
         * @description message
         * @return message
         */
        @AuraEnabled public String message{get;set;}
        
        /**
         * @description data
         * @return data
         */
        @AuraEnabled public object data{get;set;}
    }

    // For Update Meeting status
    /**
        * @description Requestobj
    */
    public class Requestobj{
        /**
         * @description recordId
         * @return recordId
         */
        @AuraEnabled public string recordId{get;set;}
        
        /**
         * @description attendee
         * @return attendee
         */
        @AuraEnabled public String attendee{get;set;}
        
        /**
         * @description appointmentdate
         * @return appointmentdate
         */
        @AuraEnabled public String appointmentdate{get;set;}

        /**
         * @description appointmenttime
         * @return appointmenttime
         */
        @AuraEnabled public String appointmenttime{get;set;}
        
        /**
         * @description meetingPreference
         * @return meetingPreference
         */
        @AuraEnabled public String meetingPreference{get;set;}
    }

    /**
        * @description ProductListWrapper
    */
    public class ProductListWrapper{
        /**
         * @description totalRecords
         * @return totalRecords
         */
        @AuraEnabled public Integer totalRecords{get;set;}
        
        /**
         * @description productList
         * @return productList
         */
        @AuraEnabled public List<MSD_CORE_catalog__c> productList {get;set;}
    }

    /**
        * @description UserWrap
    */
    public class UserWrap{
        /**
         * @description type
         * @return type
         */
        @AuraEnabled public String type{get;set;}
        
        /**
         * @description usridval
         * @return usridval
         */
        @AuraEnabled public Id usridval {get;set;}
    }

    /**
        * @description meetingtimeswrapper
    */
    public class meetingtimeswrapper{
        /**
         * @description string
         * @return string
         */
        @AuraEnabled public String meetingdate{get;set;}
        
        /**
         * @description timeslot
         * @return timeslot
         */
        @AuraEnabled public String timeslot {get;set;}
    }
}