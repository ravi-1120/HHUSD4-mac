/**
* @author - Brian Pfeil, Merck & Co.,Inc.
* @className - MSD_CORE_JobQueueGroupHandler.cls
* @description - processing logic for the MSD_CORE_Job_Queue_Group__c object
* @createdate - Sept 10th, 2015
*
*/

public class MSD_CORE_JobQueueGroupHandler implements MSD_CORE_ITrigger {

	public MSD_CORE_JobQueueGroupHandler() {}
	public void bulkBefore() {}
	public void bulkAfter() {}
	public void beforeInsert(SObject so) {}
	public void beforeUpdate(SObject oldSo, SObject so) {}
	public void beforeDelete(SObject so) {}
	public void afterInsert(SObject so) {}
	public void afterUpdate(SObject oldSo, SObject so) {
	    MSD_CORE_Job_Queue_Group__c jqg = (MSD_CORE_Job_Queue_Group__c)so;
	    String notifyNameExcludeRegex = MSD_CORE_Setting.getString('LIST_MANAGER', 'notifyNameExcludeRegex');
	    String notifyStatusIncludeRegex = MSD_CORE_Setting.getString('LIST_MANAGER', 'notifyStatusIncludeRegex');
		Boolean notifyEnabled = (MSD_CORE_Setting.getString('LIST_MANAGER', 'notifyEnabled') == 'true');
		String notifyJobQueueGroupURLTemplate = MSD_CORE_Setting.getString('LIST_MANAGER', 'notifyJobQueueGroupURLTemplate');
		String notifyEmailBodyTemplate = MSD_CORE_Setting.getString('LIST_MANAGER', 'notifyEmailBodyTemplate');
		String notifySubjectTemplate = MSD_CORE_Setting.getString('LIST_MANAGER', 'notifySubjectTemplate');
		if (!notifyEnabled) {
			return;
		}

		// exit if in the exclude filter
	    if ( Pattern.matches(notifyNameExcludeRegex, jqg.MSD_CORE_Name__c) ) {
	    	return;
	    }


	    if ( Pattern.matches(notifyStatusIncludeRegex, jqg.MSD_CORE_Status__c) ) {
	    	String notifyEmailListString = MSD_CORE_Setting.getString('LIST_MANAGER', 'notifyEmailList');
	    	List<String> notifyEmailList = notifyEmailListString.split(';');

            Messaging.reserveSingleEmailCapacity(notifyEmailList.size());
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            mail.setToAddresses(notifyEmailList);
            mail.setSenderDisplayName( MSD_CORE_Setting.getString('LIST_MANAGER', 'notifySenderDisplayName') );
            mail.setBccSender(false);
            mail.setUseSignature(false);

			String subject = notifySubjectTemplate;
			subject = subject.replace('{{MSD_CORE_Name__c}}', jqg.MSD_CORE_Name__c);
			subject = subject.replace('{{MSD_CORE_Status__c}}', jqg.MSD_CORE_Status__c);
			subject = subject.replace('{{Id}}', jqg.Id);
			mail.setSubject(subject);

			String body = notifyEmailBodyTemplate;
			body = body.replace('{{MSD_CORE_Name__c}}', jqg.MSD_CORE_Name__c);
			body = body.replace('{{MSD_CORE_Status__c}}', jqg.MSD_CORE_Status__c);
			body = body.replace('{{Id}}', jqg.Id);
            mail.setPlainTextBody(body);

            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
	    }


	}
	public void afterDelete(SObject so) {}
	public void andFinally() {}

}