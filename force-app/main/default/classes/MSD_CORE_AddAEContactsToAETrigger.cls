/*
* MSD_CORE_AddAEContactsToAETrigger
* Created By:    Samuel Rosen
* Created Date:  5/18/2015
* Description:   This class adds AE Contact records to an Adverse Event for the Customer
*                and Referred By specified on the Interaction.

* Change Log:
* Updated Date: 7/7/2021
* Updated By:   Vamshi Bashyakarla
* Description: Code Refactor to reduce the SOQL Queries
*/
public with sharing class MSD_CORE_AddAEContactsToAETrigger implements TriggersMVN.HandlerInterface{
     public void handle() {
        List<Case> cases = Trigger.new; 
        
        Service_Cloud_Settings_MVN__c setting = Service_Cloud_Settings_MVN__c.getInstance(); 
        /*By Satish (8.0 Release): Added the filter in the where clause for SobjectType because the record type name is same in two objects*/
        //RecordType aeRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = :setting.Combo_Case_Preview_Record_Type__c];
        Id aeRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(setting.Combo_Case_Preview_Record_Type__c).getRecordTypeId();
        //system.debug('@@@@@aeRecordTypeID'+aeRecordType.Id+'@@@'+aeRecordTypeId);
         /*By Satish (8.0 Release): Added the below query for extractign the recordtype Id of te Adverse Event Contact id*/
        //RecordType aeContactRecType = [SELECT Id from Recordtype WHERE SObjectType = 'MSD_CORE_AE_Contact__c' AND DeveloperName = :setting.Adverse_Event_Record_Type_MVN__c]; //29
        Id aeContactRecTypeId = Schema.SObjectType.MSD_CORE_AE_Contact__c.getRecordTypeInfosByDeveloperName().get(setting.Adverse_Event_Record_Type_MVN__c).getRecordTypeId();
		//system.debug('@@@@@aeContactRecTypeId'+aeContactRecType.Id+'@@@'+aeContactRecTypeId);
        Map<Id,Set<Case>> accountToAdverseEventMap = new Map<Id,Set<Case>>(); 
        for(Case cs:cases) {
            if(cs.RecordTypeId == aeRecordTypeId) {
                if(cs.AccountId != null) {
                    if(accountToAdverseEventMap.get(cs.AccountId) == null) {
                        accountToAdverseEventMap.put(cs.AccountId, new Set<Case>());
                        accountToAdverseEventMap.get(cs.AccountId).add(cs); 
                    } else {
                        accountToAdverseEventMap.get(cs.AccountId).add(cs); 
                    }
                }

                if(cs.Referred_By_MVN__c != null) {
                    if(accountToAdverseEventMap.get(cs.Referred_By_MVN__c) == null) {
                        accountToAdverseEventMap.put(cs.Referred_By_MVN__c, new Set<Case>());
                        accountToAdverseEventMap.get(cs.Referred_By_MVN__c).add(cs); 
                    } else {
                        accountToAdverseEventMap.get(cs.Referred_By_MVN__c).add(cs); 
                    }
                }
            }
        }
        if(!accountToAdverseEventMap.isEmpty())
        {
        /*List<Account> accounts = [SELECT Id, Firstname, Lastname, Class_of_Trade_Sub_MRK__c, Phone, Fax, Credentials_vod__c, 
                                            (SELECT Id, Account_vod__c, Name, Address_line_2_vod__c, 
                                                City_vod__c, Country_vod__c, State_vod__c, Zip_vod__c, 
                                                Phone_vod__c, Fax_vod__c 
                                            FROM Address_vod__r 
                                            ORDER BY Primary_vod__c desc, CreatedDate desc LIMIT 1)  
                                    FROM Account WHERE Id IN :accountToAdverseEventMap.keySet()]; */
        
        List<MSD_CORE_AE_Contact__c> contactList = new List<MSD_CORE_AE_Contact__c>(); 

        for(Account account:[SELECT Id, Firstname, Lastname, Class_of_Trade_Sub_MRK__c, Phone, Fax, Credentials_vod__c, 
                                            (SELECT Id, Account_vod__c, Name, Address_line_2_vod__c, 
                                                City_vod__c, Country_vod__c, State_vod__c, Zip_vod__c, 
                                                Phone_vod__c, Fax_vod__c 
                                            FROM Address_vod__r 
                                            ORDER BY Primary_vod__c desc, CreatedDate desc LIMIT 1)  
                                    FROM Account WHERE Id IN :accountToAdverseEventMap.keySet()]) {
            Set<Case> adverseEventSet = accountToAdverseEventMap.get(account.Id); 
            for(Case adverseEvent:adverseEventSet) {
                MSD_CORE_AE_Contact__c aeContact = new MSD_CORE_AE_Contact__c();

                if(adverseEvent.Referred_By_MVN__c == account.Id 
                    || (adverseEvent.AccountId == account.Id 
                        && String.isBlank(adverseEvent.Referred_By_MVN__c))){
                    aeContact.MSD_CORE_Primary_Contact__c = true;
                }
                aeContact.RecordTypeid = aeContactRecTypeId;
                aeContact.MSD_CORE_Adverse_Event__c = adverseEvent.Id; 
                aeContact.MSD_CORE_First_Name__c = account.FirstName;
                aeContact.MSD_CORE_Last_Name__c = account.LastName; 
                aeContact.MSD_CORE_Type__c = account.Class_of_Trade_Sub_MRK__c; 
                aeContact.MSD_CORE_Credentials__c = account.Credentials_vod__c;

                if(adverseEvent.AccountId == account.Id) {
                    if(String.isBlank(adverseEvent.Case_AddressLine1_MVN__c)) {
                        if(account.Address_vod__r.size() > 0) {
                            aeContact = fillIn(account, aeContact, false);
                        }
                    } else {
                        aeContact.MSD_CORE_Address_Line_1__c = adverseEvent.Case_AddressLine1_MVN__c; 
                        aeContact.MSD_CORE_Address_Line_2__c = adverseEvent.Case_AddressLine2_MVN__c; 
                        aeContact.MSD_CORE_City__c = adverseEvent.Case_City_MVN__c;
                        aeContact.MSD_CORE_Country__c = adverseEvent.Case_Country_MVN__c;
                        aeContact.MSD_CORE_State_Province__c = adverseEvent.Case_State_MVN__c;
                        aeContact.MSD_CORE_Postal_Code__c = adverseEvent.Case_Postal_Code_MVN__c;
                    }

                    if(String.isBlank(adverseEvent.Case_Account_Phone_MVN__c)) {
                        aeContact.MSD_CORE_Phone__c = account.Phone; 
                    } else {
                        aeContact.MSD_CORE_Phone__c = adverseEvent.Case_Account_Phone_MVN__c;    
                    }

                    if(String.isBlank(adverseEvent.Case_Account_Fax_MVN__c)) {
                        aeContact.MSD_CORE_Fax__c = account.Fax;
                    } else {
                        aeContact.MSD_CORE_Fax__c = adverseEvent.Case_Account_Fax_MVN__c;
                    }
                }else if (adverseEvent.Referred_By_MVN__c == account.Id) {
                    if(account.Address_vod__r.size() > 0) {   
                        aeContact = fillIn(account, aeContact, true); 
                    }else{
                        aeContact.MSD_CORE_Phone__c = account.Phone; 
                        aeContact.MSD_CORE_Fax__c = account.Fax; 
                    }
                }
                contactList.add(aeContact); 
            }
        }

        insert contactList;
        }
     }

     private MSD_CORE_AE_Contact__c fillIn(Account account, MSD_CORE_AE_Contact__c aeContact, Boolean shouldFillInPhone) {
        aeContact.MSD_CORE_Address_Line_1__c = account.Address_vod__r[0].Name; 
        aeContact.MSD_CORE_Address_Line_2__c = account.Address_vod__r[0].Address_line_2_vod__c; 
        aeContact.MSD_CORE_City__c = account.Address_vod__r[0].City_vod__c;
        aeContact.MSD_CORE_Country__c = account.Address_vod__r[0].Country_vod__c;
        aeContact.MSD_CORE_State_Province__c = account.Address_vod__r[0].State_vod__c;
        aeContact.MSD_CORE_Postal_Code__c = account.Address_vod__r[0].Zip_vod__c;

        if(shouldFillInPhone) {
            aeContact.MSD_CORE_Phone__c = account.Phone; 
            aeContact.MSD_CORE_Fax__c = account.Fax;
        }

        return aeContact;
     }

}