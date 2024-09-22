public class MSD_CORE_GDGS_DCR_Controller {

List<Data_Change_Request_Line_vod__c> CustLineItems {get;set;}
List<Data_Change_Request_Line_vod__c> AddrLineItems {get;set;}

//List<Data_Change_Request_Line_vod__c> DCRParentId;
Private Id DCRId;
//Private Id DCRParentId;

public Id AccRecId {get;set;}
public Id UserId{get;set;}

//Added for Lightning
public string theme{get;set;}

public Id DCRAccRTId {get;set;}
public Id DCRAddRTId {get;set;}
public Data_Change_Request_vod__c DCRHeader{get;set;}  // DCR Header
public Data_Change_Request_vod__c DCRChild{get;set;}  // DCR Child - update the status of the corresponding Child Address DCR. 07/02/2014
public boolean modeflg {get;set;} //If the DCR is approved or rejected Data Stewards will not be able to modify it.


public Account DCRAcc {get;set;}
public Address_vod__c DCRAdd {get;set;}
public List<Data_Change_Request_vod__c> listDCRsToUpdate;

//public  String addressType='Address_vod__c';
//public  Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
//public  Schema.SObjectType leadSchema = schemaMap.get(addressType);
//public  Map<String, Schema.SObjectField> addressObjfieldMap = leadSchema.getDescribe().fields.getMap();

public MSD_CORE_GDGS_DCR_Controller(ApexPages.StandardController stdController){

UserId = UserInfo.getUserId();

//Added for Lightning Upgrade:
theme = UserInfo.getUiTheme();

DCRId = stdController.getId();
system.debug('Ankur DCR ID' +  DCRId);

RecordType DCRAccRT = [SELECT Id FROM RecordType WHERE SobjectType = 'Data_Change_Request_vod__c' AND Name = 'Account_vod' AND IsActive = true];
DCRAccRTId = DCRAccRT.Id;

RecordType DCRAddRT = [SELECT Id FROM RecordType WHERE SobjectType = 'Data_Change_Request_vod__c' AND Name = 'Address_vod' AND IsActive = true];
DCRAddRTId = DCRAddRT.Id;

DCRHeader = new Data_Change_Request_vod__c ();
DCRHeader = [Select Name,Type_vod__c,Account_vod__c,Account_vod__r.RecordTypeId,MSD_CORE_Application_Source__c,MSD_CORE_Master_Id_Formula__c,Account_External_ID_vod__c,Application_Source__c,MSD_CORE_Error__c,Address_vod__c,Master_Id_MRK__c,Status_vod__c,MSD_CORE_DCR_Status__c,OwnerId,MSD_Core_Rep_Notes__c,User__c,MSD_Core_DataSteward_Notes__c,MSD_CORE_Data_Steward_Master_Id__c,Notes_vod__c,MSD_CORE_Request_Type__c  from Data_Change_Request_vod__c where Id =: DCRId];
AccRecId = DCRHeader.Account_vod__r.RecordTypeId;
DCRHeader.User__c = UserId;

//DCRChild = new Data_Change_Request_vod__c ();  // 07/02/2014
//listDCRsToUpdate = [Select Id,Status_vod__c,MSD_CORE_DCR_Status__c from Data_Change_Request_vod__c where Parent_Data_Change_Request_vod__c =: DCRId]; // 07/02/2014

 If (DCRHeader.MSD_CORE_DCR_Status__c == 'Submitted' || DCRHeader.MSD_CORE_DCR_Status__c == 'Pending Approval' ) 
  modeflg = true;
  

//step to populate the Final value Field in case updated by Data Steward
DCRAcc = new Account(RecordTypeId = AccRecId);
for(Data_Change_Request_Line_vod__c cust : [select Field_API_Name_vod__c,Final_Value_vod__c from Data_Change_Request_Line_vod__c where Data_Change_Request_vod__c =: DCRId and Data_Change_Request_vod__r.RecordTypeId =: DCRAccRTId]){
DCRAcc.put(cust.Field_API_Name_vod__c,cust.Final_Value_vod__c);
}


//step to populate the Final value Field in case updated by Data Steward
DCRAdd = new Address_vod__c();
//for(Data_Change_Request_Line_vod__c addr : [select Field_API_Name_vod__c,Final_Value_vod__c from Data_Change_Request_Line_vod__c where (Data_Change_Request_vod__r.Parent_Data_Change_Request_vod__c =: DCRId or Data_Change_Request_vod__c =: DCRId )and Data_Change_Request_vod__r.RecordTypeId =: DCRAddRTId  and Field_API_Name_vod__c not in ('Physical_Address_MRK__c','Business_vod__c','Mailing_vod__c','Home_and_Office_MRK__c')]){ //Added 'Mailing_vod__c','Home_and_Office_MRK__c'to fix string to boolean error on 9/14/2015
//DCRAdd.put(addr.Field_API_Name_vod__c,addr.Final_Value_vod__c);
//}

//}

for(Data_Change_Request_Line_vod__c addr : [select Field_API_Name_vod__c,Final_Value_vod__c from Data_Change_Request_Line_vod__c where (Data_Change_Request_vod__r.Parent_Data_Change_Request_vod__c =: DCRId or Data_Change_Request_vod__c =: DCRId )and Data_Change_Request_vod__r.RecordTypeId =: DCRAddRTId]){ //Added 'Mailing_vod__c','Home_and_Office_MRK__c'to fix string to boolean error on 9/14/2015
//system.debug('Ankur Check boolean Physical_Address_MRK__c Business_vod__c Mailing_vod__c Home_and_Office_MRK__c' + addr.Final_Value_vod__c );
if(addr.Field_API_Name_vod__c == 'Business_vod__c' && addr.Final_Value_vod__c != null)
{
DCRAdd.put(addr.Field_API_Name_vod__c,Boolean.valueOf(addr.Final_Value_vod__c));
}
else if(addr.Field_API_Name_vod__c == 'Physical_Address_MRK__c' && addr.Final_Value_vod__c != null)
{
DCRAdd.put(addr.Field_API_Name_vod__c,Boolean.valueOf(addr.Final_Value_vod__c));
}
else if(addr.Field_API_Name_vod__c == 'Mailing_vod__c' && addr.Final_Value_vod__c  != null)
{
DCRAdd.put(addr.Field_API_Name_vod__c,Boolean.valueOf(addr.Final_Value_vod__c));
}
else if(addr.Field_API_Name_vod__c == 'Home_and_Office_MRK__c' && addr.Final_Value_vod__c != null)
{
DCRAdd.put(addr.Field_API_Name_vod__c,Boolean.valueOf(addr.Final_Value_vod__c));
}
else
{
DCRAdd.put(addr.Field_API_Name_vod__c,addr.Final_Value_vod__c);
}

}
}



public List<Data_Change_Request_Line_vod__c> getCustLineItems() {

                if(CustLineItems == null) 
                CustLineItems = [select Field_Name_vod__c,Field_API_Name_vod__c, Old_Value_vod__c,New_Value_vod__c,Final_Value_vod__c from Data_Change_Request_Line_vod__c where Data_Change_Request_vod__c =: DCRId and Data_Change_Request_vod__r.RecordTypeId =: DCRAccRTId  order by Display_Order__c Asc];
                system.debug('Ankur custom line items' +  CustLineItems);
                return CustLineItems;

        }

public List<Data_Change_Request_Line_vod__c> getAddrLineItems() {

                if(AddrLineItems == null)    //Find the Parent Data Change Request & store it in a variable

//                DCRParentId = [Select Id, (select Field_Name_vod__c, Old_Value_vod__c,New_Value_vod__c,Final_Value_vod__c from Data_Change_Request_Line_vod__c) from Data_Change_Request_vod__c where Parent_Data_Change_Request_vod__c =: DCRId];

              //  AddrLineItems = [select Field_Name_vod__c,Field_API_Name_vod__c, Old_Value_vod__c,New_Value_vod__c,Final_Value_vod__c from Data_Change_Request_Line_vod__c where (Data_Change_Request_vod__r.Parent_Data_Change_Request_vod__c =: DCRId or Data_Change_Request_vod__c =: DCRId )and Data_Change_Request_vod__r.RecordTypeId = '012U0000000Zl5g' and Field_API_Name_vod__c not in ('Physical_Address_MRK__c','Business_vod__c') order by Display_Order__c Asc];
                AddrLineItems = [select Field_Name_vod__c,Field_API_Name_vod__c, Old_Value_vod__c,New_Value_vod__c,Final_Value_vod__c from Data_Change_Request_Line_vod__c where (Data_Change_Request_vod__r.Parent_Data_Change_Request_vod__c =: DCRId or Data_Change_Request_vod__c =: DCRId )and Data_Change_Request_vod__r.RecordTypeId =: DCRAddRTId   order by Display_Order__c Asc];
                system.debug('Ankur custom line items' +  AddrLineItems);
                return AddrLineItems;
        }

public void Save()
    {
        updateDCRLIs();
        If(DCRHeader.User__c != NULL) {
        DCRHeader.MSD_CORE_DCR_Status__c = 'Pending Approval';
        if(!listDCRsToUpdate.isEmpty()) listDCRsToUpdate[0].MSD_CORE_DCR_Status__c = 'Pending Approval'; // 07/02/2015
        } else {
        DCRHeader.MSD_CORE_DCR_Status__c = 'Submitted';
        if(!listDCRsToUpdate.isEmpty()) listDCRsToUpdate[0].MSD_CORE_DCR_Status__c = 'Pending Approval'; // 07/02/2015
        }
        listDCRsToUpdate.add(DCRHeader);
        update listDCRsToUpdate;
    //    update DCRChild; // 07/02/2015
        
     //   system.debug('Ankur inside save' + CustDCR);
        
         
    }


public pagereference Approve()
    {
    
    updateDCRLIs();
    DCRHeader.MSD_CORE_DCR_Status__c = 'Pre-Approved';
  //  DCRChild.MSD_CORE_DCR_Status__c = 'Pre-Approved'; // 07/02/2015
  if(!listDCRsToUpdate.isEmpty()) listDCRsToUpdate[0].MSD_CORE_DCR_Status__c = 'Pre-Approved'; // 07/02/2015
    listDCRsToUpdate.add(DCRHeader);
    
    
    try{
        update listDCRsToUpdate;
        }
          catch (Exception ex) {
          String errorMessage = ex.getMessage();
          Integer occurence;
          if (ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
          occurence = errorMessage.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION,') + 34;
          errorMessage = errorMessage.mid(occurence, errorMessage.length());
          occurence = errorMessage.lastIndexOf(':');
          errorMessage = errorMessage.mid(0, occurence);
          }
          else {
          errorMessage = ex.getMessage();
          }

          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
          return null; //line added to stay on the same page in case of a validation error.
          }

        
        
        
    //update DCRHeader;
  //  update DCRChild; // 07/02/2015
    
    
    modeflg = false;
    
   
    return null;
    
    }

public pagereference Reject()
    {
    
    updateDCRLIs();
     DCRHeader.MSD_CORE_DCR_Status__c = 'Rejected';
    // DCRChild.MSD_CORE_DCR_Status__c = 'Rejected'; // 07/02/2015
    if(!listDCRsToUpdate.isEmpty()) listDCRsToUpdate[0].MSD_CORE_DCR_Status__c = 'Rejected'; // 07/02/2015
    listDCRsToUpdate.add(DCRHeader);
    
    try{
        update listDCRsToUpdate;
        }
          catch (Exception ex) {
          String errorMessage = ex.getMessage();
          Integer occurence;
          if (ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
          occurence = errorMessage.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION,') + 34;
          errorMessage = errorMessage.mid(occurence, errorMessage.length());
          occurence = errorMessage.lastIndexOf(':');
          errorMessage = errorMessage.mid(0, occurence);
          }
          else {
          errorMessage = ex.getMessage();
          }

          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
          return null; //line added to stay on the same page in case of a validation error.
          }

        
        
        
        
     //update DCRHeader;
    // update DCRChild; // 07/02/2015
     
    modeflg = false;
    
    return null;
    
    }

public PageReference cancel()
    {
     //Updated for Lightning Upgrade: 
     if(theme == 'Theme3'){
       PageReference HomePage = new PageReference('/home/home.jsp'); 
       HomePage.setRedirect(true);
       return HomePage;
    }else{
       PageReference HomePage = new PageReference('/lightning/page/home'); 
       HomePage.setRedirect(true);
       return HomePage;
    }
        
    }

public PageReference DCRTab()
    {
    
    PageReference DCRPage = new PageReference('/a2j/o'); 
    DCRPage.setRedirect(true);
    return DCRPage;
        
    }


public void updateDCRLIs() {
    List<Data_Change_Request_Line_vod__c> listDCRLIsToUpdate = new List<Data_Change_Request_Line_vod__c>();
    System.debug('Ankur Acc Data' + DCRAcc);
    
      String accountType='Account';
      Map<String, Schema.SObjectType> AccschemaMap = Schema.getGlobalDescribe();
      Schema.SObjectType AccleadSchema = AccschemaMap.get(accountType);
      Map<String, Schema.SObjectField> accountObjfieldMap = AccleadSchema.getDescribe().fields.getMap();
    
         for(Data_Change_Request_Line_vod__c DCRLi: CustLineItems){
           //  if(DCRAcc.get(DCRLi.Field_API_Name_vod__c) != null){
           
          Schema.DescribeFieldResult fa = accountObjfieldMap.get(DCRLi.Field_API_Name_vod__c).getDescribe();  
          DCRLi.Final_Value_vod__c  = getStringValueOf(fa,DCRAcc.get(DCRLi.Field_API_Name_vod__c)); 
           
           //  DCRLi.Final_Value_vod__c  = (String) DCRAcc.get(DCRLi.Field_API_Name_vod__c);
          //   }
          }
        System.debug('Customer Line Items...' + CustLineItems);  
        //update CustLineItems;
        listDCRLIsToUpdate.addAll(CustLineItems);
                     
         System.debug('Ankur Address Data' + DCRAdd);
         
      String addressType='Address_vod__c';
      Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
      Schema.SObjectType leadSchema = schemaMap.get(addressType);
      Map<String, Schema.SObjectField> addressObjfieldMap = leadSchema.getDescribe().fields.getMap();
      
         for(Data_Change_Request_Line_vod__c DCRLi: AddrLineItems){
        // if(DCRAdd.get(DCRLi.Field_API_Name_vod__c) != null){
        
      //  system.debug('Ankur ' + DCRAdd.(DCRLi.Field_API_Name_vod__c));
      
         Schema.DescribeFieldResult f = addressObjfieldMap.get(DCRLi.Field_API_Name_vod__c).getDescribe();  // Work on this line of code -- Ankur MSD_CORE_GDGS_DCR_Controller Compile Error: Method does not exist or incorrect signature: [Object].getDescribe() at line 177 column 80
          DCRLi.Final_Value_vod__c  = getStringValueOf(f,DCRAdd.get(DCRLi.Field_API_Name_vod__c)); 
           //  DCRLi.Final_Value_vod__c  = (String) DCRAdd.get(DCRLi.Field_API_Name_vod__c);
       //      }
        }
        System.debug('Address Line Items...' + AddrLineItems);  
        //update AddrLineItems;
        listDCRLIsToUpdate.addAll(AddrLineItems);
        
        
        try{      
                update listDCRLIsToUpdate;
            }
          catch (Exception ex) {
          String errorMessage = ex.getMessage();
          Integer occurence;
          if (ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
          occurence = errorMessage.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION,') + 34;
          errorMessage = errorMessage.mid(occurence, errorMessage.length());
          occurence = errorMessage.lastIndexOf(':');
          errorMessage = errorMessage.mid(0, occurence);
          }
          else {
          errorMessage = ex.getMessage();
          }

          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
         // return null; //line added to stay on the same page in case of a validation error.
          }

        
        listDCRsToUpdate = new List<Data_Change_Request_vod__c>([Select Id,Status_vod__c,MSD_CORE_DCR_Status__c from Data_Change_Request_vod__c where Parent_Data_Change_Request_vod__c =: DCRId]); // 07/02/2014
        
}

/******************************/

public static String getStringValueOf(Schema.DescribeFieldResult f,Object val){
             
            if (f.getType() == Schema.DisplayType.String){
               return (String)val;
            }else if (f.getType() == Schema.DisplayType.BOOLEAN){
               return MSD_CORE_Convert.ToString((BOOLEAN)val);      
            }else if (f.getType() == Schema.DisplayType.INTEGER){
               return MSD_CORE_Convert.ToString((INTEGER)val);      
            }else if (f.getType() == Schema.DisplayType.DATE){
               return MSD_CORE_Convert.ToString((DATE)val);      
           }else if (f.getType() == Schema.DisplayType.DATETIME){
               return MSD_CORE_Convert.ToString((DATETIME)val);      
           }else if (f.getType() == Schema.DisplayType.DOUBLE){
               return MSD_CORE_Convert.ToString((DOUBLE)val);       
           }else{
               return (String)val; 
            }
   }

/******************************/


}