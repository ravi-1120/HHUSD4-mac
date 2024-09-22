trigger MRK_Medical_Inquiry_AfterInsert on Medical_Inquiry_vod__c (after insert) {

    /**
     * BMP 2013-10-25
     * 
     * In support of the Veeva to GPIR integration, this populates the Address_Integration_MRK__c field with a delimited
     * list of address field components for the associated Account's primary address or if that doesn't exist, then
     * the first address found.
     *
     **/
    
    List<Medical_Inquiry_vod__c> updateList = new List<Medical_Inquiry_vod__c>();
    Map<Id,String> medicalInquiryIdToIntegrationAddressMap = new Map<Id,String>();
    Map<Id,String> medicalInquiryIdToStatusMap = new Map<Id,String>();
    //CR18932 : Including "Relevant Approved Training" and "Self-knowledge"
    List<String> deliveryMethodTypes = new List<String>{'Email_vod','Fax_vod','Mail_vod','Phone_vod','No Action Necessary','Self-knowledge','Relevant Approved Training'};
    
    for (Medical_Inquiry_vod__c mi : Trigger.new) {
        
        //if(mi.Delivery_Method_vod__c == 'Email_vod' || mi.Delivery_Method_vod__c == 'Fax_vod' || mi.Delivery_Method_vod__c == 'Mail_vod' || mi.Delivery_Method_vod__c == 'Phone_vod' || mi.Delivery_Method_vod__c == 'No Action Necessary') {
        if(deliveryMethodTypes.contains(mi.Delivery_Method_vod__c)){
        	System.debug('Delivery method is Email, Fax, Mail, Phone, No Action Required,Self-knowledge,Relevant Approved Training');
        }
        else {
            System.debug('Delivery method is not Email, Fax, Mail, Phone, No Action Required,Relevant Approved Training,Self-knowledge. Returning...');
            return;
        }

        // exit if address integration already contains a value
        if (String.IsBlank(mi.Address_Integration_MRK__c)) {
            System.debug('Address Integration MRK is blank');
        }
        else {
            System.debug('Address Integration MRK is not blank. Returning...');
            return;
        }

        String acctId = mi.Account_vod__c;
      
        List<Address_vod__c> addressList = [select Id, Primary_vod__c, Account_vod__c, Name, Address_line_2_vod__c, City_vod__c, State_vod__c, Zip_vod__c from Address_vod__c WHERE Account_vod__c = :acctId order by Primary_vod__c desc, Name asc];

        // no addresses for account.  unable to populate Address_Integration_MRK__c
        if (addressList.size() == 0) {
            System.debug('No addresses...returning');
            return;
        }

        Address_vod__c addr = addressList[0];
        String addressFields = 'Name,Address_line_2_vod__c,City_vod__c,State_vod__c,Zip_vod__c';
        List<Object> addressFieldValues = new List<Object>();
        for (String fieldName : addressFields.split(',')) {
            System.debug('fieldName = ' + fieldName);
            addressFieldValues.add( addr.get(fieldName) );
        }

        String addressIntegration = String.join(addressFieldValues, ';');
        medicalInquiryIdToIntegrationAddressMap.put(mi.Id, addressIntegration);
    }
    

    for (Medical_Inquiry_vod__c mi : [select Id, Address_Integration_MRK__c, Status_vod__c, Lock_vod__c from Medical_Inquiry_vod__c where Id in :medicalInquiryIdToIntegrationAddressMap.keySet()]) {
        mi.Address_Integration_MRK__c = (String)medicalInquiryIdToIntegrationAddressMap.get(mi.Id);
        mi.Lock_vod__c = false;

        // store initial value of status prior to update
        // we will set back below after the update
        medicalInquiryIdToStatusMap.put(mi.Id, mi.Status_vod__c);

        updateList.add(mi);
    }
    
    update updateList; // results in a status change from submitted to saved

    updateList.clear();

    // set status back to initial value
    for (Medical_Inquiry_vod__c mi : [select Id, Address_Integration_MRK__c, Lock_vod__c from Medical_Inquiry_vod__c where Id in :medicalInquiryIdToIntegrationAddressMap.keySet()]) {
        mi.Status_vod__c = (String)medicalInquiryIdToStatusMap.get(mi.Id);
        //mi.Lock_vod__c = false;
        updateList.add(mi);
    }
    update updateList;
    
}