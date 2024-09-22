/**
 * Global Account search
 *
 * @version        2.0 
 * @version Update: 2.1 (7/31/13)
 * @author         Veeva Technical Services (Jeff Kelso, Murugesh Naidu, Wayne Abbott)
 * Update: mnaidu - 7/16/13 - Added Custom Filtering mechanism and migrated code to GAS Hierarchical Custom settings
 * Update: jkelso - 8/9/13 - Added ability to align accounts to multiple territories
 */
public class searchAccts {
     
    //Merck Added Variables 10/16
    /*
    public Boolean individualAdvRendered{set;get;}
    public Boolean organizationAdvRendered{set;get;} 
    public List <SearchField> addrAdvSearchFields {set;get;}
    public List <SearchField> individualAdvSearchFields {set;get;}
    public List <SearchField> organizationAdvSearchFields {set;get;}  
    private List<String> individualAcctRecordTypeSearchFieldSet  ;
    private List<String> organizationAcctRecordTypeSearchFieldSet  ;
    private List<Id> individualAccountRecTypeIdList = new List<Id>();
    private List<Id> organizationAccountRecTypeIdList = new List<Id>();
    private List<String> individualAdvAcctSearchFieldSet  ;
    private List<String> organizationAdvAcctSearchFieldSet  ;       
    private List<String> addrAdvSearchFieldSet  ;
    private List<String> acctSearchableIdFieldSet  ;
    private Map <ID,RecordType> individualAccountRecTypesMap = new Map <ID,RecordType> (); 
    private Map <ID,RecordType> organizationAccountRecTypesMap = new Map <ID,RecordType> (); 
    public Boolean showTablet {get;set;}
    public String selectedAccountId {get;set;}
    public String resultsAsJSON {get; set;}
    public String javascriptToExecuteOnClient {get; set;}

    */
    //End Merck Variables
    
    
    public List<ResultHeader> resultHeaders {set;get;}

    public String wc {get;set;}

    public Boolean individualAdvRendered{set;get;}
    public Boolean organizationAdvRendered{set;get;} 
    
    public List <SearchField> acctSearchFields {set;get;}
    public List <SearchField> addrSearchFields {set;get;}
    public List <SearchField> childAcctSearchFields {set;get;}

    public List <SearchField> addrAdvSearchFields {set;get;}

    public List <SearchField> individualAdvSearchFields {set;get;}
    public List <SearchField> organizationAdvSearchFields {set;get;}  

    private List<String> acctSearchFieldSet  ;
    private List<String> addrSearchFieldSet  ;
    private List<String> childAcctSearchFieldSet  ;
    
    
    private List<String> individualAcctRecordTypeSearchFieldSet  ;
    private List<String> organizationAcctRecordTypeSearchFieldSet  ;
    
    private List<Id> individualAccountRecTypeIdList = new List<Id>();
    private List<Id> organizationAccountRecTypeIdList = new List<Id>();
     
    private List<String> individualAdvAcctSearchFieldSet  ;
    private List<String> organizationAdvAcctSearchFieldSet  ;   
    
    private List<String> addrAdvSearchFieldSet  ;
    private List<String> acctSearchableIdFieldSet  ;
    
    private List<String> childAcctSeachFieldSet;
   

    private List<String> resultFieldSet  ;
    private Set <String> acctResultFields = new Set<String> () ;
    private Set <String> addrResultFields = new Set<String> () ;


    private Map<String, Schema.SObjectField> acctFieldMap ;
    private Map<String, Schema.SObjectField> addrFieldMap ;
    
    private Map<String, Schema.SObjectField> acctFieldMapLcase ;  
    private Map<String, Schema.SObjectField> addrFieldMapLcase; 
        
    
    private Map<String, Schema.SObjectField> childAcctFieldMap ;

    public Map <String,String> resFieldTypeMap = new Map <String,String> () ;
    private Map <String,String> resFieldLabelMap = new Map <String,String> () ;

    public static List<SelectOption> acctRecTypesPlist ;
    public static List<SelectOption> addrRecTypesPlist ;
    private Map <String,String> recTypeXlation = new Map <String,String> () ;

    private Map <ID,RecordType> individualAccountRecTypesMap = new Map <ID,RecordType> (); 
    private Map <ID,RecordType> organizationAccountRecTypesMap = new Map <ID,RecordType> (); 

    public String parentSearch {set;get;}
    public String parentAcctField {set;get;}
    public String returnElemId {set;get;}

    public Boolean showAllAddrs {set;get;}
    public Boolean trackAlignmentHistory {get;set;}

    public SearchResult [] results {get;set;}

    public Boolean showTablet {get;set;}
    public String selectedAccountId {get;set;}
    public String resultsAsJSON {get; set;}
    public String javascriptToExecuteOnClient {get; set;}
    public String uarDefaultStatus {get;set;}

    public String sortKey {get;set;}
    public String sortDir {get;set;}
    
    //jk cookie for default search
    public Boolean isPersonSearch {get;set;}
    
    // Custom Labels
    public String GAS_CANCEL {set;get;}
    public String GAS_SEARCH {set;get;}
    public String GAS_LOOKUP {set;get;}
    public String GAS_SFA {set;get;}
    public String GAS_SFPA {set;get;}
    public String GAS_EM {set;get;}
    public String GAS_SW {set;get;}
    public String GAS_CONTAINS {set;get;}
    public static String GAS_NONE {set;get;}
    public String GAS_RESULTS {set;get;}
    public String GAS_ATT {set;get;}
    public String GAS_NOCRIT {set;get;}
    public String GAS_NAMESEARCH {set;get;}
    public String GAS_NOMATCH {set;get;}
    public String GAS_TOOMANY {set;get;}
    public Integer GAS_LIMIT {set;get;} //Added as part of 9.0 release to parameterize the results.
    public String GAS_NOTALGN {set;get;}
    public String GAS_MANYALGN {set;get;}
    public String GAS_INTERR {set;get;}
    public String GAS_SUCCESS {set;get;}
    public String GAS_SELECT {set;get;}
    public String GAS_CLEAR {set;get;}
    public Boolean GAS_ALIGN_MULTIPLE {get;set;}
    public User theUser;


    //Merck Added for Rel 5.0
    public List<SelectOption> getSearchTypes() {
        List<SelectOption> options = new List<SelectOption>(); 
        options.add(new SelectOption('Individuals','Individuals')); 
        options.add(new SelectOption('Organizations','Organizations')); 
        return options; 
    }
    
    public String searchType
    {
       get
       {
         if(searchType==null)
           searchType='Individuals';
           return searchType;
       }
       set;
    }
    
   
    

