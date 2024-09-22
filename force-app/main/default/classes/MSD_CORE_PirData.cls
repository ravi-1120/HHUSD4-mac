/*
* Company		: Merck Co.
* Date			: 07-02-2018	
* Author		: Ramesh Elapakurthi
* Description	: PIR data class. which contains PIR fields and other additional fields to submit the request.
* History		: First version
*/
public class MSD_CORE_PirData {
    
    public MSD_CORE_PirData(Case c,MSD_CORE_RTB_Pir_Request_Info__c pirInfo, DateTime utcDateTime){
        
        //Contact Details:
        if(String.isNotBlank(c.Account.FirstName))
            this.contact_firstname = c.Account.FirstName;
        
        if(String.isNotBlank(c.Account.LastName))
            this.contact_lastname = c.Account.LastName;
        
        if(String.isNotBlank(c.MSD_CORE_Customer_Contact_Salutation__c))
            this.contact_salutation = c.MSD_CORE_Customer_Contact_Salutation__c;
        
        if(String.isNotBlank(c.case_AddressLine1_MVN__c))
            this.contact_address = c.case_AddressLine1_MVN__c;
        /// -chetan changes start --
        this.contact_address_line_1 = c.case_AddressLine1_MVN__c;
        this.contact_address_line_2 = c.case_AddressLine2_MVN__c;
        this.contact_addr_sf_id = c.Address_MVN__c;
        this.contact_sf_id = c.AccountId; 
        this.contact_party_id = c.Account.Merck_ID_MRK__c;
        this.contact_party_addr_id = c.Address_MVN__r.Merck_Address_ID_MRK__c;
        /// ---end
        
        if(String.isNotBlank(c.case_AddressLine2_MVN__c))
            this.contact_address = this.contact_address + ' ' + c.case_AddressLine2_MVN__c;
        
        if(String.isNotBlank(c.case_City_MVN__c))
            this.contact_city = c.case_City_MVN__c;
        
        if(String.isNotBlank(c.case_State_MVN__c))
            this.contact_state = c.case_State_MVN__c;
        
        if(String.isNotBlank(c.case_Postal_Code_MVN__c))
            this.contact_postal = c.case_Postal_Code_MVN__c;
        
        if(String.isNotBlank(c.case_Country_MVN__c))
            this.contact_country = c.case_Country_MVN__c;
        
        if(String.isNotBlank(c.case_Account_Phone_MVN__c))
            this.contact_phone1 = c.case_Account_Phone_MVN__c;
        
        if(String.isNotBlank(c.case_Account_Fax_MVN__c))
            this.contact_fax = c.case_Account_Fax_MVN__c;
        
        if(String.isNotBlank(c.case_Account_Email_MVN__c))
            this.contact_email = c.case_Account_Email_MVN__c;
        
        if(String.isNotBlank(c.Account.Credentials_vod__c))
            this.contact_degree = c.Account.Credentials_vod__c;
        
        if(String.isNotBlank(c.MSD_CORE_Business_Name__c))
            this.contact_company = c.MSD_CORE_Business_Name__c;
        
        //Request, Question and Product details:
        this.external_req_id = c.Id;
		this.case_number = c.CaseNumber;       
        this.case_source = pirInfo.NSC_Case_Source__c;
        this.case_language = pirInfo.Source_Language__c;
        
        if(String.isNotBlank(c.MSD_CORE_Global_MedInfo_Delivery_Method__c)){
        	//Removing this check as the transformation is handled in RTB.
        //    if(c.MSD_CORE_Global_MedInfo_Delivery_Method__c == 'No Delivery')
        //    	this.case_handling = 'Telephone';
        //   	else
                this.case_handling = c.MSD_CORE_Global_MedInfo_Delivery_Method__c;
        }
        
        List<String> handlings = pirInfo.Complete_Cases_For_Delivery_Methods__c.split(';');
        if((String.isNotBlank(this.case_handling) && handlings.contains(this.case_handling))){
        	this.complete_case = 'Y';
        }
       
        //Status is set to Transferred
        this.pir_status_code = pirInfo.PIR_Status_Code__c;
        
        //if(String.isNotBlank(c.Type))
        //    this.case_type = c.Type;
        
        if(String.isNotBlank(c.Details_MVN__c))
            this.question = c.Details_MVN__c;
        else
            this.question = 'NO QUESTION TEXT';
        
        if(String.isNotBlank(c.Product_MVN__r.Name ))
            this.question_product_code = c.Product_MVN__r.Name ;
        
        if(String.isNotBlank(c.MSD_CORE_PIR_Concept_Code__c)){
            this.document =  new List<Document>();
            Document document = new Document();
            document.docid = c.MSD_CORE_PIR_Concept_Code__c;
            this.document.add(document);
            this.coded_pir_ind = 'Y';
        }
        else
            this.coded_pir_ind = 'N';
        
        //User Details:
        If (c.Referred_By_MVN__r.Class_of_Trade_MRK__c == 'EMPLOYEE'){
            if(String.isNotBlank(c.Referred_By_MVN__r.Preferred_First_Name_MRK__c))
                this.rep_firstname = c.Referred_By_MVN__r.Preferred_First_Name_MRK__c;
            if(String.isNotBlank(c.Referred_By_MVN__r.Preferred_Last_Name_MRK__c))
                this.rep_lastname = c.Referred_By_MVN__r.Preferred_Last_Name_MRK__c;
            if(String.isNotBlank(c.Referred_By_MVN__r.MSD_CORE_Employee_Alias__c))
                this.rep_code = c.Referred_By_MVN__r.MSD_CORE_Employee_Alias__c;
            if(String.isNotBlank(c.Referred_By_MVN__r.MSD_CORE_Merck_Employee_ID__c))
                this.external_rep_id = c.Referred_By_MVN__r.MSD_CORE_Merck_Employee_ID__c;
            
            
        }
        else {
            
            if(String.isNotBlank(c.Owner.FirstName))
                this.rep_firstname = c.Owner.FirstName;
            if(String.isNotBlank(c.Owner.LastName))
                this.rep_lastname = c.Owner.LastName;
            
        }
        this.req_date_utc = utcDateTime;
        
       // this.case_entry_period = 'Business Hours';
       // this.case_priority = 'Normal';
       // this.origin_system = 'Import: ISC';
    }
    
