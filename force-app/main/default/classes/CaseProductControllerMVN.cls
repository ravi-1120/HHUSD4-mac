/*
 * CaseProductControllerMVN
 * Created By:      Prasanjeet Sharma
 * Description:     This class returns the translated record type name of the class
 *                  to be displayed on the Case Record Type page.  It also determines
 *                  if the Request is an Adverse Event/PQC or Temperature Excursion in
 *                  order to display the appropriate disclaimer in the Case Record Type
 *                  page.  
 */
public with sharing class CaseProductControllerMVN {
    public MSD_CORE_AE_Product__c product {get;set;}
    public String productId {get;set;}
    public String pdctRecordTypeName {get;set;}
    String caseId;
    String recordTypeId;
    public boolean isError {get;set;}
    
    public CaseProductControllerMVN (ApexPages.StandardController controller){  
        productId = controller.getRecord().Id;
        product = new MSD_CORE_AE_Product__c();
        
        caseId = ApexPages.currentPage().getParameters().get('CaseId');
        recordTypeId = ApexPages.currentPage().getParameters().get('RecordType');
        
        if(caseId != null)
            product.MSD_CORE_Adverse_Event__c = caseId;
        
        if(recordTypeId != null)
            product.RecordTypeId = recordTypeId;
        
        if(productId != null)
            product = [select id, Name, MSD_CORE_Adverse_Event__c, MSD_CORE_Catalog_Number__c,
                       MSD_CORE_Country_Code__c, MSD_CORE_Dose_Frequency__c, MSD_CORE_Expiration_Date__c,
                       MSD_CORE_Hazardous_Product__c, MSD_CORE_Lot_Number__c, MSD_CORE_Model_Number__c,
                       MSD_CORE_Obtain__c, MSD_CORE_Other_Company_Product__c, MSD_CORE_Primary_Product__c,
                       MSD_CORE_Product_Circular__c, MSD_CORE_Product_External_ID__c, MSD_CORE_Product_Lookup__c,
                       MSD_CORE_ProductName__c, MSD_CORE_Product_Qty__c, MSD_CORE_Product_Return_Date__c,
                       MSD_CORE_Product_Type__c, MSD_CORE_Related_to__c, MSD_CORE_Serial_Number__c,
                       MSD_CORE_Unique_Identifier__c from MSD_CORE_AE_Product__c
                       where id =: productId];
    }
    
    public void updateRelatedTo()
    {
        update product;
    }
    
    public void saveCaseNew()
    {
        try
        {
            upsert product;
            productId = product.Id;
            PageReference p = new PageReference('/apex/CaseProductEditMVN');
            
            p.getParameters().put('RecordType', recordTypeId);
            p.getParameters().put('CaseId', caseId);
            p.getParameters().put('nooverride', '1');
        
            //return p.setRedirect(true);
            isError = false;
        }
        catch(Exception ex)
        {
            addPageMessageError(ex.getMessage());
            isError = true;
            //return null;
        }
    }
    
    public void saveCase()
    {
        try
        {
            upsert product;
            productId = product.Id;
            isError = false;
            //return new PageReference('/'+product.Id).setRedirect(true);
        }
        catch(Exception ex)
        {
            addPageMessageError(ex.getMessage());
            isError = true;
            //return null;
        }
    }
    
    public void addPageMessageError(String error)
    {
        error = error.replace(': []', '');
            
        if(error.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION, '))
            error = error.split('FIELD_CUSTOM_VALIDATION_EXCEPTION, ')[1];
        
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, error);
        ApexPages.addMessage(myMsg);
    }
}