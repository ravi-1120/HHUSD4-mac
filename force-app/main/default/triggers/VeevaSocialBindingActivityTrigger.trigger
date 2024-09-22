trigger VeevaSocialBindingActivityTrigger on Social_Binding_Activity_vod__c (before update) {
    VeevaSocialBindingActivityHandler sbaHandler = new VeevaSocialBindingActivityHandler();
    sbaHandler.handleTrigger();
}