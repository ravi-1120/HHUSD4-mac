trigger MRK_Product_BeforeUpdate on Product_vod__c (before update) {

       /*  KRB - 11/12/12 - Product Name Field on the Product Page Layout 
                 is a required field and therefore editable. Sample Admins 
                 have access to this Pagelayout. We need to stop the Sample Admins
                 from being able to change the value in this field.
       */
    
    if (Trigger.isUpdate) {
    
        String usrProfileName = [select u.Profile.Name from User u where u.id = :Userinfo.getUserId()].Profile.Name;
    
        if (usrProfileName == 'MRK - Samples Admin'){
          for (Product_vod__c product: Trigger.new) {
             if( product.Name != trigger.oldMap.get(product.id).name){
               product.addError('Product Name cannot be changed.');
             }        
          }
        }
    }
}