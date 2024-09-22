public with sharing class MCAConvertToCallController {

    private static final Integer MAX_DML_RECORD_PER_TRANSACTION = 10000;
    private static final Integer MAX_ATTENDEE_COUNT = 100;

    public class ReconcilingEntity {
        public Account account {get; set;}
        public Call2_vod__c call {get; set;}

        public ReconcilingEntity(Account account) {
            this.account = account;
        }
    }

    public class ProductDetailGroupCombo {
        public Id productId;
        public Id detailGroupId;
        public String productName;

        public Datetime startDatetime;

        public ProductDetailGroupCombo (Multichannel_Activity_Line_vod__c mcal) {
            this.productId = (Id) get(mcal, 'Product_vod__c');
            this.detailGroupId = (Id) get(mcal, 'Detail_Group_vod__c');
            this.productName = getProductName(mcal);
            this.startDatetime = (Datetime) get(mcal, 'DateTime_vod__c');
        }

        public ProductDetailGroupCombo (Call2_Key_Message_vod__c ckm) {
            this.productId = (Id) get(ckm, 'Product_vod__c');
            this.detailGroupId = (Id) get(ckm, 'Detail_Group_vod__c');
            this.productName = getProductName(ckm);
            this.startDatetime = (Datetime) get(ckm, 'Start_Time_vod__c');
        }

        public ProductDetailGroupCombo (Call2_Detail_vod__c cd) {
            this.productId = (Id) get(cd, 'Product_vod__c');
            this.detailGroupId = (Id) get(cd, 'Detail_Group_vod__c');
            this.productName = getProductName(cd);
        }

        public boolean equals(Object obj) {
            if (obj instanceof ProductDetailGroupCombo) {
                ProductDetailGroupCombo other = (ProductDetailGroupCombo) obj;
                return this.productId == other.productId && this.detailGroupId == other.detailGroupId;
            }
            return false;
        }

        public Integer hashCode() {
            Integer result = 0;
            if(this.productId != null) {
                result += ((String)this.productId).hashCode();
            }
            if(this.detailGroupId != null) {
                result += ((String)this.detailGroupId).hashCode();
            }
            result = 31 * result;
            return result;
        }

        public Boolean isProductInfoAvailable() {
            return this.productId != null || this.detailGroupId != null;
        }
    }

    // ckm wrapper to help sort CKMs by start time ASC
    public class CallKeyMessageWrapper implements Comparable {
        public Call2_Key_Message_vod__c ckm;
        public ProductDetailGroupCombo pdgCombo;
        public CallKeyMessageWrapper(Call2_Key_Message_vod__c ckm) {
            this.ckm = ckm;
        }
        public Integer compareTo(Object compareTo) {
            CallKeyMessageWrapper compareToOppy = (CallKeyMessageWrapper)compareTo;
            Datetime thisDatetime = this.ckm.Start_Time_vod__c;
            Datetime thatDatetime = compareToOppy.ckm.Start_Time_vod__c;
            if(thisDatetime > thatDatetime) {
                return 1;
            } else if (thisDatetime == thatDatetime) {
                return 0;
            } else {
                return -1;
            }
        }
    }

    @AuraEnabled(cacheable=true)
    public static Veeva_Settings_vod__c getVeevaCustomSettings(){
        return Veeva_Settings_vod__c.getInstance();
    }

    public static List<Multichannel_Activity_Line_vod__c> queryMCALs(Id mcaId, List<String> mcalFields) {
        return queryMCALs(mcaId, mcalFields, 'View_Order_vod__c');
    }

    public static List<Multichannel_Activity_Line_vod__c> queryMCALs(Id mcaId, List<String> mcalFields, String orderByField) {
        List<Multichannel_Activity_Line_vod__c> result = new List<Multichannel_Activity_Line_vod__c>();
        if(Schema.SObjectType.Multichannel_Activity_Line_vod__c.isAccessible()) {
            Set<String> toQueryFields = new Set<String>(mcalFields);
            toQueryFields.add('Id');

            VeevaBaseObject vbo = VeevaBaseObject.create(MCAL_OBJECT);
            Set<String> accessCheckFields = new Set<String>(toQueryFields);
            if(orderByField != null) {
                // also check if the order by field is accessible
                accessCheckFields.add(orderByField);
            }
            vbo.mapRelationships(new List<String>(accessCheckFields));

            List<String> accessibleFields = new List<String>(vbo.getAccessibleFields(accessCheckFields));
            toQueryFields.retainAll(accessibleFields);
            String mcalQuery = 'SELECT ' + String.join(new List<String>(toQueryFields), ',') +
                ' FROM Multichannel_Activity_Line_vod__c' +
                ' WHERE Multichannel_Activity_vod__c =: mcaId';
            if(orderByField != null && accessibleFields.contains(orderByField)) {
                mcalQuery += ' ORDER BY ' + orderByField + ' ASC';
            }
            List<Multichannel_Activity_Line_vod__c> queryResult = Database.query(mcalQuery);
            result.addAll(queryResult);
        }
        return result;
    }

    private static final String MCAL_OBJECT = 'Multichannel_Activity_Line_vod__c';
    private static final List<String> MCAL_FIELDS = new List<String>(new String[]{
        'CLM_Presentation_vod__c',
        'CLM_Presentation_vod__r.Name',
        'CLM_Presentation_vod__r.Version_vod__c',
        'Detail_Group_vod__c',
        'Detail_Group_vod__r.Name',
        'DateTime_vod__c',
        'Duration_vod__c',
        'Entity_Reference_KM_ID_vod__c',
        'Key_Message_vod__c',
        'Key_Message_vod__r.Name',
        'Key_Message_vod__r.Media_File_Name_vod__c',
        'Key_Message_Version_vod__c',
        'Product_vod__c',
        'Product_vod__r.Name',
        'Reaction_vod__c',
        'Segment_vod__c',
        'Share_Channel_vod__c',
        'View_Order_vod__c'
    });

    public static Boolean isChildAccountEnabled() {
        return getVeevaCustomSettings().Enable_Child_Account_vod__c;
    }

    @AuraEnabled
    public static Id reconcile(Id mcaId, Id accountId, Id callRecordTypeId, Child_Account_vod__c location, Map<Id, Child_Account_vod__c> attendeeLocations, Boolean isUniqueActivity) {
        if(!hasAllRequiredFLSToConvertACall()) {
            throw new AuraHandledException('reconcile - Insufficient FLS');
        }

        // validate account is available
        Account account = getAccount(accountId);
        if(account == null) {
            throw new AuraHandledException('reconcile - account not found');
        }
        Boolean isPersonAccount = account.IsPersonAccount;

        // validate mca is available and is still an unassigned presentation
        Multichannel_Activity_vod__c mca = fetchAndValidateMca(mcaId);

        // validate the call record type selected is available to the selected account
        String accountRecordTypeName = account.RecordType.DeveloperName;
        if(!isRecordTypeValid(accountRecordTypeName, callRecordTypeId)) {
            throw new AuraHandledException('reconcile - record type ' + callRecordTypeId + ' is not available for account ' + accountId);
        }

        // location is only available when Person Account is selected under Child account enablement
        Boolean isChildAccountEnabled = getVeevaCustomSettings().Enable_Child_Account_vod__c;
        if(location != null) {
            if(isPersonAccount && isChildAccountEnabled) {
                // validate location is one of Account's parent account
                Id locationId = location.Parent_Account_vod__c;
                if(!isLocationValid(accountId, locationId)) {
                    throw new AuraHandledException('reconcile - location ' + locationId + ' is not available for account ' + accountId);
                }
            } else {
                location = null;
            }
        }

        // validate attendeeIds
        Integer attendeeCount = 0;
        List<Account> attendees = null;
        if(attendeeLocations != null && !attendeeLocations.isEmpty()) {
            // validate selected account's type
            if(isPersonAccount) {
                throw new AuraHandledException('reconcile - you can add attendees when selected account is a Business Account');
            }
            attendeeCount = attendeeLocations.size();
            // number of attendees cannot exceed maximum limit
            if (attendeeCount > MAX_ATTENDEE_COUNT) {
                throw new AuraHandledException('reconcile - number of attendees exceed the max number of attendees allowed');
            }
            // query attendees
            attendees = getAttendees(attendeeLocations.keySet());
            if(attendeeCount > attendees.size()) {
                throw new AuraHandledException('reconcile - at least one attendee is no longer available');
            }
            // validate all attendees are Person Accounts (true whether child account is enabled or not)
            for(Account attendee : attendees) {
                if(!attendee.IsPersonAccount) {
                    throw new AuraHandledException('reconcile - all attendees must be Person Account');
                }
                Id attendeeId = attendee.Id;
                Child_Account_vod__c attendeeChildAccount = attendeeLocations.get(attendeeId);

                if(isChildAccountEnabled){
                    if(attendeeChildAccount == null) {
                        throw new AuraHandledException('reconcile - location is required for attendee in an child account enabled org');
                    } else {
                        Id attendeeLocationId = attendeeChildAccount.Parent_Account_vod__c;
                        // verify that the locaiton id is indeed one of the attendee's parent
                        List<Child_Account_vod__c> parents = attendee.Child_Account_vod__r;
                        if(!isParent(parents, attendeeLocationId)) {
                            throw new AuraHandledException('reconcile - location provided for attendee ' + attendeeId + ' is not its parent');
                        }
                    }
                }
            }
        }

        Integer mcalCount = 0;
        // keep a separate list holding the names to avoid looping again
        List<String> mcalProductNames = new List<String>();
        // keep track of the unqiue detail group/product combinations
        Set<ProductDetailGroupCombo> comboSet = new Set<ProductDetailGroupCombo>();
        List<ProductDetailGroupCombo> mcalProductDetailGroupCombo = new List<ProductDetailGroupCombo>();
        List<Multichannel_Activity_Line_vod__c> mcals = queryMCALs(mcaId, MCAL_FIELDS);
        if(mcals != null && !mcals.isEmpty()) {
            mcalCount = mcals.size();
            for(Multichannel_Activity_Line_vod__c mcal : mcals) {
                ProductDetailGroupCombo productDetailGroupCombo = new ProductDetailGroupCombo(mcal);
                // only add unique pair that has product info
                if(productDetailGroupCombo.isProductInfoAvailable() && comboSet.add(productDetailGroupCombo)) {
                    mcalProductDetailGroupCombo.add(productDetailGroupCombo);
                    String mcalProductName = productDetailGroupCombo.productName;
                    if(String.isNotBlank(mcalProductName)) {
                        mcalProductNames.add(mcalProductName);
                    }
                }
            }
        }

        Boolean createRelatedRecordForParent = false;
        // calculate the anticipating number of DML rows and compare against the apex dml row limits
        if(location != null) {
            // if location is available, we'll be creating a child call for the location account
            attendeeCount++;
            createRelatedRecordForParent = true;
        }
        Integer expectedDmlCount = calculateAnticipatingDmlRowCount(mcalCount, attendeeCount, createRelatedRecordForParent, mcalProductDetailGroupCombo.size());
        validateDmlCount(expectedDmlCount);

        String userTerrName = getUserTerritory(accountId);
        String callDetailProducts = getCallDetailProductsString(mcalProductNames);

        // create entities with basic call objects
        ReconcilingEntity accountEntity = constructBaseEntityWithCall(mca, account, callRecordTypeId, userTerrName, location, callDetailProducts, isUniqueActivity, false);
        List<ReconcilingEntity> attendeeEntities = new List<ReconcilingEntity>();
        if(location != null) {
            // if location is available, we'll be creating a child call for the location account
            Id parentAccountId = location.Parent_Account_vod__c;
            Account parentAccount = getAccount(parentAccountId);
            attendeeEntities.add(constructBaseEntityWithCall(mca, parentAccount, callRecordTypeId, userTerrName, location, callDetailProducts, isUniqueActivity, true));
        }
        if(attendees != null) {
            for(Account attendee : attendees) {
                Child_Account_vod__c attendeeChildAccount = null;
                if(isChildAccountEnabled) {
                    attendeeChildAccount = attendeeLocations.get(attendee.Id);
                }
                attendeeEntities.add(constructBaseEntityWithCall(mca, attendee, callRecordTypeId, userTerrName, attendeeChildAccount, callDetailProducts, isUniqueActivity, false));
            }
        }
        CallAddressService.populateCallAddress(accountEntity.call, account.Id, getUserTerritory(account.Id), callRecordTypeId);
        return upsertRecords(accountEntity, attendeeEntities, createRelatedRecordForParent, mca, mcals, mcalProductDetailGroupCombo);
    }

    @AuraEnabled
    public static Id reconcileWithExistingCall(Id mcaId, Id callId, Map<Id, Child_Account_vod__c> viewedMediaAttendees, Boolean isUniqueActivity, Boolean isSD) {
        if(!hasAllRequiredFLSToConvertACall()) {
            throw new AuraHandledException('reconcileWithExistingCall - Insufficient FLS');
        }

        Multichannel_Activity_vod__c mca = fetchAndValidateMca(mcaId);

        Call2_vod__c baseCall = [
            SELECT Id, RecordTypeId, Account_vod__c, Contact_vod__c, User_vod__c, Account_vod__r.IsPersonAccount, Detailed_Products_vod__c, Location_Name_vod__c, Location_Id_vod__c, OwnerId, Signature_Date_vod__c, Detail_Section_Attribute_vod__c,
                (SELECT Id, Account_vod__c, Contact_vod__c, User_vod__c, Signature_Date_vod__c FROM Call2_vod__r WHERE Account_vod__c != NULL OR Contact_vod__c != NULL OR User_vod__c != NULL),
                (SELECT Id, Call2_vod__c, Account_vod__c, Start_Time_vod__c,
                    Product_vod__c, Product_vod__r.Name, Detail_Group_vod__c, Detail_Group_vod__r.Name FROM Call2_Key_Message_vod__r),
                (SELECT Id, Call2_vod__c, Product_vod__c, Product_vod__r.Name, Detail_Group_vod__c, Detail_Group_vod__r.Name FROM Call2_Detail_vod__r)
            FROM Call2_vod__c
            WHERE Id =: callId];
        if(baseCall == null) {
            throw new AuraHandledException('reconcileWithExistingCall - Call not found');
        }
        Id baseCallAccountId = baseCall.Account_vod__c;
        if (baseCall.Signature_Date_vod__c != null && isSD) {
            throw new AuraHandledException('reconcileWithExistingCall - call signature date populated');
        }
        Boolean isPersonAccount = (Boolean) get(baseCall, 'Account_vod__r', 'isPersonAccount');
        isPersonAccount = isPersonAccount == null ? false : isPersonAccount;
        Id callRecordTypeId = baseCall.RecordTypeId;

        // verify accounts for the selected Call + its child calls & other additional attendees are passing validation
        List<Id> childCallIds = new List<Id>();
        List<Id> accountIds = new List<Id>();
        if (baseCallAccountId != null) {
            accountIds.add(baseCallAccountId);
        }
        if(baseCall.Call2_vod__r != null) {
            Set<Id> viewMediaAccounts = new Set<Id>();
            if(viewedMediaAttendees != null) {
                viewMediaAccounts = viewedMediaAttendees.keySet();
            }
            for(Call2_vod__c childCall : baseCall.Call2_vod__r) {
                childCallIds.add(childCall.Id);
                // only add accounts for validation check
                if (childCall.Account_vod__c != null) {
                    if (viewMediaAccounts.contains(childCall.Account_vod__c) && childCall.Signature_Date_vod__c != null && isSD){
                        throw new AuraHandledException('reconcileWithExistingCall - call signature date populated');
                    }
                    accountIds.add(childCall.Account_vod__c);
                }
            }
        }
        List<Id> attendeeIds = new List<Id>();
        if(viewedMediaAttendees != null) {
            attendeeIds.addAll(viewedMediaAttendees.keySet());
        }
        if(!attendeeIds.isEmpty()) {
            if(isPersonAccount == true) {
                throw new AuraHandledException('reconcile - you can add attendees when the call account is a Business Account');
            }
            if (attendeeIds.size() > MAX_ATTENDEE_COUNT) {
                throw new AuraHandledException('reconcile - number of attendees exceed the max number of attendees allowed');
            }
            accountIds.addAll(attendeeIds);
        }
        Map<Id, S4LAccountValidationResult> validationResult = new Map<Id, S4LAccountValidationResult>();
        if (!accountIds.isEmpty()) {
            validationResult = S4LAccountValidator.validateAccounts(mcaId, accountIds);
        }
        if(!validationResult.isEmpty()) {
            throw new AuraHandledException('reconcileWithExistingCall - call account(s) failed either account, product, or segmentation restrictions');
        }

        Map<Id, Call2_vod__c> accountIdToCallMap = new Map<Id, Call2_vod__c>();
        accountIdToCallMap.put(baseCallAccountId, baseCall);

        // to upsert
        List<Call2_vod__c> toProcess = new List<Call2_vod__c>();
        // both map's key is the account id on the Call
        Map<String, List<Call2_Key_Message_vod__c>> callKeyMessagesToUpsert = new Map<String, List<Call2_Key_Message_vod__c>>();
        Map<String, List<Call2_Detail_vod__c>> callDetailsToUpsert = new Map<String, List<Call2_Detail_vod__c>>();

        Boolean addedBaseCall = false;

        // add parent call for all non-UA record types
        // CRM-300826: added isPersonAccount. person call with UA configured should still be treated as person call
        if (isPersonAccount || !isUniqueActivity) {
            toProcess.add(baseCall);
            addedBaseCall = true;
        }

        // query child calls + their CKM/ CD
        if(!childCallIds.isEmpty()) {
            List<Call2_vod__c> childCalls = [
                SELECT Id, Account_vod__c, Contact_vod__c, User_vod__c, Detailed_Products_vod__c, OwnerId,
                    (SELECT Id, Call2_vod__c, Account_vod__c, Contact_vod__c, User_vod__c, Start_Time_vod__c,
                        Product_vod__c, Product_vod__r.Name, Detail_Group_vod__c, Detail_Group_vod__r.Name FROM Call2_Key_Message_vod__r),
                    (SELECT Id, Call2_vod__c, Product_vod__c, Product_vod__r.Name, Detail_Group_vod__c, Detail_Group_vod__r.Name FROM Call2_Detail_vod__r)
                FROM Call2_vod__c
                WHERE Id IN: childCallIds];
            for(Call2_vod__c childCall : childCalls) {
                // can only add accounts as attendees through unique activity flow
                if (childCall.Account_vod__c != null) {
                    accountIdToCallMap.put(childCall.Account_vod__c, childCall);
                }
            }
            // add child calls for all non-UA calls
            if(isPersonAccount || !isUniqueActivity) {
                toProcess.addAll(childCalls);
            }
        }

        // query MCALs
        List<Multichannel_Activity_Line_vod__c> mcals = queryMCALs(mcaId, MCAL_FIELDS, 'DateTime_vod__c');

        // for unqiue activity
        if(isUniqueActivity) {
            if(mcals != null && !mcals.isEmpty()) {
                // update baseCall's Detailed_Products_vod__c
                List<String> originalProductNames = parseCallDetailProductsString(baseCall.Detailed_Products_vod__c);
                List<String> allProductNames = new List<String>();
                Set<String> allProductNamesSet = new Set<String>();
                for(Multichannel_Activity_Line_vod__c mcal : mcals) {
                    String mcalProdName = getProductName(mcal);
                    Integer found = originalProductNames.indexOf(mcalProdName);
                    if(found >= 0) {
                        originalProductNames.remove(found);
                    }
                    if(allProductNamesSet.add(mcalProdName)) {
                        allProductNames.add(mcalProdName);
                    }
                }
                baseCall.CLM_vod__c = true;

                List<String> detailProducts = new List<String>(originalProductNames);
                detailProducts.addAll(allProductNames);
                baseCall.Detailed_Products_vod__c = getCallDetailProductsString(detailProducts);
            }
            if(attendeeIds != null && !attendeeIds.isEmpty()) {
                String userTerrName = getUserTerritory(baseCallAccountId);
                List<Account> attendees = getAttendees(new Set<Id>(attendeeIds));
                for(Account attendee : attendees) {
                    Id attendeeId = attendee.Id;
                    Call2_vod__c call = accountIdToCallMap.get(attendeeId);
                    if(call == null) {
                        // create new child call record for the toProcess loop later
                        // get Child Account if available
                        Child_Account_vod__c childAccount = null;
                        if(viewedMediaAttendees != null) {
                            childAccount = viewedMediaAttendees.get(attendeeId);
                        }
                        // set detail products to blank (will be set later in the toProcess loop)
                        ReconcilingEntity entity = constructBaseEntityWithCall(mca, attendee, callRecordTypeId, userTerrName, childAccount, '', isUniqueActivity, false);
                        call = entity.call;
                        // set parent call lookup
                        call.Parent_Call_vod__c = callId;
                        call.Detail_Section_Attribute_vod__c = baseCall.Detail_Section_Attribute_vod__c;
                        accountIdToCallMap.put(attendeeId, call);
                    }
                    toProcess.add(call);
                }
            }
        }

        // for each call to process, create new CKM for each MCAL
        // while looping through the MCALs, check if there's a CD created for the product/ detail group combo
        Boolean populatedMcalProducts = false;
        List<String> mcalProductNames = new List<String>();
        for(Call2_vod__c callToProcess : toProcess) {
            Id callAccountId = callToProcess.Account_vod__c;
            Id callContactId = callToProcess.Contact_vod__c;
            Id callUserId = callToProcess.User_vod__c;

            String callDetailProducts = callToProcess.Detailed_Products_vod__c;
            List<String> callsAllProductNames = parseCallDetailProductsString(callDetailProducts);

            List<CallKeyMessageWrapper> callKeyMessageWrappers = new List<CallKeyMessageWrapper>();
            Map<ProductDetailGroupCombo, Call2_Detail_vod__c> originalPdgCdMap = new Map<ProductDetailGroupCombo, Call2_Detail_vod__c>();

            List<Call2_Key_Message_vod__c> ckms = new List<Call2_Key_Message_vod__c>();
            List<Call2_Detail_vod__c> cds = new List<Call2_Detail_vod__c>();

            if(callToProcess.Call2_Key_Message_vod__r != null) {
                List<CallKeyMessageWrapper> wrappers = getCallKeyMessageWrappers(callToProcess.Call2_Key_Message_vod__r);
                callKeyMessageWrappers.addAll(wrappers);

            }
            if(callToProcess.Call2_Detail_vod__r != null) {
                Map<ProductDetailGroupCombo, Call2_Detail_vod__c> callDetailProductDetailGroupComboMap = getCallDetailProductDetailGroupComboMap(callToProcess.Call2_Detail_vod__r);
                originalPdgCdMap.putAll(callDetailProductDetailGroupComboMap);
            }

            if(mcals != null && !mcals.isEmpty()) {
                for(Multichannel_Activity_Line_vod__c mcal : mcals) {
                    // creates new CKM for each MCAL
                    Account callAccount = !String.isBlank(callAccountId) ? new Account(Id = callAccountId) : null;
                    Contact callContact = !String.isBlank(callContactId) ? new Contact(Id = callContactId) : null;
                    User callUser = !String.isBlank(callUserId) ? new User(Id = callUserId) : null;

                    CallKeyMessageWrapper callKeyMessageWrapper = new CallKeyMessageWrapper(constructCallKeyMessage(callToProcess, callAccount, callContact, callUser, mcal));
                    callKeyMessageWrapper.pdgCombo = new ProductDetailGroupCombo(mcal);
                    callKeyMessageWrappers.add(callKeyMessageWrapper);
                }

                // since we're creating new CKMs, extract the product/ detail group from CKMs + reorder based on
                Set<ProductDetailGroupCombo> tmpComboSet = new Set<ProductDetailGroupCombo>();
                // sorted unqiue product/ detail group
                List<ProductDetailGroupCombo> uniqueProductDetailGroupCombo = new List<ProductDetailGroupCombo>();
                Integer displayOrder = 1;
                callKeyMessageWrappers.sort();
                for(CallKeyMessageWrapper callKeyMessageWrapper : callKeyMessageWrappers) {

                    Call2_Key_Message_vod__c ckm = callKeyMessageWrapper.ckm;

                    // reorder CKM's display order after they're sorted by start time
                    ckm.Display_Order_vod__c = displayOrder++;

                    ProductDetailGroupCombo pdgCombo = callKeyMessageWrapper.pdgCombo;
                    if(pdgCombo.isProductInfoAvailable() && tmpComboSet.add(pdgCombo)) {
                        uniqueProductDetailGroupCombo.add(pdgCombo);
                    }

                    ckms.add(ckm);
                }

                Integer detailPriority = 1;
                List<String> productNames = new List<String>();
                for(ProductDetailGroupCombo uniquePdgCombo : uniqueProductDetailGroupCombo) {
                    String productName = uniquePdgCombo.productName;
                    productNames.add(productName);
                    Integer found = callsAllProductNames.indexOf(productName);
                    if(found >= 0) {
                        callsAllProductNames.remove(found);
                    }
                    Call2_Detail_vod__c cd = originalPdgCdMap.get(uniquePdgCombo);
                    if(cd == null) {
                        // create new Call details
                        cd = constructCallDetail(callToProcess, uniquePdgCombo, detailPriority);
                    } else {
                        cd.Detail_Priority_vod__c = detailPriority;
                        cd.Type_vod__c = 'EDetail_vod';
                    }
                    detailPriority++;
                    cds.add(cd);
                }

                // make sure existing product names are not lost
                List<String> detailProductNames = new List<String>(callsAllProductNames);
                detailProductNames.addAll(productNames);
                callDetailProducts = getCallDetailProductsString(detailProductNames);

                String objectId;
                if (!String.isBlank(callAccountId)) {
                    objectId = callAccountId;
                } else if (!String.isBlank(callContactId)) {
                    objectId = callContactId;
                } else if (!String.isBlank(callUserId)) {
                    objectId = callUserId;
                }

                callKeyMessagesToUpsert.put(objectId, ckms);
                callDetailsToUpsert.put(objectId, cds);
            }

            callToProcess.CLM_vod__c = true;
            callToProcess.Detailed_Products_vod__c = callDetailProducts;
        }

        if(!addedBaseCall) {
            toProcess.add(baseCall);
        }

        // calculate if the anticipating DML row count is going to exceed apex limit
        Integer expectedDmlCount = calculateAnticipatingDmlRowCount(toProcess, callKeyMessagesToUpsert, callDetailsToUpsert);
        validateDmlCount(expectedDmlCount);

        mca.Call_vod__c = callId;
        mca.Saved_For_Later_vod__c = false;

        Boolean upsertSuccessful = upsertRecordsForAddToExistingCall(mca, toProcess, callKeyMessagesToUpsert, callDetailsToUpsert);
        return upsertSuccessful? callId : null;
    }

    private static List<CallKeyMessageWrapper> getCallKeyMessageWrappers(List<Call2_Key_Message_vod__c> callKeyMessages) {
        List<CallKeyMessageWrapper> wrappers = new List<callKeyMessageWrapper>();
        for(Call2_Key_Message_vod__c callKeyMessage : callKeyMessages) {
            CallKeyMessageWrapper wrapper = new CallKeyMessageWrapper(callKeyMessage);
            wrapper.pdgCombo = new ProductDetailGroupCombo(callKeyMessage);
            wrappers.add(wrapper);
        }
        return wrappers;
    }

    private static Map<ProductDetailGroupCombo, Call2_Detail_vod__c> getCallDetailProductDetailGroupComboMap(List<Call2_Detail_vod__c> callDetails) {
        Map<ProductDetailGroupCombo, Call2_Detail_vod__c> resultMap = new Map<ProductDetailGroupCombo, Call2_Detail_vod__c>();
        for(Call2_Detail_vod__c callDetail : callDetails) {
            ProductDetailGroupCombo combo = new ProductDetailGroupCombo(callDetail);
            if(combo.isProductInfoAvailable() && !resultMap.containsKey(combo)) {
                resultMap.put(combo, callDetail);
            }
        }
        return resultMap;
    }

    private static Integer calculateAnticipatingDmlRowCount(List<Call2_vod__c> toProcess,
                                                            Map<String, List<Call2_Key_Message_vod__c>> callKeyMessagesToUpsert,
                                                            Map<String, List<Call2_Detail_vod__c>> callDetailsToUpsert) {
        Integer count = toProcess.size() + 1; // + 1 for the MCA update
        for(List<Call2_Key_Message_vod__c> callKeyMessages : callKeyMessagesToUpsert.values()) {
            count += callKeyMessages.size();
        }
        for(List<Call2_Detail_vod__c> callDetails : callDetailsToUpsert.values()) {
            count += callDetails.size();
        }
        return count;
    }

    private static void validateDmlCount(Integer expectedDmlCount) {
        Integer remainingDmlCount = Limits.getLimitDmlRows();
        if(expectedDmlCount > remainingDmlCount) {
            throw new AuraHandledException('reconcile - the anticipated number of DML rows exceeds Apex limit');
        }
    }

    private static Boolean upsertRecordsForAddToExistingCall(Multichannel_Activity_vod__c mca, List<Call2_vod__c> toProcess,
                                                        Map<String, List<Call2_Key_Message_vod__c>> callKeyMessagesToUpsert,
                                                        Map<String, List<Call2_Detail_vod__c>> callDetailsToUpsert) {
        Savepoint sp = Database.setSavepoint();
        try {
            // upsert all Calls first
            if(allUpsertSuccess(Database.upsert(toProcess))) {
                List<Call2_Key_Message_vod__c> toCreateCallKeyMessages = new List<Call2_Key_Message_vod__c>();
                List<Call2_Detail_vod__c> toCreateCallDetails = new List<Call2_Detail_vod__c>();

                // since we might be creating new calls, go through CKM/ CD to stamp call lookup with id when needed
                for(Call2_vod__c upsertedCall : toProcess) {
                    Id callId = upsertedCall.Id;
                    Id objectId;
                    if (upsertedCall.Account_vod__c != null) {
                        objectId = upsertedCall.Account_vod__c;
                    } else if (upsertedCall.Contact_vod__c != null) {
                        objectId = upsertedCall.Contact_vod__c;
                    } else if (upsertedCall.User_vod__c != null) {
                        objectId = upsertedCall.User_vod__c;
                    }

                    // stamp call lookup on Call Key Messages
                    List<Call2_Key_Message_vod__c> callKeyMessages = callKeyMessagesToUpsert.get(objectId);
                    if(callKeyMessages != null) {
                        for(Call2_Key_Message_vod__c callKeyMessage : callKeyMessages) {
                            if(callKeyMessage.Call2_vod__c == null) {
                                callKeyMessage.Call2_vod__c = callId;
                            }
                        }
                        toCreateCallKeyMessages.addAll(callKeyMessages);
                    }

                    // stamp call lookup on Call Details
                    List<Call2_Detail_vod__c> callDetails = callDetailsToUpsert.get(objectId);
                    if(callDetails != null) {
                        for(Call2_Detail_vod__c callDetail : callDetails) {
                            if(callDetail.Call2_vod__c == null) {
                                callDetail.Call2_vod__c = callId;
                            }
                        }
                        toCreateCallDetails.addAll(callDetails);
                    }

                }

                // upsert the rest of the records (CKM/ CD/ MCA) separately to avoid getting System.TypeException
                // erorr msg: Cannot have more than 10 chunks in a single operation. Please rearrange the data to reduce chunking.
                if(allUpsertSuccess(Database.upsert(toCreateCallKeyMessages)) &&
                    allUpsertSuccess(Database.upsert(toCreateCallDetails)) &&
                    successfulUpsert(Database.upsert(mca))) {
                    // when all upsert are successful, return success flag
                    return true;
                }
            }
        } catch(DmlException e) {
            System.debug(e);
        }
        Database.rollback(sp);
        return false;
    }

    private static Multichannel_Activity_vod__c fetchAndValidateMca(Id mcaId) {
        // validate mca is available and is still an unassigned presentation
        Multichannel_Activity_vod__c mca = [SELECT Id, Saved_For_Later_vod__c, Call_vod__c, Start_DateTime_vod__c, OwnerId FROM Multichannel_Activity_vod__c WHERE Id =: mcaId];
        if(mca == null) {
            throw new AuraHandledException('MCA not found');
        } else if (!(mca.Saved_For_Later_vod__c == true && mca.Call_vod__c == null)) {
            throw new AuraHandledException('MCA no longer in unassigned status');
        }
        return mca;
    }

    private static List<String> parseCallDetailProductsString(String callDetailProducts) {
        return (callDetailProducts != null? callDetailProducts : '').split('  ');
    }

    private static String getCallDetailProductsString(List<String> productNames) {
        return String.join(productNames, '  ');
    }

    @TestVisible
    private static Integer calculateAnticipatingDmlRowCount(Integer mcalCount, Integer attendeeCount, Boolean createRelatedRecordForParent, Integer uniqueMcalProductComboIdSize) {
        // 1 account call + 1 mca update
        Integer expectedDmlCount = 2;
        // default multiplier to 1 when there's no attendees
        Integer attendeeMultiplier = 1;
        if(attendeeCount > 0) {
            // child call per attendee
            expectedDmlCount += attendeeCount;
            // when there's attendee(s), use attendee count as multiplier
            attendeeMultiplier = attendeeCount;
            if(createRelatedRecordForParent) {
                // for location child call, we're also creating CKM/ CD for the parent call
                attendeeMultiplier++;
            }
        }
        if(mcalCount >= 0) {
            // 1 call key message per attendeeMultiplier per MCA line
            expectedDmlCount += (mcalCount * attendeeMultiplier);
            if(uniqueMcalProductComboIdSize >= 0) {
                // 1 call detail per attendeeMultiplier per MCAL product/ detail group combo
                expectedDmlCount += (uniqueMcalProductComboIdSize * attendeeMultiplier);
            }
        }
        return expectedDmlCount;
    }

    // FLS validations

    @AuraEnabled(cacheable=true)
    public static Boolean hasAllRequiredFLSToConvertACall() {
        Boolean isChildAccountEnabled = getVeevaCustomSettings().Enable_Child_Account_vod__c == null ? false : getVeevaCustomSettings().Enable_Child_Account_vod__c;        
        return
            canUpdateObjectWithFields(Multichannel_Activity_vod__c.getSObjectType().getDescribe(), new String[]{
                'Call_vod__c', 'Saved_For_Later_vod__c'}) &&
            canCreateObjectWithFields(Call2_vod__c.getSObjectType().getDescribe(), new String[]{
                'Account_vod__c', 'CLM_vod__c', 'Detailed_Products_vod__c',
                'Parent_Call_vod__c', 'Status_vod__c', 'Territory_vod__c'}) &&
            // user can have fls to call date and/or datetime
            (canCreateFields(Call2_vod__c.getSObjectType().getDescribe(), new String[]{'Call_Datetime_vod__c'}) ||
             canCreateFields(Call2_vod__c.getSObjectType().getDescribe(), new String[]{'Call_Date_vod__c'})) &&
            canCreateObjectWithFields(Call2_Key_Message_vod__c.getSObjectType().getDescribe(), new String[]{
                'Account_vod__c', 'Call2_vod__c', 'CLM_ID_vod__c', 'Clm_Presentation_Name_vod__c', 'Detail_Group_vod__c',
                'Display_Order_vod__c', 'Key_Message_Name_vod__c', 'Presentation_ID_vod__c'}) &&
            canCreateObjectWithFields(Call2_Detail_vod__c.getSObjectType().getDescribe(), new String[]{
                'Call2_vod__c', 'Detail_Group_vod__c', 'Detail_Priority_vod__c', 'Product_vod__c', 'Type_vod__c'}) &&
            // check for additional fls if org is child account enabled
            (!isChildAccountEnabled || 
            (canCreateFields(Call2_vod__c.getSObjectType().getDescribe(), new String[]{
                'Child_Account_vod__c', 'Child_Account_Id_vod__c', 'Location_Name_vod__c', 'Location_Id_vod__c',
                'Location_Text_vod__c'}) &&
             canAccessObjectWithFields(Child_Account_vod__c.getSObjectType().getDescribe(), new String[]{
                'Child_Account_vod__c', 'Parent_Child_Name_vod__c'})));
    }

    public static Boolean canUpdateObjectWithFields (DescribeSobjectResult describe, String[] requiredEditFields) {
        return describe != null && describe.isUpdateable() && canUpdateFields(describe, requiredEditFields);
    }

    private static Boolean canCreateObjectWithFields (DescribeSobjectResult describe, String[] requiredEditFields) {
        return describe != null && describe.isCreateable() && canCreateFields(describe, requiredEditFields);
    }

    public static Boolean canAccessObjectWithFields (DescribeSobjectResult describe, String[] requiredEditFields) {
        return describe != null && describe.isAccessible() && canAccessFields(describe, requiredEditFields);
    }

    private static Boolean canUpdateFields(DescribeSobjectResult describe, String[] requiredEditFields) {
        Map<String, Schema.SObjectField> fieldMap = describe.fields.getMap();
        for(String requiredEditField : requiredEditFields) {
            Schema.SObjectField sfField = fieldMap.get(requiredEditField);
            if(sfField == null || !sfField.getDescribe().isUpdateable()) {
                return false;
            }
        }
        return true;
    }

    private static Boolean canCreateFields(DescribeSobjectResult describe, String[] requiredEditFields) {
        Map<String, Schema.SObjectField> fieldMap = describe.fields.getMap();
        for(String requiredEditField : requiredEditFields) {
            Schema.SObjectField sfField = fieldMap.get(requiredEditField);
            if(sfField == null || !sfField.getDescribe().isCreateable()) {
                return false;
            }
        }
        return true;
    }

    private static Boolean canAccessFields(DescribeSobjectResult describe, String[] requiredEditFields) {
        Map<String, Schema.SObjectField> fieldMap = describe.fields.getMap();
        for(String requiredEditField : requiredEditFields) {
            Schema.SObjectField sfField = fieldMap.get(requiredEditField);
            if(sfField == null || !sfField.getDescribe().isAccessible()) {
                return false;
            }
        }
        return true;
    }

    // validate call record type

    private static Boolean isRecordTypeValid(String accountRecordTypeName, Id callRecordTypeId) {
        List<Schema.RecordTypeInfo> availableCallRecordTypes = S4LRecordTypeSelectorController.getAllAvailableCallRecordTypeForAccount(accountRecordTypeName);
        for(Schema.RecordTypeInfo recordType : availableCallRecordTypes) {
            if(recordType.getRecordTypeId() == callRecordTypeId) {
                return true;
            }
        }
        return false;
    }

    // validate location id

    private static Boolean isLocationValid (Id accountId, Id locationId) {
        List<S4LChildAccountService.Location> locations = S4LChildAccountService.getChildLocations(accountId);
        if(locations != null && !locations.isEmpty()) {
            for(S4LChildAccountService.Location location : locations) {
                Child_Account_vod__c parent = location.parent;
                if(parent.Parent_Account_vod__c == locationId) {
                    return true;
                }
            }
        }
        return false;
    }

    @TestVisible
    private static Boolean isParent(List<Child_Account_vod__c> parents, Id toCheckId) {
        if(parents != null && !parents.isEmpty()) {
            for(Child_Account_vod__c parent : parents) {
                if(parent.Parent_Account_vod__c == toCheckId) {
                    return true;
                }
            }
        }
        return false;
    }

    // query MCAL product name

    private static String getProductName(SObject sobj) {
        String productName = (String) get(sobj, 'Product_vod__r', 'Name');
        String detailGroupId = (String) get(sobj, 'Detail_Group_vod__c');
        String detailGroupName = (String) get(sobj, 'Detail_Group_vod__r', 'Name');
        if(detailGroupId != null) {
            productName += '(' + detailGroupName + ')';
        }
        return productName;
    }

    private static Account getAccount(Id accountId) {
        return [SELECT Id, Name, IsPersonAccount, RecordType.DeveloperName FROM Account WHERE Id = :accountId];
    }

    private static List<Account> getAttendees(Set<Id> attendeeIds) {
        return [SELECT Id, Name, IsPersonAccount, (SELECT Parent_Account_vod__c FROM Child_Account_vod__r) FROM Account WHERE Id IN: attendeeIds];
    }

    @AuraEnabled
    public static String getUserTerritory(Id accountId) {
        List<ObjectTerritory2Association> result =
            [SELECT Id, Territory2.Name
                FROM ObjectTerritory2Association
                WHERE ObjectId = :accountId AND
                    Territory2Id IN (SELECT Territory2Id FROM UserTerritory2Association WHERE UserId = :UserInfo.getUserId())];
        if(result != null && !result.isEmpty()) {
            ObjectTerritory2Association ot2a = result.get(0);
            return ot2a.Territory2.Name;
        }
        return null;
    }

    // object constructions

    private static ReconcilingEntity constructBaseEntityWithCall(Multichannel_Activity_vod__c mca, Account account, Id callRecordTypeId, String userTerrName,
                                                                Child_Account_vod__c locationChildAccount, String callDetailProducts, Boolean isUniqueActivity, Boolean isChildLocationAccount) {
        ReconcilingEntity entity = new ReconcilingEntity(account);
        Call2_vod__c call = new Call2_vod__c();
        call.Account_vod__c = account.Id;
        call.CLM_vod__c = true;
        Boolean isPersonAccount = (Boolean) get(account, 'IsPersonAccount');
        String attendeeType = isPersonAccount != null && isPersonAccount ? 'Person_Account_vod' : 'Group_Account_vod';
        String callType;
        if (!String.isBlank(callDetailProducts)){
            callType = isPersonAccount != null && isPersonAccount && locationChildAccount == null && !isUniqueActivity ? 'Detail Only' : 'Group Detail';
        } else {
            callType = 'Call Only';
        }
        call.Attendee_Type_vod__c = attendeeType;
        call.Call_Type_vod__c = callType;
        call.Detailed_Products_vod__c = callDetailProducts;
        Datetime mcaStartDatetime = (Datetime) get(mca, 'Start_DateTime_vod__c');
        if(mcaStartDatetime != null) {
            call.Call_Datetime_vod__c = mcaStartDatetime;
            call.Call_Date_vod__c = mcaStartDatetime.date();
        }
        call.RecordTypeId = callRecordTypeId;
        call.Status_vod__c = 'Saved_vod';
        call.Territory_vod__c = userTerrName;
        if(locationChildAccount != null) {
            if (!isChildLocationAccount) {
                Id childAccountId = locationChildAccount.Id;
                call.Child_Account_vod__c = childAccountId;
                call.Child_Account_Id_vod__c = childAccountId;
            }
            Id locationId = locationChildAccount.Parent_Account_vod__c;
            call.Location_Name_vod__c = locationId;
            call.Location_Id_vod__c = locationId;
            call.Location_Text_vod__c = locationChildAccount.Parent_Name_vod__c;
        }
                                                                    
        call.OwnerId = mca.OwnerId;
        entity.call = call;
        call.zvod_Unique_Group_Activities_vod__c = isUniqueActivity;
        return entity;
    }

    public static Object get(SObject sobj, String field) {
        if(sobj.isSet(field)) {
            return sobj.get(field);
        } else {
            return null;
        }
    }

    public static Object get(SObject sobj, String refField, String field) {
        SObject refObject = (SObject) sobj.getSObject(refField);
        if(refObject != null) {
            return get(refObject, field);
        }
        return null;
    }

    private static Call2_Key_Message_vod__c constructCallKeyMessage(Call2_vod__c call, Account account, Contact contact, User user, Multichannel_Activity_Line_vod__c mcal) {
        Call2_Key_Message_vod__c ckm = new Call2_Key_Message_vod__c();
        ckm.Call2_vod__c = call.Id;
        String attendeeType;
        String referenceId;
        if (account != null) {
            ckm.Account_vod__c = account.Id;
            referenceId = account.Id;
            Boolean isPersonAccount = (Boolean) get(account, 'IsPersonAccount');
            attendeeType = isPersonAccount != null && isPersonAccount ? 'Person_Account_vod' : 'Group_Account_vod';
        } else if (contact != null) {
            ckm.Contact_vod__c = contact.Id;
            referenceId = contact.Id;
            attendeeType = 'Contact_vod';
        } else if (user != null) {
            ckm.User_vod__c = user.Id;
            referenceId = user.Id;
            attendeeType = 'User_vod';
        }
        ckm.Attendee_Type_vod__c = attendeeType;
        ckm.Entity_Reference_Id_vod__c = referenceId;
        ckm.CLM_ID_vod__c = (String) get(mcal, 'Key_Message_vod__r', 'Media_File_Name_vod__c');
        Datetime mcalDatetime = (Datetime) get(mcal, 'DateTime_vod__c');
        if(mcalDatetime != null) {
            ckm.Call_Date_vod__c = mcalDatetime.date();
            ckm.Start_Time_vod__c = mcalDatetime;
        }
        ckm.Clm_Presentation_vod__c = (String) get(mcal, 'CLM_Presentation_vod__c');
        ckm.Clm_Presentation_Name_vod__c = (String) get(mcal, 'CLM_Presentation_vod__r', 'Name');
        ckm.Clm_Presentation_Version_vod__c = (String) get(mcal, 'CLM_Presentation_vod__r', 'Version_vod__c');
        ckm.Detail_Group_vod__c = (String) get(mcal, 'Detail_Group_vod__c');
        ckm.Display_Order_vod__c = (Decimal) get(mcal, 'View_Order_vod__c');
        ckm.Duration_vod__c = (Decimal) get(mcal, 'Duration_vod__c');
        ckm.Entity_Reference_KM_Id_vod__c = (String) get(mcal, 'Entity_Reference_KM_ID_vod__c');
        ckm.Key_Message_vod__c = (String) get(mcal, 'Key_Message_vod__c');
        ckm.Key_Message_Name_vod__c = (String) get(mcal, 'Key_Message_vod__r', 'Name');
        ckm.Presentation_ID_vod__c = (String) get(mcal, 'CLM_Presentation_vod__c');
        ckm.Product_vod__c = (String) get(mcal, 'Product_vod__c');
        ckm.Reaction_vod__c = (String) get(mcal, 'Reaction_vod__c');
        ckm.Segment_vod__c = (String) get(mcal, 'Segment_vod__c');
        ckm.Share_Channel_vod__c = (String) get(mcal, 'Share_Channel_vod__c');
        ckm.Slide_Version_vod__c = (String) get(mcal, 'Key_Message_Version_vod__c');
        return ckm;
    }

    private static Call2_Detail_vod__c constructCallDetail(Call2_vod__c call, ProductDetailGroupCombo productDetailGroupCombo, Integer viewOrder) {
        Call2_Detail_vod__c cd = new Call2_Detail_vod__c();
        cd.Call2_vod__c = call.Id;
        cd.Detail_Group_vod__c = productDetailGroupCombo.detailGroupId;
        cd.Detail_Priority_vod__c = viewOrder;
        cd.Product_vod__c = productDetailGroupCombo.productId;
        cd.Type_vod__c = 'EDetail_vod';
        return cd;
    }

    // upsert

    private static Id upsertRecords(ReconcilingEntity accountEntity, List<ReconcilingEntity> attendeeEntities, Boolean createRelatedRecordForParent, Multichannel_Activity_vod__c mca, List<Multichannel_Activity_Line_vod__c> mcals, List<ProductDetailGroupCombo> mcalProductDetailGroupCombo) {
        Savepoint sp = Database.setSavepoint();
        try {
            // insert base account call
            Call2_vod__c accountCall = accountEntity.call;
            Database.SaveResult callResult = Database.insert(accountCall, true);
            if(success(callResult)) {
                Id createdCallId = callResult.getId();

                List<Call2_Key_Message_vod__c> ckms = new List<Call2_Key_Message_vod__c>();
                List<Call2_Detail_vod__c> cds = new List<Call2_Detail_vod__c>();

                List<ReconcilingEntity> entitiesToProcess = new List<ReconcilingEntity>();
                if(attendeeEntities != null && !attendeeEntities.isEmpty()) {
                    if(createRelatedRecordForParent) {
                        // in case of location child call, we also want the CKM/ CD records to be created for the parent account as well
                        entitiesToProcess.add(accountEntity);
                    }
                    // stamp parent call lookup and create attendee calls
                    List<Call2_vod__c> attendeeCalls = new List<Call2_vod__c>();
                    for(ReconcilingEntity attendeeEntity : attendeeEntities) {
                        Call2_vod__c attendeeCall = attendeeEntity.call;
                        attendeeCall.Parent_Call_vod__c = createdCallId;
                        attendeeCalls.add(attendeeCall);
                    }
                    // we dont need to worry about the attendee call # exceed DML bc MAX_ATTENDEE_COUNT limits how many attendees can be added
                    List<Database.SaveResult> attendeeCallResults = Database.insert(attendeeCalls, true);
                    if(!allSuccess(attendeeCallResults)) {
                        throw new AuraException('failed to save attendee calls');
                    }
                    // build CKM/ CD for attendees
                    entitiesToProcess.addAll(attendeeEntities);
                } else {
                    // build CKM/ CD for the account
                    entitiesToProcess.add(accountEntity);
                }

                // construct and save CKM and CD
                if(mcals != null && !mcals.isEmpty()) {
                    for(ReconcilingEntity entity : entitiesToProcess) {
                        Call2_vod__c call = entity.call;
                        for(Multichannel_Activity_Line_vod__c mcal : mcals) {
                            ckms.add(constructCallKeyMessage(call, entity.account, null, null, mcal));
                        }
                        for(Integer i = 0; i < mcalProductDetailGroupCombo.size(); i++){
                            ProductDetailGroupCombo productDetailGroupCombo = mcalProductDetailGroupCombo.get(i);
                            // base-one
                            Integer viewOrder = i + 1;
                            cds.add(constructCallDetail(call, productDetailGroupCombo, viewOrder));
                        }
                    }
                }

                List<Database.SaveResult> ckmResults = Database.insert(ckms, true);
                if(allSuccess(ckmResults)) {
                    List<Database.SaveResult> cdResults = Database.insert(cds, true);
                    if(allSuccess(cdResults)) {
                        mca.Call_vod__c = callResult.getId();
                        mca.Saved_For_Later_vod__c = false;
                        Database.SaveResult mcaResults = Database.update(mca, true);
                        if(success(mcaResults)) {
                            return createdCallId;
                        }
                    }
                }
            }
        } catch(DmlException e) {
            System.debug(e);
        }
        Database.rollback(sp);
        return null;
    }

    private static Boolean success(Database.SaveResult saveResult) {
        return saveResult != null && saveResult.isSuccess() && saveResult.getId() != null;
    }

    private static Boolean allSuccess(List<Database.SaveResult> saveResults) {
        if(saveResults != null) {
            for(Database.SaveResult saveResult : saveResults) {
                if(!success(saveResult)) {
                    return false;
                }
            }
        }
        return true;
    }

    private static Boolean allUpsertSuccess(List<Database.UpsertResult> upsertResults) {
        if(upsertResults != null) {
            for(Database.UpsertResult upsertResult : upsertResults) {
                if(!successfulUpsert(upsertResult)) {
                    return false;
                }
            }
        }
        return true;
    }

    private static Boolean successfulUpsert(Database.UpsertResult upsertResult) {
        return upsertResult != null && upsertResult.isSuccess() && upsertResult.getId() != null;
    }    
}