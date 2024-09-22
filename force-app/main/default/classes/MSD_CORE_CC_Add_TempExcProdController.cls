public class MSD_CORE_CC_Add_TempExcProdController {
	@AuraEnabled
    //Case objCase, String requestType, String custId
    public static String createChildComboCase(String caseId){
        Case childCase = new Case();
        Map<String,Id> recordTypeMap = new Map<String,Id>();
        List<RecordType> allCaseTypes = [select Id,DeveloperName from RecordType where SObjectType='Case'];
        for(RecordType r : allCaseTypes) {
            recordTypeMap.put(r.DeveloperName,r.Id);
        }
        
        Service_Cloud_Settings_MVN__c settings = Service_Cloud_Settings_MVN__c.getInstance();
        
        Case objCase = [select Id, ParentId, AccountId from Case where Id =: caseId];
        String custId = objCase.AccountId;
        objCase = [SELECT Id, Interaction_Notes_MVN__c, Address_MVN__c, case_AddressLine1_MVN__c, case_AddressLine2_MVN__c,
                    case_City_MVN__c, case_Country_MVN__c, case_Postal_Code_MVN__c, case_State_MVN__c, case_Account_Email_MVN__c,
                    RecordTypeId, RecordType.Name, AccountId, ContactId, isClosed, Origin, Referred_By_MVN__c, Subject, Description,
                    MSD_CORE_Source__c, MSD_CORE_Campaign__c, MSD_CORE_Business__c, MSD_CORE_Business_Name__c,
                    Customer_Type_MVN__c, MSD_CORE_Interaction_Has_Requests__c, MSD_CORE_AE_Description__c
                    //KRB REL 9.0 3/13/2017
                    , MSD_CORE_Referred_By_Customer_Type__c
                    FROM Case WHERE RecordType.Name = 'Interaction'
                    and (Id =: objCase.Id
                    or Id =: objCase.ParentId)];
                
        childCase = objCase.clone(false,true,false,false);
        childCase.ParentId = objCase.Id;
        childCase.MSD_CORE_AE_Description__c = objCase.MSD_CORE_AE_Description__c;
        childCase.AccountId = custId;
        childCase.Status = settings.Open_Status_MVN__c;
        childCase.MSD_CORE_Interaction_Has_Requests__c = false;

        childCase.RecordTypeId = recordTypeMap.get(settings.Combo_Case_Preview_Record_Type__c);
        childCase.MSD_CORE_Event_Case_Type__c = null;
        

        Savepoint sp = Database.setSavepoint();
        try{
            insert childCase;

            if(!objCase.MSD_CORE_Interaction_Has_Requests__c){
                objCase.MSD_CORE_Interaction_Has_Requests__c = true;
                update objCase;
            }
            return childCase.Id;
        }catch(Exception e){
            Database.rollback(sp);
            return 'Exception';
        }
    }
    
    @AuraEnabled    
    public static MSD_CORE_TE_Product_Lot_Details__c createLotDetails(String prodId, String lotNumber, Date expDate){       
        MSD_CORE_Temperature_Excursion_Product__c objTempExProd = new MSD_CORE_Temperature_Excursion_Product__c();
        objTempExProd.Id = prodId;
        objTempExProd.MSD_CORE_Lot_Number__c = '';
        objTempExProd.MSD_CORE_Expiration_Date__c = null;
        update objTempExProd;
        
        MSD_CORE_TE_Product_Lot_Details__c objLotDetails = new MSD_CORE_TE_Product_Lot_Details__c();
        objLotDetails.MSD_CORE_Temp_Excursion_Product__c = prodId;
        objLotDetails.Name = lotNumber;
        objLotDetails.MSD_CORE_Expiration_Date__c = expDate;
        insert objLotDetails;
        return objLotDetails;
    }

	@AuraEnabled    
    public static String getCaseStatus(String csId){
        return [SELECT Status FROM Case WHERE Id = :csId].Status;
    }    
}