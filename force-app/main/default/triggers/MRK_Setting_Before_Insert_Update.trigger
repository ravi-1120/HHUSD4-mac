trigger MRK_Setting_Before_Insert_Update on Setting_MRK__c (before insert, before update) {

	/*
	 BMP - 7/31/13
	 ensure settings of type JSON are well-formed JSON by trying to parse/
	 deserialize	 
	*/

	for (Setting_MRK__c s : Trigger.new) {

		// ensure settings of type JSON are well-formed JSON
		if ( (s.Type_MRK__c == 'JSON') && (s.Text_MRK__c != null) && (s.Text_MRK__c != '')) {
			try {
				// try to parse
				JSON.deserializeUntyped(s.Text_MRK__c);
			} catch (Exception e) {
				s.Text_MRK__c.addError('Invalid JSON\n\n' + e.getMessage() + '\n\n' + e.getStackTraceString());
			}
		}
	}

}