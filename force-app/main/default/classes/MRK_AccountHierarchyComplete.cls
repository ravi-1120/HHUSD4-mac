public class MRK_AccountHierarchyComplete {
    
    private final Account acct;
    
    public String accountId {get;set;}
    public String jsonData {get;set;}
    public String jsonMetadata {get;set;}
    public String alignedAccountsJsonData {get;set;}
    public String baseResourceURL {

        get {
            return MRK_StaticResourceUtil.getResourceURL('mrk_account_hierarchy_complete');
        }
    }

    public MRK_AccountHierarchyComplete() {
    }
    
    public MRK_AccountHierarchyComplete(ApexPages.StandardController stdController) {
        Set<Id> alignedAccounts = new Set<Id>();
        
        //KRB 2/13/2020 - out for TM2.0
        //List<UserTerritory> userTerritoryList = [select TerritoryId from UserTerritory where UserId = :UserInfo.getUserId()];
        
        List<UserTerritory2Association> userTerritoryList = [
                                                             SELECT Territory2Id 
                                                             FROM   UserTerritory2Association 
                                                             WHERE  UserId = :UserInfo.getUserId() 
                                                             AND    IsActive = true  
                                                             AND    Territory2.Territory2Model.state ='Active' 
                                                            ];
        
        //KRB 2/13/2020 - out for TM2.0
        //String userTerritoryName = [select Name from Territory where Id = :userTerritoryList[0].TerritoryId].Name;
        String userTerritoryName = [select Name 
                                    from Territory2 
                                    where Id = :userTerritoryList[0].Territory2Id].Name;
        
        //KRB 2/13/2020 - out for TM2.0
        //String territoryId = [SELECT Id FROM Territory WHERE Name = :userTerritoryName].Id;
        String territoryId = [SELECT Id 
                              FROM   Territory2 
                              WHERE  Name = :userTerritoryName].Id;        
        
        String groupId = [select Id from group where RelatedId = :territoryId AND Type IN ('Territory')].Id;
        
        
        for (AccountShare acctShare : [select AccountId from AccountShare WHERE UserOrGroupId = :groupId]) {
            alignedAccounts.add(acctShare.AccountId);
        }
        
        this.acct = (Account)stdController.getRecord();
        
        //String accountId = '001J00000088YZwIAM';
        //accountId = ApexPages.currentPage().getParameters().get('accountId');
        //accountId = (accountId == null) ? '001J00000088YZwIAM' : accountId;
        accountId = acct.Id;
        
        Id rootAccountId = findRootAccountFor(accountId);

        List<Map<String,String>> accounts = new List<Map<String,String>>();
        Map<String,String> rootAccountMap = new Map<String,String>();

        rootAccountMap.put('Parent_Account_vod__c', '');
        rootAccountMap.put('Parent_Account_vod__r.Name', '');
        rootAccountMap.put('Parent_Account_vod__r.Merck_ID_MRK__c', '');
        rootAccountMap.put('Child_Account_vod__c', rootAccountId);
        Account rootAccount = [SELECT Id, Name, Merck_ID_MRK__c, Formatted_Name_vod__c, IsPersonAccount FROM Account WHERE Id = :rootAccountId];
        rootAccountMap.put('Child_Account_vod__r.Name', rootAccount.Formatted_Name_vod__c);
        rootAccountMap.put('Child_Account_vod__r.Merck_ID_MRK__c', rootAccount.Merck_ID_MRK__c);
        rootAccountMap.put('Child_Account_vod__r.Preferred_Name_vod__c', rootAccount.Formatted_Name_vod__c);
        rootAccountMap.put('Child_Account_vod__r.IsPersonAccount', rootAccount.IsPersonAccount + '');
        accounts.add(rootAccountMap);
        accounts.addAll( getChildAccountsFor(rootAccountId) );

        jsonData = JSON.serialize(accounts);
        alignedAccountsJsonData = JSON.serialize(alignedAccounts);
    }

    
    public Id findRootAccountFor(Id accountId) {
        Id currentAccountId = accountId,
           previousAccountId = accountId;

        while (currentAccountId != null) {
            previousAccountId = currentAccountId;
            List<Child_Account_vod__c> l = [SELECT Id, Parent_Account_vod__c FROM Child_Account_vod__c WHERE Child_Account_vod__c = :currentAccountId];
            if (l.size() > 0) {
                currentAccountId = l[0].Parent_Account_vod__c;
            } else {
                currentAccountId = null;
            }
        }
        return previousAccountId;
    }
    
    public List<Map<String,String>> getChildAccountsFor(Id accountId) {
        List<Map<String,String>> results = new List<Map<String,String>>();
        try {

            // hit query governor limits
            if ( Limits.getQueries() == (Limits.getLimitQueries() - 1) ) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,'Please note you are seeing a partial hierarchy for this account during proof of concept (POC).  There is a limit to the number of accounts that can currently display which will be addressed after the POC.  All child accounts for this account hierarchy are not displayed.'));
                jsonMetadata = JSON.serialize(new Map<String,String>{'queryLimitHit' => 'true'});
                return results;
            }


            List<Child_Account_vod__c> l = [SELECT Id, Parent_Account_vod__c, Parent_Account_vod__r.Name, Parent_Account_vod__r.Formatted_Name_vod__c, Parent_Account_vod__r.Merck_ID_MRK__c, Child_Account_vod__c, Child_Account_vod__r.Name, Child_Account_vod__r.Merck_ID_MRK__c, Child_Account_vod__r.Preferred_Name_vod__c, Child_Account_vod__r.Formatted_Name_vod__c, Child_Account_vod__r.IsPersonAccount FROM Child_Account_vod__c WHERE Parent_Account_vod__c = :accountId and Child_Account_vod__r.IsPersonAccount = false];
            for (Child_Account_vod__c ca : l) {
                Map<String,String> m = new Map<String,String>();
                m.put('Parent_Account_vod__c', ca.Parent_Account_vod__c);
                m.put('Parent_Account_vod__r.Name', ca.Parent_Account_vod__r.Formatted_Name_vod__c);
                m.put('Parent_Account_vod__r.Merck_ID_MRK__c', ca.Parent_Account_vod__r.Merck_ID_MRK__c);
                m.put('Child_Account_vod__c', ca.Child_Account_vod__c);
                m.put('Child_Account_vod__r.Name', ca.Child_Account_vod__r.Formatted_Name_vod__c);
                m.put('Child_Account_vod__r.Merck_ID_MRK__c', ca.Child_Account_vod__r.Merck_ID_MRK__c);
                m.put('Child_Account_vod__r.Preferred_Name_vod__c', ca.Child_Account_vod__r.Formatted_Name_vod__c);
                m.put('Child_Account_vod__r.IsPersonAccount', ca.Child_Account_vod__r.IsPersonAccount + '');
                
                results.add(m);
                results.addAll( getChildAccountsFor(ca.Child_Account_vod__c) );
            }
        } catch (Exception e) {
            // TODO: handle / optimize / batch account queries
        }
        return results;
    }
    
}