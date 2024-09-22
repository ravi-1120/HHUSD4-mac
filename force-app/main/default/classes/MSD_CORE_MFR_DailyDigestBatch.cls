global class MSD_CORE_MFR_DailyDigestBatch implements Database.Batchable<sObject>, Schedulable {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator('SELECT Id, Daily_Digest_Summary__c FROM User WHERE Daily_Digest_Summary__c = true AND IsActive = true ');
    }
    
    global void execute(Database.BatchableContext BC, List<User> scope) {
        List<MSD_CORE_Daily_Digest__c> dailyDigestList = new List<MSD_CORE_Daily_Digest__c>();
        String dailyContent = '<ul style="font-family: Invention;">';
        
        for(MSD_CORE_Catalog__c rec : [SELECT Id, Name, MSD_CORE_Meeting_Request__r.Name, MSD_CORE_Expiration_Date__c, 
                                       MSD_CORE_Meeting_Request__r.MSD_CORE_Source__c, MSD_CORE_Meeting_Request__c,
                                       MSD_CORE_Payor__r.Prior_Days_to_Expire__c 
                                       FROM MSD_CORE_Catalog__c 
                                       WHERE MSD_CORE_Payor__c IN : scope 
                                       AND MSD_CORE_Expiration_Date__c != null 
                                       AND MSD_CORE_Post_Presentation__c = true
                                       AND MSD_CORE_Meeting_Request__r.MSD_CORE_Source__c = 'MFR']) {
            
            if(rec.MSD_CORE_Payor__r.Prior_Days_to_Expire__c == '10' && rec.MSD_CORE_Expiration_Date__c == Date.today().addDays(-10)) {
                dailyContent += '<li style="margin: 0px 0 20px 0px;"><p style="font-family: Invention;">A resource from request <a href="'+Label.MSD_CORE_Domain_URL+ '/library/viewschedule?recordId=' + rec.MSD_CORE_Meeting_Request__c + '" style="color:#00857C; font-family: Invention;" target="_blank">' + rec.MSD_CORE_Meeting_Request__r.Name + '</a> is about to expire.</p></li>';
            }
            
            if(rec.MSD_CORE_Payor__r.Prior_Days_to_Expire__c == '5' && rec.MSD_CORE_Expiration_Date__c == Date.today().addDays(-5)) {
                dailyContent += '<li style="margin: 0px 0 20px 0px;"><p style="font-family: Invention;">A resource from request <a href="'+Label.MSD_CORE_Domain_URL+ '/library/viewschedule?recordId=' + rec.MSD_CORE_Meeting_Request__c + '" style="color:#00857C; font-family: Invention;" target="_blank">' + rec.MSD_CORE_Meeting_Request__r.Name + '</a> is about to expire.</p></li>';
            }
            
            if(rec.MSD_CORE_Payor__r.Prior_Days_to_Expire__c == '30' && rec.MSD_CORE_Expiration_Date__c == Date.today().addDays(-30)) {
                dailyContent += '<li style="margin: 0px 0 20px 0px;"><p style="font-family: Invention;">A resource from request <a href="'+Label.MSD_CORE_Domain_URL+ '/library/viewschedule?recordId=' + rec.MSD_CORE_Meeting_Request__c + '" style="color:#00857C; font-family: Invention;" target="_blank">' + rec.MSD_CORE_Meeting_Request__r.Name + '</a> is about to expire.</p></li>';
            }
            
            if(rec.MSD_CORE_Expiration_Date__c == Date.today().addDays(-1) || rec.MSD_CORE_Expiration_Date__c == Date.today()) {
                dailyContent += '<li style="margin: 0px 0 20px 0px;"><p style="font-family: Invention;">A resource from request <a href="'+Label.MSD_CORE_Domain_URL+ '/library/viewschedule?recordId=' + rec.MSD_CORE_Meeting_Request__c + '" style="color:#00857C; font-family: Invention;" target="_blank">' +  rec.MSD_CORE_Meeting_Request__r.Name + '</a> has expired.</p></li>';
            }
        }
        
        for(Meeting_Request_vod__c rec : [SELECT Id, Name, MSD_CORE_Status__c, MSD_CORE_S3_Link_2__c, LastModifiedDate,
                                         (SELECT Id, MSD_CORE_Meeting_Request__r.Name, MSD_CORE_Label__c 
                                          FROM Notifications__r
                                          WHERE CreatedDate >=: Datetime.now().addDays(-1))
                                          FROM Meeting_Request_vod__c 
                                          WHERE MSD_CORE_Payor__c IN : scope
                                          AND MSD_CORE_Source__c = 'MFR']) {
            
            if(rec.MSD_CORE_S3_Link_2__c != null && rec.LastModifiedDate >= Datetime.now().addDays(-1)) {
                dailyContent += '<li style="margin: 0px 0 20px 0px;"><p style="font-family: Invention;">A resource for request <a href="'+Label.MSD_CORE_Domain_URL+ '/library/viewschedule?recordId=' + rec.Id + '" style="color:#00857C; font-family: Invention;" target="_blank">' +  rec.Name + '</a> has been shared.</p>';
            }
            
            for(MSD_CORE_Notification__c notification : rec.Notifications__r) {
                if(notification.MSD_CORE_Label__c == 'Appointments') {
                    dailyContent += '<li style="margin: 0px 0 20px 0px;"><p style="font-family: Invention;">An appointment for <a href="'+Label.MSD_CORE_Domain_URL+ '/library/viewschedule?recordId=' + rec.Id + '" style="color:#00857C; font-family: Invention;" target="_blank">' +  rec.Name + '</a> has been scheduled.</p></li>';
                }
                
                if(notification.MSD_CORE_Label__c == 'Closed' && rec.MSD_CORE_Status__c == 'Rejected') {
                    dailyContent += '<li style="margin: 0px 0 20px 0px;"><p style="font-family: Invention;">Request <a href="'+Label.MSD_CORE_Domain_URL+ '/library/viewschedule?recordId=' + rec.Id + '" style="color:#00857C; font-family: Invention;" target="_blank">' +  rec.Name + '</a> for a resource has been denied.</p></li>';
                }
                
                if(notification.MSD_CORE_Label__c == 'Closed' && (rec.MSD_CORE_Status__c == 'Rejected' || rec.MSD_CORE_Status__c == 'Approved')) {
                    dailyContent += '<li style="margin: 0px 0 20px 0px;"><p style="font-family: Invention;">Request <a href="'+Label.MSD_CORE_Domain_URL+ '/library/viewschedule?recordId=' + rec.Id + '" style="color:#00857C; font-family: Invention;" target="_blank">' +  rec.Name + '</a> has been closed.</p></li>';
                }
                
                if(notification.MSD_CORE_Label__c == 'Closed' && rec.MSD_CORE_Status__c != 'Rejected' && rec.MSD_CORE_Status__c != 'Approved') {
                    dailyContent += '<li style="margin: 0px 0 20px 0px;"><p style="font-family: Invention;">Request <a href="'+Label.MSD_CORE_Domain_URL+ '/library/viewschedule?recordId=' + rec.Id + '" style="color:#00857C; font-family: Invention;" target="_blank">' +  rec.Name + '</a> has been canceled.</p></li>';
                }
                
                if(notification.MSD_CORE_Label__c == 'Pending' && rec.MSD_CORE_Status__c == 'Pending') {
                    dailyContent += '<li style="margin: 0px 0 20px 0px;"><p style="font-family: Invention;">Your request <a href="'+Label.MSD_CORE_Domain_URL+ '/library/viewschedule?recordId=' + rec.Id + '" style="color:#00857C; font-family: Invention;" target="_blank">' +  rec.Name + '</a> has been submitted.</p></li>';
                }
            }
        }
        
        dailyContent += '</ul>';
        
        if(String.isNotBlank(dailyContent)) {
            MSD_CORE_Daily_Digest__c dailyDigest = new MSD_CORE_Daily_Digest__c(MSD_CORE_Payor__c = scope[0].Id,
                                                                                MSD_CORE_Type__c = 'Daily Digest',
                                                                                MSD_CORE_Message__c = dailyContent);
                    
            dailyDigestList.add(dailyDigest);
        }
        
        if(dailyDigestList.size() > 0) {
            insert dailyDigestList;
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        System.debug('Batch Process Finished Successfully');
    }
    
    global void execute(SchedulableContext SC) {
        Database.executeBatch(new MSD_CORE_MFR_DailyDigestBatch(), 1);
    }
}