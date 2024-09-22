public class CAsupportForMIHelper {

    private Boolean childAccountSupporForMedicalInquiryEnabled;

    public CAsupportForMIHelper(Boolean enableChildAccount, Boolean isMedicalInquiryCreatable, 
            Boolean medicalInquiryLocationIsEditable, Boolean medicalInquiryChildAccountIsEditable) {
        this.childAccountSupporForMedicalInquiryEnabled = enableChildAccount && isMedicalInquiryCreatable
                 && medicalInquiryLocationIsEditable && medicalInquiryChildAccountIsEditable;
    }

    public Medical_Inquiry_Audit_vod__c stampMedicalInquiryAudit(Medical_Inquiry_Audit_vod__c medicalInquiryAudit, Medical_Inquiry_vod__c medicalInquiry) {
        if (this.childAccountSupporForMedicalInquiryEnabled) {
            medicalInquiryAudit.Location_vod__c = medicalInquiry.Location_vod__c;
            medicalInquiryAudit.Child_Account_vod__c = medicalInquiry.Child_Account_vod__c;
        }
        return medicalInquiryAudit;
    }

    public Medical_Inquiry_Fulfillment_vod__c stampMedicalInquiryFulfillment(Medical_Inquiry_Fulfillment_vod__c medicalInquiryFulfillment, Medical_Inquiry_vod__c medicalInquiry) { 
        if (this.childAccountSupporForMedicalInquiryEnabled) {
            medicalInquiryFulfillment.Location_vod__c = medicalInquiry.Location_vod__c;
            medicalInquiryFulfillment.Child_Account_vod__c = medicalInquiry.Child_Account_vod__c;
        }
        return medicalInquiryFulfillment;
    }
}