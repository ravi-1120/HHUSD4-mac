trigger MSD_CORE_CC_ContentDocTrigger on ContentDocument (after insert) {
    /*for(ContentDocument objCD : Trigger.New){
        Decimal mb = Decimal.ValueOf(objCD.ContentSize);
        System.debug(objCD.ContentSize);
		mb = mb.divide((1024*1024),2);
        System.debug(mb);
        if(mb > 21){
            objCD.addError('Cannot add');
        }
    }*/
}