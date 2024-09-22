trigger MRK_Before_Insert_UserProductCheck on Survey_Target_vod__c (after insert) {

    String userid = UserInfo.getUserid();
    Set<Id> SurveyIds = new Set<Id>(); 
    
    for (Survey_Target_vod__c st : Trigger.new) {
    //        Survey_vod__c s = [select Product_vod__c from Survey_vod__c where Id = :st.Survey_vod__c][0];   //Commented
        SurveyIds.add(st.Survey_vod__c);
    }

    Set<Id> ProductIds = new Set<Id>(); 
    for(Survey_vod__c sy : [select Product_vod__c from Survey_vod__c where Id = :SurveyIds])
    {
        ProductIds.add(sy.Product_vod__c);
    }
    
    List <My_Setup_Products_vod__c> userProducts = [select  Product_vod__c from My_Setup_Products_vod__c where OwnerId = :userid and Product_vod__c =: ProductIds];
    
    for(Survey_Target_vod__c STV : Trigger.New)
    {
            If(userProducts.isEmpty())
                {
                STV.addError('Unable to create.  You do not carry the survey product.');
                }
    
    }
    
    
    
    
  /*  
    for(Id s: ProductIds)
    {
        Boolean blockCreate = false;
        if (s.Id == null) {
            blockCreate = true;
        } else {

        
            Boolean userHasSurveyProduct = false;
            for (My_Setup_Products_vod__c mp : userProducts) {
                if (mp.Product_vod__c == s.Id) {
                    userHasSurveyProduct = true;
                }
            }
            
            if (!userHasSurveyProduct) {
                blockCreate = true;
            }
        }

        if (blockCreate) {
            st.addError('Unable to create.  You do not carry the survey product.');
        }

    }
    */   

}