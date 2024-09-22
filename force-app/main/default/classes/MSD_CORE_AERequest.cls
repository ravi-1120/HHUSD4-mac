global class MSD_CORE_AERequest {
    
    public MSD_CORE_AERequest(MSD_CORE_SC_RTB_Request_Info__mdt reqInfo, List<ServiceCloudSafetyCase> aeData, String requestId)
    {
        this.x07requestid = requestId;
        this.x06source_system = reqInfo.Source_System__c;
        this.x05source_type = reqInfo.Source_Type__c;
        this.x04source_language = reqInfo.Source_Language__c;
        this.x03division = reqInfo.Division__c;
        this.x02source_department = reqInfo.Source_Department__c;
        this.x01ServiceCloudSafetyCase = aeData;         
    }  
    public String x07requestid {get;set;}
    public String x06source_system {get;set;}
    public String x05source_type {get;set;}
    public String x04source_language {get;set;}
    public String x03division {get;set;}
    public String x02source_department {get;set;}
    public List<ServiceCloudSafetyCase> x01ServiceCloudSafetyCase {get;set;}
    
    public class ServiceCloudSafetyCase
    {
        public CaseInfo x12caseInfo {get;set;}
        public CaseAdditionalInfo x11caseAdditionalInfo {get;set;}
        public AdverseEvent x10adverseEvent {get;set;}
        public Patient x09patient {get;set;}
        public PatientSupportProgram x08patientSupportProgram {get;set;}
        public ProductQualitycomplaint x07productQualitycomplaint {get;set;}
        public CustomerFeedback x06customerFeedback {get;set;}
        public List<AdditionalContact> x05additionalContacts {get;set;}
        public List<Product> x04products {get;set;}
        public List<CaseNote> x03caseNotes {get;set;}
        public List<Attachment> x02attachments {get;set;}
        public List<ChatTranscript> x01chatTranscripts {get;set;}
    }
    public class CaseInfo {
        public String caseID {get;set;}
        public String caseStatus {get;set;}
        public string integrationLogUniqueID {get;set;}
        public string integrationLogDes {get;set;}
        public string integrationLogDR {get;set;}
        public string integrationLogCT {get;set;}
        public DateTime integrationLogTDT {get;set;}
        public Decimal integrationLogNotesCount {get;set;}
        public String integrationLogNotesIDs {get;set;}
        public Decimal integrationLogAttCount {get;set;}
        public String integrationLogAttIDs {get;set;}
        public Decimal integrationLogProdCount {get;set;}
        public String integrationLogProdIDs {get;set;}
        public Decimal integrationLogAddConCount {get;set;}
        public String integrationLogAddConIDs {get;set;}
        public Decimal integrationLogCTCount {get;set;}
        public String integrationLogCTIDs {get;set;}
        public DateTime createdDateTimeUtc {get;set;}
        public DateTime lastModifiedDateTimeUtc {get;set;}
        public String interactionNumber {get;set;}
        public String caseNumber {get;set;}
        public String caseOwner {get;set;}
        public DateTime companyAwarenessDateUtc {get;set;}
        public String interactionChatUniqueIdentifierID {get;set;}
        public String eventCaseType {get;set;}
        public Boolean alertSecurity {get;set;}
        public Boolean alertLegal {get;set;}
        public String marrS_CaseNumber {get;set;}
        public String DHS_Number {get;set;}
        public Boolean multiplePatientsInvolved {get;set;}
        public String routeOfAdministration {get;set;}
        public DateTime caseLatestSubmittedDateUtc {get;set;}
        public DateTime caseLatestClosedsDateUtc {get;set;}
    }
    
    public class CaseAdditionalInfo {
        public String concomitantMedications {get;set;}
        public String pertinentMedicalHistory {get;set;}
        public String drugReactions_Allergies {get;set;}
        public String labDiagnostics_StudiesPerformed {get;set;}
    }
    
    public class Patient {
        public String firstName {get;set;}
        public String lastName {get;set;}
        public String dateOfBirthText {get;set;}
        public String patientAgeText {get;set;}
        public String patientGender {get;set;}
        public String isPatientPregnant {get;set;}
        public String pregnancyGestationOrLMP {get;set;}
    }
    
    
    public class PatientSupportProgram {
        public String programName {get;set;}
        public String programNameOther {get;set;}
        public String company {get;set;}
        public String companyOther {get;set;}
        public String psP_Number {get;set;}
        public String psP_NumberOther {get;set;}
        public String agentName {get;set;}
    }
    
    public class AdverseEvent {
        public String reactionDescription {get;set;}
        public String onsetDate {get;set;}
        public String presentStatus {get;set;}
        public string therapyDiscontinued {get;set;}
        public String therapyStartDate {get;set;}
        public String therapyEndDate {get;set;}
        public String recoveryDate {get;set;}
        public String indication {get;set;}
        public String wasTreatmentGivenForAE {get;set;}
        public String treatmentProvided {get;set;}
        public String rechallenge {get;set;}
        public String dechallenge {get;set;}
        public String soughtMedicalAttention {get;set;}
        public String resultedInDeath {get;set;}
        public String causeOfDeath {get;set;}
        public String dateOfDeath {get;set;}
        public String interventionToPreventSeriousCriteria {get;set;}
        public String isCancer {get;set;}
        public String isOverdose {get;set;}
        public String isCongenitalAnomaly {get;set;}
        public String significantDisabilityIncapacity {get;set;}
        public String isHospitalizedOrProlonged {get;set;}
        public String isLifeThreatening {get;set;}
    }
    
    public class ProductQualitycomplaint {
        public Boolean pqC_Present {get;set;}
        public String userExperience {get;set;}
       // public String operatorOfDevice {get;set;}
        public String priority {get;set;}
        public Boolean qiR_Requested {get;set;}
        public DateTime qiR_ReceivedDateUtc {get;set;}
    }
    
    public class AdditionalContact {
        public String type {get;set;}
        public String firstName {get;set;}
        public String lastName {get;set;}
        public String contactNumber {get;set;}
        public String credentials {get;set;}
        public String addressLine1 {get;set;}
        public String addressLine2 {get;set;}
        public String city {get;set;}
        public String state {get;set;}
        public String country {get;set;}
        public String postalCode {get;set;}
        public String phone {get;set;}
        public String fax {get;set;}
        public String Email {get;set;}//CEF2F-22189 added by Priyanka Tiwari
        public String contactRelatedTo {get;set;}
        public String hasPermissionToContact {get;set;}
        public boolean isPrimaryContact {get;set;}
        public boolean isCorrespondenceContact {get;set;}
    }
    
    public class Product {
        public Boolean isPrimaryProduct {get;set;}
        public String productName {get;set;}
        public String doseFrequency {get;set;}
        public String expirationDate {get;set;}
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
        public String note {get;set;}
        public DateTime createdDateTimeUtc {get;set;}
    } 
    
    public class Attachment {
        public String id {get;set;}
        public String name {get;set;}
        public Integer bodyLength {get;set;}
        public String parentId {get;set;}
        public DateTime createdDateTimeUtc {get;set;}
        public DateTime lastModifiedDateTimeUtc {get;set;}
        public Boolean isDeleted {get;set;}
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
    
    public class CustomerFeedback {
        public String feedbackText {get;set;}
        public String feedbackClassification {get;set;}
        public String cdt {get;set;}
    }
    
    
    
}