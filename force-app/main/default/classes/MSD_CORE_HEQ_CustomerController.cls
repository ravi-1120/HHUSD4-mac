/**
 * Component Name:      MSD_CORE_HEQ_CustomerController
 * Created By:          Ravi Modi (Focal CXM)
 * Created Date:        19th Aug 2024
 * @description:        Server side controller for mSD_CORE_HEQ_Customer LWC component
 * Test Class:          
 */

public without sharing class MSD_CORE_HEQ_CustomerController {

    /**
     * Method Name  :   getCustomerList
     * @description :   Use to get customer user list 
     * @return      :   List<Map<String, Object>>
     * Created By   :   Ravi Modi (Focal CXM)
     * Created Date :   19th Aug 2024
     */
    // @AuraEnabled
    // public static List<Map<String, Object>> getCustomerList() {
    //     List<Map<String, Object>> resultList = new List<Map<String, Object>>();
    
    //     try {
    //         List<Id> accountIds = MSD_CORE_FBEAccountMappingHelper.getFBEAccountMapping(UserInfo.getUserId());
            
    //         List<Account> accountList = [SELECT Id, Name, FirstName, LastName, IsPersonAccount, IsCustomerPortal, PersonEmail FROM Account WHERE Id IN :accountIds];
            
    //         for (Account acc : accountList) {
    //             Map<String, Object> resultMap = new Map<String, Object>();
                
    //             if (acc.IsPersonAccount && acc.IsCustomerPortal) {
    //                 User personUser = [SELECT Id, FirstName, LastName, Name, Email, LastLoginDate 
    //                                 FROM User 
    //                                 WHERE AccountId = :acc.Id 
    //                                 LIMIT 1];
                    
    //                 resultMap.put('Id', personUser.Id);
    //                 resultMap.put('FirstName', personUser.FirstName);
    //                 resultMap.put('LastName', personUser.LastName);
    //                 resultMap.put('Name', personUser.Name);
    //                 resultMap.put('Email', personUser.Email);
    //                 resultMap.put('LastLoginDate', personUser.LastLoginDate);
    //                 resultMap.put('IsRegister', true);
                    
    //             } else {
    //                 resultMap.put('Id', acc.Id);
    //                 resultMap.put('FirstName', acc.FirstName);
    //                 resultMap.put('LastName', acc.LastName);
    //                 resultMap.put('Name', acc.Name);
    //                 resultMap.put('Email', acc.PersonEmail);
    //                 resultMap.put('IsRegister', false);
    //             }
                
    //             resultList.add(resultMap);
    //         }
            
    //     } catch (Exception e) {
    //         System.debug('Error>>' + e.getMessage() + '----' + e.getLineNumber());
    //     }
        
    //     return resultList;
    // }
 
   
    @AuraEnabled
    public static List<Map<String, Object>> getCustomerList() {
        List<Map<String, Object>> resultList = new List<Map<String, Object>>();
        Map<Id, Boolean> isInvitedMap = new Map<Id, Boolean>();
        Map<Id, User> userMap = new Map<Id, User>();
        List<Id> nonPortalAccountIds = new List<Id>();
        List<Id> portalAccountIds = new List<Id>();

        try {
            List<Id> accountIds = MSD_CORE_FBEAccountMappingHelper.getFBEAccountMapping(UserInfo.getUserId());
            if (accountIds.isEmpty()) {
                return resultList;
            }

            List<Account> accountList = [SELECT Id, Name, FirstName, LastName, IsPersonAccount, IsCustomerPortal, PersonEmail
                                        FROM Account 
                                        WHERE Id IN :accountIds];

            
            for (Account acc : accountList) {
                if (acc.IsPersonAccount && !acc.IsCustomerPortal) {
                    nonPortalAccountIds.add(acc.Id);
                }
                if (acc.IsPersonAccount && acc.IsCustomerPortal) {
                    portalAccountIds.add(acc.Id);
                }
            }

            if (!portalAccountIds.isEmpty()) {
                for (User u : [
                    SELECT Id, FirstName, LastName, Name, Email, LastLoginDate, AccountId 
                    FROM User 
                    WHERE AccountId IN :portalAccountIds
                ]) {
                    userMap.put(u.AccountId, u);
                }
            }
            
            if (!nonPortalAccountIds.isEmpty()) {
                for (MSD_CORE_HEQ_UserPreference__c customObject : [
                    SELECT MSD_CORE_Account__c, MSD_CORE_Is_Invited__c 
                    FROM MSD_CORE_HEQ_UserPreference__c 
                    WHERE MSD_CORE_Account__c IN :nonPortalAccountIds
                ]) {
                    isInvitedMap.put(customObject.MSD_CORE_Account__c, customObject.MSD_CORE_Is_Invited__c);
                }
            }

          List<Address_vod__c> addressList1 = [
            SELECT Name, Address_line_2_vod__c, Address_Line_3_MRK__c, City_vod__c, State_vod__c, Zip_vod__c, Account_vod__c, Primary_vod__c 
            FROM Address_vod__c 
            WHERE Account_vod__c IN :accountIds
        ];

        List<MSD_CORE_HEQ_Address__c> addressList2 = [
            SELECT Name, MSD_CORE_HEQ_Address_1__c, MSD_CORE_HEQ_Address_2__c, MSD_CORE_HEQ_Address_3__c, MSD_CORE_HEQ_City__c, MSD_CORE_HEQ_Country__c, MSD_CORE_HEQ_Is_Default__c, MSD_CORE_HEQ_State__c, MSD_CORE_HEQ_Street__c, MSD_CORE_HEQ_Zip_Code__c, MSD_CORE_HEQ_Account__c
            FROM MSD_CORE_HEQ_Address__c
            WHERE MSD_CORE_HEQ_Account__c IN :accountIds
        ];

        Map<Id, List<Map<String, Object>>> addressMap = new Map<Id, List<Map<String, Object>>>();

        for (Address_vod__c addr1 : addressList1) {
            if (!addressMap.containsKey(addr1.Account_vod__c)) {
                addressMap.put(addr1.Account_vod__c, new List<Map<String, Object>>());
            }
            Map<String, Object> addressMapObject1 = new Map<String, Object>();
            addressMapObject1.put('Name', addr1.Name);
            addressMapObject1.put('AddressLine2', addr1.Address_line_2_vod__c);
            addressMapObject1.put('AddressLine3', addr1.Address_Line_3_MRK__c);
            addressMapObject1.put('City', addr1.City_vod__c);
            addressMapObject1.put('State', addr1.State_vod__c);
            addressMapObject1.put('Zip', addr1.Zip_vod__c);
            addressMapObject1.put('Primary', addr1.Primary_vod__c);
            addressMap.get(addr1.Account_vod__c).add(addressMapObject1);
        }

        for (MSD_CORE_HEQ_Address__c addr2 : addressList2) {
            if (!addressMap.containsKey(addr2.MSD_CORE_HEQ_Account__c)) {
                addressMap.put(addr2.MSD_CORE_HEQ_Account__c, new List<Map<String, Object>>());
            }
            Map<String, Object> addressMapObject2 = new Map<String, Object>();
            addressMapObject2.put('Name', addr2.Name);
            addressMapObject2.put('AddressLine2', addr2.MSD_CORE_HEQ_Address_1__c);
            addressMapObject2.put('AddressLine3', addr2.MSD_CORE_HEQ_Address_2__c);
            addressMapObject2.put('City', addr2.MSD_CORE_HEQ_City__c);
            addressMapObject2.put('State', addr2.MSD_CORE_HEQ_State__c);
            addressMapObject2.put('Zip', addr2.MSD_CORE_HEQ_Zip_Code__c);
            addressMapObject2.put('Primary', addr2.MSD_CORE_HEQ_Is_Default__c);
            addressMap.get(addr2.MSD_CORE_HEQ_Account__c).add(addressMapObject2);
        }

        for (Account acc : accountList) {
            Map<String, Object> resultMap = new Map<String, Object>();
            if (acc.IsPersonAccount && acc.IsCustomerPortal) {
                    User personUser = userMap.get(acc.Id);
                    if (personUser != null) {
                        resultMap.put('Id', personUser.Id);
                        resultMap.put('FirstName', personUser.FirstName);
                        resultMap.put('LastName', personUser.LastName);
                        resultMap.put('Name', personUser.Name);
                        resultMap.put('Email', personUser.Email);
                        resultMap.put('LastLoginDate', personUser.LastLoginDate);
                        resultMap.put('IsRegister', true);
                        resultMap.put('AccountName', acc.Name);
                    }
                } else {
                    resultMap.put('Id', acc.Id);
                    resultMap.put('FirstName', acc.FirstName);
                    resultMap.put('LastName', acc.LastName);
                    resultMap.put('Name', acc.Name);
                    resultMap.put('Email', acc.PersonEmail);
                    resultMap.put('IsRegister', false);
                }

            // Combine addresses from both objects into a single list
            List<Map<String, Object>> combinedAddressList = addressMap.get(acc.Id);
            resultMap.put('Addresses', combinedAddressList != null ? combinedAddressList : new List<Map<String, Object>>());

            resultList.add(resultMap);
        }


        } catch (Exception e) {
            System.debug('Error in getCustomerList: ' + e.getMessage() + ' at line ' + e.getLineNumber());
        }

        return resultList;
    }

    @AuraEnabled
    public static void saveRecipients(List<MSD_CORE_HEQ_Recipient__c> recipients) {
        System.debug('>>> Recipients to save: ' + recipients);
        if (recipients != null && !recipients.isEmpty()) {
            for (MSD_CORE_HEQ_Recipient__c rec : recipients) {
                System.debug('>>> FirstName: ' + rec.MSD_CORE_HEQ_FirstName__c);
                System.debug('>>> LastName: ' + rec.MSD_CORE_HEQ_LastName__c);
                System.debug('>>> Email: ' + rec.MSD_CORE_HEQ_Email__c);
            }
            try {
                insert recipients;
                System.debug('Recipients inserted successfully');
            } catch (Exception e) {
                System.debug('Error inserting recipients: ' + e.getMessage());
                throw new AuraHandledException('Failed to save recipients: ' + e.getMessage());
            }
        } else {
            throw new AuraHandledException('No recipients to save.');
        }
    }

    @AuraEnabled
    public static List<MSD_CORE_HEQ_Recipient__c> getRecipients() {
        return [SELECT Id, MSD_CORE_HEQ_FirstName__c, MSD_CORE_HEQ_LastName__c, MSD_CORE_HEQ_Email__c FROM MSD_CORE_HEQ_Recipient__c];
    }
    
}