    //KRB 10/19/2022 22R4.1 - updated the Signature to include a Parent Account List...
    //public MSD_CORE_PirData(Medical_Inquiry_vod__c pData, MSD_CORE_RTB_Pir_Request_Info__c pirInfo, DateTime utcDateTime){
    public MSD_CORE_PirData(Medical_Inquiry_vod__c pData, MSD_CORE_RTB_Pir_Request_Info__c pirInfo, DateTime utcDateTime, List<Child_Account_vod__c> parentAccountList){

        //Contact Details:
        
        //KRB 10/19/2022 22R4.1 Start - added to capture accounts Parent. 
        if(String.isNotBlank(pData.Account_vod__r.Primary_Parent_vod__r.name)){

            this.contact_company = pData.Account_vod__r.Primary_Parent_vod__r.name;
        
        }else{ // if the account did not have a primary parent account indicated, lets see if we can just find a parent...
           System.debug('KRB: pData.Account_vod__r.Primary_Parent_vod__r.name was Blank. Processing the Parent List now...');          
           //Lets see if they have any other Parents...only need to assign one...
           for (Child_Account_vod__c parentRec: parentAccountList){
              if(pData.Account_vod__c == parentRec.Child_Account_vod__c &&
                !String.isBlank(parentRec.Parent_Name_vod__c)){
                   this.contact_company = parentRec.Parent_Name_vod__c; 
                   break;
               }
            }
            
        }
        //KRB 10/19/2022 22R4.1 End - added to capture accounts Parent. 

               
        if(String.isNotBlank(pData.Account_vod__r.FirstName))
            this.contact_firstname = pData.Account_vod__r.FirstName;
        
        if(String.isNotBlank(pData.Account_vod__r.LastName))
            this.contact_lastname = pData.Account_vod__r.LastName;
        
        if(String.isNotBlank(pData.Salutation_MRK__c))
            this.contact_salutation = pData.Salutation_MRK__c;
        
        if(String.isNotBlank(pData.Phone_Number_vod__c))
            this.contact_phone1 = pData.Phone_Number_vod__c;
        
        if(String.isNotBlank(pData.Fax_Number_vod__c))
            this.contact_fax = pData.Fax_Number_vod__c;
        
        if(String.isNotBlank(pData.Email_vod__c))
            this.contact_email = pData.Email_vod__c;
        
        if(String.isNotBlank(pData.Account_vod__r.Credentials_vod__c))
            this.contact_degree = pData.Account_vod__r.Credentials_vod__c;
        
        //Request, Question and Product details:
        this.external_req_id = pData.Id;
        
        this.case_number = pData.Name; //added this Name field to append to Inquiry text.
        
        System.debug('recordtype.developername ' + pData.RecordType.DeveloperName);
        List<String> madsRecordTypes = pirInfo.MADS_Record_Types__c.split(';'); // Updated on 6/4/2019: requirement to include new record types for MADS 
        System.debug('MADS Record Types ' + madsRecordTypes);
        
        if(madsRecordTypes.contains(pData.RecordType.DeveloperName)){ // Updated on 6/4/2019: requirement to include new record types for MADS 
            this.rep_cc = 'Y';
            this.case_source = pirInfo.MS_Case_Source__c;
        }
        else{
            this.rep_cc = 'N';
            this.case_source = pirInfo.FS_Case_Source__c;
        }
            
        
        this.case_language = pirInfo.Source_Language__c;
        
        if(String.isNotBlank(pData.Delivery_Method_vod__c)){
            //Removing this check as the transformation is handled in RTB.
           // if(pData.Delivery_Method_vod__c == 'No Action Necessary')
             //   this.case_handling = 'Face-to-face';
           // else
            	this.case_handling = pData.Delivery_Method_vod__c;
            
            if(this.case_handling == 'Mail_vod'){
                if(String.isNotBlank(pData.Address_Line_1_vod__c))
            		this.contact_address = pData.Address_Line_1_vod__c;
                if(String.isNotBlank(pData.Address_Line_2_vod__c))
                    this.contact_address = this.contact_address + ',' + pData.Address_Line_2_vod__c;
                if(String.isNotBlank(pData.City_vod__c))
                    this.contact_city = pData.City_vod__c;
                if(String.isNotBlank(pData.State_vod__c))
                    this.contact_state = pData.State_vod__c;
                if(String.isNotBlank(pData.Zip_vod__c))
                    this.contact_postal = pData.Zip_vod__c;
                if(String.isNotBlank(pData.Country_vod__c))
                    this.contact_country = pData.Country_vod__c;
            }
            else { //if the delivey method is not Mail, send primary contact address
                if(String.isNotBlank(pData.Address_Integration_MRK__c)){
                	List<String> addressList = pData.Address_Integration_MRK__c.split(';');
                    
                    if(String.isNotBlank(addressList[0]))
                        this.contact_address = addressList[0];
                    if(String.isNotBlank(addressList[1]))
                        this.contact_address = this.contact_address + ',' + addressList[1];
                    if(String.isNotBlank(addressList[2]))
                        this.contact_city = addressList[2];
                    if(String.isNotBlank(addressList[3]))
                        this.contact_state = addressList[3];
                    if(String.isNotBlank(addressList[4]))
                        this.contact_postal = addressList[4];
                    if(String.isNotBlank(pData.Country_vod__c))
                        this.contact_country = pData.Account_vod__r.Country_vod__c;
                }
             }
        }
        List<String> handlings = pirInfo.Complete_Cases_For_Delivery_Methods__c.split(';');
        if((String.isNotBlank(this.case_handling) && handlings.contains(this.case_handling))){
        	this.complete_case = 'Y';
        }
        
        //Status is set to Transferred
        this.pir_status_code = pirInfo.PIR_Status_Code__c;
        
        if(String.isNotBlank(pData.Inquiry_Text__c))
            this.question = pData.Inquiry_Text__c;
        
        if(String.isNotBlank(pData.PIR_Concept_Product_MRK__c ))
            this.question_product_code = pData.PIR_Concept_Product_MRK__c;
        
        if(String.isNotBlank(pData.PIR_Concept_Number_MRK__c)){
            this.document = new List<Document>();
            Document d = new Document();
            d.docid = pData.PIR_Concept_Number_MRK__c;
            this.document.add(d);
            this.coded_pir_ind = 'Y';
        }
        else
            this.coded_pir_ind = 'N';
        
        //User Details:
        if(String.isNotBlank(pData.CreatedBy.FirstName))
            this.rep_firstname = pData.CreatedBy.FirstName;
        if(String.isNotBlank(pData.CreatedBy.LastName))
            this.rep_lastname = pData.CreatedBy.LastName;
        if(String.isNotBlank(pData.CreatedBy.Alias))
            this.rep_code = pData.CreatedBy.Alias;
        
        this.req_date_utc = utcDateTime;
        
        //this.origin_system = 'Import: ISC';
        
    }
        
