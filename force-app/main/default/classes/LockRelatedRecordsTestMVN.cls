/*
* LockRelatedRecordsTestMVN
* Created By: Roman Lerman
* Created Date: 4/8/2013
* Description: This is the test class for LockRelatedRecordsMVN
*/
@isTest
private class LockRelatedRecordsTestMVN {
	static Case cs;
	static Task task;
	static Event event;
	static Attachment attachment;
	static{
		TestDataFactoryMVN.createSettings(true);
		cs = TestDataFactoryMVN.createTestCase();

		attachment = new Attachment();
    	attachment.Name = 'Test Attachment';
    	Blob bodyBlob = Blob.valueOf('Test Attachment Body');
    	attachment.Body = bodyBlob;
        attachment.ParentId = cs.id;

        task = new Task();
        task.Subject = 'Test Subject';
        task.Description = 'Test Description';
        task.WhatId = cs.Id;
        task.Status = 'Not Started';
        task.Priority = 'Normal';

        event = new Event();
        event.Subject = 'Test Subject';
        event.Description = 'Test Description';
        event.WhatId = cs.Id;
	}
	static testMethod void testCreateAttachment(){
		cs.Status = 'Closed';
		update cs;

        try{
			insert attachment;
		}catch(Exception e){
			System.assert(e.getMessage().contains(Label.Cannot_Modify_Record_on_Closed_Case));
		}
	}
	static testMethod void testUpdateAttachment(){
		insert attachment;

		cs.Status = 'Closed';
		update cs;

		attachment.Description = 'New Description';

		try{
			update attachment;
		}catch(Exception e){
			System.assert(e.getMessage().contains(Label.Cannot_Modify_Record_on_Closed_Case));
		}
	}
	static testMethod void testDeleteAttachment(){
		insert attachment;

		cs.Status = 'Closed';
		update cs;

		try{
			delete attachment;
		}catch(Exception e){
			System.assert(e.getMessage().contains(Label.Cannot_Modify_Record_on_Closed_Case));
		}
	}
	static testMethod void testCreateTask(){
		cs.Status = 'Closed';
		update cs;

        try{
			insert task;
		}catch(Exception e){
			System.assert(e.getMessage().contains(Label.Cannot_Modify_Record_on_Closed_Case));
		}
	}
	static testMethod void testUpdateTask(){
		insert task;

		cs.Status = 'Closed';
		update cs;

		task.Description = 'New Description';

		try{
			update task;
		}catch(Exception e){
			System.assert(e.getMessage().contains(Label.Cannot_Modify_Record_on_Closed_Case));
		}
	}
	static testMethod void testDeleteTask(){
		insert task;

		cs.Status = 'Closed';
		update cs;

		try{
			delete task;
		}catch(Exception e){
			System.assert(e.getMessage().contains(Label.MSD_CORE_Cannot_Delete_Tasks));
		}
	}
}