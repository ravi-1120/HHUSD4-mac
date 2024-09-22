public class PW_Speaker_Status_Model 
{
    public String PW_Speaker_ID {get;set;}
    public String PW_Speaker_Status {get;set;}
    public Id SpeakerId {get;set;}
	public String LastModifiedDate {get;set;}   //New
    
     public boolean initializeSpeakerStatus( String Status, String PW_Speaker_ID ,Id SpkId ,String LastModifiedDatee)
    { 
             this.PW_Speaker_ID     =  PW_Speaker_ID ;                         
             PW_Speaker_Status = Status ;  
			 SpeakerId=SpkId;
			 LastModifiedDate=LastModifiedDatee;  //New
             return true;
      }

}