public without sharing class VeevaCampaignActivityTriggerHandler extends VeevaTriggerHandler {

  protected override String sObjectType() {
    return 'Campaign_Activity_vod__c';
  }

  private List<Campaign_Activity_vod__c> oldActivities = new List<Campaign_Activity_vod__c>();
  private List<Campaign_Activity_vod__c> newActivities = new List<Campaign_Activity_vod__c>();
  private Map<Id, Campaign_Activity_vod__c> oldActivitiesMap = new Map<Id, Campaign_Activity_vod__c>();
  private Map<Id, Campaign_Activity_vod__c> newActivitiesMap = new Map<Id, Campaign_Activity_vod__c>();

  @testVisible protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap) {
    this.newActivities = (List<Campaign_Activity_vod__c>) triggerNew;
    this.oldActivities = (List<Campaign_Activity_vod__c>) triggerOld;
    this.newActivitiesMap = (Map<Id, Campaign_Activity_vod__c>) triggerNewMap;
    this.oldActivitiesMap = (Map<Id, Campaign_Activity_vod__c>) triggerOldMap;
  }

  @testVisible protected override void beforeInsert() {
    handleValidations();
  }

  @testVisible protected override void beforeUpdate() {
    handleValidations();
  }

  private void handleValidations() {
    Set<Id> campaignIds = new Set<Id>();
    Set<String> approvedDocumentIds = new Set<String>();

    for(Campaign_Activity_vod__c campaignActivity: this.newActivities) {
      campaignIds.add(campaignActivity.Campaign_vod__c);
      addTemplateAndFragments(campaignActivity, approvedDocumentIds);
    }

    Map<String, String> defaultErrorMessageMap = buildDefaultErrorMessageMap();
    Map<String, String> errorMessageMap = buildCampaignErrorMessageMap(defaultErrorMessageMap);
    
    Map<Id, Campaign_vod__c> parentMap = buildParentMap(campaignIds);
    Map<String, List<Approved_Document_vod__c>> approvedDocumentMap = buildDocumentMap(approvedDocumentIds);

    for(Campaign_Activity_vod__c campaignActivity: this.newActivities) {
      validateEmailSource(campaignActivity, errorMessageMap);
      validateDates(campaignActivity, parentMap.get(campaignActivity.Campaign_vod__c), errorMessageMap);
      validateApprovedDocuments(campaignActivity, approvedDocumentMap, errorMessageMap);
    }
  }

  private void validateApprovedDocuments(Campaign_Activity_vod__c campaignActivity, Map<String, List<Approved_Document_vod__c>> approvedDocumentMap, Map<String,String> errorMessageMap) {
    //Only perform following validations if template ID is filled in
    String templateVaultId = campaignActivity.Email_Template_Vault_Doc_ID_vod__c;
    String vaultInstance = campaignActivity.Vault_Instance_ID_vod__c;
    if(String.isBlank(templateVaultId) || String.isBlank(vaultInstance)) {
      clearSFIDs(campaignActivity);
    }
    else {
      Approved_Document_vod__c emailTemplate = validateEmailTemplate(approvedDocumentMap, campaignActivity, errorMessageMap);
      List<Approved_Document_vod__c> emailFragments = validateEmailFragments(approvedDocumentMap, campaignActivity, errorMessageMap);
      validateEmailTemplateFields(emailTemplate, campaignActivity, errorMessageMap);
      validateEmailTemplateFragmentProducts(emailTemplate, emailFragments, campaignActivity, errorMessageMap);
      stampSFIDs(emailTemplate, emailFragments, campaignActivity);
    }
  }

  private void addTemplateAndFragments(Campaign_Activity_vod__c campaignActivity, Set<String> approvedDocumentIds) {
    String templateVaultId = campaignActivity.Email_Template_Vault_Doc_ID_vod__c;
    String fragmentVaultIds = campaignActivity.Email_Fragment_Vault_Doc_IDs_vod__c;
    if(!String.isBlank(templateVaultId)) {
      approvedDocumentIds.add(templateVaultId);
      if(!String.isBlank(fragmentVaultIds)) {
        for(String fragmentVaultId : fragmentVaultIds.trim().split(',')) {
          approvedDocumentIds.add(fragmentVaultId);
        }
      }
    }
  }

  @testVisible private void stampSFIDs(Approved_Document_vod__c emailTemplate, List<Approved_Document_vod__c> emailFragments, Campaign_Activity_vod__c campaignActivity) {
    if(!campaignActivity.hasErrors()) {
      List<String> fragmentSalesforceIds = new List<String>();
      if(emailFragments != null) {
        for(Approved_Document_vod__c fragment : emailFragments) {
          fragmentSalesforceIds.add(fragment.Id);
        }
      }
      campaignActivity.Email_Template_vod__c = emailTemplate.Id;
      campaignActivity.Email_Fragments_vod__c = String.join(fragmentSalesforceIds, ',');
    }
  }

  private void clearSFIDs(Campaign_Activity_vod__c campaignActivity) {
    campaignActivity.Email_Template_vod__c = null;
    campaignActivity.Email_Fragments_vod__c = '';
  }

  @testVisible private void validateEmailTemplateFragmentProducts(Approved_Document_vod__c emailTemplate, List<Approved_Document_vod__c> emailFragments, Campaign_Activity_vod__c campaignActivity, Map<String,String> errorMessageMap) {
    if(!campaignActivity.hasErrors()) {
      Boolean allowAnyProductFragment = emailTemplate.Allow_Any_Product_Fragment_vod__c;
      List<String> fragmentIdsWithProductMismatch = new List<String>();
      if(!allowAnyProductFragment && emailFragments != null) {
        for(Approved_Document_vod__c fragment : emailFragments) {
          if(fragment.Product_vod__c != emailTemplate.Product_vod__c) {
            fragmentIdsWithProductMismatch.add(fragment.Vault_Document_ID_vod__c);
          }
        }
        if(!fragmentIdsWithProductMismatch.isEmpty()) {
          String errorMessage = errorMessageMap.get('CAMPAIGN_ACTIVITY_EMAIL_TEMPLATE_PRODUCT_RESTRICTS_FRAGMENT');
          errorMessage = addOptionalParamToMessage(errorMessage, String.join(fragmentIdsWithProductMismatch, ','));
          campaignActivity.addError('Email_Fragment_Vault_Doc_IDs_vod__c', errorMessage);
        }
      }
    }
  }

  @testVisible private List<Approved_Document_vod__c> validateEmailFragments(Map<String, List<Approved_Document_vod__c>> approvedDocumentMap, Campaign_Activity_vod__c campaignActivity, Map<String,String> errorMessageMap) {
    String fragmentVaultIds = campaignActivity.Email_Fragment_Vault_Doc_IDs_vod__c;
    List<String> fragmentVaultIdList;
    if(!String.isEmpty(fragmentVaultIds)) {
      fragmentVaultIdList = fragmentVaultIds.trim().split(',');
    }
    else {
      fragmentVaultIdList = new List<String>();
    }
    List<Approved_Document_vod__c> fragments = new List<Approved_Document_vod__c>();
    Set<String> uniqueVaultIds = new Set<String>();
    String duplicateFragment;
    List<String> fragmentsWithNotFoundError = new List<String>();
    List<String> fragmentsWithNotApprovedError = new List<String>();
    List<String> fragmentsWithInvalidRecordTypeError = new List<String>();
    Boolean fragmentsWithNoMatchError = false;
    for(String fragmentVaultId : fragmentVaultIdList) {
      if(!uniqueVaultIds.add(fragmentVaultId)) {
        duplicateFragment = fragmentVaultId;
        break;
      }
      List<Approved_Document_vod__c> documentList = approvedDocumentMap.get(fragmentVaultId);
      documentList = documentList == null ? null : documentList.clone();
      filterByVaultInstance(campaignActivity, documentList);
      if(documentList == null || documentList.isEmpty()) {
        fragmentsWithNotFoundError.add(fragmentVaultId);
      }
      else if(filterApprovedDocuments(documentList)){
        fragmentsWithNotApprovedError.add(fragmentVaultId);
      }
      else if(filterDocumentsByRecordType(documentList, 'Email_Fragment_vod')) {
        fragmentsWithInvalidRecordTypeError.add(fragmentVaultId);
      }
      else if(documentList.size() > 1 && filterDocumentMultiproductCheck(documentList, campaignActivity)) {
        fragmentsWithNoMatchError = true;
      }
      else {
        fragments.add(documentList[0]);
      }
    }
    Boolean errorFound = true;
    if(duplicateFragment != null) {
      String errorMessage = errorMessageMap.get('CAMPAIGN_ACTIVITY_DUPLICATE_FRAGMENT');
      errorMessage = addOptionalParamToMessage(errorMessage, duplicateFragment);
      campaignActivity.addError('Email_Fragment_Vault_Doc_IDs_vod__c', errorMessage);
    }
    else if(!fragmentsWithNotFoundError.isEmpty()) {
      String errorMessage = errorMessageMap.get('CAMPAIGN_ACTIVITY_EMAIL_FRAGMENT_NOT_FOUND');
      errorMessage = addOptionalParamToMessage(errorMessage, String.join(fragmentsWithNotFoundError, ','));
      campaignActivity.addError('Email_Fragment_Vault_Doc_IDs_vod__c', errorMessage);
    }
    else if(!fragmentsWithNotApprovedError.isEmpty()) {
      String errorMessage = errorMessageMap.get('CAMPAIGN_ACTIVITY_EMAIL_FRAGMENT_NOT_APPROVED');
      errorMessage = addOptionalParamToMessage(errorMessage, String.join(fragmentsWithNotApprovedError, ','));
      campaignActivity.addError('Email_Fragment_Vault_Doc_IDs_vod__c', errorMessage);
    }
    else if (!fragmentsWithInvalidRecordTypeError.isEmpty()) {
      String errorMessage = errorMessageMap.get('CAMPAIGN_ACTIVITY_INVALID_EMAIL_FRAGMENT_RECORD_TYPE');
      errorMessage = addOptionalParamToMessage(errorMessage, String.join(fragmentsWithInvalidRecordTypeError, ','));
      campaignActivity.addError('Email_Fragment_Vault_Doc_IDs_vod__c', errorMessage);
    }
    else if (fragmentsWithNoMatchError) {
      String errorMessage = errorMessageMap.get('CAMPAIGN_ACTIVITY_NO_MATCH_FOR_MULTI_PRODUCT_EMAIL_FRAGMENT');
      errorMessage = addOptionalParamToMessage(errorMessage, buildNoMatchOptionalParam(campaignActivity));
      campaignActivity.addError('Email_Fragment_Vault_Doc_IDs_vod__c', errorMessage);
    }
    else {
      errorFound = false;
    }

    return errorFound ? null : fragments; 
  }

  private String buildNoMatchOptionalParam(Campaign_Activity_vod__c campaignActivity) {
    String optionalParamProduct = '';
    String optionalParamDetailGroup = '';
    Set<Id> productIds = new Set<Id>();
    if(campaignActivity.Product_vod__c != null) {
      productIds.add(campaignActivity.Product_vod__c);
    }
    if(campaignActivity.Detail_Group_vod__c != null) {
      productIds.add(campaignActivity.Detail_Group_vod__c);
    }
    List<Product_vod__c> products = [SELECT Name, Id FROM Product_vod__c WHERE Id IN :productIds];
    for(Product_vod__c product : products) {
      if(product.Id == campaignActivity.Product_vod__c) {
        optionalParamProduct = product.Name;
      }
      else if(product.Id == campaignActivity.Detail_Group_vod__c) {
        optionalParamDetailGroup = ' | ' + product.Name;
      }
    }
    return optionalParamProduct + optionalParamDetailGroup;
  }

  @testVisible private Approved_Document_vod__c validateEmailTemplate(Map<String, List<Approved_Document_vod__c>> approvedDocumentMap, Campaign_Activity_vod__c campaignActivity, Map<String,String> errorMessageMap) {
    Approved_Document_vod__c emailTemplate;
    List<Approved_Document_vod__c> documentList = approvedDocumentMap.get(campaignActivity.Email_Template_Vault_Doc_ID_vod__c);
    documentList = documentList == null ? null : documentList.clone();
    filterByVaultInstance(campaignActivity, documentList);
    if(documentList == null || documentList.isEmpty()) {
      String errorMessage = errorMessageMap.get('CAMPAIGN_ACTIVITY_EMAIL_TEMPLATE_NOT_FOUND');
      errorMessage = addOptionalParamToMessage(errorMessage, campaignActivity.Email_Template_Vault_Doc_ID_vod__c);
      campaignActivity.addError('Email_Template_Vault_Doc_ID_vod__c', errorMessage);
    }
    else if(filterApprovedDocuments(documentList)){
      String errorMessage = errorMessageMap.get('CAMPAIGN_ACTIVITY_EMAIL_TEMPLATE_NOT_APPROVED');
      errorMessage = addOptionalParamToMessage(errorMessage, campaignActivity.Email_Template_Vault_Doc_ID_vod__c);
      campaignActivity.addError('Email_Template_Vault_Doc_ID_vod__c', errorMessage);
    }
    else if(filterDocumentsByRecordType(documentList, 'Email_Template_vod')) {
      String errorMessage = errorMessageMap.get('CAMPAIGN_ACTIVITY_INVALID_EMAIL_TEMPLATE_RECORD_TYPE');
      errorMessage = addOptionalParamToMessage(errorMessage, campaignActivity.Email_Template_Vault_Doc_ID_vod__c);
      campaignActivity.addError('Email_Template_Vault_Doc_ID_vod__c', errorMessage);
    }
    else if(documentList.size() > 1 && filterDocumentMultiproductCheck(documentList, campaignActivity)) {
      String errorMessage = errorMessageMap.get('CAMPAIGN_ACTIVITY_NO_MATCH_FOR_MULTI_PRODUCT_EMAIL_TEMPLATE');
      errorMessage = addOptionalParamToMessage(errorMessage, buildNoMatchOptionalParam(campaignActivity));
      campaignActivity.addError('Email_Template_Vault_Doc_ID_vod__c', errorMessage);
    }
    else {
      emailTemplate = documentList[0];
    }
    return emailTemplate;
  }

  @testVisible private void validateEmailTemplateFields(Approved_Document_vod__c emailTemplate, Campaign_Activity_vod__c campaignActivity, Map<String,String> errorMessageMap) {
    if(!campaignActivity.hasErrors()) {
      String allowedIds = emailTemplate.Allowed_Document_IDs_vod__c;
      Boolean allowsDocuments = emailTemplate.Email_Allows_Documents_vod__c;
      String html = emailTemplate.Email_HTML_1_vod__c;
      if(html == null) {
        html = '';
      }
      String fragmentVaultIds = campaignActivity.Email_Fragment_Vault_Doc_IDs_vod__c;
      List<String> fragments = new List<String>();
      if(!String.isEmpty(fragmentVaultIds)) {
        fragments = fragmentVaultIds.trim().split(',');
      }
      String regex = '\\{\\{insertEmailFragments\\[(\\d+)(?:,(\\d+))?\\]\\}\\}';
      Matcher myMatcher = Pattern.compile(regex).matcher(html);
      Boolean matchFound = myMatcher.find();
      Boolean isAlternativeToken = matchFound && !myMatcher.group(0).contains(',');
      if(isAllowedIdsError(allowedIds, fragments)) {
        String errorMessage = errorMessageMap.get('CAMPAIGN_ACTIVITY_ALLOWED_DOC_IDS_RESTRICT_EMAIL_FRAGMENT');
        errorMessage = addOptionalParamToMessage(errorMessage, allowedIds);
        campaignActivity.addError('Email_Fragment_Vault_Doc_IDs_vod__c', errorMessage);
      }
      else if(isAllowsDocumentsError(allowsDocuments, fragmentVaultIds)) {
        String errorMessage = errorMessageMap.get('CAMPAIGN_ACTIVITY_EMAIL_TEMPLATE_CANNOT_HAVE_FRAGMENTS');
        campaignActivity.addError('Email_Fragment_Vault_Doc_IDs_vod__c', errorMessage);
      }
      else if(matchFound && !isAlternativeToken && isMinFragmentError(myMatcher, fragments.size())){
        String errorMessage = errorMessageMap.get('CAMPAIGN_ACTIVITY_EMAIL_FRAGMENT_MINIMUM_NOT_REACHED');
        campaignActivity.addError('Email_Fragment_Vault_Doc_IDs_vod__c', errorMessage);
      }
      else if(matchFound && isMaxFragmentError(myMatcher, fragments.size(), isAlternativeToken)) {
        String errorMessage = errorMessageMap.get('CAMPAIGN_ACTIVITY_EMAIL_FRAGMENT_MAXIMUM_REACHED');
        campaignActivity.addError('Email_Fragment_Vault_Doc_IDs_vod__c', errorMessage);
      }
    }
  }

  private void filterByVaultInstance(Campaign_Activity_vod__c campaignActivity, List<Approved_Document_vod__c> documentList) {
    if(documentList != null) {
      for(Integer i = documentList.size() - 1; i >= 0; i--) {
        if(documentList[i].Vault_Instance_ID_vod__c != campaignActivity.Vault_Instance_ID_vod__c) {
          documentList.remove(i);
        }
      }
    }
  }

  private Boolean isMinFragmentError(Matcher myMatcher, Integer fragmentCount) {
    Boolean isInvalid = false;
    String minString = myMatcher.group(1);
    if(!String.isBlank(minString)) {
      Integer min = Integer.valueOf(minString);
      if(fragmentCount < min) {
        isInvalid = true;
      }
    }
    return isInvalid;
  }

  private Boolean isMaxFragmentError(Matcher myMatcher, Integer fragmentCount, Boolean isAlternativeToken) {
    Boolean isInvalid = false;
    String maxString = isAlternativeToken ? myMatcher.group(1) : myMatcher.group(2);
    if(!String.isBlank(maxString)) {
      Integer max = Integer.valueOf(maxString);
      if(max > 0 && fragmentCount > max) {
        isInvalid = true;
      }
    }
    
    return isInvalid;
  }

  private Boolean isAllowsDocumentsError(Boolean allowsDocuments, String fragmentVaultIds) {
    return !allowsDocuments && !String.isEmpty(fragmentVaultIds);
  }

  private Boolean isAllowedIdsError(String allowedIds, List<String> fragmentIds) {
    Boolean isInvalid = false;
    if(!String.isEmpty(allowedIds)) {
      List<String> allowedIdsList = allowedIds.trim().split(';;');
      for(String fragmentId : fragmentIds) {
        if(!allowedIdsList.contains(fragmentId)) {
          isInvalid = true;
          break;
        }
      }
    }
    return isInvalid;
  }

  private Boolean filterDocumentMultiproductCheck(List<Approved_Document_vod__c> documentList, Campaign_Activity_vod__c campaignActivity) {
    for(Integer i = documentList.size() - 1; i >= 0; i--) {
      if(documentList[i].Product_vod__c == null || documentList[i].Product_vod__c != campaignActivity.Product_vod__c || documentList[i].Detail_Group_vod__c != campaignActivity.Detail_Group_vod__c) {
        documentList.remove(i);
      }
    }
    return documentList.isEmpty();
  }

  private Boolean filterApprovedDocuments(List<Approved_Document_vod__c> documentList) {
    for(Integer i = documentList.size() - 1; i >= 0; i--) {
      if(documentList[i].Status_vod__c != 'Approved_vod') {
        documentList.remove(i);
      }
    }
    return documentList.isEmpty();
  }

  private Boolean filterDocumentsByRecordType(List<Approved_Document_vod__c> documentList, String recordType) {
    for(Integer i = documentList.size() - 1; i >= 0; i--) {
      if(documentList[i].RecordType.DeveloperName != recordType) {
        documentList.remove(i);
      }
    }
    return documentList.isEmpty();
  }

  private Map<Id, Campaign_vod__c> buildParentMap(Set<Id> recordIds) {
    return new Map<Id, Campaign_vod__c>([SELECT Start_Date_vod__c, End_Date_vod__c, Id FROM Campaign_vod__c WHERE Id IN :recordIds]);
  }

  private Map<String, List<Approved_Document_vod__c>> buildDocumentMap(Set<String> vaultIds) {
    Map<String, List<Approved_Document_vod__c>> documentMap = new Map<String, List<Approved_Document_vod__c>>();
    for(Approved_Document_vod__c approvedDocument : [SELECT Id, Name, Allow_Any_Product_Fragment_vod__c, Allowed_Document_IDs_vod__c,
      Vault_Document_ID_vod__c, Email_Template_Fragment_Document_ID_vod__c, Email_HTML_1_vod__c,  Email_Allows_Documents_vod__c,
      Product_vod__c, Detail_Group_vod__c, Status_vod__c, Vault_Instance_ID_vod__c, RecordType.DeveloperName FROM Approved_Document_vod__c WHERE Vault_Document_ID_vod__c IN :vaultIds]) {
        List<Approved_Document_vod__c> docs = documentMap.get(approvedDocument.Vault_Document_ID_vod__c);
        if (docs == null) {
          docs = new List<Approved_Document_vod__c>();
          documentMap.put(approvedDocument.Vault_Document_ID_vod__c, docs);
        }
        docs.add(approvedDocument);        
      }
    return documentMap;
  }

  private void validateEmailSource(Campaign_Activity_vod__c campaignActivity, Map<String, String> errorMessageMap) {
    String emailSource = campaignActivity.Email_Source_vod__c;

    if(emailSource != NULL) {
      if (emailSource.countMatches(',') > 4){
        campaignActivity.addError('Email_Source_vod__c', errorMessageMap.get('TOO_MANY_EMAIL_SOURCE_FIELDS'));
      }
    }
  }

  private void validateDates(Campaign_Activity_vod__c campaignActivity, Campaign_vod__c parentCampaign, Map<String, String> errorMessageMap) {
    Date campaignStartDate = parentCampaign.Start_Date_vod__c;
    Date campaignEndDate = parentCampaign.End_Date_vod__c;
    Date publishDate = campaignActivity.Publish_Date_vod__c;
    Datetime scheduledSendDate = campaignActivity.Scheduled_Send_Datetime_vod__c;
    if(scheduledSendDate != NULL) {
      if(scheduledSendDate.date() < campaignStartDate || scheduledSendDate.date() > campaignEndDate) {
        campaignActivity.addError('Scheduled_Send_Datetime_vod__c', errorMessageMap.get('CAMPAIGN_DATE_SCHEDULED_SEND_ERROR'));
      }
      if(publishDate != NULL && publishDate >= scheduledSendDate.date()) {
        campaignActivity.addError('Publish_Date_vod__c', errorMessageMap.get('PUBLISH_DATE_SCHEDULED_SEND_ERROR'));
      }
    }
    if(publishDate != NULL && publishDate > campaignEndDate) {
      campaignActivity.addError('Publish_Date_vod__c', errorMessageMap.get('PUBLISH_DATE_CAMPAIGN_END_DATE_ERROR'));
    }
  }

  @testVisible private static Map<String, String> buildDefaultErrorMessageMap() {
    Map<String, String> defaultErrorMessageMap = new Map<String, String>();
    defaultErrorMessageMap.put('PUBLISH_DATE_CAMPAIGN_END_DATE_ERROR', 'The Publish Date cannot be later than the Campaign\'s End Date.');
    defaultErrorMessageMap.put('PUBLISH_DATE_SCHEDULED_SEND_ERROR', 'The Publish Date has to be at least 1 day before the Scheduled Send Datetime.');
    defaultErrorMessageMap.put('CAMPAIGN_DATE_SCHEDULED_SEND_ERROR', 'Scheduled send datetime has to be between the campaign\'s start and end date.');
    defaultErrorMessageMap.put('TOO_MANY_EMAIL_SOURCE_FIELDS', 'Maximum 5 email fields can be configured.');
    defaultErrorMessageMap.put('CAMPAIGN_ACTIVITY_EMAIL_FRAGMENT_NOT_FOUND', 'Approved Document record not found for one or more email fragment(s): {0}.');
    defaultErrorMessageMap.put('CAMPAIGN_ACTIVITY_EMAIL_FRAGMENT_NOT_APPROVED', 'One or more email fragment(s) are not approved: {0}.');
    defaultErrorMessageMap.put('CAMPAIGN_ACTIVITY_INVALID_EMAIL_FRAGMENT_RECORD_TYPE', 'One or more email fragment(s) are an invalid record type: {0}.');
    defaultErrorMessageMap.put('CAMPAIGN_ACTIVITY_NO_MATCH_FOR_MULTI_PRODUCT_EMAIL_FRAGMENT', 'Approved Document record not found for one or more email fragment(s) with product {0}.');
    defaultErrorMessageMap.put('CAMPAIGN_ACTIVITY_EMAIL_TEMPLATE_NOT_FOUND', 'Approved Document record not found for the email template: {0}.');
    defaultErrorMessageMap.put('CAMPAIGN_ACTIVITY_EMAIL_TEMPLATE_NOT_APPROVED', 'Email template is not approved: {0}.');
    defaultErrorMessageMap.put('CAMPAIGN_ACTIVITY_INVALID_EMAIL_TEMPLATE_RECORD_TYPE', 'Email template is an invalid record type: {0}.');
    defaultErrorMessageMap.put('CAMPAIGN_ACTIVITY_NO_MATCH_FOR_MULTI_PRODUCT_EMAIL_TEMPLATE', 'Approved Document record not found for email template with product {0}.');
    defaultErrorMessageMap.put('CAMPAIGN_ACTIVITY_ALLOWED_DOC_IDS_RESTRICT_EMAIL_FRAGMENT', 'One or more fragment(s) are not under the email template\'s allowed documents. The Allowed Document IDs are: {0}.');
    defaultErrorMessageMap.put('CAMPAIGN_ACTIVITY_EMAIL_TEMPLATE_CANNOT_HAVE_FRAGMENTS', 'Email fragments are not allowed on this email template.');
    defaultErrorMessageMap.put('CAMPAIGN_ACTIVITY_EMAIL_FRAGMENT_MINIMUM_NOT_REACHED', 'Minimum number of required Email Fragments is not reached.');
    defaultErrorMessageMap.put('CAMPAIGN_ACTIVITY_EMAIL_FRAGMENT_MAXIMUM_REACHED', 'Maximum number of required Email Fragments is reached.');
    defaultErrorMessageMap.put('CAMPAIGN_ACTIVITY_EMAIL_TEMPLATE_PRODUCT_RESTRICTS_FRAGMENT', 'One or more email fragment(s) are restricted based on the product specified for the email template: {0}.');
    defaultErrorMessageMap.put('CAMPAIGN_ACTIVITY_DUPLICATE_FRAGMENT', 'Duplicate fragment found: {0}.');

    return defaultErrorMessageMap;
  }

  private static Map<String, String> buildCampaignErrorMessageMap(Map<String, String> defaultErrorMessageMap) {
    Set<String> messageNames = defaultErrorMessageMap.keySet();
    Map<String, String> errorMessageMap = new Map<String, String>();
    List<Message_vod__c> messages = [Select Text_vod__c, Name From Message_vod__c WHERE Name IN :messageNames AND Category_vod__c='Campaign' AND Active_vod__c=true AND Language_vod__c=:userInfo.getLanguage()];
    for(Message_vod__c message : messages) {
      errorMessageMap.put(message.Name, message.Text_vod__c);
    }
    for(String key : defaultErrorMessageMap.keySet()) {
      if(!errorMessageMap.containsKey(key)) {
        errorMessageMap.put(key, defaultErrorMessageMap.get(key));
      }
    }
    return errorMessageMap;
  }

  public static String addOptionalParamToMessage(String message, String optionalParam) {
    return message.replace('{0}', optionalParam);
  }
}