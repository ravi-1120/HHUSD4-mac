/**
 * MRK_Update_Account_Request_Before
 * Before a UAR is inserted, stamp it with the Employee ID and Merck Account Id
 *
 * @version        1.0 
 * @author         Jeff Kelso, Veeva Technical Services
 */

trigger MRK_Update_Account_Request_Before on Update_Account_Request_MRK__c (before insert) {
    List<Id> accountIds = new List<Id>();
    
    //get account Ids
    for (Update_Account_Request_MRK__c uar : trigger.new) {
        accountIds.add(uar.Account_MRK__c);
    }
    system.debug(Logginglevel.INFO,'jk - accountIds count :' + accountIds.size() + ' ' + accountIds);

    
    //get map of IDs to accounts
    User user = [SELECT Id, Merck_Employee_ID_MRK__c FROM User WHERE ID = :UserInfo.getUserId()]; 
    Map<ID, Account> accounts = new Map<ID, Account>([SELECT Id, External_ID_vod__c, Merck_ID_MRK__c FROM Account WHERE ID IN :accountIds]);
    
    system.debug(Logginglevel.INFO,'jk - user :' + user);
    system.debug(Logginglevel.INFO,'jk - accounts count :' + accounts.size() + ' ' + accounts);
    
    //set employee ID and master ID on newly created UAR
    for (Update_Account_Request_MRK__c uar : trigger.new) {
        system.debug(Logginglevel.INFO,'jk - CreatedById :' + uar.CreatedById);
        system.debug(Logginglevel.INFO,'jk - Account_MRK__c :' + uar.Account_MRK__c);
        uar.Merck_Employee_ID_MRK__c = user.Merck_Employee_ID_MRK__c;
        uar.Merck_ID_MRK__c = accounts.get(uar.Account_MRK__c).Merck_ID_MRK__c;
    }
}