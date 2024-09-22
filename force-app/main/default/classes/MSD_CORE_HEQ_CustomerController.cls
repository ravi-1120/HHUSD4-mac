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
                if(acc.IsPersonAccount && acc.IsCustomerPortal){
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
                    }
                } else {
                    resultMap.put('Id', acc.Id);
                    resultMap.put('FirstName', acc.FirstName);
                    resultMap.put('LastName', acc.LastName);
                    resultMap.put('Name', acc.Name);
                    resultMap.put('Email', acc.PersonEmail);
                    resultMap.put('IsRegister', false);
                    
                    Boolean isInvited = isInvitedMap.get(acc.Id);
                    resultMap.put('isInvited', isInvited != null ? isInvited : false);
                }
                
                resultList.add(resultMap);
            }
            
        } catch (Exception e) {
            System.debug('Error in getCustomerList: ' + e.getMessage() + ' at line ' + e.getLineNumber());
        }
        
        return resultList;
    }

}