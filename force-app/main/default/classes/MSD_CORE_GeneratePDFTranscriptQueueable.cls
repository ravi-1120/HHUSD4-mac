public with sharing class MSD_CORE_GeneratePDFTranscriptQueueable  implements Queueable, Database.AllowsCallouts {

    private List<Event> eventList;
    private List<String> caseIds;
    private Map<String, Case> casesMap;

    public MSD_CORE_GeneratePDFTranscriptQueueable(List<Event> events) {
        this.eventList = events;
        caseIds = new List<String>();
        casesMap = new Map<String, Case>();
        for (Event e : eventList) {
            if (e.WhatId != null) {
                Schema.sObjectType whatIdObjectType = e.WhatId.getSObjectType();
                if (whatIdObjectType != null && whatIdObjectType == (Case.SObjectType)) {
                    caseIds.add(e.WhatId);
                }
            }
        }
        List<Case> cases = [SELECT Id FROM Case WHERE Id = :caseIds];
        casesMap = new Map<String, Case>(cases);
    }

    public void execute(QueueableContext param1) {
        if(casesMap != null && !casesMap.isEmpty()) {
            for (Event e : eventList) {
                PageReference pageRef = Page.MSD_CORE_GeneratePDFChatTranscript;
                pageRef.getParameters().put('id', e.Id);
                pageRef.setRedirect(false);
                Blob body;
                try {
                    //body = pageRef.getContent();
                     body = pageRef.getContentAsPDF();
                } catch (VisualforceException exc) {
                    body = Blob.valueOf('Some Text');
                }
                String fileTitle = 'Chat Transcript';
                if (casesMap.containsKey(e.WhatId)) {
                    fileTitle = casesMap.get(e.WhatId).Id + '-' + fileTitle;
                }
                ContentVersion cv = new ContentVersion();
                cv.ContentLocation = 'S';
                cv.VersionData = body;
                cv.Title = fileTitle;
                cv.PathOnClient = 'chatTranscript.pdf';
                cv.IsMajorVersion = true;
                insert cv;
                Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.LinkedEntityId = e.WhatId;
                cdl.ContentDocumentId = conDocId;
                cdl.ShareType = 'V';
                insert cdl;
            }
        }
    }
}