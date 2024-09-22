@isTest
public class MSD_CORE_ArticleCategoryBatchTest {
     Public static Knowledge__kav kav = new Knowledge__kav();
        static{
       // kav.RecordTypeId = recordtypeId;
        kav.MSD_CORE_Questions__c = 'test';
        kav.MSD_CORE_Audience__c = 'CONSUMER';
        kav.MSD_CORE_KnwlArtCat__c = 'NSC';
        kav.Title = 'test';
        kav.UrlName = '53jk';
        insert kav;
        
        knowledge__DataCategorySelection dataCategory1 = new knowledge__DataCategorySelection();
        dataCategory1.DataCategoryName = 'MSD_CORE_NSC';
        dataCategory1.DataCategoryGroupName = 'Knowledge_Article_Categories';
        dataCategory1.ParentId = kav.Id;
        insert dataCategory1;
        
        knowledge__DataCategorySelection dataCategory2 = new knowledge__DataCategorySelection();
        dataCategory2.DataCategoryName = 'MSD_CORE_PCC';
        dataCategory2.DataCategoryGroupName = 'Knowledge_Article_Categories';
        dataCategory2.ParentId = kav.Id;
        insert dataCategory2;
        
        knowledge__DataCategorySelection dataCategory3 = new knowledge__DataCategorySelection();
        dataCategory3.DataCategoryName = 'MSD_CORE_RMPDC';
        dataCategory3.DataCategoryGroupName = 'Knowledge_Article_Categories';
        dataCategory3.ParentId = kav.Id;
        insert dataCategory3; 
    } 
      @isTest static void testgetKnowledge(){
        Test.startTest();
        MSD_CORE_ArticleCategoryBatch articleBatch  = new MSD_CORE_ArticleCategoryBatch();
        Database.executeBatch(articleBatch);
        Test.stopTest();    
    }
}