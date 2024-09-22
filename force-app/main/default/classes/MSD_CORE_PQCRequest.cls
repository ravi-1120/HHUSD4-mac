global class MSD_CORE_PQCRequest {
    
    public MSD_CORE_PQCRequest(MSD_CORE_SC_RTB_Request_Info__mdt reqInfo, List<ServiceCloudSafetyCase> aeData, String requestId)
    {

        this.x01ServiceCloudSafetyCase = aeData;         
    }  
   
    
    public List<ServiceCloudSafetyCase> x01ServiceCloudSafetyCase {get;set;}
    
    public class ServiceCloudSafetyCase
    {
        public CaseInfo x12caseInfo {get;set;}
        public List<CaseNote> x03caseNotes {get;set;}
        public List<Attachment> x02attachments {get;set;}
        public List<ChatTranscript> x01chatTranscripts {get;set;}
    }
    public class CaseInfo {
        public String case_Status_List {get;set;}
        public Boolean CaseProcessedFirstTime {get;set;}
         public String externalInitialValue  {get;set;}
        public String case_Status {get;set;}
        
        
          public String adverse_event {get;set;}
         public String case_type {get;set;}
         public String caseEventType {get;set;}
         public Date awareness_date {get;set;}
         public String description_normal {get;set;}
         public String external_response_required {get;set;}
         public String reported_batch_number {get;set;}
         public String reported_product_description {get;set;}
        public String sample_expected {get;set;}
        public String case_id {get;set;}
        public String reporter_country {get;set;}
        public String expiration_date {get;set;}
        
        public String catalog{get;set;}
        public String complainant_type {get;set;} 
        public String date_of_event {get;set;}
        public String model {get;set;}
        public String case_notes {get;set;}
        public String operator_of_device {get;set;}
        public String reporter_address{get;set;}
        public String reporter_city {get;set;}
        public String reporter_email {get;set;}
        public String reporter_first_name {get;set;}
        public String reporter_last_name {get;set;}
        public String reporter_contact_number {get;set;}
        public String serial {get;set;}
        public String udi {get;set;}
        public String defective_quantity_text {get;set;}
        public String reporter_stateregionprovince {get;set;}
        public String biohazard {get;set;}
      	public String system_salesforce_id {get;set;}
        public String Date_PQC_Observed {get;set;}
        public String dpoc_child_pqc_event_id{get;set;}
 
         public string integrationLogUniqueID {get;set;}
        public String  title{get;set;}
		
        // hard coded
        public String complaint_type {get;set;}
        public String intake_source {get;set;}
        public String country_of_incident {get;set;}
         public String photo_available {get;set;}

        // chetan added for integration logs
        //public String caseID {get;set;}
        public string integrationLogDes {get;set;}
        public string integrationLogDR {get;set;}
        public string integrationLogCT {get;set;}
        public DateTime integrationLogTDT {get;set;}
        public Decimal integrationLogNotesCount {get;set;}
        public String integrationLogNotesIDs {get;set;} 
        public Decimal integrationLogAttCount {get;set;}
        public String integrationLogAddConIDs {get;set;}
        public Decimal integrationLogAddConCount {get;set;}
        public Decimal integrationLogProdCount {get;set;}
        public String integrationLogProdIDs {get;set;}
        public String integrationLogCTIDs {get;set;}
        public Decimal integrationLogCTCount {get;set;}
        public String integrationLogAttIDs {get;set;}
         public DateTime createdDateTimeUtc {get;set;}
        public DateTime lastModifiedDateTimeUtc {get;set;}
        public String interactionNumber {get;set;}
         public String caseOwner {get;set;}
         public String caseNumber {get;set;}
        public String Veeva_ID {get;set;}
        public String reporter_zippostal_code {get;set;}
        
        
        public String ComplainantRole {get;set;}

        public Boolean isPrimaryProduct {get;set;}
        public String productName {get;set;}
        public String doseFrequency {get;set;}
       
        public String relatedTo {get;set;}
        public Boolean obtain {get;set;}
        public Boolean isHazardousProduct {get;set;}
        public String productQuantity {get;set;}//changed from decimal to String
        public DateTime productReturnDateUtc {get;set;}
        public String lotNumber {get;set;}
        public String productCircularNumber {get;set;}
        public String catalogNumber {get;set;}
        public String modelNumber {get;set;}
        public String serialNumber {get;set;}
        public String uniqueIdentifier {get;set;}
         public String operatorOfDevice {get;set;}
      
    }
        
    
   public class CaseNote {
        public String noteID {get;set;}
        public String followUpQuestion {get;set;}
        public String followUpAnswer {get;set;}
       	public String Is_followup_Answer_record {get;set;}

    } 
    
    
    public class ChatTranscript {
        public String id {get;set;}
        public Boolean isLatest {get;set;}
        public Integer contentSize {get;set;}
        public String fileExtension {get;set;}
        public String title {get;set;}
        public String contentDocumentId {get;set;}
        public String linkedEntityId {get;set;}
        public String fileAvailability {get;set;}
        public Boolean isDeleted {get;set;}
    }
    
   
    
    public class Attachment {
        public String id {get;set;}
       
    }
    
}