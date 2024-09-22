///-----------------------------------------------------------------
///   Namespace:      <Class Namespace>
///   Class:          PW_SpeakerQualificaiton_Model
///   Description:    This class is a Model class for Speaker Qualification object 
///   Author:         Nitesh Kodle                   
///   Notes:          Conatins methods to initialize data members of class for Speaker Qualification object 
///    Date: 20-12-2016
///   Revision History:

global class PW_SpeakerQualificaiton_Model
{

      
    public string Qualification_vod{get;set;}
    public string Qualification_type{get;set;}//topic contract compliance
    public string Speaker_vod{get;set;}
    public string Tp_Speaker_ID{get;set;}
    public string Start_Date_vod{get;set;}
    public string End_Date_vod{get;set;}
    public string PW_Row_ID{get;set;}// not present in dev
    public string message{get;set;}
    public Boolean isTrained{get;set;}
    public string contractStatus{get;set;}
    public string PW_Contract_Name{get;set;} // New for merck
    public string LastModifiedDate{get;set;} // New for merck
}