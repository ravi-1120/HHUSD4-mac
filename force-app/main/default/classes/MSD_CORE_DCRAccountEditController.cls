/*
 * MSD_CORE_DCRAccountEditController
 * Created by: David Andrew Helmer
 * Created Date: July 10th, 2014
 * Last Modified Date: July 23rd, 2014
 * Description: This is the controller for the MSD_CORE_DCR_Account_Edit page
 *              responsible for submitting Edit Account DCRs when Customer Master
 *              managed HCPs and HBPs are edited as well as allowing direct edits
 *              for HCPs and HBPs who have not been validated due to lack 
 *              of information.
 * KRB REL 10.0 7/12/2017 - added a bypass field for DCR Creation. We did not want to create a DCR if this was the only field touched.
 */
public with sharing class MSD_CORE_DCRAccountEditController {
    private final Id accountId;
    private final Boolean isNeedMoreInfoAccount;
    private final Boolean isPerson;
    private sObject beforeAccount;

    private final ApexPages.StandardController theController;
    private final Service_Cloud_Settings_MVN__c settings;

    public Account dcrAccount { get; set; }

    public List<String> sectionKeys { get; set; }
    public Map<String, String> sectionMap { get; set; }
    public Map<String, List<MSD_CORE_NAW_Field_Types__c>> dcrFieldsSectionMap { get; set; }

    public Boolean isATab { get; set; }
    public Boolean didSaveSucceed { get; set; }
    public Boolean hadInitializationError { get; set; }

    public List<MSD_CORE_NAW_Field_Types__c> dcrFieldList;

    /* Initialization */
    public MSD_CORE_DCRAccountEditController(ApexPages.StandardController accountController) {
        settings = Service_Cloud_Settings_MVN__c.getInstance();
        theController = accountController;

        isATab = true;
        didSaveSucceed = false;
        hadInitializationError = false;

        accountId = theController.getRecord().Id;
        isNeedMoreInfoAccount = ((Account)theController.getRecord()).Status_MRK__c == settings.MSD_CORE_Account_Status_Need_More_Info__c;
        Id recordTypeId = ((Account)theController.getRecord()).RecordTypeId;
        isPerson = [SELECT Id, IsPersonType FROM RecordType WHERE Id=:recordTypeId].IsPersonType;

        dcrFieldList = getDCRFieldList(accountId, recordTypeId);

        if(dcrFieldList != null){
            String dcrAccountQueryString = getDCRAccountQueryString(dcrFieldList);

            try {
                dcrAccount = Database.query(dcrAccountQueryString);
            } catch (Exception ex){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.MSD_CORE_FATAL_Querying_Account + ': \n' + ex.getMessage()));
                hadInitializationError = true;
                return;
            }
            beforeAccount = dcrAccount.clone(true);

            refreshSectionMap();

            mapFieldsToSections(dcrFieldList);

        }
    }

    private List<MSD_CORE_NAW_Field_Types__c> getDCRFieldList(Id accountId, Id recordTypeId){        
        String country = [SELECT MSD_CORE_Country_Code__c 
                            FROM User 
                           WHERE Id = :userinfo.getUserId()].MSD_CORE_Country_Code__c; 
        
        List<MSD_CORE_NAW_Field_Types__c> dcrFieldList = MSD_CORE_DCRUtility.fieldsFor('Account', country, recordTypeId);

        if(isNeedMoreInfoAccount){
            Set<String> requiredFields = new Set<String>(
                UtilitiesMVN.splitCommaSeparatedString(settings.MSD_CORE_DCR_More_Info_Required_Fields__c));
            for(MSD_CORE_NAW_Field_Types__c dcrField : dcrFieldList){
                dcrField.Required__c = requiredFields.contains(dcrField.Field_API_Name__c);                
                dcrField.DCR__c = false;
                dcrField.Editable__c = true;
            }
        }

        if(dcrFieldList == null || dcrFieldList.size() == 0){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.MSD_CORE_FATAL_No_Fields_For_Record_Type + ' ' + recordTypeId));
            return null;
        }

        return dcrFieldList;
    }

    private String getDCRAccountQueryString(List<MSD_CORE_NAW_Field_Types__c> dcrFieldList){
        if(dcrFieldList == null){
            System.debug(LoggingLevel.ERROR, 'Require a dcrFieldList to getDCRAccountQueryString');
            return null;
        }

        Set<String> fieldsToQuery = new Set<String>();

        for(MSD_CORE_NAW_Field_Types__c dcrField : dcrFieldList){
            fieldsToQuery.add(dcrField.Field_API_Name__c);
        }

        String dcrAccountQueryString = 'SELECT ' + String.join(new List<String>(fieldsToQuery),', ') +
                                        ' FROM Account WHERE Id=:accountId LIMIT 1';

        return dcrAccountQueryString;
    }

    private void refreshSectionMap(){
        sectionMap = new Map<String, String>();
        sectionKeys = new List<String>();

        Schema.DescribeFieldResult fieldResult = MSD_CORE_NAW_Field_Types__c.Page_Section__c.getDescribe();
        List<Schema.PicklistEntry> sections = fieldResult.getPicklistValues();

        Set<String> pageSectionSet = new Set<String>();
        for(MSD_CORE_NAW_Field_Types__c nawFieldType : dcrFieldList){
            pageSectionSet.add(nawFieldType.Page_Section__c);    
        }

        for(Schema.PicklistEntry section : sections){
            String sectionKey = section.getValue();
            String sectionLabel = section.getLabel();

            if(pageSectionSet.contains(sectionKey)){
                sectionKeys.add(sectionKey);
                sectionMap.put(sectionKey, sectionLabel);
            }
        }
    }

    private void mapFieldsToSections(List<MSD_CORE_NAW_Field_Types__c> dcrFieldList){
        dcrFieldsSectionMap = new Map<String, List<MSD_CORE_NAW_Field_Types__c>>();

        Map<String, Integer> sectionIsLastLeft = new Map<String, Integer>();  
        Map<String, Integer> sectionLastLeftDisplayOrder = new Map<String, Integer>();
        Map<String, Integer> sectionLastRightDisplayOrder = new Map<String, Integer>();
        List<FieldWrapper> orderedDCRFieldList = new List<FieldWrapper>();
        for(MSD_CORE_NAW_Field_Types__c dcrField : dcrFieldList){
            if(dcrField.Display_Order__c != null && !dcrField.Edit_Page_Hidden__c){
                orderedDCRFieldList.add(new FieldWrapper(dcrField));
                if(!sectionIsLastLeft.containsKey(dcrField.Page_Section__c)){
                    sectionIsLastLeft.put(dcrField.Page_Section__c, -1);
                    sectionLastLeftDisplayOrder.put(dcrField.Page_Section__c, -1);
                    sectionLastRightDisplayOrder.put(dcrField.Page_Section__c, -1);
                }
            }
        }

        orderedDCRFieldList.sort();

        // add in spacers for "gaps" in the display order (i.e. 101 -> 103 === 1 spacer at 102)
        List<FieldWrapper> spacersToAdd = new List<FieldWrapper>();
        for(FieldWrapper wrappedField : orderedDCRFieldList){
            MSD_CORE_NAW_Field_Types__c dcrField = wrappedField.field;

            Boolean isLeft = ((Integer)(dcrField.Display_Order__c / 100)) == 1;
            Map<String, Integer> sectionLastDisplayOrder = (isLeft ? sectionLastLeftDisplayOrder : sectionLastRightDisplayOrder);
            Integer lastDisplayOrder = sectionLastDisplayOrder.get(dcrField.Page_Section__c);
            if(lastDisplayOrder != -1){
                while (dcrField.Display_Order__c > lastDisplayOrder + 1){
                    lastDisplayOrder++;
                    spacersToAdd.add(new FieldWrapper(
                        new MSD_CORE_NAW_Field_Types__c(Page_Section__c = dcrField.Page_Section__c,
                            Display_Order__c = lastDisplayOrder)));
                }
            } 
            sectionLastDisplayOrder.put(dcrField.Page_Section__c, (Integer)dcrField.Display_Order__c);
        }
        orderedDCRFieldList.addAll(spacersToAdd);

        orderedDCRFieldList.sort();

        for(FieldWrapper wrappedField : orderedDCRFieldList){
            MSD_CORE_NAW_Field_Types__c dcrField = wrappedField.field;
            if(!sectionMap.containsKey(dcrField.Page_Section__c)){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 
                    dcrField.Field_API_Name__c + ' '+ Label.MSD_CORE_FATAL_Has_Invalid_Section + ' (' + 
                    dcrField.Page_Section__c + ')'));
            }

            if(!dcrFieldsSectionMap.containsKey(dcrField.Page_Section__c)){
                dcrFieldsSectionMap.put(dcrField.Page_Section__c,
                    new List<MSD_CORE_NAW_Field_Types__c>());
            }

            // add spacers for when there are more fields in one column than the other
            Boolean isLeft = ((Integer)(dcrField.Display_Order__c / 100)) == 1;
            Integer isLastLeft = sectionIsLastLeft.get(dcrField.Page_Section__c);
            if((isLastLeft == -1 && !isLeft)
                || (isLastLeft != -1 && (isLastLeft == 1) == isLeft)) {
                dcrFieldsSectionMap.get(dcrField.Page_Section__c).add(
                        new MSD_CORE_NAW_Field_Types__c());
            }
            sectionIsLastLeft.put(dcrField.Page_Section__c, (isLeft ? 1 : 0));

            // actually add the field
            dcrFieldsSectionMap.get(dcrField.Page_Section__c).add(wrappedField.field);
        }

        for(String sectionKey : sectionKeys){
            if(!dcrFieldsSectionMap.containsKey(sectionKey)){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 
                    Label.MSD_CORE_FATAL_Missing_Fields_For_Section + ' ' + sectionKey));
            }
        }
    }

    private class FieldWrapper implements Comparable {
        public final MSD_CORE_NAW_Field_Types__c field;
        public final Decimal orderValue;

        public FieldWrapper(MSD_CORE_NAW_Field_Types__c initField){
            field = initField;

            if(initField.Display_Order__c >= 200){
                orderValue = ((initField.Display_Order__c - 200) * 2) + 1;
            } else if(initField.Display_Order__c >= 100) {
                orderValue = (initField.Display_Order__c - 100) * 2;
            } else {
                orderValue = initField.Display_Order__c;
            }
        }

        public Integer compareTo(Object compareTo) {
            FieldWrapper compareToField = (FieldWrapper)compareTo;
            Integer returnValue = 0;

            if(field.Page_Section__c == compareToField.field.Page_Section__c){
                if (orderValue > compareToField.orderValue) {
                    returnValue = 1;
                } else if (orderValue < compareToField.orderValue) {
                    returnValue = -1;
                }
            } else {
                if(field.Page_Section__c > compareToField.field.Page_Section__c){
                    returnValue = 1;
                } else if(field.Page_Section__c > compareToField.field.Page_Section__c){
                    returnValue = -1;
                }
            }
             
            return returnValue;            
        }

    }
    
    /* Actions */
    public PageReference saveDCR(){
        Account rollbackAccount = dcrAccount.clone(true,true,false,false);

        //Creation
        SavePoint sp = Database.setSavePoint();

        try {
            Map<String, String> dcrMap = new Map<String, String>();
            Set<String> editableFields = new Set<String>();

            for(String sectionKey : dcrFieldsSectionMap.keySet()){
                for(MSD_CORE_NAW_Field_Types__c field : dcrFieldsSectionMap.get(sectionKey)){
                    String fieldName = field.Field_API_Name__c;                
                   
                    //KB Out Rel 10.0
                    //if(fieldName != null && beforeAccount.get(fieldName) != dcrAccount.get(fieldName)){
                    //KB In Rel 10.0    
                    if(fieldName != null && beforeAccount.get(fieldName) != dcrAccount.get(fieldName) && fieldName != 'MSD_CORE_Submit_DCR__c'){    
                        if(field.DCR__c){
                            dcrMap.put(fieldName, (String)dcrAccount.get(fieldName));
                        }
                        if(field.Editable__c){
                            editableFields.add(field.Field_API_Name__c);
                        }
                    }
                }
            }

            updateEditableFields(editableFields);
            if(dcrMap.size() > 0){
                MSD_CORE_DCRUtility.submitUpdatedAccount((Account)beforeAccount, dcrMap);
            } else if(isNeedMoreInfoAccount){
                String country = [SELECT MSD_CORE_Country_Code__c FROM User WHERE Id =: userinfo.getUserId()].MSD_CORE_Country_Code__c; 
                Set<String> addressSelectFields = new Set<String>();
                List<MSD_CORE_NAW_Field_Types__c> addressFields =  MSD_CORE_DCRUtility.fieldsFor('Address_vod__c', country, null);
                for(MSD_CORE_NAW_Field_Types__c addressField : addressFields){
                    addressSelectFields.add(addressField.Field_API_Name__c);
                }

                String addressQuery = 'SELECT '  + String.join(new List<String>(addressSelectFields), ',') + ' '
                                    + 'FROM Address_vod__c '
                                    + 'WHERE Account_vod__c = :accountId '
                                    + 'ORDER BY Primary_vod__c DESC, CreatedDate DESC';
                List<Address_vod__c> addresses = Database.query(addressQuery);
                if(addresses != null && addresses.size() > 0){
                    Address_vod__c address = addresses.get(0);
                    MSD_CORE_DCRUtility.checkAndSubmitNewRecordsToDCR((Account)dcrAccount, address);
                }
            }
        } catch(Exception ex){
            dcrAccount = rollbackAccount;

            ApexPages.addMessages(ex);
            Database.rollback(sp);

            return null;
        }
        return goBackToDetail();
    }

    private void updateEditableFields(Set<String> editableFields){
        if(editableFields == null || editableFields.size() == 0){
            return;
        }

        Map<String, String> fieldsToStamp = (isPerson ? MSD_CORE_DCRUtility.PersonFieldsToStamp
                                                      : MSD_CORE_DCRUtility.BusinessFieldsToStamp).clone();
        Map<String, String> editableFieldsToStamp = new Map<String,String>();
        for(String editableField : editableFields){
            if(fieldsToStamp.containsKey(editableField)){
                editableFieldsToStamp.put(editableField, fieldsToStamp.get(editableField));
            }
        }
        MSD_CORE_DCRUtility.stampObject(dcrAccount, editableFieldsToStamp);

        editableFields.addAll(editableFieldsToStamp.values());

        String accountQuery = 'SELECT ' + String.join(new List<String>(editableFields),',') + ' FROM Account WHERE Id = :accountId';
        Account accountToUpdate = (Account)(Database.query(accountQuery)[0]);

        for(String fieldName : editableFields){
            accountToUpdate.put(fieldName, dcrAccount.get(fieldName));
        }

        update accountToUpdate;
    }

    public PageReference goBackToDetail(){
        if(isATab){
            didSaveSucceed = true;
            return null;
        } else {
            return theController.view();
        }
    }
}