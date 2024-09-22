///-----------------------------------------------------------------
///   Namespace:      <Class Namespace>
///   Class:          PW_SpeakerProfile_Model
///   Description:    This class is a Model class for Speaker Profile object 
///   Author:         Nitesh Kodle                   
///   Notes:          Conatins methods to initialize data members of class for Speaker Profile object 
///    Date: 24-11-2016
///   Revision History:
/// 1. 15/01/2019 added the Presentation_Language field
global class PW_SpeakerProfile_Model 
{
      
    public string Account_vod{get;set;}
    public string PW_Speciality{get;set;} //not present as of nw
    public string First_Name_vod{get;set;}
    public string Last_Name_vod{get;set;}
    public string Status_vod{get;set;}
    public string PW_Client_ID{get;set;}// accountid
    public string PW_Speaker_ID{get;set;}
    public string Address_vod{get;set;}
    public string Credentials_vod{get;set;}
    public string Name{get;set;}
    public string Message{get;set;}
    public string PW_Presentation_Language{get;set;}
    //public PW_W9Info_SpeakerProfile_Model  PW_W9Information {get;set;}
    public string LastModifiedDate{get;set;} //--Added for Merck
    public List<PW_W9_Information_Model> ListOfW9Info{get;set;} // Added April 2020 //stores the w9 information for the Speaker
    public boolean PW_Client_ID_Required{get;set;} // Added for Jan 2021 Release
    public string PW_Speaker_Credentials{get;set;} // Added for Jan 2021 Release
}