    // Constructor
    public searchAccts () {
        try{
 
        // BP 8/8 - commented out to provide the "only show [Request New Account] button"
        // after the user has performed a search.
        //results = new List<searchResult> () ;
        showTablet = (ApexPages.currentPage().getParameters().get('showTablet') == null) ? true : ApexPages.currentPage().getParameters().get('showTablet') == '1';

        parentSearch = ApexPages.currentPage().getParameters().get('parentSearch');
        parentAcctField = ApexPages.currentPage().getParameters().get('parentAcctField');
        returnElemId = ApexPages.currentPage().getParameters().get('returnElemId');
        String lang = UserInfo.getLanguage() ;
        // Get labels from Message_vod__c for user's language
        //mnaidu - 7/18/2013 - This will be moved to a Hierarchical Custom setting in GAS 2.1
       /* Message_vod__c [] labels = [SELECT Name,Text_vod__c 
                                    FROM Message_vod__c 
                                    WHERE Language_vod__c = :lang AND 
                                          Category_vod__c = 'Account' AND 
                                          Name LIKE 'GAS%' AND
                                          Active_vod__c = true] ;
        Map <String,String> labelMap = new Map <String,String> () ;
        for (Message_vod__c label : labels) {
            labelMap.put(label.Name, String.escapeSingleQuotes(label.Text_vod__c)) ;
        }
        */

        // Get values of custom settings
        //mnaidu - 7/16/2013 - We should leverage Hierarchy Custom settings for this as it is more suited to this type of transaction. Also should
        //give us the ability to have different search and results columns for different users
        //GASSettings__c gas = [select Account_Search_Field_Set__c,Address_Search_Field_Set__c,Result_Field_Set__c,Show_All_Addresses__c, Track_Alignment_History__c from GASSettings__c where name = 'Main'] ;
        GAS_Hierarchical_Setting__c   gas = GAS_Hierarchical_Setting__c.getInstance();//this returns the appropriate settings for the user based on his user profile  
        GAS_CANCEL = gas.GAS_Message_Cancel__c ;
        GAS_SEARCH = gas.GAS_Message_Search__c;
        GAS_LOOKUP = gas.GAS_Message_Lookup__c ;
        GAS_SFA = gas.GAS_Message_SFA__c ;
        GAS_SFPA = gas.GAS_Message_SFPA__c ;
        GAS_EM = gas.GAS_Message_EM__c ;
        GAS_SW = gas.GAS_Message_STARTS_WITH__c ;
        GAS_CONTAINS = gas.GAS_Message_CONTAINS__c ;
        GAS_NONE = gas.GAS_Message_NONE__c ;
        GAS_RESULTS = gas.GAS_Message_RESULTS__c ;
        GAS_ATT = gas.GAS_Message_ATT__c ;
        GAS_NOCRIT = gas.GAS_Message_NoCriteria__c;
        GAS_NAMESEARCH = gas.GAS_Message_NameSearch__c ;
        GAS_NOMATCH = gas.GAS_Message_NOMATCH__c ;
        GAS_TOOMANY = gas.GAS_Message_TOO_MANY__c ;
        GAS_LIMIT = gas.LIMIT__c.intValue() ; //Added as part of 9.0 release to parameterize the search results.
        GAS_NOTALGN = gas.GAS_Message_NOTALIGNED__c ;
        GAS_MANYALGN = gas.GAS_Message_MANYALIGN__c;
        GAS_INTERR = gas.GAS_Message_INTERR__c ;
        GAS_SUCCESS = gas.GAS_Message_SUCCESS__c ;
        GAS_SELECT = gas.GAS_Message_SELECT__c ;
        GAS_CLEAR = gas.GAS_Message_CLEAR__c ;
        GAS_ALIGN_MULTIPLE = gas.Align_Multiple_Territory__c;
        this.uarDefaultStatus = gas.UAR_Default_Status__c;
        system.debug(LoggingLevel.INFO,'jk - getting custom setting for UAR status: ' + this.uarDefaultStatus);
        
     /*   GAS_CANCEL = labelMap.get('GAS_CANCEL') ;
        GAS_SEARCH = labelMap.get('GAS_SEARCH') ;
        GAS_LOOKUP = labelMap.get('GAS_LOOKUP') ;
        GAS_SFA = labelMap.get('GAS_SFA') ;
        GAS_SFPA = labelMap.get('GAS_SFPA') ;
        GAS_EM = labelMap.get('GAS_EM') ;
        GAS_SW = labelMap.get('GAS_SW') ;
        GAS_CONTAINS = labelMap.get('GAS_CONTAINS') ;
        GAS_NONE = labelMap.get('GAS_NONE') ;
        GAS_RESULTS = labelMap.get('GAS_RESULTS') ;
        GAS_ATT = labelMap.get('GAS_ATT') ;
        GAS_NOCRIT = labelMap.get('GAS_NOCRIT') ;
        GAS_NAMESEARCH = labelMap.get('GAS_NAMESEARCH') ;
        GAS_NOMATCH = labelMap.get('GAS_NOMATCH') ;
        GAS_TOOMANY = labelMap.get('GAS_TOOMANY') ;
        GAS_NOTALGN = labelMap.get('GAS_NOTALGN') ;
        GAS_MANYALGN = labelMap.get('GAS_MANYALGN') ;
        GAS_INTERR = labelMap.get('GAS_INTERR') ;
        GAS_SUCCESS = labelMap.get('GAS_SUCCESS') ;
        GAS_SELECT = labelMap.get('GAS_SELECT') ;
        GAS_CLEAR = labelMap.get('GAS_CLEAR') ;
        */
        
        //KRB 8/17 -- Default UI search Type
        individualAdvRendered = True;
        
        //jk - get default search cookie
        
        Cookie cookie = ApexPages.currentPage().getCookies().get('GASsearch');
        if (cookie != null) {
            String searchType = cookie.getValue();
            if (searchType == 'person') {
                isPersonSearch = true;
            } else if (searchType == 'business') {
                isPersonSearch = false;
            } else {
                isPersonSearch = true;
            }        
        } else {
            isPersonSearch = true;
        }
        

        // Get Record Types for Accounts and Addresses
        // We need to use the translation table, and also filter by sObjectType
        acctRecTypesPlist = new List<SelectOption> () ;
        acctRecTypesPlist.add(new SelectOption('',GAS_NONE)) ;
        for (RecordTypeLocalization rtl : [select ParentId, Parent.Name, Value from RecordTypeLocalization where ParentId in (select Id FROM RecordType where SobjectType = 'Account' AND IsActive = true) and Language = :lang order by Value]) {
            acctRecTypesPlist.add(new SelectOption(rtl.ParentId,rtl.Value));
            recTypeXlation.put (rtl.Parent.Name, rtl.Value) ;
        }
        // Also need to pick up those Record Types not in RecordTypeLocalization
        for (RecordType rt :[select Id,Name from RecordType where SobjectType = 'Account' AND IsActive = true and Id not in (select ParentId FROM RecordTypeLocalization where Language = :lang)]) {
            acctRecTypesPlist.add(new SelectOption(rt.Id,rt.Name));
            recTypeXlation.put (rt.Name, rt.Name) ;
        }
        acctRecTypesPlist = SortOptionList(acctRecTypesPlist) ;
        // Address Record Types
        addrRecTypesPlist = new List<SelectOption> () ;
        addrRecTypesPlist.add(new SelectOption('',GAS_NONE)) ;
        for (RecordTypeLocalization rtl : [select ParentId, Parent.Name, Value from RecordTypeLocalization where ParentId in (select Id FROM RecordType where SobjectType = 'Address_vod__c' AND IsActive = true) and Language = :lang order by Value]) {
            addrRecTypesPlist.add(new SelectOption(rtl.ParentId,rtl.Value));
            recTypeXlation.put (rtl.Parent.Name, rtl.Value) ;
        }
        // Also need to pick up those Record Types not in RecordTypeLocalization
        for (RecordType rt :[select Id,Name from RecordType where SobjectType = 'Address_vod__c' AND IsActive = true and Id not in (select ParentId FROM RecordTypeLocalization where Language = :lang)]) {
            addrRecTypesPlist.add(new SelectOption(rt.Id,rt.Name));
            recTypeXlation.put (rt.Name, rt.Name) ;
        }
        addrRecTypesPlist = SortOptionList(addrRecTypesPlist) ;

        //Merck Added - Start
        // Get values of custom settings
        // BP 8/8 - added Result_Field_Set_Extended__c field
        /* Uncomment out 
        GASSettings__c gasMrk = [select  Individual_RecType_Search_Filter_Set_MRK__c,
                                      Org_RecType_Search_Filter_Set_MRK__c,
                                      Organization_Adv_Search_Field_Set__c,
                                      Individual_Adv_Search_Field_Set__c,
                                      Searchable_Account_Ids__c,
                                      Account_Search_Field_Set__c, 
                                      Account_Advance_Search_Field_Set__c, 
                                      Address_Advance_Search_Field_Set__c, 
                                      Address_Search_Field_Set__c,
                                      Result_Field_Set__c,
                                      Result_Field_Set_Extended__c,
                                      Show_All_Addresses__c 
                              from    GASSettings__c 
                              where   name = 'Main'] ;

        */
        //Merck Added - End


        acctSearchFieldSet = gas.Account_Search_Field_Set__c.split(',') ;
        addrSearchFieldSet = gas.Address_Search_Field_Set__c.split(',') ;
        childAcctSearchFieldSet = gas.Child_Account_Search_Field_Set_MRK__c.split(',');
 
        //Merck Added - Start
        individualAcctRecordTypeSearchFieldSet =  gas.Individual_RecType_Search_Filter_Set_MRK__c.split(','); 
        organizationAcctRecordTypeSearchFieldSet = gas.Org_RecType_Search_Filter_Set_MRK__c.split(',');
                           
        individualAdvAcctSearchFieldSet = gas.Individual_Adv_Search_Field_Set_MRK__c.split(',') ;
        organizationAdvAcctSearchFieldSet = gas.Organization_Adv_Search_Field_Set_MRK__c.split(',') ;
        
        addrAdvSearchFieldSet = gas.Address_Advance_Search_Field_Set_MRK__c.split(',') ;
        acctSearchableIdFieldSet = gas.Searchable_Account_Ids_MRK__c.split(',') ; 
                //Merck Added - End

 
 
        resultFieldSet = gas.Result_Field_Set__c.split(',') ;
 
        //Merck Added - Start
        // BP 8/8 - can't fit all result fields in a "single" 255 char setting
        // added Result Field Set Extended where it's fields are appended
        resultFieldSet.addAll(gas.Result_Field_Set_Extended_MRK__c.split(',')) ;
               //Merck Added - End
 
        showAllAddrs = gas.Show_All_Addresses__c ;
        
        //Merck Added - Start
        //Create a MAP of the Record Type Ids that we will use to filter our search 
        individualAccountRecTypesMap   = new Map<Id, RecordType>([Select Id, DeveloperName FROM RecordType where DeveloperName in :individualAcctRecordTypeSearchFieldSet]); 
        organizationAccountRecTypesMap = new Map<Id, RecordType>([Select Id, DeveloperName FROM RecordType where DeveloperName in :organizationAcctRecordTypeSearchFieldSet]); 
        //Merck Added - End
        
         
        trackAlignmentHistory  = gas.Track_Alignment_History__c;
        
        // Set up search fields
        acctSearchFields = new List <SearchField> () ;
        acctFieldMap = Schema.SObjectType.Account.fields.getMap();
        //jk - winter 15 patch
        /* maps from describe information should be case insensitive, but this is not proving to be the case in winter 2015
           creating a new map with all lowercase values to compare on
           old code - acctFieldMap = Schema.SObjectType.Account.fields.getMap();
        */
        acctFieldMapLcase = new Map<String,Schema.SObjectField>();  
        for (String key : acctFieldMap.keySet()) {
            acctFieldMapLcase.put(key.toLowerCase(),acctFieldMap.get(key));
        }
        //jk - end winter 15 patch
            
        for (String f : acctSearchFieldSet) {
            Schema.DescribeFieldResult  dfr = acctFieldMap.get(f).getDescribe() ;
            acctSearchFields.add (new SearchField('Account',dfr)) ;
        }
        addrSearchFields = new List <SearchField> () ;
        addrFieldMap = Schema.SObjectType.Address_vod__c.fields.getMap();
        //jk - winter 15 patch
        /* maps from describe information should be case insensitive, but this is not proving to be the case in winter 2015
           creating a new map with all lowercase values to compare on
           old code - acctFieldMap = Schema.SObjectType.Account.fields.getMap();
        */
        addrFieldMapLcase = new Map<String,Schema.SObjectField>();
        for (String key : addrFieldMap.keySet()) {
            addrFieldMapLcase.put(key.toLowerCase(),addrFieldMap.get(key));
        }
        //jk - end winter 15 patch            
        for (String f : addrSearchFieldSet) {
            Schema.DescribeFieldResult  dfr = addrFieldMap.get(f).getDescribe() ;
            addrSearchFields.add (new SearchField('Address_vod__c',dfr)) ;
        }

        individualAdvSearchFields = new List <SearchField> () ;
        acctFieldMap = Schema.SObjectType.Account.fields.getMap();
        for (String f : individualAdvAcctSearchFieldSet) {
            system.debug(LoggingLevel.INFO,'jk - string individualAdvAcctSearch: ' + f);            
            Schema.DescribeFieldResult  dfr = acctFieldMap.get(f).getDescribe() ;
            individualAdvSearchFields.add (new searchField('Account',dfr)) ;
        }
        
        organizationAdvSearchFields = new List <SearchField> () ;
        acctFieldMap = Schema.SObjectType.Account.fields.getMap();
        for (String f : organizationAdvAcctSearchFieldSet) {
           system.debug(LoggingLevel.INFO,'jk - organizationAdvAcctSearchField: ' + f);
           Schema.DescribeFieldResult  dfr = acctFieldMap.get(f).getDescribe() ;
           System.debug('kevin1104: ' + f);  
           organizationAdvSearchFields.add (new searchField('Account',dfr)) ;
        }
        
        addrAdvSearchFields = new List <SearchField> () ;
        addrFieldMap = Schema.SObjectType.Address_vod__c.fields.getMap();
        for (String f : addrAdvSearchFieldSet) {
            Schema.DescribeFieldResult  dfr = addrFieldMap.get(f).getDescribe() ;
            addrAdvSearchFields.add (new searchField('Address_vod__c',dfr)) ;
        }

        childAcctSearchFields = new List<SearchField>();
        //We are not actually querying Child Account, but the related Account that is the Parent
        childAcctFieldMap = Schema.SObjectType.Child_Account_vod__c.fields.getMap();
        for (String f : childAcctSearchFieldSet) {
            Schema.DescribeFieldResult dfr = childAcctFieldMap.get(f).getDescribe();
            childAcctSearchFields.add(new SearchField('Child_Account_vod__c',dfr));
            //individualAdvSearchFields.add (new searchField('Child_Account_vod__c',dfr)) ;
            //organizationAdvSearchFields.add (new searchField('Child_Account_vod__c',dfr)) ;
        }
        
        system.debug('jk - individualAdvSearchFields: ' + individualAdvSearchFields);
        //Merck Added - End 

        
        // Parse resultFieldSet to get result Account and Address fields
        acctResultFields = new Set<String> () ;
        addrResultFields = new Set<String> () ;
        resultHeaders = new List<ResultHeader> () ;
        sortKey = '' ;
        sortDir = 'A' ;
        for (String rf : resultFieldSet) {
            if (sortKey == '') {
                // Set sortKey to first result field in list
                sortKey = rf; 
            }
            if (rf.startsWith('ADD.')) {
                String dataType = addrFieldMap.get(rf.replace('ADD.', '')).getDescribe().getType().name() ;
                resFieldTypeMap.put (rf, dataType) ;
                String label = addrFieldMap.get(rf.replace('ADD.', '')).getDescribe().getLabel() ;
                if (dataType == 'Reference') {
                    // We need to add Relationship.Name to acctResultFields
                    String rel = addrFieldMap.get(rf.replace('ADD.', '')).getDescribe().getRelationshipName() ;
                    addrResultFields.add(rel + '.Name') ;
                    // Remove trailing ' ID' from label
                    label = label.replaceFirst(' ID$', '') ;
                }
                resFieldLabelMap.put (rf, label) ;
                addrResultFields.add (rf.replace('ADD.', '')) ;
                ResultHeader rh = new ResultHeader () ;
                rh.label = label ;
                rh.apiname = rf ;
                resultHeaders.add (rh) ;
            }
            else {
                String dataType = acctFieldMap.get(rf).getDescribe().getType().name() ;
                resFieldTypeMap.put (rf, dataType) ;
                String label = acctFieldMap.get(rf).getDescribe().getLabel() ;
                if (dataType == 'Reference') {
                    // We need to add Relationship.Name to acctResultFields
                    String rel = acctFieldMap.get(rf).getDescribe().getRelationshipName() ;
                    acctResultFields.add(rel + '.Name') ;
                    // Remove trailing ' ID' from label
                    label = label.replaceFirst(' ID$', '') ;
                }
                resFieldLabelMap.put (rf, label) ;
                acctResultFields.add (rf) ;
                ResultHeader rh = new ResultHeader () ;
                rh.label = label ;
                rh.apiname = rf ;
                resultHeaders.add (rh) ;
            }
        }
        // Add the fields which we always need for Account and Address
        acctResultFields.add('Id') ;
        acctResultFields.add('FirstName') ;
        acctResultFields.add('LastName') ;
        acctResultFields.add('Name') ;
        acctResultFields.add('IsPersonAccount') ;
        addrResultFields.add('Id') ;
        addrResultFields.add('Account_vod__c') ;
        addrResultFields.add('Primary_vod__c') ;
               
        //Merck Added - Start
        List <SearchField> allSearchFields = new List <SearchField>();
        allSearchFields.addAll(acctSearchFields);
        allSearchFields.addAll(addrSearchFields);
        allSearchFields.addAll(childAcctSearchFields);
        allSearchFields.addAll(individualAdvSearchFields);
        allSearchFields.addAll(organizationAdvSearchFields);
        allSearchFields.addAll(addrAdvSearchFields);

        List<Map<String,String>> searchMetadata = new List<Map<String,String>>();
        for (searchField sf : allSearchFields) {
            system.debug('kevin1105_10 search field name being added: ' + sf.apiname);
            String  ANI = ApexPages.currentPage().getParameters().get('ANI');

         system.debug('Abu search field name being added: ' + ANI );
            /*Map<String,String> m = new Map<String,String>();
                        if(sf.apiname=='Phone_vod__c'){
                         String  ANI = ApexPages.currentPage().getParameters().get('ANI');
                        system.debug('Abu search field name being added: ' + ANI );
                         m.put('value', ANI );


            }else{
                        m.put('value', sf.value);

            }*/
            Map<String,String> m = new Map<String,String>();
            m.put('apiQualifiedFieldName', sf.obj + '-' + sf.apiname);
            m.put('obj', sf.obj);
            m.put('label', sf.label);
            m.put('apiname', sf.apiname);
        m.put('value', sf.value);
            m.put('alvalue', sf.alvalue);
            m.put('opt_value', sf.opt_value);
            m.put('is_picklist', sf.is_picklist + '');

            if (sf.is_picklist && (sf.plist != null) ) {
                List<Map<String,String>> picklistOptions = new List<Map<String,String>>();
                for (SelectOption so : sf.plist) {
                    Map<String,String> opt = new Map<String,String>();
                    opt.put('label', so.getLabel());
                    opt.put('value', so.getValue());
                    picklistOptions.add(opt);
                }
                m.put('picklist_options', JSON.serialize(picklistOptions));
            }
            
            searchMetadata.add(m);
        }

        remoteClientExecute('searchMetadata', true, null, JSON.serialize(searchMetadata));
        //Merck Added - End
      }catch(Exception ex){ 
         ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'An issue occurred when creating this page. Please contact your System Administator.'));
          system.debug(LoggingLevel.INFO,'jk - ERROR: ' + ex);
      }

    }

   //Merck Added - Start
    public Boolean processRequestedAlignment(String accountId , String alignmentType){
 
            Boolean result = false;
            
            //Determine first if the Account in inactive. User cannot align an Inactive Account.
            //TODO: Uncomment this!!!!! and delete the line below it!
            //Boolean isInactive = [select Inactive_MRK__c from Account where Id = :accountId].Inactive_MRK__c;
            Account a = [SELECT Status_MRK__c FROM Account WHERE Id = :accountId];
            
            Boolean isActive = false;
            if (a.Status_MRK__c == '' || a.Status_MRK__c == null || a.Status_MRK__c == 'ACTIVE') {
                 isActive = true;
            }
            if (!isActive){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'An Alignment Request cannot be processed on an Inactive or Pending Account.'));
                result = false;
            }

            if (isActive){
               
                Savepoint sp = Database.setSavepoint();   

               try {
                  System.debug('About to call: createAlignmentUARObject');
                  AlignmentUARRecord rec = createAlignmentUARObject(accountId, alignmentType);
                  
                  // TODO Uncomment this and make it work
                  addToTerritory(accountId, alignmentType, rec);                  
                  
                  //jk - uncommented insertTSFRecord function
                  insertTSFRecord(rec);
                  System.debug('About to call: insertAlignmentUARRecord');
                  insertAlignmentUARRecord(rec);
                  //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,'Alignment Request Processed.'));
                  
                  result = true;
                  
               } catch (Exception ex) {
                  ApexPages.addMessages(ex);
                  //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Alignment Request aborted.'));
                  Database.rollback(sp);   
                  result =false;
               }
            }
            
            Map<String,String> requestInfo = new Map<String,String>();
            requestInfo.put('alignmentType', alignmentType);
            requestInfo.put('accountId', accountId);
            remoteClientExecute('alignmentResults', result, ApexPages.getMessages(), JSON.serialize(requestInfo));

           return result;
        }
    
    public PageReference temporaryAlignmentRequest() {
        
        String accountId = ((selectedAccountId == null) || (selectedAccountId == '')) ? getSelectedAccount() : selectedAccountId;
        system.debug('In temporaryAlignmentRequest PageReference, about to call processRequestedAlignment...');
        processRequestedAlignment(accountId, 'Temporary');
        system.debug('In temporaryAlignmentRequest PageReference, after our call to processRequestedAlignment...');
        return null;
    }
 
    public PageReference permanentAlignmentRequest() {
         

        String accountId = ((selectedAccountId == null) || (selectedAccountId == '')) ? getSelectedAccount() : selectedAccountId;
        processRequestedAlignment(accountId, 'Permanent');
        
        return null;
    }
    
    public PageReference oneDayAlignmentRequest() {
         

        String accountId = ((selectedAccountId == null) || (selectedAccountId == '')) ? getSelectedAccount() : selectedAccountId;
        processRequestedAlignment(accountId, 'One Day'); 
        
        return null;
    }
    
    
    public PageReference refreshPageRequest() {
        PageReference pg = new PageReference('/apex/searchAccts?sfdc.tabName=01rU0000000Ir4W&showTablet=false');
        pg.setRedirect(true);
        return pg;
    }
  
    
    public void insertAlignmentUARRecord(AlignmentUARRecord rec) {
       try{
            Update_Account_Request_MRK__c uar = new Update_Account_Request_MRK__c();
            uar.Account_MRK__c=rec.accountId;            
            uar.Alignment_End_Date_MRK__c=rec.alignmentEndDate;
            uar.Requestor_MRK__c=rec.userId;
            uar.Alignment_Start_Date_MRK__c=rec.alignmentStartDate;
            uar.Alignment_Request_Type_MRK__c=rec.alignmentType;
            uar.Alignment_Territory_Name_MRK__c=rec.territoryName;
            uar.Change_Type_MRK__c=rec.changeType;
            uar.Approval_Status_MRK__c = rec.approvalStatus;
            uar.recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'MRK_UAR_AR' AND SobjectType = 'Update_account_request_MRK__c'].id;
            system.debug(Logginglevel.INFO,'jk - inserting UAR:' + uar);
            insert uar;
        }catch(Exception ex){
           System.debug('kevin1120 -Exception thrown in insertAlignmentUARRecord:' + ex.getMessage());
           ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Alignment Record Insert Failed. ' + ex.getMessage()));
           throw ex;
        }
    }
     
 
   public AlignmentUARRecord createAlignmentUARObject(Id accountId, String alignmentType) {
        
        AlignmentUARRecord rec; 
                
        try{
           //Removed to support TM2.0
           //List<UserTerritory> utList = [select TerritoryId from userterritory where UserId = :UserInfo.getUserId()];
           //Added to support TM2.0
           List<UserTerritory2Association> utList = [select Territory2Id 
                                                     from UserTerritory2Association 
                                                     where UserId = :UserInfo.getUserId() 
                                                     AND IsActive = true
                                                     AND Territory2.Territory2Model.state ='Active'];           
           
           rec = new AlignmentUARRecord();
           //Removed to support TM2.0
           //rec.territoryName = [select Name from Territory where Id = :utList[0].TerritoryId].Name;
           //Added to support TM2.0           
           rec.territoryName = [select Name from Territory2 where Id = :utList[0].Territory2Id].Name;  
            
           rec.userId = UserInfo.getUserId();
           rec.changeType = 'Alignment Request';
           rec.accountId = accountId;
           rec.requestDate = System.now().date();
           rec.alignmentType = alignmentType;
           rec.alignmentStartDate = System.now().date();
           if (alignmentType == 'One Day') {
                rec.approvalStatus = this.uarDefaultStatus;
                rec.alignmentEndDate = system.now().addDays(1).date();
                rec.source = 'ODA';
           } else if (alignmentType == 'Permanent' || alignmentType == 'Temporary') {
                //TODO: set approval status to Pending
                rec.approvalStatus = this.uarDefaultStatus;
                rec.alignmentEndDate = lastDayOfXMonthsOut(3);
                rec.source = 'GAS'; 
           }

           //rec.approvalStatus = 'Approved';
           //jk - now getting approval status from custom setting
           
            
           System.debug('Kevin: About to leave: createAlignmentUARObject');
        }catch(Exception ex){
           System.debug('Kevin:Exception in : createAlignmentUARObject ' + ex.getMessage());
           ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Alignment Record creation Failed. ' + ex.getMessage()));
           throw ex;
        }    
        
        return rec;     
               
    }
        
    //jk - uncommented this method
    public void insertTSFRecord(AlignmentUARRecord rec) {
        //TODO: jk - check for existing TSF and update
        List<TSF_vod__c> existingTSFs = new List<TSF_vod__c>();
        String externalId = rec.accountId +'__' + rec.territoryName;
        existingTSFs = [SELECT Name, Territory_vod__c, Account_vod__c, 
                              Alignment_Start_Date_MRK__c, Alignment_End_Date_MRK__c, Call_Deck_Status_MRK__c
                       FROM TSF_vod__c
                       WHERE External_Id_vod__c = :externalId];
        
        if (!existingTSFs.IsEmpty()) {
            //There is an existing TSF for this account. Update
            for (TSF_vod__c tsf : existingTSFs) {
                tsf.Alignment_Start_Date_MRK__c=rec.alignmentStartDate;
                tsf.Alignment_End_Date_MRK__c=rec.alignmentEndDate;
                tsf.Call_Deck_Status_MRK__c=rec.alignmentType;
                tsf.Approval_Status_MRK__c=rec.approvalStatus;
                //TODO: if temp of perm set approval status = approved
                tsf.Sync_MRK__c=true;
            }
            try {
                system.debug(Logginglevel.INFO,'jk - updating TSF:' + existingTSFs);
                update existingTSFs;
            } catch (Exception ex) {
                system.debug(Logginglevel.INFO,'jk - updating TSF ERROR:' + ex);
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'TSF Record Update Failed.'));
                throw ex;
            }
        } else {
            //no existing TSF. Create a new one
            // create new TSF record
            TSF_vod__c tsf = new TSF_vod__c(
                Name=rec.territoryName,
                Territory_vod__c=rec.territoryName,
                Account_vod__c=rec.accountId,
                Alignment_Start_Date_MRK__c=rec.alignmentStartDate,
                Alignment_End_Date_MRK__c=rec.alignmentEndDate,
                Call_Deck_Status_MRK__c=rec.alignmentType,
                //TODO: if temp of perm set approval status = approved
                Approval_Status_MRK__c=rec.approvalStatus,
                Sync_MRK__c=true 
            );
            try{
                system.debug(Logginglevel.INFO,'jk - inserting TSF:' + tsf);
                insert tsf;
            }catch(Exception ex){
               ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'TSF Record Insert Failed.'));
               throw ex;
            }
        }
    }   
    

 
    public Date lastDayOfXMonthsOut(Integer monthsOut){
        
        DateTime now = System.now();
        Integer month = now.month(),
                daysToAdd = 1,
                nextMonth = now.addMonths(monthsOut + 1).month();
        while (month != nextMonth) {
            month = now.addDays(daysToAdd++).month();
        }
 
        // back up to last day
        daysToAdd -= 1;
        
        return now.addDays((daysToAdd < 0) ? 0 : daysToAdd ).date() -1;
 
    }
    
    /*
    public Date lastDayXMonthsOut(Integer monthsOut) {
        DateTime now = System.now();
        Integer month = now.month(),
                daysToAdd = 1,
                nextMonth = now.addMonths(monthsOut).month();
        while (month != nextMonth) {
            month = now.addDays(daysToAdd++).month();
        }
 
        // back up to last day
        daysToAdd -= 1;
 
        return now.addDays( (daysToAdd < 0) ? 0 : daysToAdd ).date();
    }   

    */

    public PageReference processSearchType(){
 
      if(searchType=='Individuals'){
                individualAdvRendered=true;
                organizationAdvRendered=false; 
      }else{
            individualAdvRendered=false;
            organizationAdvRendered=true; 
      }
        return null;
     }
