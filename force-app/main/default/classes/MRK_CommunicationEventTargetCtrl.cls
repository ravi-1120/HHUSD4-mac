public with sharing class MRK_CommunicationEventTargetCtrl {

  public ApexPages.StandardController sc { get; set; }
  public final sObject targetRecord;
  private String objectTypeName;
  private String objectLabel;
  private String parentObjectFieldName;
  private String parentObjectRelationshipName;
  public String parentObjectLabel { get; set; }
  public String parentObjectName { get; set; }

  public String title { get; set; }
  public String eventType { get; set; }
  public SelectOption[] eventTypes { get; set; }

  public SelectOption[] allProfiles { get; set; }
  public SelectOption[] selectedProfiles { get; set; }

  public SelectOption[] allProducts { get; set; }
  public SelectOption[] selectedProducts { get; set; }

  public SelectOption[] allTeams { get; set; }
  public SelectOption[] selectedTeams { get; set; }

  private List<Product_vod__c> sourceProducts;
  private List<Sales_Team_MRK__c> sourceTeams;

  public String message { get; set; }

    public MRK_CommunicationEventTargetCtrl(ApexPages.StandardController stdController) {

    objectTypeName = ApexPages.currentPage().getUrl().contains('MRK_CommunicationEventTarget') ? 'Communication_Event_Target_MRK__c' : 'Communication_Target_MRK__c';
    parentObjectFieldName = (objectTypeName == 'Communication_Target_MRK__c') ? 'Communication_MRK__c' : 'Communication_Event_MRK__c';
    parentObjectRelationshipName = parentObjectFieldName.replace('__c', '__r');
    parentObjectLabel = (objectTypeName == 'Communication_Target_MRK__c') ? 'Communication' : 'Communication Event';
    objectLabel = (objectTypeName == 'Communication_Target_MRK__c') ? 'Communication' : 'Communication Event';
    title = objectLabel + ' Target Edit';    

    this.sc = stdController;

    sc.addFields(new List<String>{'Type_MRK__c' ,'Profile_MRK__c', 'Product_IDs_MRK__c', 'Team_IDs_MRK__c', parentObjectFieldName});
        
    this.targetRecord = stdController.getRecord();

    eventTypes = new List<SelectOption>();
    eventTypes.add(new SelectOption('--None--', '--None--'));
    if (getIsCommunicationTarget()) {
      eventTypes.add(new SelectOption('Action', 'Action'));
      eventTypes.add(new SelectOption('Background', 'Background'));
    } else {
      eventTypes.add(new SelectOption('Required', 'Required'));
      eventTypes.add(new SelectOption('Optional', 'Optional'));
    }

    selectedProfiles = new List<SelectOption>();    
    List<String> profileNames = new List<String>{
      'MRK - Sales Representative',
      'MRK - Sales Manager',
      'MRK - Sales Director',
      'MRK - Communication User',
      'MRK - Account Exec',
      'MRK - Contact Center Sales Representative',
      'MRK - Contact Center Sales Manager',    
      'MRK - Contact Center Sales Director',
      'MRK - PR Sales Director',
      'MRK - PR Sales Manager',
      'MRK - PR Sales Representative'};

    allProfiles = new List<SelectOption>();
    for ( String profileName : profileNames ) {
        allProfiles.add(new SelectOption(profileName, profileName));
    }

    selectedProducts = new List<SelectOption>();    
    sourceProducts = [select Id, Name, External_ID_vod__c, Active_MRK__c from Product_vod__c where External_ID_vod__c != null and Active_MRK__c = true and Product_Type_vod__c = 'Detail' and (External_Product_Type_MRK__c = 'Detail Product' or External_ID_vod__c = 'GENERAL') order by Name];    
    allProducts = new List<SelectOption>();
    String generalProductName = 'General';
    String generalProductId = 'placeholderid';
    allProducts.add(new SelectOption(generalProductId, generalProductName));
    for ( Product_vod__c p : sourceProducts ) {
      if (p.Name.toLowerCase() == generalProductName.toLowerCase()) {
        generalProductId = p.External_ID_vod__c;
      } else {
        allProducts.add(new SelectOption(p.External_ID_vod__c, p.Name));
      }
    }

    // set General as the first product in the list
    allProducts.set(0, new SelectOption(generalProductId, generalProductName));

    selectedTeams = new List<SelectOption>();

    // create "virtual" ALL sales team
    Sales_Team_MRK__c allSalesTeam = new Sales_Team_MRK__c(Sales_Team_Code_MRK__c='000', Name='MERCK & CO.');
    sourceTeams = [select Active_MRK__c, CreatedById, CreatedDate, Id, LastModifiedById, LastModifiedDate, Name, OwnerId, Sales_Team_Code_MRK__c from Sales_Team_MRK__c where Active_MRK__c = true order by Name];    
    List<Sales_Team_MRK__c> allSalesTeams = new List<Sales_Team_MRK__c>();
    allSalesTeams.add(allSalesTeam);
    allSalesTeams.addAll(sourceTeams);
    allTeams = new List<SelectOption>();
    for ( Sales_Team_MRK__c t : allSalesTeams ) {
        allTeams.add(new SelectOption(t.Sales_Team_Code_MRK__c, t.Name));
    }

    if (targetRecord.Id != null) {
      sObject sourceCommEventTarget = Database.query('select Id, Type_MRK__c, Profile_MRK__c, Product_IDs_MRK__c, Team_IDs_MRK__c, ' + parentObjectFieldName + ', ' + parentObjectRelationshipName + '.Name from ' + objectTypeName + ' where Id = \'' + targetRecord.Id + '\'')[0];
      eventType = (String)sourceCommEventTarget.get('Type_MRK__c');
      setSelectedOptions(sourceCommEventTarget, 'Profile_MRK__c', allProfiles, selectedProfiles, null, null, null);
      setSelectedOptions(sourceCommEventTarget, 'Product_IDs_MRK__c', allProducts, selectedProducts, sourceProducts, 'External_ID_vod__c', 'Name');
      setSelectedOptions(sourceCommEventTarget, 'Team_IDs_MRK__c', allTeams, selectedTeams, allSalesTeams, 'Sales_Team_Code_MRK__c', 'Name');      
    }
    }

  public Boolean getIsCommunicationTarget() {
    return parentObjectFieldName == 'Communication_MRK__c';
  }

  public Boolean getIsCommunicationEventTarget() {
    return parentObjectFieldName == 'Communication_Event_MRK__c';
  }

  public Communication_Event_Target_MRK__c getCommunicationEventTargetRecord() {
    return (Communication_Event_Target_MRK__c)targetRecord;
  }

  public Communication_Target_MRK__c getCommunicationTargetRecord() {
    return (Communication_Target_MRK__c)targetRecord;
  }


  private void setSelectedOptions(sObject obj, String fieldName, SelectOption[] allSelectOptionsList, SelectOption[] selectedOptionList, List<sObject> sourceItems, String optionValueFieldName, String optionLabelFieldName) {
    
    if (obj == null) {
      return;
    }

    String optionsListString = (String)obj.get(fieldName);

    // if empty, do nothing
    if ((optionsListString == null) || (optionsListString == '')) {
      return;
    }
    
    for (String value : optionsListString.split(';')) {
      sObject sourceObj = findObject(sourceItems, optionValueFieldName, value);
      String selectOptionValue = (optionValueFieldName == null) ? value : (String)sourceObj.get(optionValueFieldName);
      String selectOptionLabel = (optionLabelFieldName == null) ? value : (String)sourceObj.get(optionLabelFieldName);

      selectedOptionList.add( new SelectOption( selectOptionValue, selectOptionLabel ) );

      for (Integer i = 0; i < allSelectOptionsList.size(); i++) {
        SelectOption so = allSelectOptionsList.get(i);
        if ((so.getValue() == selectOptionValue) && (so.getLabel() == selectOptionLabel)) {
          allSelectOptionsList.remove(i);
          break;
        }
      }


    }

  }

  private sObject findObject(List<sObject> objectList, String fieldName, String fieldValue) {
    sObject result = null;

    if ((objectList != null) && (fieldName != null)) {

      for (sObject obj : objectList) {
        if (obj.get(fieldName) == fieldValue) {
          result = obj;
        }
      }

    }

    return result;
  }

  private void setMultiselectValue(sObject obj, String fieldName, SelectOption[] selectOptionList) {
    List<String> values = new List<String>();
    for (SelectOption so : selectOptionList) {
      values.add(so.getValue());
    }
    obj.put(fieldName, String.join(values, ';'));
  }

  private boolean save() {
    message = 'eventType: ' + eventType;

    if (eventType == '--None--') {
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must select a Type'));
    }

    // check each for empty
    // selectedProfiles, selectedProducts, selectedTeams
    if (selectedProfiles.size() == 0) {
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must select at least one Profile'));
    }

    if (selectedProducts.size() == 0) {
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must select at least one Product'));
    }

    if (selectedTeams.size() == 0) {
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must select at least one Team'));
    }

    // return if there are any errors
    if (ApexPages.getMessages().size() > 0) {
      return false;
    }

    // check for too many values / max string length

    targetRecord.put('Type_MRK__c', eventType);
    
    setMultiselectValue(targetRecord, 'Profile_MRK__c', selectedProfiles);
    setMultiselectValue(targetRecord, 'Product_IDs_MRK__c', selectedProducts);
    setMultiselectValue(targetRecord, 'Team_IDs_MRK__c', selectedTeams);

    return true;
  }

    public PageReference doSave() {
        if ( save() ) {
          return sc.save();  
        } else {
          return null;
        }
        
    }

  public Pagereference doSaveAndNew() {
    save();
    sc.save();

    Schema.DescribeSObjectResult r = targetRecord.getSObjectType().getDescribe();
    String keyPrefix = r.getKeyPrefix();

    //String s = '/' + ('' + targetRecord.get('Id')).subString(0, 3) + '/e?';
    String s = '/' + keyPrefix + '/e?';

    return new Pagereference(s);
  }  

  public PageReference doCancel() {
    return sc.cancel();
  }  

  public PageReference doEdit() {
    return sc.edit();
  }

  public PageReference doDelete() {
    return sc.delete();
  }

}