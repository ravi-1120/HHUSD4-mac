/*
* AccountSearchResultMockMVN
* Created By: Kai Amundsen
* Created Date: April 5, 2013
* Last Modified Date: April 5, 2013
* Description:  Mock class used to store search results for account search.
*               The results are assembled in the AccountSearchControllerMVN class
*               and are displayed to the end user in the AccountSearchMVN page.
*/

global without sharing class AccountSearchResultMockMVN implements Comparable {
    @AuraEnabled
    public Account theAccount{get;set;}
    @AuraEnabled
    public Address_vod__c theAddress {get;set;}
    @AuraEnabled
    public String sapIds { get; set; }
    private AccountSearchUtilityMVN.searchInterface searchUtility;

    public AccountSearchResultMockMVN (AccountSearchUtilityMVN.searchInterface utility) {
        this(new Account(),new Address_vod__c(), utility);
    }

    public AccountSearchResultMockMVN(Account acct, AccountSearchUtilityMVN.searchInterface utility) {
        this(acct,new Address_vod__c(Country_vod__c = acct.MSD_CORE_Country_Code__c), utility);
    }

    public AccountSearchResultMockMVN(Account acct, Address_vod__c addr, AccountSearchUtilityMVN.searchInterface utility) {
        this(acct, addr, '', utility);
    }

    public AccountSearchResultMockMVN(Account acct, Address_vod__c addr, String newSAPIds, AccountSearchUtilityMVN.searchInterface utility) {
        theAccount = acct;
        theAddress = addr;
        sapIds = newSAPIds;
        
        searchUtility = utility;
        if (searchUtility == null) {
            searchUtility = defaultSearchUtlity();
        }
    }

    // the first listed is the default
    private AccountSearchUtilityMVN.searchInterface defaultSearchUtlity() {
        AccountSearchUtilityMVN.searchInterface utilityInstance;
        Service_Cloud_Settings_MVN__c settings = Service_Cloud_Settings_MVN__c.getInstance();
        List<String> searchUtlities = UtilitiesMVN.splitCommaSeparatedString(settings.Account_Search_Utility_Classes_MVN__c);
        if (searchUtlities.size() > 0) {
            try {
                Type t = Type.forName(searchUtlities[0]);
                utilityInstance = (AccountSearchUtilityMVN.searchInterface) t.newInstance();

            } catch(Exception e) {
                ApexPages.addMessages(e);
                return null;
            }

        }
        return utilityInstance;
    }

    public AccountSearchResultMockMVN insertAccountDetails() {
        return searchUtility.insertAccountDetails(this);
    }

    public Account getAccount() {
        return theAccount;
    }

    public Address_vod__c getAddress() {
        return theAddress;
    }

    public String getSAPIds(){
        return sapIds;
    }

    public void setAccount(Account acct) {
        theAccount = acct;
    }

    public void setAddress(Address_vod__c addr) {
        theAddress = addr;
    }    

    public void setSAPIds(String newSAPIds){
        sapIds = newSAPIds;
    }

    public String getAccountID() {
        String acctId = '';
        if (String.isBlank(theAccount.External_ID_vod__c)) {
            acctId = theAccount.Id;
        } else {
            acctId = theAccount.External_ID_vod__c;
        }

        return acctId;
    }

    public String getSFDCAccountID() {
        return theAccount.Id;
    }

    public String getResultKey () {
        String key = getAccountId();
        if(String.isNotBlank(theAddress.External_ID_vod__c)) {
            key += '_' + theAddress.External_ID_vod__c;
        } else if(String.isNotBlank(theAddress.Id)) {
            key += '_' + theAddress.Id;
        }

        return key;
    }

    global Integer compareTo(Object compareTo) {
        AccountSearchResultMockMVN asr = (AccountSearchResultMockMVN) compareTo;

        Integer compareInt = 0;
    
        if(!String.isBlank(theAccount.Preferred_Full_Name_MRK__c) && !String.isBlank(asr.theAccount.Preferred_Full_Name_MRK__c)){
            compareInt = theAccount.Preferred_Full_Name_MRK__c.compareTo(asr.theAccount.Preferred_Full_Name_MRK__c);
        }
    
        if(compareInt != 0){
            return compareInt;
        }
    
        if(!String.isBlank(theAccount.Preferred_Last_Name_MRK__c) && !String.isBlank(asr.theAccount.Preferred_Last_Name_MRK__c)){
            compareInt = theAccount.Preferred_Last_Name_MRK__c.compareTo(asr.theAccount.Preferred_Last_Name_MRK__c);
        }
    
        if(compareInt != 0){
            return compareInt;
        }   
    
        if (!String.isBlank(theAccount.Preferred_First_Name_MRK__c) && !String.isBlank(asr.theAccount.Preferred_First_Name_MRK__c)) {
            compareInt = theAccount.Preferred_First_Name_MRK__c.compareTo(asr.theAccount.Preferred_First_Name_MRK__c);
        }
        
        return compareInt; 
    }
}