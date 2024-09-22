trigger Sample_Transaction_Transfer_Validate_Quantity on Sample_Transaction_vod__c (before insert) {

    /*
    
          KRB - 5/7/2012 -  Validation to ensure that the Transfer qty amount is valid. 
                            It must be in multiples of the value defined in the units per Case
                            for the given Product.
                            Note: there is another Before Insert Trigger on this Obj
                            (OOTB Veeva Trigger). 
    */
    
    Set<String> transferProducts = new Set<String>();
    
    for (Sample_Transaction_vod__c sampleTrans : Trigger.new){
        transferProducts.add(sampleTrans.Sample_vod__c);
    }

    List<Product_vod__c> productCatalog = new  List<Product_vod__c>();
    
    productCatalog = [SELECT Name,
                             Product_Type_vod__c,
                             Quantity_Per_Case_vod__c,
                             Sample_U_M_vod__c
                      FROM   Product_vod__c 
                      WHERE  Product_Type_vod__c = 'Sample'
                      AND    Name IN :transferProducts];

    for (Sample_Transaction_vod__c transProduct : Trigger.new){
        
       if (transProduct.Type_vod__c == 'Transfer_vod'){
       
          for (Product_vod__c sampleProduct : productCatalog)   {
         
             if (sampleProduct.Name == transProduct.Sample_vod__c){
            
                if (sampleProduct.Quantity_Per_Case_vod__c > 0){
                  //If there is no Quantity per Case defined or if it is defined as 0, skip validation.
               
                   Integer x = Integer.valueOf(transProduct.Quantity_vod__c); //can be zero
                   Integer y = integer.valueOf(sampleProduct.Quantity_Per_Case_vod__c); // can not be 0
               
                   Integer value = 0;
               
                   if (y > 0){
                      value = Math.mod(x, y);
                   }

                   if (value > 0){
                     transProduct.addError('Invalid Amount Entered for Quantity Transfered Boxes. Amount is not in multiples of the defined Box Quantity Per Case.');
                   }
                }  
             }
          }
       }
        
     }

}