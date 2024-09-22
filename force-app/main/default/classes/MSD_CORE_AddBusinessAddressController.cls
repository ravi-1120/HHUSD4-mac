/*
 * MSD_CORE_AddBusinessAddressController
 * Created by: Roman Lerman
 * Created Date: October 7, 2015
 * Description: Controller for the Add Business Address page.
 *              Enables adding addresses for Business Accounts.
 *              A Data Change Request will be created behind the scenes.
 */
public with sharing class MSD_CORE_AddBusinessAddressController {
    private Service_Cloud_Settings_MVN__c settings = Service_Cloud_Settings_MVN__c.getInstance();
    private Set<String> countriesRequiringState;
    
    
    //KRB 7/31/2017 - Release 10.0 - Start
    private Set<Id> dcrRecordTypeIds;
    public Boolean isDCR { get; set; }
    private Service_Cloud_Settings_MVN__c serviceCloudSettings;
    //KRB 7/31/2017 - Release 10.0 - End
    
    public Account acct {get; set;}
    public Address_vod__c newAddress { get; set; }
    public Boolean saveSuccess {get; set;}

    public MSD_CORE_AddBusinessAddressController() {
        saveSuccess = false;
        
        //KRB 7/31/2017 - Release 10.0 
        isDCR = false;
        serviceCloudSettings = Service_Cloud_Settings_MVN__c.getInstance();
        
        countriesRequiringState = new Set<String>(UtilitiesMVN.splitCommaSeparatedString(settings.MSD_CORE_Address_Country_Requires_State__c));

        newAddress = new Address_vod__c();

        String acctId = ApexPages.CurrentPage().getParameters().get('id');

        acct = [select Id,
                        Name,
                        IsPersonAccount,
                IMS_Sub_Specialty_MRK__c,
                MSD_CORE_Submit_DCR__c,
                Credentials_vod__c,
                Preferred_Last_Name_MRK__c,
                Preferred_First_Name_MRK__c,
                IMS_Specialty_MRK__c,
                Class_of_Trade_Owner_MRK__c,
                        Status_MRK__c,
                        Preferred_Full_Name_MRK__c, 
                        Merck_ID_MRK__c, 
                        RecordTypeId, 
                        Class_of_Trade_MRK__c,
                        Class_of_Trade_Sub_MRK__c 
                from Account where Id =: acctId];

        newAddress.Account_vod__c = acct.Id;

        newAddress.recordTypeId = [SELECT Id FROM RecordType 
                                            WHERE SObjectType = 'Address_vod__c' 
                                            AND DeveloperName =: settings.MSD_CORE_Company_Maintained_Rec_Type__c].Id;
        
        newAddress.Country_vod__c = [select MSD_CORE_Country_Code__c 
                                        from User where Id = :UserInfo.getUserId()].MSD_CORE_Country_Code__c;

/* Code added by Satish to check the Account record type and then update the Flags to Office or Home. 
The two flags for Business are already present and will now be checked for only business accounts only*/

        if(!acct.IsPersonAccount){
        newAddress.Physical_Address_MRK__c = true;
        newAddress.Mailing_vod__c = false;
        }
    
    
        //KRB 7/31/2017 Rel 10.0 - Start
        List<String> dcrRecordTypeDeveloperNames = UtilitiesMVN.splitCommaSeparatedString(serviceCloudSettings.MSD_CORE_DCR_Record_Types__c);

        List<RecordType> dcrRecordTypes = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName IN :dcrRecordTypeDeveloperNames];
        dcrRecordTypeIds = new Set<Id>();
        for(RecordType dcrRecordType : dcrRecordTypes) {
            dcrRecordTypeIds.add(dcrRecordType.Id);
        }
        
        if(dcrRecordTypeIds.contains(acct.RecordTypeId)){
            isDCR = true;
            System.debug('KRB: Account: ' + acct.id + ' has a Record Type that requires a DCR. ');
        }else{
            System.debug('KRB: Account: ' + acct.id + ' does not have a Record Type that requires a DCR. ');
        }
        //KRB 7/31/2017 Rel 10.0 - End
    
    
    }

    public Boolean getRequireState() {
        return countriesRequiringState.contains(newAddress.Country_vod__c);        
    }

    public PageReference createAddress() {
        SavePoint sp = Database.setSavePoint();

        saveSuccess = false;

        try {
            insert newAddress;
            
            //KRB 7/31/2017 REL 10.0 Out
            //MSD_CORE_DCRUtility.checkAndSubmitNewRecordsToDCR(acct, newAddress);
            
            
            //KRB 7/31/2017 REL 10.0 In
            if(isDCR){
                MSD_CORE_DCRUtility.checkAndSubmitNewRecordsToDCR(acct, newAddress);
                System.debug('KRB: Submitted a DCR.');
            }else{
                System.debug('KRB: Not submitting a DCR.');
            }
        } catch (Exception e) {
            System.debug('Exception -->'+e);
            ApexPages.addMessages(e);
            newAddress = newAddress.clone(false,true,false,false);
            Database.rollback(sp);
            return null;
        }
        
        saveSuccess = true;

        return null;
    }
}