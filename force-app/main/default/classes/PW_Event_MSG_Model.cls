//Event Modal
//-----------------------------------------------------------------
///   Namespace:      <Class Namespace>
///   Class:          PW_Event_MSG_Model
///   Description:    Whenever the event is modified after approved this message would be sent
///   Author:         Anshuman Hazarika                   
///   Notes:          
///   Date: 31-08-2020
///   Revision History:
///-----------------------------------------------------------------

global class PW_Event_MSG_Model
{
   public Id Id{get;set;}//Event_Id updated to id 
    
    
    public void PopulateModel(Id EventId)
    {
        Id= EventId;
    }
   
}