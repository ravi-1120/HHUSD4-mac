global class PW_Event_Attachment_Model {
      
    public id EventID{get;set;}
    public id AttachmentID{get;set;}  
	public string Firstname{get;set;}
	public string Lastname{get;set;}
	public string EmployeeNumber{get;set;}
    
   public PW_Event_Attachment_Model(id attachId, id parentId,string fname,string lname,string empNumber){
       EventID=parentId;
       AttachmentID=attachId;  
	   Firstname=fname;
	   Lastname=lname;
	   EmployeeNumber=empNumber;
    }
   /* public void PopulateModel(id attachId){
         system.debug('Event Attachment ID :'+ attachmentId);
        list<attachment> attachmentList = [SELECT Id,Name,ParentId FROM Attachment WHERE Id =: attachId];
         system.debug('Event Attachment list :'+ attachmentList);
        if(attachmentList.size()>0){
            
             system.debug('Event Attachment list ids :'+ attachmentList[0].ParentId);
              system.debug('Event Attachment list ids attachment :'+ attachmentId);
            EventID=attachmentList[0].ParentId;
            AttachmentID=attachId;
        }
    }*/
    
}