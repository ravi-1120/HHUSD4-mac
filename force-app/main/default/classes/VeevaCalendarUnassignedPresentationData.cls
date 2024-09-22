public with sharing class VeevaCalendarUnassignedPresentationData extends VeevaCalendarData {
    VeevaBaseObject mcal = VeevaBaseObject.create('Multichannel_Activity_Line_vod__c');
    Boolean hasKeyMessageDescriptionFls = mcal?.getAccessibleField('Key_Message_vod__c', false, false) != null 
                                            && VeevaBaseObject.create('Key_Message_vod__c')?.getAccessibleField('Description_vod__c', false, false) != null;
    Boolean hasViewOrderFls = mcal?.getAccessibleField('View_Order_vod__c', false, false) != null;

    public VeevaCalendarUnassignedPresentationData(Datetime startDateTime, Datetime endDateTime) {
        this(startDateTime, endDateTime, UserInfo.getUserId());
    }

    public VeevaCalendarUnassignedPresentationData(Datetime startDateTime, Datetime endDateTime, Id userId) {
        super(
            new Set<String> {'OwnerId', 'CreatedById', 'Start_DateTime_vod__c', 'Total_Duration_vod__c', 'Id', 'Name', 'toLabel(RecordType.Name)', 'Saved_For_Later_vod__c', 'Call_vod__c'},
            userId, 
            'Multichannel_Activity_vod__c',
            startDateTime,
            endDateTime
        );
        Map<String, SObjectField> descr = Multichannel_Activity_vod__c.SObjectType.getDescribe().fields.getMap();
        this.fields = filterFields(descr, this.getQueryFields());
    }

    protected override List<SObject> fetchData() {
        String optionalViewOrderField = hasViewOrderFls ? ', View_Order_vod__c' : '';
        String optionalKeyMessageDescriptionField = hasKeyMessageDescriptionFls ? ', (Select Key_Message_vod__r.Description_vod__c ' + optionalViewOrderField + ' From Multichannel_Activity_Lines_vod__r)' : '';
        
        if (this.fields.size() <= 0 || !this.isFieldAccessible('Saved_For_Later_vod__c')) {
            return new List<Multichannel_Activity_vod__c>();
            
        } else {
            String userId = this.getCalendarOwnerId();
            String stmt = 'Select ' + String.join(this.fields, ',') + optionalKeyMessageDescriptionField + ' from Multichannel_Activity_vod__c ' + 'where OwnerId = :userId and RecordType.Name = \'CLM_vod\' and Saved_For_Later_vod__c = true and ' + 
                '(Start_DateTime_vod__c >= :startDate and Start_DateTime_vod__c < :endDate)';
			return Database.query(stmt);
        }
    }

    @TestVisible
    protected override List<VeevaCalendarEvent> convertToEvents(List<SObject> objectList) {
        List<Multichannel_Activity_vod__c> upList = (List<Multichannel_Activity_vod__c>) objectList;
        List<VeevaCalendarEvent> result = new List<VeevaCalendarEvent>();
        
        for (Multichannel_Activity_vod__c up : upList) {
            result.add(VeevaCalendarEventFactory.createUnassignedPresentationEvent(up, hasKeyMessageDescriptionFls, hasViewOrderFls));
        }
        return result;
    }

    public static Map<String, String> discardEvent(Id recordId) {
        Map<String, String> result = new Map<String, String>();

        try {
            Multichannel_Activity_vod__c event = [Select Id, Saved_For_Later_vod__c from Multichannel_Activity_vod__c where Id = :recordId];
            if (event != null) {
                event.Saved_For_Later_vod__c = false;
                update event;
            }
        } catch (DmlException e) {
            result.put('error', e.getDmlMessage(0));
        }
        return result;
    }
}