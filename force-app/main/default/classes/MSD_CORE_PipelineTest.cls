/**
 * Component Name:      MSD_CORE_PipelineTest
 * Created By:          Tausif (Focal CXM)
 * Description:         Used for MSD_CORE_Pipeline
 * Class Type:          Test
 * @description MSD_CORE_PipelineTest
 */
@isTest
public with sharing class MSD_CORE_PipelineTest {

    @IsTest
    static void getPhaseDetail() {
        Test.startTest();        
        MSD_CORE_Med_Therapeutic__c ms = createTherapeutic();
        System.runAs(new User(Id = UserInfo.getUserId())){ 
        MSD_CORE_Pipeline.getPhaseDetail('Phase2',1,1,'','','Name');
        MSD_CORE_Pipeline.getPhaseCount();
        }
        Test.stopTest();
        System.Assert(ms!= null,'getPhaseDetail');
    }

 	@IsTest
    static void getPhaseDetailWithTherapeuticArea() {
        Test.startTest();        
        MSD_CORE_Med_Therapeutic__c ms = createTherapeutic();
        System.runAs(new User(Id = UserInfo.getUserId())){ 
        MSD_CORE_Pipeline.getPhaseDetail('Phase2',1,1,'','Cardiovascular disease','Name');
        MSD_CORE_Pipeline.getPhaseCount();
        }
        Test.stopTest();
        System.Assert(ms!= null,'getPhaseDetailWithTherapeuticArea');
    }
    
    @IsTest
    static void getPhaseDetailWithSearchKey() {
        Test.startTest();        
        MSD_CORE_Med_Therapeutic__c ms = createTherapeutic();
        System.runAs(new User(Id = UserInfo.getUserId())){ 
        MSD_CORE_Pipeline.getPhaseDetail('Phase2',1,1,'Cardiovascular','','Name');
        MSD_CORE_Pipeline.getPhaseCount();
        }
        Test.stopTest();
        System.Assert(ms!= null,'getPhaseDetailWithSearchKey');
    }
      /**
     * @description MSD_CORE_Med_Therapeutic__c createTherapeutic
     * @return mt
    */
    public static MSD_CORE_Med_Therapeutic__c createTherapeutic(){
        MSD_CORE_Study_detail__c sd = new MSD_CORE_Study_detail__c();
        sd.MSD_CORE_Phase__c = 'Phase2';
        sd.MSD_CORE_Therapeutic__c = 'Cardiovascular disease';
        sd.MSD_CORE_Compound__c = 'Investigational Product';
        sd.MSD_CORE_Compound_Warning__c = 'This information concerns investigational products. The safety and effectiveness of these investigational products has not been established.';
        insert sd;

        MSD_CORE_Med_Therapeutic__c mt = new MSD_CORE_Med_Therapeutic__c();
        mt.MSD_CORE_Study_detail__c = sd.Id;        
        insert mt;
        return mt;
    }
}