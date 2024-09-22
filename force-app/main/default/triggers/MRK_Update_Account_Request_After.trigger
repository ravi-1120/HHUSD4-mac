/**
 * MRK_Update_Account_Request_After
 * If a UAR record has been rejected or denied, send an alert to the user
 *
 * @version        1.0 
 * @author         Jeff Kelso, Veeva Technical Services
 *
 */
trigger MRK_Update_Account_Request_After on Update_Account_Request_MRK__c (after update) {
    List<Alert_vod__c> alerts = new List<Alert_vod__c>();
    List<Id> acctIds = new List<Id>();
    
    //Get Account Names
    for (Update_Account_Request_MRK__c uar : trigger.new) {
        //Get old version of UAR
        Update_Account_Request_MRK__c oldUar = trigger.oldMap.get(uar.ID);
        if ((uar.Approval_Status_MRK__c == 'Denied' && oldUar.Approval_Status_MRK__c != 'Denied') ||
            (uar.Approval_Status_MRK__c == 'Rejected' && oldUar.Approval_Status_MRK__c != 'Rejected')) {        
            acctIds.add(uar.Account_MRK__c);        
        }
    }
    
    //get map of account to name
    Map<ID, Account> accounts = new Map<ID, Account>([SELECT Id, Name FROM Account WHERE Id IN :acctIds]);

    
    for (Update_Account_Request_MRK__c uar : trigger.new) {
        //Get old version of UAR
        Update_Account_Request_MRK__c oldUar = trigger.oldMap.get(uar.ID);

        
        if ((uar.Approval_Status_MRK__c == 'Denied' && oldUar.Approval_Status_MRK__c != 'Denied') ||
            (uar.Approval_Status_MRK__c == 'Rejected' && oldUar.Approval_Status_MRK__c != 'Rejected')) {
            //UAR has been rejected or denied, create an alert 
            Alert_vod__c alert = new Alert_vod__c();
            alert.Activation_Date_vod__c = Date.today();
            alert.Expiration_Date_vod__c = Date.today().addDays(7);
            alert.Dismissible_vod__c = true;
            alert.Priority_vod__c = 'Normal';
            alert.Public_vod__c = false;
            alert.OwnerId = uar.Requestor_MRK__c;
            alert.Update_Account_Request_MRK__c = uar.Id;
            alert.Name = 'Update Account Request Alert';
            String alertText = '';
            String reason = '';
            if (!String.isEmpty(uar.Alignment_Status_Reason_MRK__c)) {
                reason = ' ' + uar.Alignment_Status_Reason_MRK__c + '.'; 
            }
            if (!String.isEmpty(uar.Stewards_Notes_MRK__c)) {
                reason += ' ' + uar.Stewards_Notes_MRK__c + '.';
            }
            if (uar.Approval_Status_MRK__c == 'Denied' && uar.Change_Type_MRK__c == 'Alignment Request') {
                alertText = 'Alignment request for ' + accounts.get(uar.Account_MRK__c).Name + ' has been denied for the following reason:' + reason;
            } else if (uar.Approval_Status_MRK__c == 'Rejected' && uar.Change_Type_MRK__c == 'Alignment Request') {
                alertText = 'Alignment request for ' + accounts.get(uar.Account_MRK__c).Name + ' has been rejected for the following reason:' + reason;
            } else if (uar.Approval_Status_MRK__c == 'Rejected' && uar.Change_Type_MRK__c == 'Remove from Territory') {
                alertText = 'Alignment removal request for ' + accounts.get(uar.Account_MRK__c).Name + ' has been rejected for the following reason:' + reason;
            } else if (uar.Approval_Status_MRK__c == 'Denied' && uar.Change_Type_MRK__c == 'Remove from Territory') {
                alertText = 'Alignment removal request for ' + accounts.get(uar.Account_MRK__c).Name + ' has been denied for the following reason:' + reason;
            }
            alert.Alert_Text_vod__c = alertText;
            alerts.add(alert);
        } 
    }
    insert alerts;
}