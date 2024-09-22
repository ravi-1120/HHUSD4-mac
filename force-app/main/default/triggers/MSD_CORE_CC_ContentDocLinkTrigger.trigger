trigger MSD_CORE_CC_ContentDocLinkTrigger on ContentDocumentLink (after insert) {
    Schema.DescribeSobjectResult r = Knowledge__kav.getSobjectType().getDescribe();
    String keyPrefix = r.getKeyPrefix();

    List<ContentDocumentLink> cdLinkList = new List<ContentDocumentLink>();
    for (ContentDocumentLink cdl : trigger.new) {
        if((cdl.LinkedEntityId+'').startsWith(keyPrefix))
        {
            cdLinkList.add(new ContentDocumentLink(ContentDocumentId = cdl.ContentDocumentId, 
                                                    LinkedEntityId = UserInfo.getUserId(), 
                                                    ShareType = 'C', 
                                                    Visibility = 'AllUsers'));
        }
    }
    
    if(cdLinkList.size() > 0)
        database.insert(cdLinkList, false);
}