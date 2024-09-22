trigger MSD_CORE_UpdateDCRStatus on Data_Change_Request_Line_vod__c (after insert) {
    
    /* KRB 6/16/2015 REL 6.0
    
      If the DCRL record is an insert AND
      is associated to an Edit DCR Type
      AND the field that is being updated is a GDGS Stewarded Field
      Flip the Statuses of the associated DCR to 'Submitted, Submitted'
      
      KRB 11/10/2015 - Do not flip the status to 'Submitted, Submitted' if
                       the Account or Address is inactive. 

    */
 
    Set<Id> associatedDCRIdSet = new Set<Id>();
    Map<Id, Data_Change_Request_vod__c> associatedDCRMap = new Map<Id, Data_Change_Request_vod__c>();
    List <Id> dcrIdList = new List <Id>();
    Set<Id> associatedAccountIdSet = new Set<Id>();
    Set<Id> associatedAddressIdSet = new Set<Id>();
    List<Id> associatedAccountIdList = new List<Id>(); 
    List<Id> associatedAddressIdList = new List<Id>();
    
    Map<Id, List<Data_Change_Request_Line_vod__c>> DCRidToDCRLListMap = 
        new Map<Id, List<Data_Change_Request_Line_vod__c>>();
    Set<Data_Change_Request_vod__c> dcrsToUpdateSet =  new Set<Data_Change_Request_vod__c>(); 
    List<Data_Change_Request_vod__c> dcrsToUpdateList =  new List<Data_Change_Request_vod__c>(); 
    
    //Retrive the GDGS HCP Stewarded Fields:

    //HCP Account Stewarded Fields
    MSD_CORE_DCR_Service_Layer_Settings__c dcrServiceLayerSettings = MSD_CORE_DCR_Service_Layer_Settings__c.getInstance('Main');
    String HCP_GDGS_STEWARDED_FIELDS = '';
    HCP_GDGS_STEWARDED_FIELDS = dcrServiceLayerSettings.MSD_CORE_HCP_Account_GDGS_Steward_Fields__c;  
    List <String> HCPGDGSStewardedFieldList = new List <String>();
    HCPGDGSStewardedFieldList = HCP_GDGS_STEWARDED_FIELDS.split(',') ;
    
    //Org Type Address Stewarded Fields
    String Org_Address_GDGS_Steward_Fields = '';
    Org_Address_GDGS_Steward_Fields = dcrServiceLayerSettings.MSD_CORE_Org_Address_GDGS_Steward_Fields__c;  
    List <String> OrgAddressGDGSStewardFieldList = new List <String>();
    OrgAddressGDGSStewardFieldList = Org_Address_GDGS_Steward_Fields.split(',') ;
    
    
    //Get a list of all the associated DCRs
    for (Id DCRLId : Trigger.newMap.keySet()) {
        Data_Change_Request_Line_vod__c dcrl = (Data_Change_Request_Line_vod__c)Trigger.newMap.get(DCRLId);
        associatedDCRIdSet.add(dcrl.Data_Change_Request_vod__c);
    }
    
    //get all the DCR Objects that are associated to this DCRL
    //create a LIST from our unique DCR Id Set
    List <Id> associatedDCRIdList = new List <Id>();
    associatedDCRIdList.addAll(associatedDCRIdSet);
    associatedDCRMap = MSD_CORE_DCRServiceGateway.retrieveEditTypeDCRMapByDCRIdList(associatedDCRIdList);
    
    if (associatedDCRMap.isEmpty()){ //exit if the DCRLs are only related to "New" Type DCRs
        return;
    }
    
    //Get a Map of Account to Record Type
    for (Id DCRLId : Trigger.newMap.keySet()) {
       Data_Change_Request_Line_vod__c dcrl = (Data_Change_Request_Line_vod__c)Trigger.newMap.get(DCRLId);
       //get the associated DCR:
       Data_Change_Request_vod__c dcr = associatedDCRMap.get(dcrl.Data_Change_Request_vod__c);
       
       //Only Pulled "Edit" Type DCRs in our Call to the Gateway above. This trigger fire could be a result of a 
       //NEW DCR type, in which case the DCR would not be present in the MAP -> reason why we need to check for
       //nulls....
       if (dcr != null){ //if it is not a "New" DCR Type DCRL  
          associatedAccountIdSet.add(dcr.Account_vod__c);
       }
        
       if (dcr.RecordTypeId == RT.getId(Data_Change_Request_vod__c.SObjectType, RT.Name.Address_vod)){
           associatedAddressIdSet.add(dcr.Address_vod__c);
       }
       
    }  
        
    associatedAddressIdList.addAll(associatedAddressIdSet);
    associatedAccountIdList.addAll(associatedAccountIdSet);
    Map<Id, String> accountIdToRecordTypeNameMap = new Map<Id, String>();
    accountIdToRecordTypeNameMap = 
        MSD_CORE_DCRServiceGateway.retrieveAccountRecordTypeNamesbyAccountIdMap(associatedAccountIdList);
    
    Map<Id, Account> accountIdToAccountMap = new Map<Id, Account>();
    accountIdToAccountMap = 
        MSD_CORE_DCRServiceGateway.retrieveAccountStatusbyAccountIdMap(associatedAccountIdList);
    
    Map<Id, Address_vod__c> addressIdToAddressMap = new Map<Id, Address_vod__c>();
    addressIdToAddressMap = 
        MSD_CORE_DCRServiceGateway.retrieveAddressActiveStatusbyAddressIdMap(associatedAddressIdList);
    
    
    //Main Processing....
    //Process the newly inserted DCRLs and update the appropriate DCR Statuses:
    for (Id DCRLId : Trigger.newMap.keySet()) {
       Data_Change_Request_Line_vod__c dcrl = (Data_Change_Request_Line_vod__c)Trigger.newMap.get(DCRLId);
       //get the associated DCR:
       Data_Change_Request_vod__c dcr = associatedDCRMap.get(dcrl.Data_Change_Request_vod__c);
       
      if (dcr != null){ //need to account for "New DCRs" hitting. (New DCRs, DCR and DCLI get commited to the Database
           //at the same time. This logic is only for Edit Type DCRs

       //Only processing Edits
       if (dcr.Type_vod__c == 'Edit_vod'){
           
          //Processing DCR Record Type = Account...
          //If it is Account Type and not inactive....
          if( (dcr.RecordTypeId == RT.getId(Data_Change_Request_vod__c.SObjectType, RT.Name.Account_vod))
             && (accountIdToAccountMap.get(dcr.Account_vod__c).Status_MRK__c != 'INACTIVE')
             && (dcr.MSD_CORE_DCR_Status__c != 'Rejected')  //New Code 11/15/2015
            ){
            //and the record type of the Associated Account is HCP...
            if(accountIdToRecordTypeNameMap.get(dcr.Account_vod__c) == 'HCP'){
                
                for (String HCPGDGSStewardedField : HCPGDGSStewardedFieldList){
                   if(HCPGDGSStewardedField == dcrl.Field_API_Name_vod__c){
                     dcr.Status_vod__c = 'Submitted_vod';
                     dcr.MSD_CORE_DCR_Status__c = 'Submitted'; 
                     dcrsToUpdateSet.add(dcr);
                   }    
                }
            }
        //Only if it is of DCR Record Type is Address
        }else if ((dcr.RecordTypeId == RT.getId(Data_Change_Request_vod__c.SObjectType, RT.Name.Address_vod)) &&
                  (addressIdToAddressMap.get(dcr.Address_vod__c).Inactive_vod__c == false) &&
                  (dcr.MSD_CORE_DCR_Status__c != 'Rejected') //New Code 11/15/2015
                 ){
        //Address1, 2, 3 and City, Zip are GDGS Stewarded for all Org Types. 
        //Name,Address_line_2_vod__c,Address_Line_3_MRK__c,City_vod__c,Zip_vod__c    
           if((accountIdToRecordTypeNameMap.get(dcr.Account_vod__c) == 'Hospital_vod') ||
              (accountIdToRecordTypeNameMap.get(dcr.Account_vod__c) == 'Organization_vod')||
              (accountIdToRecordTypeNameMap.get(dcr.Account_vod__c) == 'Pharmacy_vod')){
                
                for (String OrgAddressGDGSStewardField : OrgAddressGDGSStewardFieldList){
                   if(OrgAddressGDGSStewardField == dcrl.Field_API_Name_vod__c){
                     dcr.Status_vod__c = 'Submitted_vod';
                     dcr.MSD_CORE_DCR_Status__c = 'Submitted'; 
                     dcrsToUpdateSet.add(dcr);
                   }    
                }
            }

            
        //Only if it is of DCR Record Type is Child_Account_vod
        }else if (dcr.RecordTypeId == RT.getId(Data_Change_Request_vod__c.SObjectType, RT.Name.Child_Account_vod)){
           //No Action Necessary
        }
      }
     }
    }

    if(!dcrsToUpdateSet.isEmpty()){
        dcrsToUpdateList.addAll(dcrsToUpdateSet);
        update dcrsToUpdateList;   
    }    
}