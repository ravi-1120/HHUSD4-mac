public class MSD_CORE_Addr_Confirmation_Controller{

public Id AddrId {get;set;}
public Id userid{get;set;}
public Id DCRid{get;set;}
public string DCRName {get;set;}

//Added for Lightning Switch
public string theme = UserInfo.getUiTheme();

public MSD_CORE_Addr_Confirmation_Controller(){

AddrId = ApexPages.currentPage().getParameters().get('AddId');
userid = Userinfo.getUserId();

Data_Change_Request_vod__c DCR = [SELECT Id,Name FROM Data_Change_Request_vod__c WHERE Address_vod__c =: AddrId AND OwnerId =: userid];
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