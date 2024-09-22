/**
* This class will send notification emails in batches to users based on the communication Id and a set of user Ids.
* It dynamically retrieves email-related parameters, creates contacts, sends emails using a specified email template, attaches files to the emails, 
* Creating Target_user__c records based on the identified users and logs the results of the email sending process.

**/

public class MSD_CORE_BatchSendingEmails implements Database.Batchable<SObject>,Database.Stateful {
    public Set<Id> userIds;
    public Id myCommId;
    public String userQuery;
    String displayName = 'uscafe@merck.com';
    String emailAddress = 'uscafe@merck.com';
    String orgEmail;
    Communication_MRK__c myComm;
    String emailBody;
    String subject;
    List<OrgWideEmailAddress> orgWideEmails = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = :displayName AND Address = :emailAddress];
    public MSD_CORE_BatchSendingEmails(Id communicationId,Set<Id> users){
        this.myCommId = communicationId;
        this.userIds = users;
        if(orgWideEmails!=null){
            orgEmail=String.valueOf(orgWideEmails[0].Id);
        }
        myComm = [SELECT Id, Title_MRK__c, Status_MRK__c, Effective_Date_MRK__c, Category_MRK__c, 
                                                             Source_MRK__c, Time_to_Complete_MRK__c, Expiration_Date_MRK__c, Priority_MRK__c, Summary_MRK__c, Body_MRK__c, Content_Owner_MRK__c 
                                                             FROM Communication_MRK__c WHERE Id = :myCommId];
        subject = 'New Communication: ' + myComm.Title_MRK__c;
        emailBody = '<!DOCTYPE html>' +
                              '<html>' +
                              '<head>' +
                              '<style>' +
                              'h2.title-color { color: #007A73; }' +
                              '</style>' +
                              '<h2 class="title-color">' + myComm.Title_MRK__c + '</h2>' +
                              '<br/>' +
                              '</head>' +
                              '<body>' +
                              '<table style="text-align:left;width:100%;">' +
                              '<tr>' +
                              '<td style="width:50%;"><b style="color: #155767;">Status:</b> ' + myComm.Status_MRK__c + '</td>' +
                              '<td style="width:50%;"><b style="color: #155767;">Category:</b> ' + myComm.Category_MRK__c + '</td>' +
                              '</tr>' +
                              '<tr>' +
                              '<td><b style="color: #155767;">Release Date:</b> ' + (myComm.Effective_Date_MRK__c).format('MM/dd/yyyy hh:mm a') + '</td>' +
                              '<td><b style="color: #155767;">Priority:</b> ' + myComm.Priority_MRK__c + '</td>' +
                              '</tr>' +
                              '<tr>' +
                              '<td><b style="color: #155767;">Source/Product:</b> ' + myComm.Source_MRK__c + '</td>' +
                              '<td><b style="color: #155767;">Expiration Date:</b> ' + (myComm.Expiration_Date_MRK__c).format() + '</td>' +
                              '</tr>' +
                              '<tr>' +
                              '<td><b style="color: #155767;">Time of Completion:</b> ' + myComm.Time_to_Complete_MRK__c + '</td>' +
                              '<td><b style="color: #155767;">Content Owner:</b> ' + myComm.Content_Owner_MRK__c + '</td>' +
                              '</tr>' +
           					  '<tr>' +
                              '<td colspan="2"><b style="color: #155767;">Summary:</b> ' + myComm.Summary_MRK__c + '</td>' +
                              '</tr>' +
                              '<tr>' +
                              '<td colspan="2"><b style="color: #155767;">Body:</b> ' + myComm.Body_MRK__c + '</td>' +
                              '</tr>' +
                              '</table>' +
                              '</body>' +
                              '</html>'; 
        userQuery = 'SELECT Id,Email FROM User WHERE Id IN :userIds';
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(userQuery);
    }
    
    public void execute(Database.BatchableContext bc, List<User> userRecords) {
        try {
            if(!String.isBlank(orgEmail) && userRecords!=null && userRecords.size()>0){
                List<ContentDocumentLink> documentLinks = [SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.LatestPublishedVersion.VersionData, ContentDocument.LatestPublishedVersion.FileExtension FROM ContentDocumentLink WHERE LinkedEntityId = :myCommId];
                List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
                for (ContentDocumentLink docLink : documentLinks) {
                    Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                    attachment.setFileName(docLink.ContentDocument.Title + '.' + docLink.ContentDocument.LatestPublishedVersion.FileExtension);
                    attachment.setBody(docLink.ContentDocument.LatestPublishedVersion.VersionData);
                    emailAttachments.add(attachment);
                }
                List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
                List<MSD_CORE_Target_Users__c> targetUsersList = new List<MSD_CORE_Target_Users__c>();
                for (User usr : userRecords) {
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    email.setTargetObjectId(usr.Id);
                    email.setHtmlBody(emailBody);
                    email.setSaveAsActivity(false);
                    email.setSubject(subject);
                    email.setOrgWideEmailAddressId(orgWideEmails[0].Id);
                    email.setFileAttachments(emailAttachments);
                    emailMessages.add(email);    
                    MSD_CORE_Target_Users__c targetUser = new MSD_CORE_Target_Users__c(User__c = usr.Id, MyComm__c = myCommId,Email__c =usr.Email);
                    targetUsersList.add(targetUser);
                }
                if(emailMessages.size()>0){
                  List<Messaging.SendEmailResult> emailResults = Messaging.sendEmail(emailMessages); 
                }
                if(targetUsersList.size()>0){
                    insert targetUsersList;
                }
            }
        } catch (Exception e) {
            logException(e, 'MSD_CORE_BatchEmails', 'execute', '' , 'Error');
            System.debug('An exception occurred in execute: ' + e.getMessage());
        }
    }
    public void finish(Database.BatchableContext BC) {} 
    
    private void logException(Exception ex, String className, String methodName, String recordId, String logType) {
        MSD_CORE_ExceptionLogs.logException(ex, className, methodName, recordId, logType);
    }
}