//Merck Added - End


    public PageReference sortResults() {
        String newSortKey = ApexPages.currentPage().getParameters().get('sortKey');
        if (newSortKey == sortKey) {
            // Just change sortDir
            if (sortDir == 'A') {
                sortDir = 'D' ;
            }
            else {
                sortDir = 'A' ;
            }
        }
        else {
            sortKey = newSortKey ;
            sortDir = 'A' ;
        }
        results = SortSearchResults(results, sortKey, sortDir) ;
        return null ;
    }

    public PageReference doSearch() {
        
        try {
        
        
            String individualSearchParam = apexpages.currentpage().getparameters().get('individualAdvRendered');
        
            system.debug('Kevin1105_20 The individualSearchParam value is: ' + individualSearchParam);
    
        
            //jk - set cookie
            
            if(individualSearchParam == 'true'){
                individualAdvRendered=true;
                organizationAdvRendered=false;
                
                Cookie searchCookie = new Cookie('GASsearch', 'person', null, 315569260, false);
                ApexPages.currentPage().setCookies(new Cookie[] {
                    searchCookie
                });
                
            }else{
                individualAdvRendered=false;
                organizationAdvRendered=true;
                
                Cookie searchCookie = new Cookie('GASsearch', 'business', null, 315569260, false);
                ApexPages.currentPage().setCookies(new Cookie[] {
                    searchCookie
                }); 
            }
            
            
            
            System.debug('The value of individualAdvRendered and organizationAdvRendered are: ' + individualAdvRendered + ' and '+ organizationAdvRendered);
              
            results = new List<SearchResult> () ;
            Set <Id> gotAccts = new Set<Id> ();
            List <ID> acctIds = new List <String> () ;
            String whereClause = '' ;
             String addrOnlyWhereClause = '' ;
            Boolean searchAddrFirst = false ;
            Boolean searchByAddrOnly = true;
            Boolean searchChildAccounts = false;
            String prefix = '' ;
            // Determine if user has enetered any values for address search fields
            
            // Merck Added - Start
            //KRB - Combined the Std and Adv Search Fields. New Combined Variable added to the For Loop
            List<SearchField> addrFields = new List<SearchField>();
            addrFields.addAll(addrSearchFields);
            addrFields.addAll(addrAdvSearchFields);
            
            for (searchField sf : addrFields) {
                if (sf.value != '' && sf.value != 'null' && sf.value != null) {
                searchAddrFirst = true  ;
                prefix = 'Account_vod__r.' ;
                    break ;
                }
            }
            
            for (searchField sf : childAcctSearchFields) {
                if (sf.value != '' && sf.value != 'null' && sf.value != null) {
                    searchChildAccounts = true;
                    break ;
                }
            }             
            // Merck Added - End
            
            /* Original Veeva Commented out. Replaced with the above Code.
            
            for (SearchField sf : addrSearchFields) {
                if (sf.value != '' && sf.value != 'null' && sf.value != null) {
                searchAddrFirst = true  ;
                prefix = 'Account_vod__r.' ;
                    break ;
                }
            } 
            */
            
            // Boolean got_csz = false; // Got City, State or Zip
            // Boolean got_noncsz = false; // Other than City, State or Zip
            Boolean got_pname = false; // Got person name
            Boolean got_name = false; // Got full name

            // Combine the search fields
            List <SearchField> allSearchFields = new List <SearchField> () ;
            allSearchFields.addAll(acctSearchFields) ;
            allSearchFields.addAll(addrSearchFields) ;
            allSearchFields.addAll(addrAdvSearchFields) ;
           
            System.debug('kevin1105_11: value of individualAdvRendered is : ' + individualAdvRendered);
            
            if(individualAdvRendered){
                System.debug('kevin1105_30: Assigning individualAdvSearchFields');
                allSearchFields.addAll(individualAdvSearchFields);
            }else{
                System.debug('kevin1105_30: Assigning organizationAdvSearchFields');
                allSearchFields.addAll(organizationAdvSearchFields);
            }

            /* KRB - 8/6 Need to preprocess the Searchable Id Fields. One field from UI, "Searchable_Id_MRK__c"
               needs to be converted into an "OR" condition. The fields for the OR condition will come from the 
               Custom setting: "Searchable Account Ids". Searchable Account Ids includes a list of Ids (NPI, AOA, Merck Id, etc)
               that the Searchable_Id_MRK__c will be searched against.
               TODO: Refactor the code...
            */
            
            for (searchField sf : allSearchFields) {
                          
                if (sf.apiname == 'Searchable_Id_MRK__c' && sf.value != '' && sf.value != 'null' && sf.value != null ){
                    whereClause += '(';
                    
                    for (String s: acctSearchableIdFieldSet){
            
                         System.debug('Kev - Working with Searchable field: ' + s );
                      
                         String field = s;
                         String op = '=' ;
                         String value = sf.value ;

                        if (sf.obj == 'Account') {
                             field = prefix + field ;
                        }

                        if (sf.opt_value == 'Starts With') {
                           op = 'like' ;
                           value = value + '%' ;
                        }
                    
                        if (sf.opt_value == 'Contains') {
                          op = 'like' ;
                           value = '%' + value + '%' ;
                        }
                    
                        // Put quotes around val for relevant types
                        if(!sf.no_quote) {
                           value = '\'' + value + '\'' ;
                        }
                        
                        if (whereClause != '(') {
                            whereClause += ' OR ' ;
                        }
                        
                        whereClause += ' ' + field + ' ' + op + ' ' + value;
                    }
                    
                    whereClause += ' ) ';
                }
            }
            
            System.debug ('Kev - DEBUG where clause after combining IDs: ' + whereClause) ;           
            //Merck Added - End

            //Here 
            
             /* KRB - 11/5/2013 Need to preprocess the Account Steward Search. 
               Ui Field is just in input field. Need to use the actual Formula field to preform the Search.
            */
            
            for (searchField sf : allSearchFields) {
                
                System.debug('kevin1105_1: ' +  sf.apiname + ' and value is: ' + sf.value + ' End');        
                
                if (sf.apiname == 'Account_Steward_Searchable_Name_MRK__c' && sf.value != '' && sf.value != 'null' && sf.value != null ){
                    
                    if(whereClause != '' && whereClause != null){
                        whereClause += 'AND (';
                    }else{
                       whereClause += '(';
                    }
                               
                    System.debug('Kev - Working with Searchable field: ' + sf );
                      
                    String field = 'Account_Steward_Name_MRK__c';
                    String op = '=' ;
                    String value = sf.value ;

                    if (sf.obj == 'Account') {
                        field = prefix + field ;
                    }

                    if (sf.opt_value == 'Starts With') {
                       op = 'like' ;
                       value = value + '%' ;
                    }
                    
                    if (sf.opt_value == 'Contains') {
                       op = 'like' ;
                       value = '%' + value + '%' ;
                    }
                    
                    // Put quotes around val for relevant types
                    if(!sf.no_quote) {
                       value = '\'' + value + '\'' ;
                    }
                                               
                    whereClause += ' ' + field + ' ' + op + ' ' + value;
                    
                   
                    whereClause += ' ) ';
                }
            }

            
            System.debug ('kevin1105_2 - DEBUG where clause after preprocessing Account Steward: ' + whereClause) ;           
            
            
 
            /* KRB - 10/152013 Need to preprocess the Merck Steward Field. 
               TODO: Refactor the code...
            */
            /*
            for (searchField sf : allSearchFields) {
                          
                if (sf.apiname == 'Account_Steward_Searchable_Name_MRK__c' && sf.value != '' && sf.value != 'null' && sf.value != null ){
                     String field = 'Account_Steward_Name_MRK__c' ;
                
                   
                        
                    
                    String op = 'like' ;
                    String value = '%' + sf.value + '%' ;
                    
                     System.debug('Kev66 - Working with Searchable field: ' + sf.apiname );
                     whereClause += ' ' + field + ' ' + op + ' ' + value;
                     
                     
                     
                      
                 }
                 
                 
            }

         */

         System.Debug('Kevin22: The number of search Fields is: ' + allSearchFields.size());
   
            // Go thru each search field
            for (SearchField sf : allSearchFields) {
            
            
            
            System.Debug('Kevin22: working field: API NAME: ' + sf.apiname + ' and the value is: ' + sf.value );
            

                
                
              System.debug ('Kev33 - DEBUG where clause after combining Merck Stward: ' + whereClause) ;           
              
               //if (sf.value != '' && sf.value != 'null' && sf.value != null && sf.apiname != 'Searchable_Id_MRK__c' ) {
                
                
               if (sf.value != '' && sf.value != 'null' && sf.value != null && sf.apiname != 'Searchable_Id_MRK__c' && sf.apiname != 'Account_Steward_Searchable_Name_MRK__c' ) {
                //Merck Added - End
                    String field = sf.apiname ;
                    String op = '=' ;
                    String value = sf.value ;
                    // Escape any quotes in the value
                    //JK - changing to use escapeSingleQuotes method
                    //value = value.replace('\'', '\\\'') ;
                    value = String.escapeSingleQuotes(value);
                    
                    if (sf.obj == 'Account') {
                        field = prefix + field ;
                    }

                    if (sf.opt_value == 'Starts With') {
                        op = 'like' ;
                        value = value + '%' ;
                    }
                    if (sf.opt_value == 'Contains') {
                        op = 'like' ;
                        value = '%' + value + '%' ;
                    }

                    if (sf.is_phone) {
                        op = 'like' ;
                        value = getPhoneRegex(value) ;
                    }
                    
                    // Put quotes around val for relevant types
                    if(!sf.no_quote) {
                        value = '\'' + value + '\'' ;
                    }
                    if (whereClause != '') {
                        whereClause += ' AND ' ;
                    }
                    whereClause += ' ' + field + ' ' + op + ' ' + value;

       System.Debug('Kevin1105_3: Where clause now says: ' + whereClause);
     

                    if (sf.obj == 'Account') {
                        if (sf.apiname == 'Name') {
                            got_name = true ;
                        }
                        if (sf.apiname == 'FirstName' || sf.apiname == 'LastName') {
                            got_pname = true ;
                        }
                    }
                }
            }
            
            //Merck Added - Start
             addrOnlyWhereClause = whereClause;
          if (whereClause != '') {  
            if(individualAdvRendered){
                  whereClause += ' AND IsPersonAccount=true AND RecordTypeId in ('+   createCommaSeparatedQuotedStringFromMapKeySet(individualAccountRecTypesMap)  + ')' ;
                  addrOnlyWhereClause += ' AND Account_vod__r.IsPersonAccount=true AND Account_vod__r.RecordTypeId in ('+   createCommaSeparatedQuotedStringFromMapKeySet(individualAccountRecTypesMap)  + ')' ;
               }else{ //Orgs
                  whereClause += ' AND IsPersonAccount=false AND RecordTypeId in ('+   createCommaSeparatedQuotedStringFromMapKeySet(organizationAccountRecTypesMap)  + ')' ;
                  addrOnlyWhereClause += ' AND Account_vod__r.IsPersonAccount=false AND Account_vod__r.RecordTypeId in ('+   createCommaSeparatedQuotedStringFromMapKeySet(organizationAccountRecTypesMap)  + ')' ;
               }
           }
            //Merck Added - End          
            
            
            wc = whereClause ;
            
            System.debug ('Kevin22Kev - DEBUG6 whereClause at 6: ' + whereClause) ;
            System.debug ('Kevin22Kev - DEBUG6 addrOnlyWhereClause at 6: ' + addrOnlyWhereClause) ;
 
//TODO: Uncomment
            
            if (whereClause == '' && searchChildAccounts == false) {
                ApexPages.addMessage (new ApexPages.Message(ApexPages.Severity.WARNING, GAS_NOCRIT));
                return null ;
            }
            
            if (got_pname == true && got_name == true) {
                ApexPages.addMessage (new ApexPages.Message(ApexPages.Severity.WARNING, GAS_NAMESEARCH));
                return null ;
            }
            // if (got_csz == true && got_noncsz == false) {
                // ApexPages.addMessage (new ApexPages.Message(ApexPages.Severity.WARNING, 'When enterting city, state or zip, at least one other search criteria must be provided'));
                // return null ;
            // }
            //TODO: have to probably search Child Account here
            Set<Id> childAccountIds = new Set<Id>();
            if (searchChildAccounts) {
                String query = getChildAccountQuerystring(childAcctSearchFields);
                system.debug('jk - child account query: ' + query);
                for (Child_Account_vod__c ca : Database.query(query)) {
                    //acctIds.add(ca.Child_Account_vod__c);
                    childAccountIds.add(ca.Child_Account_vod__c);
                }               
            } else {
                system.debug('jk - not searching child account');
            }
            
            if (searchAddrFirst && whereClause != '') {
            
              System.debug ('Kev -DEBUG searchAddrFirst = true -- select Account_vod__c, Account_vod__r.IsPersonAccount from Address_vod__c where ' + addrOnlyWhereClause) ;               
              System.debug ('Kev -DEBUG IDs returned:\n');               

            
            
                //for (Address_vod__c ad : Database.query('select Account_vod__c, Account_vod__r.IsPersonAccount from Address_vod__c where ' + whereClause)) {
                //Merck Added - Start
                   for (Address_vod__c ad : Database.query('select Account_vod__c, Account_vod__r.IsPersonAccount from Address_vod__c where ' + addrOnlyWhereClause)) {             
                //Merck Added End
                
                        acctIds.add(ad.Account_vod__c) ;
                }
            } else if (whereClause != '') {
                String resFields = joinStrings(acctResultFields,',') ;
                // Add Formatted_Name_vod__c if it's not there
                if (!resFields.contains('Formatted_Name_vod__c')) {
                    resFields += ',Formatted_Name_vod__c' ;
                }
                                  System.debug ('Kev -DEBUG searchAddrFirst = false -- select Id,IsPersonAccount from Account where ' + whereClause + ' order by Name,Id') ;               
                  System.debug ('DEBUG IDs returned:\n'); 

                
                for (Account a : Database.query('select Id,IsPersonAccount from Account where ' + whereClause + ' order by Name,Id')) {
                        System.debug (a.Id); 
                        acctIds.add(a.Id) ;
                }
            }
            wc = 'at 1' ;
            System.debug('ABU CODE BEGINS');
            Set <Id> commAccountIds= new Set<Id>();
            Set <Id> aIDAccountIds = new Set<Id>();
                for (searchField sf : allSearchFields) {

                    if (sf.apiname == 'Phone_vod__c' && sf.value != '' && sf.value != 'null' && sf.value != null ){
                        List<List<SObject>>searchList = new List<List<SObject>>();
                       
                        
                       if(individualAdvRendered){
                           searchList=[FIND :sf.value   IN PHONE FIELDS 
                                                          RETURNING Communication_Mechanism_MRK__c(Id,Account_MRK__c 
                                                                     where Account_MRK__r.isPersonAccount= true
                                                                       and Do_Not_Use_Inbound_Routing_MRK__c =false) ];
                        }else{
                           searchList=[FIND :sf.value   IN PHONE FIELDS 
                                                          RETURNING Communication_Mechanism_MRK__c(Id,Account_MRK__c 
                                                                     where Account_MRK__r.isPersonAccount= false
                                                                       and Do_Not_Use_Inbound_Routing_MRK__c =false) ];
                        }
                                                                       
                          List<Communication_Mechanism_MRK__c> comMechList= ((List<Communication_Mechanism_MRK__c>)searchList[0]);
                          
                          for(Communication_Mechanism_MRK__c comm: comMechList){
                            commAccountIds.add(comm.Account_MRK__c);
                          }
                           acctIds.addAll(commAccountIds);
                           System.debug('AA Communication Mechanism Ids : '+commAccountIds+' : '+sf.value);
                          break;
                    }
                }

                for (searchField sf : allSearchFields) {
                    if (sf.apiname == 'Searchable_Id_MRK__c' && sf.value != '' && sf.value != 'null' && sf.value != null ){
                        List<List<SObject>>searchList = new List<List<SObject>>();
                        
                        

                                          
                       if(individualAdvRendered){
                            searchList=[FIND :sf.value
                                     IN ALL FIELDS 
                                     RETURNING Alternate_Identifier_MRK__c(Id, Account_MRK__c,Alternate_Identifier_Value_MRK__c 
                                       where Account_MRK__r.isPersonAccount= true
                                  ) ];
                        }else{
                           searchList=[FIND :sf.value
                                     IN ALL FIELDS 
                                     RETURNING Alternate_Identifier_MRK__c(Id, Account_MRK__c,Alternate_Identifier_Value_MRK__c 
                                       where Account_MRK__r.isPersonAccount= false 
                                  ) ];
                        }

                       List<Alternate_Identifier_MRK__c> alternateIDList= ((List<Alternate_Identifier_MRK__c>)searchList[0]);
                  
                         for(Alternate_Identifier_MRK__c alternateID: alternateIDList){
                            if(alternateID.Alternate_Identifier_Value_MRK__c.contains(sf.value)){
                                aIDAccountIds.add(alternateID.Account_MRK__c);
                            }
                          }
                           acctIds.addAll(aIDAccountIds);
                           System.debug('AA Alternate Ids '+aIDAccountIds +' : '+sf.value);
                           break;   
                    }
                }
            
            
            System.debug('ABU CODE ENDS');

            // Error if nothing found
            if (acctIds.size() == 0 && childAccountIds.size() == 0) {
                ApexPages.addMessage (new ApexPages.Message(ApexPages.Severity.WARNING, GAS_NOMATCH));
                return null;
            }
            
            //jk - if we have both child account and account ids, need to filter
            if (acctIds.size() > 0 && childAccountIds.size() > 0) {
                List<Id> filteredIds = new List<id>();
                for (Id i : acctIds) {
                    if (childAccountIds.contains(i)) {
                        filteredIds.add(i);
                    }
                }
                acctIds.clear();
                acctids.addAll(filteredIds);
            } else if (acctids.size() == 0 && childAccountIds.size() > 0) {
                //no account results, but do have childAccountResults
                acctIds.addAll(childAccountIds);
            }
            
            
            // If this is a search for parent, remove the account IDs we have found which are not parents.  We can do this
            // by using a GROUP BY clause which counts child accounts per parent.  This query will not return those Accounts
            // which have no child accounts.  Since we can't have more than 1000 elements in :acctIds, error out if we have more than 1000
            if (parentSearch == '1' && acctIds.size() > 1000) {
                ApexPages.addMessage (new ApexPages.Message(ApexPages.Severity.WARNING, GAS_TOOMANY));
                return null;
            }
            Set <ID> distinctAcctIds = new Set<ID>() ;
System.debug ('parentSearch is ' + parentSearch) ;
            if (parentSearch == '1') {
                String query = 'select ' + parentAcctField + ', Count(Id) from Account where Primary_Parent_vod__c  in :acctIds group by ' + parentAcctField + '' ;
                AggregateResult[] groupedResults = database.query(query);
                for (AggregateResult ar : groupedResults)  {
                    System.debug('Primary_Parent_vod__c ID' + ar.get('Primary_Parent_vod__c'));
                    distinctAcctIds.add((String)ar.get('Primary_Parent_vod__c')) ;
                }
            }
            else {
                distinctAcctIds.addAll(acctIds) ;
            }
            // Maximum of 20 distinct Accounts; As part of 9.0 release the search result set was parameterized to use a variable "GAS_LIMIT"; Before 9.0 this limit was set as 20.
            if (distinctAcctIds.size() > GAS_LIMIT) {
                ApexPages.addMessage (new ApexPages.Message(ApexPages.Severity.WARNING, GAS_TOOMANY));
                return null;
            }
            
     // Code Commented to remove In Call Deck Indicator :   Map<Id,AccountShare> alignedAccounts = getAlignedAccountIds(distinctAcctIds);

            // We now do a Parent to Child query to get the Accounts we want, along with their addresses.  Order addresses by Primary Address
            String resFields = joinStrings(acctResultFields,',') ;
            // Add Formatted_Name_vod__c if it's not there
            if (!resFields.contains('Formatted_Name_vod__c')) {
                resFields += ',Formatted_Name_vod__c' ;
            }
            
            //mnaidu 7/16/2013 - GAS 2.1 enhancement
            //remove the account ids that need to be excluded
            if(GAS_Hierarchical_Setting__c.getInstance().Do_Criteria_Based_Filtering__c){
                acctIds = excludeAccountsIfAny(acctIds);
            }
            
            String q = 'select ' + resFields + ', (select ' + joinStrings(addrResultFields,',') + ' from Address_vod__r order by Primary_vod__c desc, CreatedDate) from Account where Id in :acctIds' ;


            for (Account a : Database.query(q)) {
                SearchResult mainSR ;
                Integer ix = 0 ;
                if (a.Address_vod__r.size() > 0) {
                    for (Address_vod__c ad : a.Address_vod__r) {
                        // Build the searchResults
                        SearchResult sr = new SearchResult () ;
                        sr.acctId = a.Id ;
                        sr.addrId = a.Address_vod__r[ix].Id ;
                        sr.isSelected = false ;
                        // Now get field values 
                        sr.srFields = new List<SearchResultField> () ;
                        for (String rf : resultFieldSet) {
                            SearchResultField srf = new SearchResultField () ;
                            srf.apiname = rf ;
                            String typex  = resFieldTypeMap.get(rf) ;
                            if (rf.startsWith('ADD.')) {
                                srf.value = getObjValue(a.Address_vod__r[ix], rf, typex) ;
                                srf.label = resFieldLabelMap.get(rf) ;
                                srf.is_Addr = true ;
                                srf.is_Acct = false ;   
                            }
                            else {
                                srf.value = getObjValue(a, rf, typex) ;
                                srf.label = resFieldLabelMap.get(rf) ;

                                // Use Formatted_Name_vod__c for Name
                                if (rf == 'Name') {
                                    srf.value = getObjValue(a, 'Formatted_Name_vod__c', 'String') ;
                                }
                                srf.is_Addr = false ;
                                srf.is_Acct = true ;
                            }
                            // The rawvalue of the srf will be used for sorting
                            srf.rawvalue = srf.value ;
                            if ((typex == 'Date' || typex == 'Datetime') && srf.value != '') {
                                // For sorting purposes, store rawvalue of Date/Datetime as seconds since epoch
                                String dtval = srf.value ;
                                if (typex == 'Date') {
                                    dtval = Datetime.newInstance(Date.parse(srf.value), Time.newInstance(0, 0, 0, 0)).format() ;
                                }
                                srf.rawvalue = (String) Datetime.parse(dtval).getTime().format() ;
                            }
                            sr.srFields.add(srf) ;
                        }
                        sr.acctName = a.Name ;
                        if (ix == 0) {
                            sr.otherAddrs = new List<SearchResult> () ;
                            mainSR = sr ;
       // Code Commented to remove In Call Deck Indicator : sr.srFields.add(getInCallDeckSearchResultField(a.Id,alignedAccounts));
                            results.add(mainSR) ;
                        }
                        else {
                            mainSR.otherAddrs.add(sr) ;
                        }
                        ix++ ;
                        // If we are not showing all addresses, and we are done with the first, then break out of loop
                        if (!showAllAddrs) {
                            break ;
                        }
                    }
                }
                else {
                    // No address, just get and set Account info
                    SearchResult sr = new SearchResult () ;
                    sr.acctId = a.Id ;
                    sr.addrId = '' ;
                    sr.isSelected = false ;
                    // Now get field values 
                    sr.srFields = new List<SearchResultField> () ;
                    for (String rf : resultFieldSet) {
                        SearchResultField srf = new SearchResultField () ;
                        srf.apiname = rf ;
                        String typex  = resFieldTypeMap.get(rf) ;
                        if (rf.startsWith('ADD.')) {
                            srf.value = '' ;
                            srf.label = resFieldLabelMap.get(rf) ;
                            srf.is_Addr = true ;
                            srf.is_Acct = false ;
                        }
                        else {
                            srf.value = getObjValue(a, rf, typex) ;
                            srf.label = resFieldLabelMap.get(rf) ;
                            // Use Formatted_Name_vod__c for Name
                            if (rf == 'Name') {
                                srf.value = getObjValue(a, 'Formatted_Name_vod__c', 'String') ;
                            }
                            srf.is_Addr = false ;
                            srf.is_Acct = true ;
                        }
                        // The rawvalue of the srf will be used for sorting
                        srf.rawvalue = srf.value ;
                        if ((typex == 'Date' || typex == 'Datetime') && srf.value != '') {
                            // For sorting purposes, store rawvalue of Date/Datetime as seconds since epoch
                            String dtval = srf.value ;
                            if (typex == 'Date') {
                                dtval = Datetime.newInstance(Date.parse(srf.value), Time.newInstance(0, 0, 0, 0)).format() ;
                            }
                            srf.rawvalue = (String) Datetime.parse(dtval).getTime().format() ;
                        }
                        sr.srFields.add(srf) ;
                        
                    }
           // Code Commented to remove In Call Deck Indicator : sr.srFields.add(getInCallDeckSearchResultField(a.Id,alignedAccounts));
                    sr.acctName = a.Name ;
                    sr.otherAddrs = new List<SearchResult> () ;
                    mainSR = sr ;
                    results.add(mainSR) ;
                }
                
                
                
            }
            // Sort.  Initial sort is by first result field, which has already been set in constructor
            results = SortSearchResults(results, sortKey, sortDir) ;
        
            //Merck Added - Start
            remoteClientExecute('searchResults', true, null, JSON.serialize(results));
            //Merck Added - End
        }
        catch (Exception ex) {
            ApexPages.addMessages(ex);
        }finally {
            //Merck Added - Start
            remoteClientExecute('searchResults', true, ApexPages.getMessages(), JSON.serialize(results));
            //Merck Added - End

        }

        return null;
    }


     public void remoteClientExecute(String type, Boolean success, ApexPages.Message[] messages, String dataAsJSON) {
        String messagesAsJSON = '[]';
        if (messages != null) {
            List<String> msgs = new List<String>();
            for (ApexPages.Message m : messages) {
                msgs.add(m.getSummary());
            }
            messagesAsJSON = JSON.serialize(msgs);
        }
        
        if (dataAsJSON == null) {
            dataAsJSON = 'null';
        }
    
        javascriptToExecuteOnClient = 'app.execute({\'type\': \'' + type + '\', \'success\': ' + success + ', \'messages\': ' + messagesAsJSON + ', \'data\': ' + dataAsJSON + '});';           
    }


        //Merck Added - Start
        //jk - uncommented this method
    public TempAlignmentRecord createAlignmentRecord(Id accountId, String alignmentType) {
        //Removed to Support TM2.0
        //List<UserTerritory> utList = [select TerritoryId from userterritory where UserId = :UserInfo.getUserId()];
        //Added to support TM2.0
        List<UserTerritory2Association> utList = [SELECT Territory2Id 
                                                  FROM   UserTerritory2Association 
                                                  WHERE  UserId = :UserInfo.getUserId()
                                                  AND    IsActive = true
                                                  AND    Territory2.Territory2Model.state ='Active']; 
        
        
        TempAlignmentRecord rec = new tempAlignmentRecord();
        //Removed to Support TM2.0
        //rec.territoryName = [select Name from Territory where Id = :utList[0].TerritoryId].Name;
        //Added to support TM2.0
        rec.territoryName = [select Name from Territory2 where Id = :utList[0].Territory2Id].Name;
        
        rec.userId = UserInfo.getUserId();
        rec.accountId = accountId;
        rec.requestDate = System.now().date();
        rec.alignmentStatus = alignmentType;
        rec.alignmentStartDate = System.now().date();
        rec.alignmentEndDate = lastDayInMonth();

        return rec;       
    }

  
    public Date lastDayInMonth() {
        DateTime now = System.now();
        Integer month = now.month(),
                daysToAdd = 1,
                nextMonth = now.addMonths(1).month();
        while (month != nextMonth) {
            month = now.addDays(daysToAdd++).month();
        }
        
        // back up to last day
        daysToAdd -= 1;
        
        return now.addDays( (daysToAdd < 0) ? 0 : daysToAdd ).date();
    }    
    
    //Merck Added - End
    
    //TODO FYI this was changed. Was a Standard Method in 1.0 - might need to revist
    public void addToTerritory(String acctId, String alignmentType, AlignmentUARRecord rec) {
    //public PageReference addToTerritory() {
        system.debug('jk - starting addToTerritory');
         
        String newAcctId  = '';
        if (results == null || results.size() == 0) {
            //return null ;
            return;
        }
        // Find the selected Account
        //jk - adding passed account id as opposed to finding selected  
        newAcctId = acctId;
        /*
        for (SearchResult sr : results) {
            if (sr.isSelected == true) {
                newAcctId = sr.acctId ;
                break ;
            }
        }
        */
        
        if (newAcctId == '') {
            //return null ;
            system.debug('jk - newAcctID is null. Exiting.');
            return;
        }

        // Get the territory for the user
        //jkelso - 8/12/13 - build list of multiple territories and territory Ids
        
        //KRB 2/7/20 - Removed for TM2.0
        //List<UserTerritory> utList = new List<UserTerritory>();
        //KRB 2/7/20 - Add for TM2.0
        List<UserTerritory2Association> utList = new List<UserTerritory2Association>();

        List<Id> utIds = new List<Id>();
        
        //KRB 2/7/20 - Removed for TM2.0
        //for (UserTerritory ut :[select TerritoryId from userterritory where UserId = :UserInfo.getUserId()]) {
        //KRB 2/7/20 - Add for TM2.0
        for (UserTerritory2Association ut :[select Territory2Id 
                                            from UserTerritory2Association 
                                            where UserId = :UserInfo.getUserId() 
                                            AND IsActive = true
                                            AND Territory2.Territory2Model.state ='Active']) { 
                                                
            system.debug(LoggingLevel.Info,'ut: ' + ut);
            utList.add(ut);
            //KRB 2/7/20 - Removed for TM2.0
            //utIds.add(ut.TerritoryId);
            //KRB 2/7/20 - Add for TM2.0
            utIds.add(ut.Territory2Id);
        }
        system.debug('utList: ' + utList);
        if (utList.size() == 0) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,GAS_NOTALGN));
            return;
        }
        //jkelso - 8/12/13 - new custom setting to allow align of multiple territory
        else if (utList.size() > 1 && !GAS_ALIGN_MULTIPLE) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,GAS_MANYALGN));
            return;
        }
        // Get the name of the Territory
        List<String> userTerrNames = new List<String>();
        String terrString = '';
        //jkelso - 8/12/13 - build string of multiple territories
        system.debug('utIds: ' + utIds);
     
        //KRB 2/7/20 - Removed for TM2.0
        //for (Territory t : [SELECT Name FROM Territory WHERE ID IN :utIds]) {
        //KRB 2/7/20 - Add for TM2.0    
        for (Territory2 t : [SELECT Name FROM Territory2 WHERE ID IN :utIds]) {    
            userTerrNames.add(t.Name);
            terrString += t.Name + ';';
        }
        terrString  = terrString.Substring(0,terrString.length()-1);
        system.debug('terrString after building territories: ' + terrString);
        
        //KRB - TODO
        // Now check for existing territories for the Account
        List <AccountShare> asList = [select AccountId,UserOrGroupId, RowCause 
                                      from AccountShare 
                                      where AccountId =  :newAcctId //and RowCause in ('TerritoryManual') - mnaidu;04/28/13 - check for any kinds of alignment
                                      ] ;
        if (asList.size() > 0) {
            // Get all the UserOrGroupIds, and store in a List
            List<Id> idlist1 = new List<Id> () ;
            Set<Id> manuallyAssignedGrpIDs = new Set<ID>();//mnaidu - 4/28/13 - capture what's manually assigned
            Set<Id> manuallyAssignedTerrIDs = new Set<ID>();//mnaidu - 4/28/13 - capture what's manually assigned
            for (AccountShare ash : asList) {
                idlist1.add(ash.UserOrGroupId) ;
                
                //KRB 2/10/2020 - out for TM2.0 
                //if(ash.RowCause=='TerritoryManual'){
                //KRB 2/10/2020 - in for TM2.0 
                if(ash.RowCause=='TerritoryManual' || ash.RowCause == 'Territory2AssociationManual'){    

                    manuallyAssignedGrpIDs.add(ash.UserOrGroupId);   //mnaidu - 4/28/13 - capture what's manually assigned              
                }
            }
            // Now let's get the IDs of the Territories
            List<Id> idlist2 = new List<Id> () ;
            List<Group> groupList = [select RelatedId from group where Id in :idlist1] ;
            for (Group g : groupList) {
                idlist2.add(g.RelatedId) ;
                if(manuallyAssignedGrpIDs.contains(g.Id)){
                    manuallyAssignedTerrIDs.add(g.RelatedId); //mnaidu - 4/28/13 - capture what's manually assigned
                }
            }
            // Finally, get the names
            
            // KRB 2/7/20 - Remove for TM2.0
            //List <Territory> terrList = [select Id, Name from Territory where Id in :idlist2] ;
            // KRB 2/7/20 - Add for TM2.0
            List <Territory2> terrList = [select Id, Name from Territory2 where Id in :idlist2] ;
            for (Territory2 t : terrList) {
                // If the Territory is already there, output a warning and exit
                for (String utn : userTerrNames) {
                    if (t.Name == utn) {
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,GAS_INTERR));
                        //jk - throwing exception here so that UAR and TSF are not created
                        throw new ApplicationException(GAS_INTERR);
                        //KRB 2/7/20 - bad code /compile error with new API 47 Version (coming from version 26...)
                        //return;
                    }
                }
                if(manuallyAssignedTerrIDs.contains(t.Id)){ //mnaidu - 4/28/13 - only add to the terrString if this is Manually already assigned
                    terrString = terrString + ';' + t.Name ;                    
                }
            }
        }
        
        system.debug('jk - terrString: ' + terrString);
        
        List <GAS_Alignment_History_vts__c> histories = new List <GAS_Alignment_History_vts__c>();
        GAS_Alignment_History_vts__c history = new GAS_Alignment_History_vts__c();
        
        try{
            
           
            // Now let's see if the Account Territory Loader already exists
            List <Account_Territory_Loader_vod__c> atlList = [select Id, Territory_vod__c from Account_Territory_Loader_vod__c where Account_vod__c = :newAcctId] ;
            if (atlList.size() == 1) {
                Account_Territory_Loader_vod__c atl = atlList[0] ;
                
                //track that Account to be aligned
                //in this case we are creating one history record for every territory
                for (String ut : userTerrNames) {
                    history = new GAS_Alignment_History_vts__c();
                    history.Account__c = newAcctId;
                    history.Account_Territory_Loader__c = atl.Id;
                    history.End_Date_MRK__c = rec.alignmentEndDate;
                    history.New_Territory__c = ut;
                    history.Old_Territory__c = atl.Territory_vod__c;
                    history.Processed_MRK__c = false;
                    history.Source_MRK__c = rec.source;
                    histories.add(history);           
                }
                
                //set new ATL territory
                atl.Territory_vod__c = terrString ;
                
                System.debug('Before updating the ATL reco: ' +  atl.Territory_vod__c);
                system.debug(Logginglevel.INFO,'jk - updating ATL:' + atl);
                update (atl) ;
 
                 System.debug('After updating the ATL reco: ' +  atl.Territory_vod__c);
 
                
                //insert history record
                system.debug('jk - trackAlignmentHistory: ' + trackAlignmentHistory);
                if (trackAlignmentHistory) {
                    system.debug(Logginglevel.INFO,'jk - inserting history:' + history);
                    insert history;
                }
                
            }
            else {
                Account_Territory_Loader_vod__c atl = new Account_Territory_Loader_vod__c(Account_vod__c=newAcctId,External_ID_vod__c=newAcctId,Territory_vod__c=terrString);
                system.debug(Logginglevel.INFO,'jk - inserting ATL:' + atl);
                insert (atl) ;
                
                //track history
                //in this case we are creating one history record for every territory
                for (String ut : userTerrNames) {
                    history = new GAS_Alignment_History_vts__c();
                    history.Account__c = newAcctId;
                    history.Account_Territory_Loader__c = atl.Id;
                    history.End_Date_MRK__c = rec.alignmentEndDate;
                    history.New_Territory__c = ut;
                    history.Processed_MRK__c = false;
                    history.Source_MRK__c = rec.source;
                    histories.add(history);           
                }
                system.debug(Logginglevel.INFO,'jk - inserting history:' + histories);
                insert histories;
                
            }
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,GAS_SUCCESS));
        }
        catch(DmlException ex){
            ApexPages.addMessages(ex);
        }
        return;
    }
    

    public PageReference cancel() {
        return null ;
    }



    private static String joinStrings (Set<String> ss, String delim) {
        String retVal = '' ;
        for (String s : ss) {
            if (retVal != '')  {
                retVal += delim ;
            }
            retVal += s ;
        }
        return retVal ;
    }

    private static String getPhoneRegex (String inph) {

        Pattern pt = Pattern.compile('[^0-9]');
        String [] res = pt.split(inph) ;
        String digits = '' ;
        for (Integer i = 0 ; i < res.size(); i++) {
        System.debug ('r1:' + res[i]) ;
            digits = digits + res[i] ;
        }
        System.debug ('r2:' + digits) ;
        String retval= '';

        if (digits.length() == 10) {
            retval = '%' + digits.substring(0,3) + '%' + digits.substring(3,6) + '%' + digits.substring (6,10) + '%' ;
        }
        else if (digits.length() == 7) {
            retval = '%' + digits.substring(0,3) + '%' + digits.substring(3,7) + '%' ;
        }
        else if (digits.length() == 4) {
            retval = '%' + digits ;
        }
        else {
            retval = digits ;
        }
System.debug ('r3:' + retval) ;
        return retval ;
    }

    //Merck Added - Start
    
        private String getSelectedAccount(){
        
        String newAcctId  = '';
                
        if (results != null && results.size() > 0) {
           // Find the selected Account
           for (searchResult sr : results) {
              if (sr.isSelected == true) {
                newAcctId = sr.acctId ;
                break ;
             }
           }           
        }
       
       return  newAcctId;
    }

    //Merck Added - End


    private String getObjValue (sObject so, String fname, String typex) {
        if (typex == 'Reference') {
            // Get relationship name
            String relship ;
            String fnameLcase;
            
            if (fname.startsWith('ADD.')) {
                //jk - winter 15 patch
                fnameLcase = fname.replace('ADD.', '').toLowerCase();               
                relship = addrFieldMapLcase.get(fnameLcase).getDescribe().getRelationshipName() ;
            }
            else {
                //jk - winter 15 patch
                fnameLcase = fname.toLowerCase();
                relship = acctFieldMapLcase.get(fnameLcase).getDescribe().getRelationshipName() ;
            }
            // Display Name field of lookup value
            SObject so2 = so.getSObject(relship);
            if (!fname.contains('RecordTypeId') && so2 != null) {
                return (String) so2.get('Name') ;
            }
            else if (fname.contains('RecordTypeId') && so2 != null) {
                // We have the value, we need to translate it
                return recTypeXlation.get((String) so2.get('Name'));
            }
            return '' ;
        }
        if (fname.startsWith('ADD.')) {
            fname = fname.replace('ADD.', '') ;
        }
        if (typex == 'Boolean') {
            Boolean b = (Boolean) so.get(fname) ;
            return (b == true ? '[X]' : '[ ]') ;
        }
        else if (typex == 'Date') {
            Date d = (Date) so.get(fname) ;
            if (d != null) {
                return d.format() ;
            }
            else {
                return '' ;
            }
        }
        else if (typex == 'Datetime') {
            Datetime d = (Datetime) so.get(fname) ;
            if (d != null) {
                return d.format() ;
            }
            else {
                return '' ;
            }
        }
        else {
            return (String) so.get(fname) ;
        }
    }


    private List<SelectOption> SortOptionList(List<SelectOption> ListToSort) {

        // Simple quick sort : see http://improveit360.blogspot.com/2010/09/implementing-quicksort-to-sort-list-of.html
        if(ListToSort == null || ListToSort.size() <= 1)
            return ListToSort;
            
        List<SelectOption> Less = new List<SelectOption>();
        List<SelectOption> Greater = new List<SelectOption>();
        integer pivot = ListToSort.size() / 2;
          
        // save the pivot and remove it from the list
        SelectOption pivotValue = ListToSort[pivot];
        ListToSort.remove(pivot);
        
        for(SelectOption x : ListToSort)
        {
            if(x.getLabel() <= pivotValue.getLabel())
                Less.add(x);
            else if(x.getLabel() > pivotValue.getLabel()) Greater.add(x);   
        }
        List<SelectOption> xList = new List<SelectOption> ();
        xList.addAll(SortOptionList(Less));
        xList.add(pivotValue);
        xList.addAll(SortOptionList(Greater));
        // Dedupe
        List<SelectOption> returnList = new List<SelectOption> ();
        Set<String> labelSet = new Set<String> () ;
        returnList.add(new SelectOption('',GAS_NONE)) ;
        labelSet.add(GAS_NONE) ;
        for(SelectOption x : xList) {
            if (!labelSet.contains(x.getLabel())) {
                returnList.add(x) ;
                labelSet.add(x.getLabel()) ;
            }
        }
        return returnList; 
    }  
    
            //mnaidu 7/16/2013 - GAS 2.1 enhancement
            //remove the account ids that need to be excluded
