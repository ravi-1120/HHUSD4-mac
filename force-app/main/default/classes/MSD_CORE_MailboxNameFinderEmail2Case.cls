/**Author: Chetan Kaushik
   Description: Apex class used as an apex action in flow to populate the corresponding mailbox name, by using the to address from Email Message Record
   Release: 24R3.0
   Project: Email2Case implementation
   Last Modified: 07/30/2024 by Chetan Kaushik
**/

public class MSD_CORE_MailboxNameFinderEmail2Case {
    @InvocableMethod(label='Get Mailbox Name' description='Returns the mailbox name for a given email address')
    public static List<String> getMailboxName(List<String> emailAddresses) {
        List<String> mailboxNames = new List<String>();
        
        for(String email : emailAddresses) {
            Email_Service_Mailbox__mdt mailbox = [SELECT Mailbox_Name__c 
                                                  FROM Email_Service_Mailbox__mdt 
                                                  WHERE Email_Address__c = :email 
                                                  LIMIT 1];
            
            if(mailbox != null) {
                mailboxNames.add(mailbox.Mailbox_Name__c);
            } else {
                mailboxNames.add('Unknown Mailbox');
            }
        }
        
        return mailboxNames;
    }
}