/**
* @File Name : MSD_CORE_HEQ_TemplateFileMDTHandler.cls
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

public class MSD_CORE_HEQ_TemplateFileMDTHandler implements MSD_CORE_ITrigger {
	public MSD_CORE_HEQ_TemplateFileMDTHandler(){}
	public void bulkBefore() {}
	public void bulkAfter() {}
	public void beforeInsert(SObject so) {}
	public void beforeUpdate(SObject oldSo, SObject so) {}
	public void beforeDelete(SObject so) {}
	public void afterDelete(SObject so) {}
	public void andFinally() {}

	/*Implement afterinsert for sending approval request notification to approver*/
	public void afterInsert(SObject so) {
		system.debug('Inside afterInsert' + so);
		MSD_CORE_HEQ_Template_File_Metadata__c templateFileMDTObj = (MSD_CORE_HEQ_Template_File_Metadata__c)so;
		if(templateFileMDTObj.MSD_CORE_Status__c == 'SUBMITTED'){
			sendEmail(templateFileMDTObj.Id, templateFileMDTObj.MSD_CORE_Job_Code__c, 'HEQ_Template_Approved_Notification_to_Author', 'joshi.ambadas@focalcxm.com', templateFileMDTObj.MSD_CORE_Status__c);
		}
	}

	/*Implement afterUpdate for sending notification to approver and to author if status is approved*/
	public void afterUpdate(SObject oldSo, SObject so) {
		system.debug('Inside afterUpdate' + so);
		MSD_CORE_HEQ_Template_File_Metadata__c templateFileMDTOldObj = (MSD_CORE_HEQ_Template_File_Metadata__c)oldSo;
		MSD_CORE_HEQ_Template_File_Metadata__c templateFileMDTNewObj = (MSD_CORE_HEQ_Template_File_Metadata__c)so;
		if(templateFileMDTOldObj.MSD_CORE_Status__c != templateFileMDTNewObj.MSD_CORE_Status__c){
			if(templateFileMDTNewObj.MSD_CORE_Status__c == 'APPROVED' || templateFileMDTNewObj.MSD_CORE_Status__c == 'REJECTED'){
				sendEmail(templateFileMDTNewObj.Id, templateFileMDTNewObj.MSD_CORE_Job_Code__c, 'HEQ_Template_Approved_Notification_to_Author', 'joshi.ambadas@focalcxm.com', templateFileMDTNewObj.MSD_CORE_Status__c);
			}
		}

	}

	/*Send email method*/
	public void sendEmail(string template_id, string job_code, string emailTemplateName, string userEmail, string status)
	{
		system.debug('Entered: ' + template_id + job_code + emailTemplateName + userEmail + status);
		String templateBuilderURL = 'https://tbt-dev.healtheq.com/personalized-resource/' + template_id + '/'+ job_code;
		EmailTemplate emailTemplateRec = [SELECT Id, Subject, Body, HtmlValue FROM EmailTemplate WHERE DeveloperName =: emailTemplateName];
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

		mail.setToAddresses(new List<String>{userEmail});
		mail.setSenderDisplayName('no-reply@HealthEQPortal.com');//replace with NPA email address
		mail.setBccSender(false);
		mail.setUseSignature(false);

		String subject = emailTemplateRec.subject.replace('{Approved}', status);
		mail.setSubject(subject);

		String htmlValue = emailTemplateRec.HtmlValue;
		htmlValue = htmlValue.replace('{linkToTBT}', templateBuilderURL);		
		mail.setHtmlBody(htmlValue);
		mail.setPlainTextBody(emailTemplateRec.Body);

		system.debug('mail object: ' + templateBuilderURL);

		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

		system.debug('Exited');
	}
}