public class PW_Send_Speaker_Qualification_Model {
   
    public Id PW_Product     	    {get;set;}         // EM_Speaker_Qualification_vod__c.Qualification_vod__r.PW_Product__c 
    public string Tp_Speaker_ID 	 	{get;set;}        // from EM_Speaker_Qualification_vod__c.Speaker_vod__r.PW_Speaker_ID__c
    public Id Qualification_vod     {get;set;}       // EM_Speaker_Qualification_vod__c.Qualification_vod__c
    public string PW_Indication         {get;set;}      // EM_Speaker_Qualification_vod__c.Qualification_vod__r.PW_Therapeutic_Area__c  
    public string Start_Date_vod            {get;set;}     // from EM_Speaker_Qualification_vod__c.Start_Date_vod__c
    public string End_Date_vod              {get;set;}    // from EM_Speaker_Qualification_vod__c.End_Date_vod__c
    public string PW_Row_ID             {get;set;}   // from EM_Speaker_Qualification_vod__c.PW_Row_ID__c
    public Id SpeakerQualificationId     	    {get;set;}  //for Speaker bidirectional flow
    public string LastModifiedDate  {get;set;}    //Added for Merck
    
 	 public Boolean initializeSpeakerQualification(Id speakerQualificationId, String triggerEvent)
    {
			    boolean flag=true;
			    List<EM_Speaker_Qualification_vod__c> speakerQualificationLst=new List<EM_Speaker_Qualification_vod__c>();
			    if(triggerEvent == 'INSERT' || triggerEvent == 'UPDATE')
			    {
				     speakerQualificationLst=[select Qualification_vod__r.PW_Product__c ,Speaker_vod__r.PW_Speaker_ID__c, Qualification_vod__c ,Qualification_vod__r.PW_Therapeutic_Area__c ,
				     Start_Date_vod__c,End_Date_vod__c,PW_Row_ID__c, LastModifiedDate from EM_Speaker_Qualification_vod__c where id=:speakerQualificationId Limit 1 ];    //LastModifiedDate added

			   }else if(triggerEvent == 'DELETE' )
                   
			   {
			 		speakerQualificationLst=[select Qualification_vod__r.PW_Product__c ,Speaker_vod__r.PW_Speaker_ID__c, Qualification_vod__c ,Qualification_vod__r.PW_Therapeutic_Area__c ,Start_Date_vod__c,End_Date_vod__c,PW_Row_ID__c ,LastModifiedDate    from EM_Speaker_Qualification_vod__c where id=:speakerQualificationId Limit 1 ALL ROWS ]; //LastModifiedDate added 

			   }
			   if(speakerQualificationLst.size()>0)
			   {
				       PW_Product 	              = speakerQualificationLst[0].Qualification_vod__r.PW_Product__c; 
				       Tp_Speaker_ID	 	      = speakerQualificationLst[0].Speaker_vod__r.PW_Speaker_ID__c;
				       Qualification_vod      	  = speakerQualificationLst[0].Qualification_vod__c;
				  	   PW_Indication           	  = speakerQualificationLst[0].Qualification_vod__r.PW_Therapeutic_Area__c;  
				       Start_Date_vod             = string.valueof(speakerQualificationLst[0].Start_Date_vod__c);
				   	   End_Date_vod               = string.valueof(speakerQualificationLst[0].End_Date_vod__c);
				       PW_Row_ID                  = speakerQualificationLst[0].PW_Row_ID__c;
                       this.SpeakerQualificationId	  = speakerQualificationId;   //for Speaker bidirectional flow
					   LastModifiedDate			  = string.valueOfGmt(speakerQualificationLst[0].LastModifiedDate);    //neww
			   }else
			   {
			  			 flag=false;
			   }

			return flag;
    }
}