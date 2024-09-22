public class MSD_CORE_NAW_Confirmation_Controller{

public Id AccountId {get;set;}
public Id userid{get;set;}
public Id DCRid{get;set;}
public string DCRName {get;set;}

//Added for Lightning Switch
public string theme = UserInfo.getUiTheme();


public MSD_CORE_NAW_Confirmation_Controller(){

AccountId  = ApexPages.currentPage().getParameters().get('AccId');
userid = Userinfo.getUserId();

Data_Change_Request_vod__c DCR = [SELECT Id,Name FROM Data_Change_Request_vod__c WHERE Account_vod__c =: AccountId   AND OwnerId =: userid];
DCRId = DCR.Id;
DCRName = DCR.Name;

}


public PageReference OK() { //Code to call the Home Page
    
    //Added for Lightning Update
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


}