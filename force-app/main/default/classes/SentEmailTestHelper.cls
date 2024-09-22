public class SentEmailTestHelper {
    public static User[] createSimpleTestUsers(Integer count) {

        User[] users = new User[count];

        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];

        for (Integer i = 0; i < count; i++) {
            String userStr = 'user' + String.valueOf(i);

            users[i] = new User(
                UserName = userStr + '@veevacrm.test', 
                LastName = userStr,
                Email = userStr + '@veevacrm.com',
                Alias = userStr,
                LanguageLocaleKey='en_US',
                LocaleSidKey='en_US',
                TimeZoneSidKey='America/Chicago',
                ProfileId = p.Id,
                EmailEncodingKey='UTF-8'
            );
        }

        return users;
    }

    public static Account[] createAccounts(Integer count) {
        Account[] accounts = new Account[count];
        for (Integer i = 0; i < count; i++) {
            accounts[i] = new Account(Name = 'account' + String.valueOf(i));
        }
        return accounts;
    }

    public static Key_Message_vod__c[] createKeyMessages(Integer count) {
        Key_Message_vod__c[] keyMessages = new Key_Message_vod__c[count];
        for (Integer i = 0; i < count; i++) {
            keyMessages[i] = new Key_Message_vod__c(
                Active_vod__c = true,
                Name = 'keymessage' + String.valueOf(i)
            );
        }
        return keyMessages;
    }

    public static Approved_Document_vod__c[] createApprovedDocuments(Integer count) {
        Approved_Document_vod__c[] docs = new Approved_Document_vod__c[count];
        for (Integer i = 0; i < count; i++) {
            docs[i] = new Approved_Document_vod__c(
                Name = 'approveddocument' + String.valueOf(i),
                Email_HTML_1_vod__c = '<html><body>test</body></html>'
            );
        }
        return docs;
    }

    public static Sent_Email_vod__c createSentEmailWithFields(Id accountId, Id templateId, String status) {
        Sent_Email_vod__c email = new Sent_Email_vod__c();
        if (accountId != null) {
            email.Account_vod__c = accountId;
        }
        if (templateId != null) {
            email.Approved_Email_Template_vod__c = templateId;
        }
        if (status != null) {
            email.Status_vod__c = status;
        } else {
            email.Status_vod__c = 'Draft_vod';
        }
        return email;
    }

    public static Veeva_Distribution_vod__c[] createVeevaDistributions(Integer count) {
        Veeva_Distribution_vod__c[] vds = new Veeva_Distribution_vod__c[count];
        for (Integer i = 0; i < count; i++) {
            vds[i] = new Veeva_Distribution_vod__c();
        }
        return vds;
    }
}