/**
***** @author = Murugesh Naidu
***** @date = July 17, 2013
***** @param - List of Account Ids to process
***** @return - List of Account Ids after exclusion criteria applied
***** GAS 2.1 enhancements
**/
    private List<ID> excludeAccountsIfAny(List<ID> accountIds){
        
        if(accountIds==null || accountIds.size() == 0){
            return accountIds;
        }
        Set<ID> originalAcctIds = new Set<ID> ();
        Set<ID> idsToExclude = GASUtilities.getAccountIdsToExclude(UserInfo.getUserId());
        if(idsToExclude!=null && idsToExclude.size() > 0){
            originalAcctIds.addAll(accountIds);
            originalAcctIds.removeAll(idsToExclude);
            accountIds.clear();
            accountIds.addAll(originalAcctIds);
        }
        return accountIds;
    }
    
    //Merck Added - Start
        private String createCommaSeparatedQuotedStringFromMapKeySet (Map<Id,RecordType> tempMap){
        
        List<Id> tempList = new List<Id>();
        
        for (Id id : tempMap.keySet()) {
           tempList.add(tempMap.get(id).Id);
        }        
        
        return createCommaSeparatedQuotedStringFromList(tempList);
    }
    
    
    private String createCommaSeparatedQuotedStringFromList(List<String> tempList){
      
       Boolean lastItem = false;
       Integer i = 0;
       String commaSeparatedList='';
       
       for(String str : tempList){
          
          i = i + 1;
          if (i == tempList.size()) {lastItem = true;}
         
         if(!lastItem){
            commaSeparatedList += '\'' + str + '\''  + ',' ;
         }else{
            commaSeparatedList += '\'' + str + '\'' ;
         }
       }
 
        // remove last additional comma from string
        return commaSeparatedList.subString(0,commaSeparatedList.length());
    }

    //Merck Added - End
    /** Code Commented to remove In Call Deck Indicator Starts
    *private Map<Id,AccountShare> getAlignedAccountIds (Set<Id> searchResultIds) {
    *    
    *   //Add current user ID to userOrGroupIds
    *    Set<Id> userOrGroupIds = new Set<Id>();
    *    userOrGroupIds.add(UserInfo.getUserId());
    *    
    *    //get territory Ids for current user territory
    *    Set<Id> territoryIds = new Set<Id>();
    *    for (UserTerritory ut : [SELECT TerritoryId FROM UserTerritory WHERE UserId = :UserInfo.getUserId()]) {
    *        territoryIds.add(ut.TerritoryId);
    *    }
    *    
    *    //get group Ids for User's territory
    *    for (Group g : [SELECT Id FROM Group WHERE Type IN ('Territory','TerritoryAndSubordinates') AND RelatedId IN :territoryIds]) {
    *        userOrGroupIds.add(g.Id);
    *    }       
    *    
    *    //get currently aligned Accounts for user or territory Id
    *    Map<ID, AccountShare> m = new Map<ID, AccountShare>();
    *    List <AccountShare> accountShares = [SELECT Id, AccountId, RowCause 
    *                                         FROM AccountShare 
    *                                         WHERE UserOrGroupId IN :userOrGroupIds
    *                                           AND AccountId IN :searchResultIds];
    *                                           
    *    //add account Ids to return list
    *    for (AccountShare accountShare : accountShares) {
    *        m.put(accountShare.AccountId, accountShare);
    *    }        
    *    
    *    return m;
    *}
    *
    *private SearchResultField getInCallDeckSearchResultField(Id AccountId, Map<Id,AccountShare> alignedAccounts) {
    *    SearchResultField srf = new SearchResultField();
    *    
    *    String inCallDeck = '';
    *    if (alignedAccounts.containsKey(AccountId)) {
    *        inCallDeck = 'Yes';
    *    } else {
    *        inCallDeck = 'No';          
    *    }
    *    
    *    srf.apiname = 'InCallDeck_MRK__c';
    *    srf.label = 'In Call Deck';
    *    srf.value = inCallDeck;
    *    srf.rawvalue = inCallDeck;
    *    srf.is_Acct = true;
    *    srf.is_Addr = false;
    *    
    *    return srf;     
    *    
    *}
   */
    private List<SearchResult> SortSearchResults (List<SearchResult> ListToSort, String keyField, String sortDir) {

        if (keyField != '') {
            // Set key field for each SearchResult
            for(SearchResult x : ListToSort) {
                for (SearchResultField y : x.srFields) {
                    // Find the keyField
                    if (y.apiname == keyField) {
                        x.key = y.rawvalue ;
                        break ;
                    }
                }
            }
        }

        // Ok, now we have the keys, can do a simple quick sort. See : http://improveit360.blogspot.com/2010/09/implementing-quicksort-to-sort-list-of.html
        if(ListToSort == null || ListToSort.size() <= 1)
            return ListToSort;
            
        List<SearchResult> Less = new List<SearchResult>();
        List<SearchResult> Greater = new List<SearchResult>();
        integer pivot = ListToSort.size() / 2;
          
        // save the pivot and remove it from the list
        SearchResult pivotValue = ListToSort[pivot];
        ListToSort.remove(pivot);
        
        if (sortDir == 'A') { // Ascending
            for(SearchResult x : ListToSort)
            {
                if(x.key <= pivotValue.key)
                    Less.add(x);
                else if(x.key > pivotValue.key) Greater.add(x);   
            }
        }
        else { // Descending 
            for(SearchResult x : ListToSort)
            {
                if(x.key <= pivotValue.key)
                    Greater.add(x);
                else if(x.key > pivotValue.key) Less.add(x);   
            }
        }
        List<SearchResult> returnList = new List<SearchResult> ();
        returnList.addAll(SortSearchResults(Less, '', sortDir));
        returnList.add(pivotValue);
        returnList.addAll(SortSearchResults(Greater, '', sortDir));
        return returnList; 
    }  

    public class SearchResult {

        public String acctId {get;set;}
        public String acctName {get;set;}
        public String addrId {get;set;}
        public Boolean isSelected {get;set;}
        public String key {set;get;}
        public List<SearchResultField> srFields {get;set;}
        public List<SearchResult> otherAddrs {get;set;}

    }

    public class SearchResultField {

        public String apiname {get;set;}
        public String label {get;set;}
        public String value {get;set;}
        public String rawvalue {get;set;}
        public Boolean is_Acct {get;set;}
        public Boolean is_Addr {get;set;}

    }

    //Merck Added – Start
   //jk - uncommented this class
   public class TempAlignmentRecord {
        public String territoryName {get;set;}
        public Id userId {get;set;}
        public Id accountId {get;set;}
        public Date requestDate {get;set;}
        public String alignmentStatus  {get;set;} //“Temporary”
        public Date alignmentStartDate {get;set;} // will be set to current day
        public Date alignmentEndDate {get;set;} // set to the last day of the month for six months from current day
    }
    
    //Merck Added – End


    public class SearchField {

        public String obj {get;set;}
        public String label {get;set;}
        public String apiname {get;set;}
        public String value {get;set;}
        public String alvalue {get;set;}
        public String opt_value {get;set;}
        public Boolean is_picklist {get;set;}
        public Boolean is_reference {get;set;}
        public Boolean is_phone {get;set;}
        public Boolean is_bool {get;set;}
        public Boolean is_acctlookup {get;set;}
                //KRB 8/9 Not needed:
        //public Boolean has_es {get;set;}
        //public Boolean has_cs {get;set;}
        //KRB 8/9 New Variable to support sw, contains, em combination
        public Boolean has_esc {get;set;}
        public Boolean no_quote {get;set;}
        public Boolean no_opt {get;set;}
        public Boolean no_picklist {get;set;}
        public List<SelectOption> plist {set;get;}

        public SearchField (String o, Schema.DescribeFieldResult dfr) {
            obj = o ;
            label = dfr.getLabel() ;
            apiname = dfr.getName () ;
            value = '' ;
            opt_value = '' ;
            is_acctlookup = false ;
            is_reference = (dfr.getType().name() == 'Reference') ;
            is_picklist = (dfr.getType().name() == 'Picklist') ;
            is_phone = (dfr.getType().name() == 'Phone') ;
            is_bool = (dfr.getType().name() == 'Boolean') ;
            no_quote = (dfr.getType().name() == 'Boolean' ||
                        dfr.getType().name() == 'Currency' ||
                        dfr.getType().name() == 'Date' ||
                        dfr.getType().name() == 'Datetime' ||
                        dfr.getType().name() == 'Double' ||
                        dfr.getType().name() == 'Integer' ||
                        dfr.getType().name() == 'Percent' ||
                        dfr.getType().name() == 'Time') ;
            if (is_picklist) {
                plist = new List<SelectOption> () ;
                List<Schema.PicklistEntry> P = dfr.getPicklistValues();
                plist.add(new SelectOption('',searchAccts.GAS_NONE)) ;
                for (Schema.PicklistEntry pe : P) {
                    plist.add(new SelectOption(pe.getValue(),pe.getLabel()));
                }
            }
            if (is_reference) {
                // Make it a picklist of names
                is_picklist = true ;
                // Remove trailing ' ID' from label
                label = label.replaceFirst(' ID$', '') ;
                List <Schema.sObjectType> sobjs = dfr.getReferenceTo() ;
                String objName = sobjs[0].getDescribe().getName() ;
System.debug ('objName is ' + objName) ;
                if (objName == 'RecordType') {
                    // Already calculated
                    plist = obj == 'Account' ? searchAccts.acctRecTypesPlist.clone()  : searchAccts.addrRecTypesPlist.clone() ;
                }
                else if (objName != 'Account') {
                    // All other references
                    plist = new List<SelectOption> () ;
                    plist.add(new SelectOption('',searchAccts.GAS_NONE)) ;
                    String query = 'select Id,Name from ' + objName + ' order by Name' ;
                    for (sObject ox : Database.query(query)) {
                        plist.add(new SelectOption((String)ox.get('Id'), (String)ox.get('Name'))) ;
                    }
                }
                else {
                    // objName is Account.  We don't want to display thousands or more Account names in a picklist,
                    // so we handle this by creating a link to aonther search page.
                    is_acctlookup = true ;
                }
System.debug ('is_acctlookup is ' + is_acctlookup) ;
            }
            
            /* Merck Commented out
            has_es = (obj == 'Account' && (apiname == 'Name' || apiname == 'FirstName' || apiname == 'LastName')) ;
            has_cs = (obj == 'Address_vod__c' && apiname == 'Name') ;
            if (has_es) {
                opt_value = 'Exact Match' ;
            }
            if (has_cs) {
                opt_value = 'Starts With' ;
            }
            no_opt = !has_cs && !has_es && !is_acctlookup;
            no_picklist = !is_picklist ;
            */
            
            // Merck Added - Start   Account_Steward_Searchable_Name_MRK__c
                        //KRB - TODO This needs to be removed from the code and added to Settings, etc.
            //has_esc = (obj == 'Address_vod__c' && apiname == 'Name') || (obj == 'Account' && (apiname =='Official_Name_MRK__c' || apiname =='Primary_Parent_Search_Field_MRK__c' || apiname == 'Name' || apiname == 'FirstName' || apiname == 'LastName')) ;
            //has_esc = ((obj == 'Address_vod__c' && (apiname == 'Name' || apiname == 'License_vod__c')) || (obj == 'Child_Account_vod__c' && apiname == 'Name') || (obj == 'Account' && (apiname =='Official_Name_MRK__c' || apiname =='Official_Formatted_Name_MRK__c' || apiname == 'Account_Steward_Searchable_Name_MRK__c' || apiname =='Primary_Parent_Search_Field_MRK__c' || apiname == 'Name' || apiname == 'FirstName' || apiname == 'LastName'))) ;
            has_esc = ((obj == 'Address_vod__c' && (apiname == 'Name' || apiname == 'License_vod__c')) || (obj == 'Child_Account_vod__c' && apiname == 'Name') || (obj == 'Account' && (apiname =='Official_Name_MRK__c' || apiname =='Official_Formatted_Name_MRK__c' || apiname == 'Account_Steward_Searchable_Name_MRK__c' || apiname =='Primary_Parent_Search_Field_MRK__c' || apiname == 'Name' || apiname == 'FirstName' || apiname == 'LastName' || apiname == 'Preferred_First_Name_MRK__c' || apiname == 'Preferred_Last_Name_MRK__c' || apiname == 'Preferred_Full_Name_MRK__c'))) ;
            
            if (has_esc ) {
                opt_value = 'Exact Match' ;
            }
           
            no_opt =  !has_esc && !is_acctlookup;
            no_picklist = !is_picklist ;

            
            //Merck Added - End
                   }
    } 

    private String getChildAccountQuerystring(List<SearchField> childAccountSearchFields) {
        String prefix = 'Parent_Account_vod__r.' ;
        //String whereClause = 'SELECT Child_Account_vod__c FROM Child_Account_vod__c WHERE ';
        String whereClause = '';
        for (SearchField sf : childAccountSearchFields) {
            if (sf.value != '' && sf.value != 'null' && sf.value != null) {
                String field = prefix + sf.apiname ;
                String op = '=' ;
                String value = sf.value ;
                
                // Escape any quotes in the value
                value = String.escapeSingleQuotes(value);
                
                if (sf.opt_value == 'Starts With') {
                    op = 'like' ;
                    value = value + '%' ;
                }
                if (sf.opt_value == 'Contains') {
                    op = 'like' ;
                    value = '%' + value + '%' ;
                }

                if (sf.is_phone) {
                        op = 'like' ;
                        value = getPhoneRegex(value) ;
                }
                
                // Put quotes around val for relevant types
                if(!sf.no_quote) {
                    value = '\'' + value + '\'' ;
                }
                if (whereClause != '') {
                    whereClause += ' AND ' ;
                }
                whereClause += ' ' + field + ' ' + op + ' ' + value;
                }
            }
        
            if (individualAdvRendered) {
                return 'SELECT Child_Account_vod__c FROM Child_Account_vod__c WHERE Child_Account_vod__r.isPersonAccount = true AND' + whereClause;
            } else {
                return 'SELECT Child_Account_vod__c FROM Child_Account_vod__c WHERE Child_Account_vod__r.isPersonAccount = false AND' + whereClause;
            }
            //return 'SELECT Child_Account_vod__c FROM Child_Account_vod__c WHERE' + whereClause;
    }

    public class ResultHeader {

        public String label {set;get;} 
        public String apiname {set;get;} 

    }
    
    public class AlignmentUARRecord {
        public String territoryName {get;set;}
        public String changeType {get;set;}
        public String source {get;set;}
        public Id userId {get;set;}
        public Id accountId {get;set;}
        public Date requestDate {get;set;}
        public String alignmentType  {get;set;}
        public Date alignmentStartDate {get;set;} // will be set to current day
        public Date alignmentEndDate {get;set;} // set to the last day of the month for six months from current day
        public String approvalStatus {get;set;}
    }

    public class ApplicationException extends Exception {}


    
 

      
}