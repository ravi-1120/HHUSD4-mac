trigger MRK_CFE_Coverage_After on CFE_Coverage_MRK__c (after insert, after update, after delete) {
    MRK_CFE_Alert_Settings__c settings = MRK_CFE_Alert_Settings__c.getValues('Default');
    Boolean sendAlerts = settings.Send_CFE_Alerts__c;
    List<CFE_Coverage_MRK__c> cfes = new List<CFE_Coverage_MRK__c>();
    
    if (!sendAlerts) {
        system.debug(Logginglevel.INFO,'jk - not sending alerts due to custom setting');
    } else {
        system.debug(Logginglevel.INFO,'jk - creating alerts');
        List<Id> acctIds = new List<Id>();
        List<Id> userIds = new List<Id>();
        if (trigger.IsInsert || trigger.IsUpdate) {
            for (CFE_Coverage_MRK__c cfe : trigger.new) {
                acctIds.add(cfe.Account_MRK__c);
                userIds.add(cfe.User_MRK__c);
                cfes.add(cfe);
            }
        } else {
            for (CFE_Coverage_MRK__c cfe : trigger.old) {
                acctIds.add(cfe.Account_MRK__c);
                userIds.add(cfe.User_MRK__c);
                cfes.add(cfe);
            }
        }
        
        

        
        Map<ID, Account> accounts = new Map<ID, Account>([SELECT Id, Name FROM Account WHERE Id IN :acctIds]);
        Map<ID, User> users = new Map<ID, User>([SELECT Id, Name FROM User WHERE Id IN :userIds]);
        
        List<CFE_Coverage_MRK__c> existingCFEs = New List<CFE_Coverage_MRK__c>();
        existingCFEs = [SELECT Account_MRK__c,Approval_Status_MRK__c,Call_Deck_Status_MRK__c,Id,Name_MRK__c,Phone_Number_MRK__c,
                               Sales_Team_MRK__c,Source_MRK__c,Territory_MRK__c,Title_MRK__c,User_MRK__c 
                        FROM CFE_Coverage_MRK__c
                        WHERE Account_MRK__c IN :acctIds];
        
        List<Alert_vod__c> alerts = new List<Alert_vod__c>();
        String name = '';
        String accountName = '';
        for (CFE_Coverage_MRK__c cfe : cfes) {
            for (CFE_Coverage_MRK__c existingCFE : existingCFEs) {
                if (existingCFE.Account_MRK__c == cfe.Account_MRK__c && existingCFE.User_MRK__c != cfe.User_MRK__c) {
                    //found another CFE that is not assigned to this user. Create an alert
                    Alert_vod__c alert = new Alert_vod__c();
                    alert.Activation_Date_vod__c = Date.today();
                    alert.Expiration_Date_vod__c = Date.today().addDays(7);
                    alert.Dismissible_vod__c = true;
                    alert.Link_Reference_vod__c = cfe.Account_MRK__c;
                    alert.Priority_vod__c = 'Normal';
                    alert.Public_vod__c = false;
                    alert.OwnerId = existingCFE.User_MRK__c;
                    //alert.Name = accounts.get(cfe.Account_MRK__c).Name;
                    String alertTitle = '';
                    Datetime startDate = datetime.newInstance(cfe.Alignment_Start_Date_MRK__c.year(), cfe.Alignment_Start_Date_MRK__c.month(),cfe.Alignment_Start_Date_MRK__c.day());
                    Datetime endDate = datetime.newInstance(cfe.Alignment_End_Date_MRK__c.year(), cfe.Alignment_End_Date_MRK__c.month(),cfe.Alignment_End_Date_MRK__c.day());

                    
                    if (trigger.isInsert) {
                        //title - user name aligned to CFE coverage for Account Name
                        //text - Account name <br> title br user name <br> cal deck status <br> startdate br end date br territory br phone number br email br 
                      //<Account name> has been <Call Deck Status>+"ly" aligned to <Territory> <Rep Name>
                      if (accounts.get(cfe.Account_MRK__c).Name.length() > 40) {
                          accountName = accounts.get(cfe.Account_MRK__c).Name.subString(0,36) + ' ...';
                      } else {
                          accountName = accounts.get(cfe.Account_MRK__c).Name;
                      }
                      
                      name = accountName + ' has been ' + cfe.Call_Deck_Status_MRK__c + 'ly aligned to ' + cfe.Territory_MRK__c + ' ' + users.get(cfe.User_MRK__c).Name;
                      
                      if (name.length() > 80) {
                          name = name.substring(0,76) + ' ...';
                      }
                      
                      alert.Name = name;
                      
                      /*
                      <Alert Title for Adds> line break
                        <Territory> line break
                        <Sales Team> line break
                        <Alignment Start Date> line break
                        <Alignment End Date> line break
                      */

                      
                      alertTitle  = alert.Name;
                      alertTitle  += '\r\n';
                      alertTitle  += cfe.Territory_MRK__c;
                      alertTitle  += '\r\n';
                      alertTitle  += cfe.Sales_Team_MRK__c;
                      alertTitle  += '\r\n';
                      alertTitle  += 'Alignment Start Date: ' + startDate.format('M/d/yyyy');
                      alertTitle  += '\r\n';
                      alertTitle  += 'Alignment End Date: ' + endDate.format('M/d/yyyy');
                      alert.Alert_Text_vod__c = alertTitle;
                      
                    } else if (trigger.isUpdate) {
                      //<Account name> alignment has been updated for <Territory> <Rep Name>
                      
                      if (accounts.get(cfe.Account_MRK__c).Name.length() > 40) {
                          accountName = accounts.get(cfe.Account_MRK__c).Name.subString(0,36) + ' ...';
                      } else {
                          accountName = accounts.get(cfe.Account_MRK__c).Name;
                      }
                      
                      name = accountName + ' alignment has been updated for ' + cfe.Territory_MRK__c + ' ' + users.get(cfe.User_MRK__c).Name;
                      
                      if (name.length() > 80) {
                          name = name.substring(0,76) + ' ...';
                      }
                      
                      alert.Name = name;
                      
                      
                      /*
                      <Alert Title for Update> line break
                        <Territory> line break
                        <Sales Team> line break
                        <Alignment Start Date> line break
                        <Alignment End Date> line break
                      */
                      alertTitle  = alert.Name;
                      alertTitle  += '\r\n';
                      alertTitle  += cfe.Sales_Team_MRK__c;
                      alertTitle  += '\r\n';
                      alertTitle  += 'Alignment Start Date: ' + startDate.format('M/d/yyyy');
                      alertTitle  += '\r\n';
                      alertTitle  += 'Alignment End Date: ' + endDate.format('M/d/yyyy');
                      alert.Alert_Text_vod__c = alertTitle;                    
                    } else if (trigger.isDelete) {
                        //title - user name removed from CFE coverage for account. name
                      //<Account name> alignment has been removed from <Territory> <Rep Name>
                      
                      if (accounts.get(cfe.Account_MRK__c).Name.length() > 40) {
                          accountName = accounts.get(cfe.Account_MRK__c).Name.subString(0,36) + ' ...';
                      } else {
                          accountName = accounts.get(cfe.Account_MRK__c).Name;
                      }
                      
                      name = accountName + ' alignment has been removed from ' + cfe.Territory_MRK__c + ' ' + users.get(cfe.User_MRK__c).Name;
                     
                      if (name.length() > 80) {
                          name = name.substring(0,76) + ' ...';
                      }
                      
                      alert.Name = name;                     
                     
                     /*
                     <Alert Title for Delete> line break
                        <Territory> line break
                        <Sales Team> line break
                        <Alignment Start Date> line break
                        <Alignment End Date> line break
                     */
                      alertTitle  = alert.Name;
                      alertTitle  += '\r\n';
                      alertTitle  += cfe.Sales_Team_MRK__c;
                      alertTitle  += '\r\n';
                      alertTitle  += 'Alignment Start Date: ' + startDate.format('M/d/yyyy');
                      alertTitle  += '\r\n';
                      alertTitle  += 'Alignment End Date: ' + endDate.format('M/d/yyyy');
                      alert.Alert_Text_vod__c = alertTitle;  
                     }
                    alerts.add(alert); 
                    system.debug(LoggingLevel.INFO,'jk - adding alert: ' + alert);                    
                } 
            }
        }
        insert alerts;
        
    }
    
}