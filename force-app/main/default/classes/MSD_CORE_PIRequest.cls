/*
* Company		: Merck Co.
* Date			: 07-02-2018	
* Author		: Ramesh Elapakurthi
* Description	: Professional Information Request class. which contains PIR data array and
additional request fields.
* History		: First version
*/

public class MSD_CORE_PIRequest {
    
    public MSD_CORE_PIRequest(MSD_CORE_RTB_Pir_Request_Info__c pirInfo, List<MSD_CORE_PirData> pData, String requestId, String requestType) {
        
        this.source_system = requestType;
        this.source_department = pirInfo.Source_Department__c;
        this.source_language = pirInfo.Source_Language__c;
        this.requestid = requestId;
        this.division = pirInfo.division__c;
        this.source_type = pirInfo.Source_Type__c;
        this.data = pData;
    }
    
    public List<MSD_CORE_PirData> data {get;set;}
    public String requestid {get;set;}
    public String source_system {get;set;}
    public String source_type {get;set;}
    public String source_language {get;set;}
    public String division {get;set;}
    public String source_department {get;set;}
    
}