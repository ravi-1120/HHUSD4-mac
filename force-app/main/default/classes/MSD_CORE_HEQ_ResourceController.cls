public class MSD_CORE_HEQ_ResourceController {
    // @AuraEnabled(cacheable=true)
    // public static List<String> getVisibleFields(String profileName) {
    //     List<MSD_CORE_Resource_Configs__mdt> configs = [
    //         SELECT MSD_CORE_Resource_Fields__c
    //         FROM MSD_CORE_Resource_Configs__mdt
    //         WHERE MSD_CORE_Profile__c = :profileName
    //     ];
    
    //     List<String> fieldNames = new List<String>();
    
    //     if (!configs.isEmpty()) {
    //         // Split the comma-separated field names
    //         fieldNames = configs[0].MSD_CORE_Resource_Fields__c.split(',\\s*');
    //     }
    
    //     return fieldNames;
    // }
    // 
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> FileDetails(String recordId) {
        try {
            // String profilename = [SELECT Profile.Name FROM User WHERE Id =: Userinfo.getUserId()].Profile.Name;
            
            // String whereClause = 'WHERE msd_core_profile__c = \'' + profilename + '\' AND msd_core_isactive__c = true ORDER BY msd_core_order__c ASC';
            // List<Map<String, Object>> metadata = MSD_CORE_HEQ_Utility.getAllFieldValues('MSD_CORE_HEQ_Resource_Configs__mdt', whereClause);
            // System.debug('metadata>>'+metadata);
            // List<String> fieldAPINames = new List<String>();
            // Map<String, String> fieldLabelMap = new Map<String, String>();
            
            // for (Map<String, Object> fieldMetadata : metadata) {
            //     String apiName = (String) fieldMetadata.get('msd_core_field_apiname__c');
            //     String fieldLabel = (String) fieldMetadata.get('label');
            //     if (!fieldAPINames.contains(apiName)) {
            //         fieldAPINames.add(apiName);
            //     }
            //     fieldLabelMap.put(apiName, fieldLabel);
            // }
            
            // String soqlQuery = 'SELECT ' + String.join(fieldAPINames, ', ') + ' FROM ContentVersion  WHERE Id =: recordId';
            
            // List<ContentVersion> contentVersionRecords = Database.query(soqlQuery);
            // System.debug('contentVersionRecords::>>'+contentVersionRecords);
            
            // List<Map<String, Object>> resultList = new List<Map<String, Object>>();
            
            // for (ContentVersion content : contentVersionRecords) {
            //     Map<String, Object> recordMap = new Map<String, Object>();
            
            //     for (String fieldName : fieldAPINames) {
            //         Object fieldValue = content.get(fieldName);
            //         // recordMap.put(fieldLabelMap.get(fieldName), content.get(fieldName));
            //         recordMap.put(fieldLabelMap.get(fieldName), fieldValue != null ? fieldValue : 'N/A');
            //     }
            //     resultList.add(recordMap);
            // }
            // return resultList;
            
            
            String profilename = [SELECT Profile.Name FROM User WHERE Id =: Userinfo.getUserId()].Profile.Name;
            
            String whereClause = 'WHERE msd_core_profile__c = \'' + profilename + '\' AND msd_core_isactive__c = true ORDER BY msd_core_order__c ASC';
            List<Map<String, Object>> metadata = MSD_CORE_HEQ_Utility.getAllFieldValues('MSD_CORE_HEQ_Resource_Configs__mdt', whereClause);
            System.debug('metadata>>' + metadata);
            
            // Using a list to store unique API Names and an ordered map to manage label-API name relationships
            List<String> fieldAPINames = new List<String>();
            List<Map<String, String>> apiNameLabelMappings = new List<Map<String, String>>();
            
            for (Map<String, Object> fieldMetadata : metadata) {
                String apiName = (String) fieldMetadata.get('msd_core_field_apiname__c');
                String fieldLabel = (String) fieldMetadata.get('label');
                
                // Add unique API Name to the query list
                if (!fieldAPINames.contains(apiName)) {
                    fieldAPINames.add(apiName);
                }
                
                // Store the mapping for both duplicate field API names and different labels
                Map<String, String> apiLabelMap = new Map<String, String>();
                apiLabelMap.put('apiName', apiName);
                apiLabelMap.put('label', fieldLabel);
                apiNameLabelMappings.add(apiLabelMap);
            }
            
            // Construct SOQL query with unique field API Names
            String soqlQuery = 'SELECT ' + String.join(fieldAPINames, ', ') + ' FROM ContentVersion WHERE Id =: recordId';
            List<ContentVersion> contentVersionRecords = Database.query(soqlQuery);
            System.debug('contentVersionRecords::>>' + contentVersionRecords);
            
            List<Map<String, Object>> resultList = new List<Map<String, Object>>();
            
            // Iterate through the contentVersionRecords and populate the resultList with field values and associated labels
            for (ContentVersion content : contentVersionRecords) {
                Map<String, Object> recordMap = new Map<String, Object>();
                
                for (Map<String, String> apiLabelMapping : apiNameLabelMappings) {
                    String apiName = apiLabelMapping.get('apiName');
                    String label = apiLabelMapping.get('label');
                    
                    Object fieldValue = content.get(apiName);
                    recordMap.put(label, fieldValue != null ? fieldValue : 'N/A');
                }
                
                resultList.add(recordMap);
            }
            
            return resultList;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching topic details: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getResourceDetails(String metadataType, String recordApiName, List<String> fieldNames) {
        Map<String, String> fieldValues = new Map<String, String>();
        String query = 'SELECT ' + String.join(fieldNames, ',') + ' FROM ' + metadataType + ' WHERE MasterLabel = :recordApiName';
        System.debug('Query is: ' + query);
        List<SObject> records = Database.query(query);
        if (!records.isEmpty()) {
            SObject record = records[0];
            for (String fieldName : fieldNames) {
                fieldValues.put(fieldName, (String) record.get(fieldName));
            }
        }
        return fieldValues;
    }
    
    @AuraEnabled
    public static String sendEmailNotification(List<map<String, String>> userInfoMapList, String orderNum, String resourceName, String resourceID, String username, String recordID, String userId) {
        try {
            if (userInfoMapList == null || userInfoMapList.size() == 0) {
                return System.label.MSD_CORE_HEQ_No_Users_Selected;
            }
            
            // Fetch the Email Template
            //HEQ_E_delivered_Resources_Ready_for_Download_1726750903620 need to remove
            EmailTemplate emailTemplate = [SELECT Id, Body, Subject, HtmlValue 
                                           FROM EmailTemplate 
                                           // WHERE DeveloperName = 'HEQ Email to customer' 
                                           WHERE DeveloperName ='HEQ_E_delivered_Resources_Ready_for_Download_1726750903620'
                                           LIMIT 1];
            if (emailTemplate == null) {
                System.debug('Email template not found.');
                return 'Email template not found.';
            }
            
            // Fetch Org Wide Email Address
            MSD_CORE_HEQ_Portal_Setting__mdt[] heqSettings = [SELECT Id, MSD_CORE_HEQ_ORG_Wide_Address__c, MSD_CORE_Expiry_Days__c
                                                              FROM MSD_CORE_HEQ_Portal_Setting__mdt 
                                                              WHERE DeveloperName='MSD_CORE_Health_EQ_Portal'];
            if (heqSettings.isEmpty()) {
                return 'Organization-wide email address setting not found.';
            }
            String orgwideadd = heqSettings[0].MSD_CORE_HEQ_ORG_Wide_Address__c;
            Integer expiryInDays = (Integer)heqSettings[0].MSD_CORE_Expiry_Days__c;
            
            // Prepare Email Message
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            // List<string> emailIdList = new List<string>();
            // string publicUrlOfResource = MSD_CORE_HEQ_Utility.createContentDistributionLink(orderNum, expiryInDays);
            String publicUrlOfResource;
            if (String.isNotBlank(orderNum)) {
                publicUrlOfResource = MSD_CORE_HEQ_Utility.createContentDistributionLink(orderNum, expiryInDays);
            } else {
                publicUrlOfResource = '';
            }
            
            
            for (map<String, String> userInfoMap : userInfoMapList) {
                /*User user = [SELECT Id, Name, Email FROM User WHERE Id = :userId LIMIT 1];
if (user == null || String.isBlank(user.Email)) {
System.debug('Skipping user with ID: ' + userId + ' - no email found.');
continue; // Skip users without email
}*/
                
                // Customize Email Body and Subject
                
                String emailBody = emailTemplate.HtmlValue
                    // .replace('{aeName}', (string)userInfoMap.get('name'))
                    .replace('{aeName}', username)
                    .replace('{orderNum}', '')
                    .replace('{resourceName}', resourceName)
                    .replace('{resourceCode}', String.isEmpty(resourceID) ? ' ' : resourceID)
                    .replace('{downloadBtn}', '<a href="' + publicUrlOfResource +'" style="display: inline-block; color: #FFFFFF; text-decoration: none; font-size: 14px; font-weight: 700; line-height: 20px; text-align: center; background-color: #00857C; padding: 8px 16px; border-radius: 5px; font-family: Arial, sans-serif;">DOWNLOAD</a>')
                    .replace('{privacyLink}', '<a href="' + System.Label.MSD_CORE_HEQ_PrivacyLink + '">Merck Privacy Statement.</a>');
                
                String formattedSubject = emailTemplate.Subject.replace('{aeName}', username);
                
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new String[] {(string)userInfoMap.get('email')});
                email.setSubject(formattedSubject);
                email.setHtmlBody(emailBody);
                email.setSaveAsActivity(false);
                
                OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :orgwideadd LIMIT 1];
                if (!owea.isEmpty()) {
                    email.setOrgWideEmailAddressId(owea[0].Id);
                }
                
                emails.add(email);
                System.debug('Email prepared for user: ' + user.Name + ' with email: ' + user.Email);
                
                // Create the order tracking record
                MSD_CORE_HEQ_Order_History__c orderRecord = new MSD_CORE_HEQ_Order_History__c();
                orderRecord.MSD_CORE_HEQ_Customer_Name__c = (string)userInfoMap.get('name');
                orderRecord.MSD_CORE_HEQ_Email__c = (string)userInfoMap.get('email');
                orderRecord.MSD_CORE_HEQ_Last_Shared__c = System.now();
                orderRecord.MSD_CORE_HEQ_Order_Type__c = 'e-Delivery';
                orderRecord.MSD_CORE_HEQ_Resource_ID__c = recordID;
                orderRecord.MSD_CORE_HEQ_Resource_Name__c = resourceName;
                // orderRecord.MSD_CORE_HEQ_Resource_Name__c = resourceName;
                orderRecord.MSD_CORE_HEQ_Resource_Code__c = resourceID;
                orderRecord.CreatedById = userId;
                
                // Insert the record
                insert orderRecord;
            }
            
            if (!emails.isEmpty()) {
                Messaging.sendEmail(emails);
                System.debug('Emails sent successfully. Total emails sent: ' + emails.size());
            }
            
            return 'Emails sent successfully.';
        } catch (Exception e) {
            return 'Error sending email: ' + e.getMessage();
        }
    }
    
    public class CustomerResourceWrapper {
        public String customerName { get; set; }
        public String email { get; set; }
        public List<ResourceWrapper> resources { get; set; }
        
        public CustomerResourceWrapper(String customerName, String email) {
            this.customerName = customerName;
            this.email = email;
            this.resources = new List<ResourceWrapper>();
        }
    }
    
    public class ResourceWrapper {
        public String resourceName { get; set; }
        public String resourceId { get; set; }
        public String lastShared { get; set; }
        public String resourceCode { get; set; } 
        public String recordId {get;set;}
        
        public ResourceWrapper(String resourceName, String resourceId, String lastShared, String resourceCode,String recordId) {
            this.resourceName = resourceName;
            this.resourceId = resourceId;
            this.lastShared = lastShared;
            this.resourceCode = resourceCode;
            this.recordId = recordId;
        }
    }
    
    @AuraEnabled
    public static String getCustomerResources() {
        String currentUserId = UserInfo.getUserId();
        List<MSD_CORE_HEQ_Order_History__c> allOrders = [
            SELECT Id,
            MSD_CORE_HEQ_Customer_Name__c,
            MSD_CORE_HEQ_Email__c,
            MSD_CORE_HEQ_Resource_Name__c,
            MSD_CORE_HEQ_Resource_ID__c,
            MSD_CORE_HEQ_Last_Shared__c,
            MSD_CORE_HEQ_Resource_Code__c
            FROM MSD_CORE_HEQ_Order_History__c
            WHERE CreatedById = :currentUserId
        ];
        
        Map<String, CustomerResourceWrapper> customerMap = new Map<String, CustomerResourceWrapper>();
        
        for (MSD_CORE_HEQ_Order_History__c order : allOrders) {
            String customerName = order.MSD_CORE_HEQ_Customer_Name__c;
            
            if (!customerMap.containsKey(customerName)) {
                customerMap.put(customerName, new CustomerResourceWrapper(customerName, order.MSD_CORE_HEQ_Email__c));
            }
            
            String lastSharedDateStr = order.MSD_CORE_HEQ_Last_Shared__c != null 
                ? String.valueOf(order.MSD_CORE_HEQ_Last_Shared__c) 
                : 'N/A';
            
            ResourceWrapper resource = new ResourceWrapper(
                order.MSD_CORE_HEQ_Resource_Name__c,
                order.MSD_CORE_HEQ_Resource_ID__c,
                lastSharedDateStr,
                order.MSD_CORE_HEQ_Resource_Code__c,
                order.Id
            );
            
            customerMap.get(customerName).resources.add(resource);
        }
        
        // Return the serialized data as JSON
        return JSON.serialize(new List<CustomerResourceWrapper>(customerMap.values()));
    }
    
    @AuraEnabled
    public static String resendEmailNotification(String username, String email, String resourceId, String resourceName, String orderNum, String userId, String recordID, String customername) {
        
        if (String.isEmpty(username) || String.isEmpty(email) || String.isEmpty(resourceId) || String.isEmpty(resourceName) || String.isEmpty(userId)) {
            throw new AuraHandledException('Invalid input parameters provided.');
        }
        
        System.debug('Customer Name: ' + customername);
        System.debug('Email: ' + email);
        System.debug('Resource ID: ' + resourceId);
        System.debug('Resource Name: ' + resourceName);
        System.debug('Order Number: ' + orderNum);
        System.debug('User ID: ' + userId);
        
        List<Map<String, String>> userInfoMapList = new List<Map<String, String>>();
        Map<String, String> userInfo = new Map<String, String>();
        userInfo.put('name', customername);
        userInfo.put('email', email);
        userInfoMapList.add(userInfo);
        
        // Call the existing sendEmailNotification method
        sendEmailNotification(
            userInfoMapList,
            orderNum, 
            resourceName,
            resourceId, 
            username,
            recordID,  
            userId
        );
        return 'success';
        
    }
    
    // public class GroupedOrderWrapper {
    //     public String orderId { get; set; }
    //     public String orderStatus { get; set; }
    //     public String customerName { get; set; }
    //     public String address { get; set; }
    //     public List<OrderItemWrapper> orderItems { get; set; } 
        
    //     public GroupedOrderWrapper(String orderId, String orderStatus, String customerName, String address) {
    //         this.orderId = orderId;
    //         this.orderStatus = orderStatus;
    //         this.customerName = customerName;
    //         this.address = address;
    //         this.orderItems = new List<OrderItemWrapper>(); 
    //     }
    // }
    
    // public class OrderItemWrapper {
    //     public String resourceId { get; set; }
    //     public String itemQuantity { get; set; }
    //     public String contentTitle { get; set; }
    //     public String resourceCode { get; set; }
        
    //     public OrderItemWrapper(String resourceId, String itemQuantity, String contentTitle, String resourceCode) {
    //         this.resourceId = resourceId;
    //         this.itemQuantity = itemQuantity;
    //         this.contentTitle = contentTitle;
    //         this.resourceCode = resourceCode;
    //     }
    // }
    
    // @AuraEnabled(cacheable=true)
    // public static List<GroupedOrderWrapper> getCustomerPrintOrders() {
    //     String currentUserId = UserInfo.getUserId();
        
    //     List<MSD_CORE_HEQ_Order__c> allOrders = [
    //         SELECT Id,
    //         MSD_CORE_Cust_Order_Number__c,
    //         MSD_CORE_Order_Status__c,      
    //         MSD_CORE_HEQ_Address__r.MSD_CORE_HEQ_User__r.FirstName,
    //         MSD_CORE_HEQ_Address__r.MSD_CORE_HEQ_User__r.LastName,
    //         MSD_CORE_HEQ_Address__r.MSD_CORE_HEQ_Address_1__c,
    //         MSD_CORE_HEQ_Address__r.MSD_CORE_HEQ_Address_2__c,
    //         MSD_CORE_HEQ_Address__r.MSD_CORE_HEQ_Address_3__c,
    //         ( 
    //             SELECT Id,
    //             MSD_CORE_Resource_Id__c,
    //             MSD_CORE_Item_Quantity__c
    //             FROM HEQ_Order_Items__r 
    //         )
    //         FROM MSD_CORE_HEQ_Order__c
    //     ];
        
    //     Set<String> resourceIds = new Set<String>();
        
    //     for (MSD_CORE_HEQ_Order__c order : allOrders) {
    //         for (MSD_CORE_HEQ_Order_Items__c orderItem : order.HEQ_Order_Items__r) {
    //             if (orderItem != null && orderItem.MSD_CORE_Resource_Id__c != null) {
    //                 resourceIds.add(orderItem.MSD_CORE_Resource_Id__c);
    //             }
    //         }
    //     }
    //     System.debug('Resource IDs extracted==> 398 line ' + resourceIds);
        
    //     Map<String, ContentVersion> contentVersionMap = new Map<String, ContentVersion>();
        
    //     if (!resourceIds.isEmpty()) {
    //         List<ContentVersion> contentVersions = [
    //             SELECT Id, Title, MSD_CORE_Resource_Code__c
    //             FROM ContentVersion
    //             WHERE Id IN :resourceIds
    //             AND IsLatest = true
    //         ];
    //         System.debug('Number of ContentVersion records fetched==> 409 line ' + contentVersions.size());
            
    //         for (ContentVersion version : contentVersions) {
    //             contentVersionMap.put(version.Id, version);
    //         }
    //     }
        
    //     Map<String, GroupedOrderWrapper> orderMap = new Map<String, GroupedOrderWrapper>();
        
    //     for (MSD_CORE_HEQ_Order__c order : allOrders) {
    //         String customerFirstName = order.MSD_CORE_HEQ_Address__r.MSD_CORE_HEQ_User__r.FirstName;
    //         String customerLastName = order.MSD_CORE_HEQ_Address__r.MSD_CORE_HEQ_User__r.LastName;
    //         String customerName = (customerFirstName != null ? customerFirstName : '') + ' ' + (customerLastName != null ? customerLastName : '');
            
    //         List<String> addressComponents = new List<String>();
    //         if (order.MSD_CORE_HEQ_Address__r.MSD_CORE_HEQ_Address_1__c != null) {
    //             addressComponents.add(order.MSD_CORE_HEQ_Address__r.MSD_CORE_HEQ_Address_1__c);
    //         }
    //         if (order.MSD_CORE_HEQ_Address__r.MSD_CORE_HEQ_Address_2__c != null) {
    //             addressComponents.add(order.MSD_CORE_HEQ_Address__r.MSD_CORE_HEQ_Address_2__c);
    //         }
    //         if (order.MSD_CORE_HEQ_Address__r.MSD_CORE_HEQ_Address_3__c != null) {
    //             addressComponents.add(order.MSD_CORE_HEQ_Address__r.MSD_CORE_HEQ_Address_3__c);
    //         }
            
    //         String customerAddress = String.join(addressComponents, ', ');
            
    //         GroupedOrderWrapper orderWrapper;
    //         if (!orderMap.containsKey(order.MSD_CORE_Cust_Order_Number__c)) {
    //             orderWrapper = new GroupedOrderWrapper(
    //                 order.MSD_CORE_Cust_Order_Number__c, 
    //                 order.MSD_CORE_Order_Status__c,    
    //                 customerName,                        
    //                 customerAddress                      
    //             );
    //             orderMap.put(order.MSD_CORE_Cust_Order_Number__c, orderWrapper);
    //         } else {
    //             orderWrapper = orderMap.get(order.MSD_CORE_Cust_Order_Number__c);
    //         }
            
    //         if (order.HEQ_Order_Items__r != null) { 
    //             for (MSD_CORE_HEQ_Order_Items__c orderItem : order.HEQ_Order_Items__r) {
    //                 System.debug('OrderItem==> Line 451 ' + orderItem.Id);
    //                 if (orderItem != null) { 
    //                     ContentVersion contentVersion = contentVersionMap.get(orderItem.MSD_CORE_Resource_Id__c);
    //                     if (contentVersion != null) {
    //                         orderWrapper.orderItems.add(new OrderItemWrapper(
    //                             orderItem.MSD_CORE_Resource_Id__c,
    //                             String.valueOf(orderItem.MSD_CORE_Item_Quantity__c),
    //                             contentVersion.Title,
    //                             contentVersion.MSD_CORE_Resource_Code__c
    //                         ));
    //                         System.debug('Order item added==> 461 line ' + contentVersion.Title);
    //                     }
    //                 }
    //             }
    //         }
    //     }
        
    //     System.debug('Number of orders processed: ' + orderMap.size());
    //     System.debug('NEw log ShR: ' + new List<GroupedOrderWrapper>(orderMap.values()));
        
    //     List<GroupedOrderWrapper> returnval = new List<GroupedOrderWrapper>(orderMap.values());
        
    //     List<GroupedOrderWrapper> filteredReturnVal = new List<GroupedOrderWrapper>();
    //     for (GroupedOrderWrapper order : returnval) {
    //         if (order.orderId != null && 
    //             order.orderStatus != null && 
    //             order.orderId.trim() != '' &&
    //             order.orderStatus.trim() != '') { 
    //                 filteredReturnVal.add(order);
    //             }
    //     }
        
    //     System.debug('Filtered returnval>>>> ' + JSON.serialize(filteredReturnVal));
    //     return filteredReturnVal;
        
    // }
    
    @AuraEnabled(cacheable=true)
    public static List<MSD_CORE_HEQ_Order__c> getCustomerPrintOrders() {
        String currentUserId = UserInfo.getUserId();

        List<MSD_CORE_HEQ_Order__c> allOrders = [
            SELECT Id,
                MSD_CORE_Cust_Order_Number__c,
                MSD_CORE_Order_Status__c,
                MSD_CORE_Requestor__c,
                MSD_CORE_Customer__r.FirstName,
                MSD_CORE_Customer__r.LastName,
                MSD_CORE_Integration_Status__c,
                CreatedDate,
                MSD_CORE_HEQ_Address__r.MSD_CORE_HEQ_Address_1__c,
                MSD_CORE_HEQ_Address__r.MSD_CORE_HEQ_City__c,
                MSD_CORE_HEQ_Address__r.MSD_CORE_HEQ_Zip_Code__c,
                ( 
                        SELECT Id,
                            MSD_CORE_Resource_Id__c,
                            MSD_CORE_Item_Quantity__c
                        FROM HEQ_Order_Items__r 
                )
            FROM MSD_CORE_HEQ_Order__c
            WHERE MSD_CORE_Requestor__c = :currentUserId
        ];
        System.debug('allOrders>>>> ' + allOrders);
        return allOrders;
    }
}