/**
 * Component Name:      MSD_CORE_HEQ_CustomerController
 * Created By:          Ravi Modi (Focal CXM)
 * Created Date:        19th Aug 2024
 * @description:        Server side controller for mSD_CORE_HEQ_Customer LWC component
 * Test Class:          
 */

public without sharing class MSD_CORE_HEQ_CustomerController {
   
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
                        resultMap.put('LastLoginDate', personUser.LastLoginDate.format('MM/dd/yyyy hh:mm a'));
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

    // Method to insert records into MSD_CORE_HEQ_Address__c when new addresses need to be added from Address_vod__c
    public static void insertAddressFromVod(Address_vod__c vodAddress) {
        try {
            if (vodAddress == null || vodAddress.Account_vod__c == null) {
                throw new AuraHandledException('Invalid Address or Account');
            }

            // Insert into MSD_CORE_HEQ_Address__c
            MSD_CORE_HEQ_Address__c newRecord = new MSD_CORE_HEQ_Address__c(
                MSD_CORE_HEQ_Account__c = vodAddress.Account_vod__c,
                MSD_CORE_HEQ_Address_1__c = vodAddress.Address_line_2_vod__c,
                MSD_CORE_HEQ_City__c = vodAddress.City_vod__c,
                MSD_CORE_HEQ_State__c = vodAddress.State_vod__c,
                MSD_CORE_HEQ_Zip_Code__c = vodAddress.Zip_vod__c,
                MSD_CORE_Address_Vod_Id__c = vodAddress.Id // Store reference to Address_vod__c record
            );

            insert newRecord;

        } catch (DmlException dmlEx) {
            System.debug('DML Exception while inserting: ' + dmlEx.getMessage());
            throw new AuraHandledException('An error occurred while saving the address. Please try again.');
        } catch (Exception ex) {
            System.debug('Exception: ' + ex.getMessage());
            throw new AuraHandledException('An unexpected error occurred. Please contact support.');
        }
    }

    public static void syncAddresses(List<Id> accountIds) {
        try {
            if (accountIds.isEmpty()) {
                return;
            }

            // Fetch addresses from Address_vod__c
            List<Address_vod__c> addressList1 = [
                SELECT Id, Address_line_2_vod__c, City_vod__c, State_vod__c, Zip_vod__c, Account_vod__c, Primary_vod__c
                FROM Address_vod__c 
                WHERE Account_vod__c IN :accountIds
            ];

            // Fetch addresses from MSD_CORE_HEQ_Address__c
            List<MSD_CORE_HEQ_Address__c> addressList2 = [
                SELECT Id, MSD_CORE_HEQ_Account__c, MSD_CORE_HEQ_Address_1__c, MSD_CORE_HEQ_City__c, MSD_CORE_HEQ_State__c, MSD_CORE_HEQ_Zip_Code__c, 
                    MSD_CORE_Address_Vod_Id__c, MSD_CORE_HEQ_Is_Default__c, MSD_CORE_IsActive__c
                FROM MSD_CORE_HEQ_Address__c
                WHERE MSD_CORE_HEQ_Account__c IN :accountIds
            ];

            // Map for easy comparison: Map<Id, MSD_CORE_HEQ_Address__c>
            Map<Id, MSD_CORE_HEQ_Address__c> heqAddressMap = new Map<Id, MSD_CORE_HEQ_Address__c>();
            for (MSD_CORE_HEQ_Address__c heqAddress : addressList2) {
                heqAddressMap.put(heqAddress.MSD_CORE_Address_Vod_Id__c, heqAddress);
            }

            List<MSD_CORE_HEQ_Address__c> addressesToInsert = new List<MSD_CORE_HEQ_Address__c>();
            List<MSD_CORE_HEQ_Address__c> addressesToUpdate = new List<MSD_CORE_HEQ_Address__c>();
            List<MSD_CORE_HEQ_Address__c> addressesToMarkInactive = new List<MSD_CORE_HEQ_Address__c>();

            // Compare and Sync: For each Address_vod__c address, check for existing records in MSD_CORE_HEQ_Address__c
            for (Address_vod__c vodAddress : addressList1) {
                MSD_CORE_HEQ_Address__c existingHeqAddress = heqAddressMap.get(vodAddress.Id);
                if (existingHeqAddress == null) {
                    // New address, insert into MSD_CORE_HEQ_Address__c
                    MSD_CORE_HEQ_Address__c newHeqAddress = new MSD_CORE_HEQ_Address__c(
                        MSD_CORE_HEQ_Account__c = vodAddress.Account_vod__c,
                        MSD_CORE_HEQ_Address_1__c = vodAddress.Address_line_2_vod__c,
                        MSD_CORE_HEQ_City__c = vodAddress.City_vod__c,
                        MSD_CORE_HEQ_State__c = vodAddress.State_vod__c,
                        MSD_CORE_HEQ_Zip_Code__c = vodAddress.Zip_vod__c,
                        MSD_CORE_Address_Vod_Id__c = vodAddress.Id,
                        MSD_CORE_IsActive__c = true // New records are active
                    );

                    // Check if Primary_vod__c is true and set MSD_CORE_HEQ_Is_Default__c accordingly
                    if (vodAddress.Primary_vod__c) {
                        newHeqAddress.MSD_CORE_HEQ_Is_Default__c = true;
                    }

                    addressesToInsert.add(newHeqAddress);
                } else {
                    // Update existing address if fields differ, but do not override MSD_CORE_HEQ_Is_Default__c
                    if (existingHeqAddress.MSD_CORE_HEQ_Address_1__c != vodAddress.Address_line_2_vod__c ||
                        existingHeqAddress.MSD_CORE_HEQ_City__c != vodAddress.City_vod__c ||
                        existingHeqAddress.MSD_CORE_HEQ_State__c != vodAddress.State_vod__c ||
                        existingHeqAddress.MSD_CORE_HEQ_Zip_Code__c != vodAddress.Zip_vod__c) {

                        existingHeqAddress.MSD_CORE_HEQ_Address_1__c = vodAddress.Address_line_2_vod__c;
                        existingHeqAddress.MSD_CORE_HEQ_City__c = vodAddress.City_vod__c;
                        existingHeqAddress.MSD_CORE_HEQ_State__c = vodAddress.State_vod__c;
                        existingHeqAddress.MSD_CORE_HEQ_Zip_Code__c = vodAddress.Zip_vod__c;
                        addressesToUpdate.add(existingHeqAddress);
                    }

                    // Set the existing record to active if it matches a vodAddress
                    //existingHeqAddress.MSD_CORE_IsActive__c = true;
                    addressesToUpdate.add(existingHeqAddress);

                    // Remove from map as it has been processed
                    heqAddressMap.remove(vodAddress.Id);
                }
            }

            // Any remaining records in heqAddressMap need to be marked as inactive (no longer present in Address_vod__c)
            for (MSD_CORE_HEQ_Address__c inactiveAddress : heqAddressMap.values()) {
                inactiveAddress.MSD_CORE_IsActive__c = false;
                addressesToMarkInactive.add(inactiveAddress);
            }

            // Perform DML operations in bulk
            if (!addressesToInsert.isEmpty()) {
                insert addressesToInsert;
            }
            if (!addressesToUpdate.isEmpty()) {
                update addressesToUpdate;
            }
            if (!addressesToMarkInactive.isEmpty()) {
                update addressesToMarkInactive; // Mark addresses as inactive
            }

        } catch (DmlException dmlEx) {
            System.debug('DML Exception while syncing: ' + dmlEx.getMessage());
            throw new AuraHandledException('An error occurred during syncing addresses. Please contact support.');
        } catch (Exception ex) {
            System.debug('Exception: ' + ex.getMessage());
            throw new AuraHandledException('An unexpected error occurred while syncing addresses. Please contact support.');
        }
    }

    @AuraEnabled
    public static String setDefaultAddress(Id addressId, Boolean isSelfPrint) {
        String message;
        try {
            MSD_CORE_HEQ_Address__c addressToUpdate;

            addressToUpdate = [
                SELECT Id, 
                    MSD_CORE_HEQ_User__c, 
                    MSD_CORE_HEQ_Is_Default__c,
                    MSD_CORE_HEQ_Account__c
                FROM MSD_CORE_HEQ_Address__c
                WHERE Id = :addressId
                LIMIT 1
            ];
        

            addressToUpdate.MSD_CORE_HEQ_Is_Default__c = true;

            List<MSD_CORE_HEQ_Address__c> otherAddresses;

            if (isSelfPrint) {
                otherAddresses = [
                    SELECT Id, MSD_CORE_HEQ_Is_Default__c
                    FROM MSD_CORE_HEQ_Address__c
                    WHERE MSD_CORE_HEQ_User__c = :addressToUpdate.MSD_CORE_HEQ_User__c
                    AND Id != :addressId
                ];
            } else {
                otherAddresses = [
                    SELECT Id, MSD_CORE_HEQ_Is_Default__c
                    FROM MSD_CORE_HEQ_Address__c
                    WHERE MSD_CORE_HEQ_Account__c = :addressToUpdate.MSD_CORE_HEQ_Account__c
                    AND Id != :addressId
                ];
            }

            for (MSD_CORE_HEQ_Address__c otherAddress : otherAddresses) {
                otherAddress.MSD_CORE_HEQ_Is_Default__c = false;
            }

            List<MSD_CORE_HEQ_Address__c> addressesToUpdate = new List<MSD_CORE_HEQ_Address__c> { addressToUpdate };
            addressesToUpdate.addAll(otherAddresses);

            update addressesToUpdate;

            message = 'Success';

        } catch (DmlException dmlEx) {
            System.debug('DML Exception while setting default address: ' + dmlEx.getMessage());
            throw new AuraHandledException('An error occurred while setting the default address. Please contact support.');
        } catch (Exception ex) {
            System.debug('Exception: ' + ex.getMessage());
            throw new AuraHandledException('An unexpected error occurred while setting the default address. Please contact support.');
        }

        return message;
    }

    @AuraEnabled
    public static List<AccountAddressWrapper> getAddressesForAccounts(Id accountId, Boolean isSelfPrint) {
        List<AccountAddressWrapper> accountAddressWrappers = new List<AccountAddressWrapper>();

        try {
            Id queryId;
            String firstName = '';
            String lastName = '';
            Boolean isSelfPrintAddress = false;

            if (isSelfPrint) {
                queryId = UserInfo.getUserId();
                isSelfPrintAddress = true;
            } else {
                queryId = accountId;

                Account account = [
                    SELECT Id, Name, IsPersonAccount, FirstName, LastName, IsCustomerPortal
                    FROM Account
                    WHERE Id = :accountId
                    LIMIT 1
                ];

                if (account.IsPersonAccount && account.IsCustomerPortal) {
                    User user = [
                        SELECT FirstName, LastName 
                        FROM User 
                        WHERE AccountId = :accountId
                        LIMIT 1
                    ];
                    firstName = user.FirstName;
                    lastName = user.LastName;
                } else {
                    firstName = account.FirstName != null ? account.FirstName : account.Name;
                    lastName = account.LastName;
                }

                List<Id> accountIds = new List<Id>{ accountId };
                syncAddresses(accountIds);
            }

            List<MSD_CORE_HEQ_Address__c> heqAddresses;

            if (isSelfPrint) {
                heqAddresses = [
                    SELECT Id, MSD_CORE_HEQ_Account__c, MSD_CORE_HEQ_Address_1__c, 
                        MSD_CORE_HEQ_City__c, MSD_CORE_HEQ_State__c, MSD_CORE_HEQ_Zip_Code__c, 
                        MSD_CORE_HEQ_Is_Default__c, MSD_CORE_Address_Vod_Id__c, 
                        MSD_CORE_HEQ_User__r.FirstName, MSD_CORE_HEQ_User__r.LastName
                    FROM MSD_CORE_HEQ_Address__c
                    WHERE MSD_CORE_HEQ_User__c = :queryId
                    AND MSD_CORE_IsActive__c = true
                ];

                if (!heqAddresses.isEmpty()) {
                    firstName = heqAddresses[0].MSD_CORE_HEQ_User__r.FirstName;
                    lastName = heqAddresses[0].MSD_CORE_HEQ_User__r.LastName;
                }
            } else {
                heqAddresses = [
                    SELECT Id, MSD_CORE_HEQ_Account__c, MSD_CORE_HEQ_Address_1__c, 
                        MSD_CORE_HEQ_City__c, MSD_CORE_HEQ_State__c, MSD_CORE_HEQ_Zip_Code__c, 
                        MSD_CORE_HEQ_Is_Default__c, MSD_CORE_Address_Vod_Id__c
                    FROM MSD_CORE_HEQ_Address__c
                    WHERE MSD_CORE_HEQ_Account__c = :queryId
                    AND MSD_CORE_IsActive__c = true
                ];
            }

            AccountAddressWrapper accountAddressWrapper = new AccountAddressWrapper();
            accountAddressWrapper.firstName = firstName;
            accountAddressWrapper.lastName = lastName;
            accountAddressWrapper.accountId = queryId;
            accountAddressWrapper.isSelfPrintAddress = isSelfPrintAddress;
            accountAddressWrapper.addressList = new List<AddressWrapper>();

            for (MSD_CORE_HEQ_Address__c heqAddress : heqAddresses) {
                accountAddressWrapper.addressList.add(
                    new AddressWrapper(
                        heqAddress.Id,
                        heqAddress.MSD_CORE_HEQ_Address_1__c,
                        heqAddress.MSD_CORE_HEQ_City__c,
                        heqAddress.MSD_CORE_HEQ_State__c,
                        heqAddress.MSD_CORE_HEQ_Zip_Code__c,
                        heqAddress.MSD_CORE_HEQ_Is_Default__c,
                        (heqAddress.MSD_CORE_Address_Vod_Id__c != null)
                    )
                );
            }

            accountAddressWrappers.add(accountAddressWrapper);

        } catch (Exception ex) {
            System.debug('Exception while fetching addresses: ' + ex.getMessage());
            throw new AuraHandledException('An error occurred while fetching addresses.');
        }

        return accountAddressWrappers;
    }

    // @AuraEnabled
    // public static String updateCartAddress(Id cartAddressId, Id customerId, Boolean isSelfPrint) {
    //     if (cartAddressId == null) {
    //         throw new AuraHandledException('Address ID cannot be null.');
    //     }

    //     List<MSD_CORE_HEQ_Cart__c> cartRecords = isSelfPrint 
    //         ? [SELECT Id FROM MSD_CORE_HEQ_Cart__c WHERE MSD_CORE_Cart_Owner__c = :UserInfo.getUserId() AND MSD_CORE_Customer__c = null]
    //         : [SELECT Id FROM MSD_CORE_HEQ_Cart__c WHERE MSD_CORE_Customer__c = :customerId AND MSD_CORE_Cart_Owner__c = :UserInfo.getUserId()];

    //     for (MSD_CORE_HEQ_Cart__c cart : cartRecords) {
    //         cart.MSD_CORE_Address__c = cartAddressId;
    //     }
        
    //     if (!cartRecords.isEmpty()) {
    //         try {
    //             update cartRecords;
    //             return 'Success';
    //         } catch (DmlException e) {
    //             throw new AuraHandledException('Error updating cart records: ' + e.getMessage());
    //         }
    //     } else {
    //         return 'No cart records found to update.';
    //     }
    // }

    @AuraEnabled
    public static String updateCartAddress(Id cartAddressId, Id customerId, Boolean isSelfPrint) {
        if (cartAddressId == null) {
            throw new AuraHandledException('Address ID cannot be null.');
        }

        List<MSD_CORE_HEQ_Cart__c> cartRecords;

        if (isSelfPrint) {
            cartRecords = [SELECT Id FROM MSD_CORE_HEQ_Cart__c 
                        WHERE MSD_CORE_Cart_Owner__c = :UserInfo.getUserId() 
                        AND MSD_CORE_Customer__c = null];
        } else {
            cartRecords = [SELECT Id FROM MSD_CORE_HEQ_Cart__c 
                        WHERE MSD_CORE_Customer__c = :customerId 
                        AND MSD_CORE_Cart_Owner__c = :UserInfo.getUserId()];
        }

        System.debug('Cart Records Found: ' + cartRecords.size());

        for (MSD_CORE_HEQ_Cart__c cart : cartRecords) {
            System.debug('Cart Record Found: ' + cartAddressId);
            cart.MSD_CORE_Address__c = cartAddressId;
        }

        if (!cartRecords.isEmpty()) {
            try {
                update cartRecords;
                return 'Success';
            } catch (DmlException e) {
                throw new AuraHandledException('Error updating cart records: ' + e.getMessage());
            }
        } else {
            return 'No cart records found to update.';
        }
    }


    @AuraEnabled
    public static String createOrUpdateAddress(String address1, String address2, String city, String state, String zip, Boolean isSelfPrint, Id userOrAccountId, Boolean isDefault, Id addressId) {
        try {
            MSD_CORE_HEQ_Address__c addressRecord;

            if (addressId == null) {
                addressRecord = new MSD_CORE_HEQ_Address__c();
            } else {
                addressRecord = [
                    SELECT Id, MSD_CORE_HEQ_User__c, MSD_CORE_HEQ_Account__c, MSD_CORE_HEQ_Is_Default__c
                    FROM MSD_CORE_HEQ_Address__c
                    WHERE Id = :addressId
                    LIMIT 1
                ];
            }

            if (isSelfPrint) {
                addressRecord.MSD_CORE_HEQ_User__c = UserInfo.getUserId();
            } else {
                addressRecord.MSD_CORE_HEQ_Account__c = userOrAccountId;
            }

            addressRecord.MSD_CORE_HEQ_Address_1__c = address1;
            addressRecord.MSD_CORE_HEQ_Address_2__c = address2;
            addressRecord.MSD_CORE_HEQ_City__c = city;
            addressRecord.MSD_CORE_HEQ_State__c = state;
            addressRecord.MSD_CORE_HEQ_Zip_Code__c = zip;

            if (addressId == null) {
                if (isDefault) {
                    List<MSD_CORE_HEQ_Address__c> addressesToUpdate;

                    if (isSelfPrint) {
                        addressesToUpdate = [
                            SELECT Id
                            FROM MSD_CORE_HEQ_Address__c
                            WHERE MSD_CORE_HEQ_User__c = :UserInfo.getUserId()
                        ];
                    } else {
                        addressesToUpdate = [
                            SELECT Id
                            FROM MSD_CORE_HEQ_Address__c
                            WHERE MSD_CORE_HEQ_Account__c = :userOrAccountId
                        ];
                    }

                    for (MSD_CORE_HEQ_Address__c addr : addressesToUpdate) {
                        addr.MSD_CORE_HEQ_Is_Default__c = false;
                    }

                    if (!addressesToUpdate.isEmpty()) {
                        update addressesToUpdate;
                    }
                }

                insert addressRecord;
            } else {
                update addressRecord;

                if (isDefault) {
                    List<MSD_CORE_HEQ_Address__c> addressesToUpdate;

                    if (isSelfPrint) {
                        addressesToUpdate = [
                            SELECT Id
                            FROM MSD_CORE_HEQ_Address__c
                            WHERE MSD_CORE_HEQ_User__c = :UserInfo.getUserId()
                            AND Id != :addressRecord.Id
                        ];
                    } else {
                        addressesToUpdate = [
                            SELECT Id
                            FROM MSD_CORE_HEQ_Address__c
                            WHERE MSD_CORE_HEQ_Account__c = :userOrAccountId
                            AND Id != :addressRecord.Id
                        ];
                    }

                    for (MSD_CORE_HEQ_Address__c addr : addressesToUpdate) {
                        addr.MSD_CORE_HEQ_Is_Default__c = false;
                    }

                    update addressesToUpdate;
                }
            }

            if (isDefault) {
                addressRecord.MSD_CORE_HEQ_Is_Default__c = true;
                update addressRecord;
            }

            return 'Success';

        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String deactivateAddress(Id addressId) {
        if (addressId == null) {
            throw new AuraHandledException('Address ID cannot be null.');
        }

        try {
            MSD_CORE_HEQ_Address__c addressToDeactivate = [
                SELECT Id, MSD_CORE_IsActive__c 
                FROM MSD_CORE_HEQ_Address__c 
                WHERE Id = :addressId 
                LIMIT 1
            ];
            
            addressToDeactivate.MSD_CORE_IsActive__c = false;
            update addressToDeactivate;

            return 'Success';
        } catch (QueryException e) {
            throw new AuraHandledException('Error retrieving address: ' + e.getMessage());
        } catch (DmlException e) {
            throw new AuraHandledException('Error deactivating address: ' + e.getMessage());
        }
    }


    public class AddressWrapper {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String street { get; set; }
        @AuraEnabled public String city { get; set; }
        @AuraEnabled public String state { get; set; }
        @AuraEnabled public String zip { get; set; }
        @AuraEnabled public Boolean isDefault { get; set; }
        @AuraEnabled public Boolean isVodAddress { get; set; }

        public AddressWrapper(Id id, String street, String city, String state, String zip, Boolean isDefault, Boolean isVodAddress) {
            this.id = id;
            this.street = street;
            this.city = city;
            this.state = state;
            this.zip = zip;
            this.isDefault = isDefault;
            this.isVodAddress = isVodAddress;
        }
    }

    public class AccountAddressWrapper {
        @AuraEnabled public String firstName { get; set; }
        @AuraEnabled public String lastName { get; set; }
        @AuraEnabled public Id accountId { get; set; }
        @AuraEnabled public Boolean isSelfPrintAddress { get; set; }
        @AuraEnabled public List<AddressWrapper> addressList { get; set; }
    }

}