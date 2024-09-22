///-----------------------------------------------------------------
///   Namespace:      <Class Namespace>
///   Class:          Pw_Validation_Output
///   Description:    This class handle different validation
///   Author:         Snehal Asare                   
///   Notes:          Conatins no method
///	  Date: 24-10-2016
///   Revision History:
///-----------------------------------------------------------------
public class Pw_Validation_Output {
    
    public enum ValidateStatus {SUCCESS, NOTCONFIRMED, MISSINGFIELDS,SPEAKERNOTFOUND, TEAMMEMEBERNOTFOUND }
    public string outputMessage{get;set;} 
    public ValidateStatus status{get;set;} 
    public Pw_Validation_Output(string msg, ValidateStatus passedStatus){
        
        outputMessage=msg;
        status=passedStatus;        
    }

}