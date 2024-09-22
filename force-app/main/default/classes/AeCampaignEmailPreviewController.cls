public with sharing class AeCampaignEmailPreviewController {
  @AuraEnabled
  public static List<String> getCampaignEmailPreviewData(Id recordId){
    try {
      Campaign_Activity_vod__c campaignActivity = [SELECT Id, Name, Email_Template_vod__c, Email_Fragments_vod__c, Email_Fragment_Vault_Doc_IDs_vod__c FROM Campaign_Activity_vod__c WHERE Id = :recordId WITH SECURITY_ENFORCED];
      return buildCampaignEmailPreviewDataFromCampaignActivity(campaignActivity);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @testVisible private static List<String> buildCampaignEmailPreviewDataFromCampaignActivity(Campaign_Activity_vod__c campaignActivity) {
    try {
      List<String> fields;
      if(campaignActivity != null) {
        List<Approved_Document_vod__c> approvedDocuments = getDocuments(campaignActivity);
        fields = buildHtml(approvedDocuments, campaignActivity);
      }
      return fields;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  private static List<Approved_Document_vod__c> getDocuments(Campaign_Activity_vod__c campaignActivity) {
    Set<Id> approvedDocumentIds = new Set<Id>();
    List<Id> fragments = new List<Id>();
    List<Approved_Document_vod__c> approvedDocuments;
    for(String fragmentId : getFragmentIdsFromCampaignActivity(campaignActivity)) {
      fragments.add(Id.valueOf(fragmentId));
    }

    if(!String.isBlank(campaignActivity.Email_Template_vod__c)) {
      approvedDocumentIds.add(campaignActivity.Email_Template_vod__c);
      approvedDocumentIds.addAll(fragments);
      approvedDocuments = [SELECT Id, Name, Document_ID_vod__c, Email_HTML_1_vod__c, Email_Template_Fragment_HTML_vod__c, Email_Fragment_HTML_vod__c FROM Approved_Document_vod__c WHERE Id IN :approvedDocumentIds WITH SECURITY_ENFORCED];
    }
    else {
      approvedDocuments = new List<Approved_Document_vod__c>();
    }
    
    return approvedDocuments;
  }

  private static List<string> buildHtml(List<Approved_Document_vod__c> approvedDocuments, Campaign_Activity_vod__c campaignActivity) {
    String html = '';
    List<String> fields = new List<String>();
    Approved_Document_vod__c template;
    List<Approved_Document_vod__c> fragments = new List<Approved_Document_vod__c>();

    for(Approved_Document_vod__c document : approvedDocuments) {
      if(document.Id == campaignActivity.Email_Template_vod__c) {
        template = document;
      }
      else {
        fragments.add(document);
      }
    }
    if(template != null) {
      html = template.Email_HTML_1_vod__c;
      if(!String.isBlank(campaignActivity.Email_Fragment_Vault_Doc_IDs_vod__c)) {
        // Regex pattern matching {{insertEmailFragments}}, {{insertEmailFragments[max]}} and {{insertEmailFragments[min,max]}} tokens
        String regex = '\\{\\{insertEmailFragments(\\[(\\d+)(,(\\d+))?\\])?\\}\\}';
        html = html.replaceFirst(regex, Matcher.quoteReplacement(buildFragmentHtml(fragments, campaignActivity)));
      }

      String footerHtml = '';
      if(!String.isBlank(template.Email_Template_Fragment_HTML_vod__c)) {
        footerHtml = template.Email_Template_Fragment_HTML_vod__c;
      }
      html = html.replace('{{emailTemplateFragment}}', footerHtml);
      fields.add(html);
      fields.add(template.Name);
      fields.add(template.Document_ID_vod__c);
    }
    return fields;
  }

  private static string buildFragmentHtml(List<Approved_Document_vod__c> fragments, Campaign_Activity_vod__c campaignActivity) {
    String fragmentHtml = '';
    for(String fragmentId : getFragmentIdsFromCampaignActivity(campaignActivity)) {
      for(Approved_Document_vod__c fragment : fragments) {
        if(fragment.Id == Id.valueOf(fragmentId)) {
          fragmentHtml += fragment.Email_Fragment_HTML_vod__c;
        }
      }
    }
    return fragmentHtml;
  }

  private static List<String> getFragmentIdsFromCampaignActivity(Campaign_Activity_vod__c campaignActivity) {
    List<String> fragmentIds;
    if(!String.isBlank(campaignActivity.Email_Fragments_vod__c)) {
      fragmentIds = campaignActivity.Email_Fragments_vod__c.split(',');
    }
    else {
      fragmentIds = new List<String>();
    }
    return fragmentIds;
  }
}