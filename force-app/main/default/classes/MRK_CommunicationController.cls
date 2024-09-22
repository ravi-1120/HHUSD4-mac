public class MRK_CommunicationController {

    private Map<string,string> pageParams = ApexPages.currentPage().getParameters();
    public Boolean functionalityEnabled {
        get {
            return MRK_UserInfo.communicationFunctionalityEnabledForUser( UserInfo.getUserId() );
        }
    }
    
    public List<ContentDocumentLink> GetFiles {get;set;}  //21R1.1 Code added

    public MRK_CommunicationController() {
     
     //21R1.1 Code start
       String CommId = pageParams.get('id');
       GetFiles = [SELECT Id, ContentDocumentId,LinkedEntityId, ContentDocument.LatestPublishedVersionId, ContentDocument.LatestPublishedVersion.Title
       FROM ContentDocumentLink WHERE LinkedEntityId = :CommId];
     //21R1.1 Code end
      
    }
    
    public Map<String, Object> getSettings() {
        return MRK_Setting.getValues(MRK_CommunicationServices.SETTING_NAME);
    }

  public Map<String, Object> getCommunication() {
    String objId = pageParams.get('id');
    Communication_MRK__c comm = null;
    Map<string,object> commData = null;
        try {
        commData = MRK_CommunicationServices.getCommunicationForUser( UserInfo.getUserId(), objId );
        if (commData != null) {
            String baseSoqlTemplate = MRK_Setting.getString(MRK_CommunicationServices.SETTING_NAME, 'communication base soql template');
            String soql = string.format(baseSoqlTemplate, new String[]{'\'' + objId + '\''});
                comm = (Communication_MRK__c)Database.query(soql)[0];
        }
    } catch (Exception e) { /* eat exception */ }
    
        String audienceImageURL = (commData != null) ? MRK_CommunicationServices.getAudienceImageURL((String)commData.get('audience')) : ('');

    return new Map<String,Object>{'available' => (comm != null), 'communication' => comm, 'audience' => ((commData != null) ? commData.get('audience') : ''), 'audienceImageURL' => audienceImageURL};
  } 

}