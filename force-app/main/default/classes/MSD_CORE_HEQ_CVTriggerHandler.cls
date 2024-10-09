/**
* @File Name : MSD_CORE_HEQ_CVTriggerHandler.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : October 6, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 6, 2024 |   | Initial Version
**/

public class MSD_CORE_HEQ_CVTriggerHandler implements MSD_CORE_ITrigger {

	public MSD_CORE_HEQ_CVTriggerHandler() {}
	public void bulkBefore() {}
	public void bulkAfter() {}
	public void beforeInsert(SObject so) {}
	public void beforeUpdate(SObject oldSo, SObject so) {}
	public void beforeDelete(SObject so) {}
	public void afterInsert(SObject so) {
        ContentVersion cv = (ContentVersion)so;
    }
	public void afterUpdate(SObject oldSo, SObject so) {

		
	    if ( true ) {
	    	String notifyEmailListString = MSD_CORE_Setting.getString('LIST_MANAGER', 'notifyEmailList');
	    	List<String> notifyEmailList = notifyEmailListString.split(';');

            Messaging.reserveSingleEmailCapacity(notifyEmailList.size());
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            mail.setToAddresses(notifyEmailList);
            mail.setSenderDisplayName( MSD_CORE_Setting.getString('LIST_MANAGER', 'notifySenderDisplayName') );
            mail.setBccSender(false);
            mail.setUseSignature(false);

			String subject = '';
			subject = subject.replace('{{MSD_CORE_Name__c}}', '');
			mail.setSubject(subject);

			String body = '';
			body = body.replace('{{MSD_CORE_Name__c}}', '');
            mail.setPlainTextBody(body);

            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
	    }


	}
	public void afterDelete(SObject so) {}
	public void andFinally() {}
}