    //pir_status_code
    public string pir_status_code {get;set;}
    
    //question
    public string question {get;set;}
    
    //contact_salutation
    public string contact_salutation {get;set;}
    
    //external_req_id
    public string external_req_id {get;set;}
    
    //contact_firstname
    public string contact_firstname {get;set;}
    
    //contact_lastname
    public string contact_lastname {get;set;}
    
    //contact_address
    public string contact_address {get;set;}
    
    //contact_city
    public string contact_city {get;set;}
    
    //contact_state 
    public string contact_state {get;set;}
    
    //contact_postal
    public string contact_postal {get;set;}
    
    //contact_phone1
    public string contact_phone1 {get;set;}
    
    //contact_fax
    public string contact_fax{get;set;}
    
    //contact_email
    public string contact_email {get;set;}
    
    //contact_degree
    public string contact_degree {get;set;}
    
    //contact_country
    public string contact_country {get;set;}
    
    //question_product_code
    public string question_product_code {get;set;}
    
    //docid
    public List<Document> document {get;set;}
    
    //rep_firstname
    public string rep_firstname {get;set;}
    
    //rep_lastname
    public string rep_lastname {get;set;}
    
    //external_rep_id
    public string external_rep_id {get;set;}
    
    //req_date_utc
    public DateTime req_date_utc {get;set;}
    
    //case_handling
    public string case_handling {get;set;}
    
    //case_type
    //public string case_type {get;set;}
    
    //case_language
    public string case_language {get;set;}
    
    //case_source
    public string case_source {get;set;}
    
    //coded_pir_ind    
    public string coded_pir_ind {get;set;}
    
    //case_number
    public string case_number {get;set;}
    
    //case_origin
    public string origin_system {get;set;}
    
    //rep_code
    public string rep_code {get;set;}
    
    //rep_cc
    public string rep_cc {get;set;}
    
    //case_entry_period
    public string case_entry_period {get;set;}
    
    //case_priority
    public string case_priority {get;set;}
    
    //contact_company
    public string contact_company {get;set;}
    
    //complete_case
    public string complete_case {get;set;}

    // start -- chetan added, as a part of miigs requirement
    public string contact_address_line_1 {get;set;}
    public string contact_address_line_2 {get;set;}
    public string contact_sf_id  {get;set;}
    public string contact_party_id {get;set;}
    public string contact_addr_sf_id  {get;set;}
    public string contact_party_addr_id  {get;set;}

// end
    
    //document
    public class Document {
        public string docid {get;set;}
    }
}