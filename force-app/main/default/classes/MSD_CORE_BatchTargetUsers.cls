/**
The class is identifying target records based on communication Ids, processing these records in batches by applying certain criteria,
* Finally triggering another batch class to send notification emails to the users associated with each communication Id.
*/
public class MSD_CORE_BatchTargetUsers implements Database.Batchable <SObject>,Database.Stateful {
    List<Id> myCommIds = new List<Id>();
    private String targetRecordsQuery;
    Map<Id,Set<Id>>	CommunicationUsersMap = new Map<Id,set<Id>>();
    
    public MSD_CORE_BatchTargetUsers(List<Id> CommId){
        this.myCommIds = CommId;
        targetRecordsQuery = 'Select Id,Name,Communication_MRK__c,Product_MRK__c,Profile_MRK__c,Team_MRK__c,Type_MRK__c,Released_Status__c '
            +'FROM Communication_Target_MRK__c WHERE Communication_MRK__c IN: myCommIds';
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(targetRecordsQuery);
    }
    
    public void execute(Database.BatchableContext bc, List<sObject> targetRecords) {
        try {
            if(targetRecords!=null && targetRecords.size()>0){
                sObject targetRecord = targetRecords[0];
                Set<String> teamNames = new Set<String>();
                Set<String> productNames = new Set<String>();
                Set<String> selectedProfiles = new Set<String>();
                if(!String.isBlank(String.valueOf(targetRecord.get('Team_MRK__c')))){
                    teamNames = new Set<String>((String.valueOf(targetRecord.get('Team_MRK__c'))).split(';'));
                }
                if(!String.isBlank(String.valueOf(targetRecord.get('Product_MRK__c')))){
                    productNames = new Set<String>((String.valueOf(targetRecord.get('Product_MRK__c'))).split(';'));
                }
                if(!String.isBlank(String.valueOf(targetRecord.get('Profile_MRK__c')))){
                    selectedProfiles = new Set<String>((String.valueOf(targetRecord.get('Profile_MRK__c'))).split(';'));
                }
                List<User_Sales_Team_MRK__c> matchingTeams = new List<User_Sales_Team_MRK__c>();
                String userSalesTeamQuery = 'SELECT Id,User_MRK__c,User_MRK__r.Name,User_MRK__r.Profile.Name,Sales_Team_MRK__c,Sales_Team_MRK__r.Name FROM User_Sales_Team_MRK__c WHERE Sales_Team_MRK__r.Name IN: teamNames AND User_MRK__r.Profile.Name IN: selectedProfiles';
                matchingTeams = Database.query(userSalesTeamQuery);
                if(matchingTeams.size()>0){
                    set<Id> users = new set<Id>();
                    for(User_Sales_Team_MRK__c team : matchingTeams){
                        users.add(team.User_MRK__c);
                    }
                    List<My_Setup_Products_vod__c> matchingProducts = new List<My_Setup_Products_vod__c>();
                    String matchProductsQuery = 'SELECT Id,Product_vod__c,Product_vod__r.Name, OwnerId FROM My_Setup_Products_vod__c WHERE Product_vod__r.Name IN: productNames AND OwnerId IN: users';
                    matchingProducts = Database.query(matchProductsQuery);
                    if(matchingProducts.size()>0){
                        set<Id> commonUsers = new set<Id>();
                        for(My_Setup_Products_vod__c product : matchingProducts){
                            commonUsers.add(product.OwnerId);
                        }
                        if(CommunicationUsersMap.containsKey((Id)targetRecord.get('Communication_MRK__c'))){
                            CommunicationUsersMap.get((Id)targetRecord.get('Communication_MRK__c')).addAll(commonUsers);
                        }else{
                            CommunicationUsersMap.put((Id)targetRecord.get('Communication_MRK__c'),commonUsers);
                        }
                    }
                }
            }
        } catch (Exception e) {
            logException(e, 'MSD_CORE_TargetUsers', 'execute','', 'Error');
            System.debug('An exception occurred in execute: ' + e.getMessage());
        }
    }
    public void finish(Database.BatchableContext BC) {
        try{
            for(Id myComm : myCommIds){
                if(CommunicationUsersMap.containsKey(myComm)){
                    if((CommunicationUsersMap.get(myComm)).size()>0){
                        Database.executeBatch(new MSD_CORE_BatchSendingEmails(myComm,CommunicationUsersMap.get(myComm)),50);
                    }
                }
            }
        } catch (Exception e) {
            logException(e, 'MSD_CORE_TargetUsers', 'finish','', 'Error');
            System.debug('An exception occurred in finish: ' + e.getMessage());
        }
    } 
    private void logException(Exception ex, String className, String methodName, String recordId, String logType) {
        MSD_CORE_ExceptionLogs.logException(ex, className, methodName, recordId, logType);
    }
}