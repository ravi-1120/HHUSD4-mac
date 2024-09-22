@isTest
public class MSD_CORE_ArticleRecordTypeBatchTest {
     Public static List<Knowledge__kav> kavlist = new  List<Knowledge__kav>();
     Public static Knowledge__kav kav = new Knowledge__kav();
     Public static Knowledge__kav kav1 = new Knowledge__kav();
     Public static Knowledge__kav kav2 = new Knowledge__kav();     
     Public static Knowledge__kav kav3 = new Knowledge__kav();
     Public static Knowledge__kav kav4 = new Knowledge__kav();
     
     
     static{
       // kav.RecordTypeId = recordtypeId;
        kav.title = 'Add Info about test';
        kav.MSD_CORE_Questions__c = 'test';
        kav.MSD_CORE_Audience__c = 'CONSUMER';
        kav.MSD_CORE_KnwlArtCat__c = 'NSC';
        kav.MSD_CORE_Subtype__c = 'Promotional';
        kav.UrlName = '53jk';
        kavlist.add(kav);
        
        kav1.MSD_CORE_Questions__c = 'test';
        kav1.MSD_CORE_Audience__c = 'CONSUMER';
        kav1.MSD_CORE_KnwlArtCat__c = 'NSC';
        kav1.MSD_CORE_Subtype__c = 'Product/Medical Information';
        kav1.MSD_CORE_GenCatgry__c = 'Q&A Script';
        kav1.MSD_CORE_Subtype__c = 'Promotional';
        kav1.Title = 'Quick Info';
        kav1.UrlName = '53jk1';
        kavlist.add(kav1);
        
        kav2.title = 'Add Info about test';
        kav2.MSD_CORE_Questions__c = 'test';
        kav2.MSD_CORE_Audience__c = 'CONSUMER';
        kav2.MSD_CORE_KnwlArtCat__c = 'NSC';
        kav2.MSD_CORE_GenCatgry__c = 'Q&A Script';
        kav2.MSD_CORE_Subtype__c = 'Promotional';
        kav2.Title = 'Add1 Info';
        kav2.UrlName = '53jk2';
        kavlist.add(kav2);
        
        kav3.MSD_CORE_Questions__c = 'test';
        kav3.MSD_CORE_Audience__c = 'CONSUMER';
        kav3.MSD_CORE_KnwlArtCat__c = 'NSC';        
        kav3.MSD_CORE_Subtype__c = 'Ponal';
        kav3.MSD_CORE_GenCatgry__c = 'test';
        kav3.MSD_CORE_Subtype__c = 'Product/Medical Information';
        kav3.Title = 'Addl Info';
        kav3.UrlName = '53jk3';
        kavlist.add(kav3);
        
        kav4.MSD_CORE_Questions__c = 'test';
        kav4.MSD_CORE_Audience__c = 'CONSUMER';
        kav4.MSD_CORE_KnwlArtCat__c = 'NSC';        
        kav4.MSD_CORE_Subtype__c = 'Ponal';
        kav4.MSD_CORE_GenCatgry__c = 'test';
        kav4.MSD_CORE_Subtype__c = 'Product/Medical Information';
        kav4.Title = 'Addl Info';
        kav4.UrlName = '53jk4';
        kavlist.add(kav4);
        
        insert kavlist;
        knowledge__DataCategorySelection dataCategory1 = new knowledge__DataCategorySelection();
        dataCategory1.DataCategoryName = 'MSD_CORE_NSC';
        dataCategory1.DataCategoryGroupName = 'Knowledge_Article_Categories';
        dataCategory1.ParentId = kavlist[0].Id;
        insert dataCategory1;
        
        knowledge__DataCategorySelection dataCategory2 = new knowledge__DataCategorySelection();
        dataCategory2.DataCategoryName = 'MSD_CORE_PCC';
        dataCategory2.DataCategoryGroupName = 'Knowledge_Article_Categories';
        dataCategory2.ParentId = kavlist[1].Id;
        insert dataCategory2;
        
        knowledge__DataCategorySelection dataCategory3 = new knowledge__DataCategorySelection();
        dataCategory3.DataCategoryName = 'MSD_CORE_RMPDC';
        dataCategory3.DataCategoryGroupName = 'Knowledge_Article_Categories';
        dataCategory3.ParentId = kavlist[2].Id;
        insert dataCategory3; 
        
        knowledge__DataCategorySelection dataCategory4 = new knowledge__DataCategorySelection();
        dataCategory4.DataCategoryName = 'MSD_CORE_PCC';
        dataCategory4.DataCategoryGroupName = 'Knowledge_Article_Categories';
        dataCategory4.ParentId = kavlist[3].Id;
        insert dataCategory4; 
        
        knowledge__DataCategorySelection dataCategory5 = new knowledge__DataCategorySelection();
        dataCategory5.DataCategoryName = 'MSD_CORE_NSC';
        dataCategory5.DataCategoryGroupName = 'Knowledge_Article_Categories';
        dataCategory5.ParentId = kavlist[4].Id;
        insert dataCategory5; 
        
        knowledge__DataCategorySelection dataCategory6 = new knowledge__DataCategorySelection();
        dataCategory6.DataCategoryName = 'MSD_CORE_NSC';
        dataCategory6.DataCategoryGroupName = 'Knowledge_Article_Categories';
        dataCategory6.ParentId = kavlist[1].Id;
        insert dataCategory6;
        


    } 
      @isTest static void testgetKnowledge(){
        Test.startTest();
        MSD_CORE_ArticleRecordTypeBatch articleRecTypeBatch = new MSD_CORE_ArticleRecordTypeBatch();
        Database.ExecuteBatch(articleRecTypeBatch);
        MSD_CORE_ArticleRecordTypeBatch.convertStringToDate(system.today());
        Test.stopTest();    
        
    }
}