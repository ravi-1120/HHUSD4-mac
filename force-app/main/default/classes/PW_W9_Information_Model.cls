///-----------------------------------------------------------------
///   Namespace:      <Class Namespace>
///   Class:          PW_W9_Information_Model
///   Description:    This class is a Model class for Speaker Profile- W9 Information object 
///   Author:         Anshuman Hazarika                   
///   Notes:          Receives the W9 information for a speaker from Touchpoint
///    Date: 21/05/2020
///   Revision History:
/// 1. Created 21/05/2020 New July 2020 release

// 
global class PW_W9_Information_Model
{
    public string PW_W9_Type {get;set;}  
    public string PW_W9_Payee_Name {get;set;}  
    //public string PW_W9_Payee_Address {get;set;}  // Removed For July 2020 Release
    public string PW_W9_TIN {get;set;}  
    public string PW_W9_Address1 {get;set;} 
    public string PW_W9_Address2 {get;set;} 
    public string PW_W9_City {get;set;} 
    public string PW_W9_StateName {get;set;} 
    public string PW_W9_ZipCode {get;set;} 
    public string PW_W9_W9TPID {get;set;} 
    //public string PW_W9_Payment_Category {get;set;}  
    public string PW_W9_Payment_Category_ID {get;set;}  
}