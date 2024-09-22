@RestResource(urlMapping='/msdcore/mysetupproducts/*')
global without sharing class MSD_CORE_MySetupProductsServices {

  @HttpPost
  global static Map<String,String> doPost(Map<String, String> data) {
    Map<String,String> result = new Map<String,String>();

    String method = (String)data.get('method');

    if (method == '') {
        //result = getList(data);
    }

    return result;
  }

  public static Map<String,String> createSyncMySetupProductsForProductMetricCampaignsJobItem(Map<String,String> opts) {

    Map<String,Object> jobItem = MSD_CORE_JobQueueService.getJobItemTemplate('syncMySetupProductsForProductMetricCampaigns');
    Map<String,String> jobItemParams = MSD_CORE_JobQueueService.getJobItemParamsTemplate('syncMySetupProductsForProductMetricCampaigns');
    jobItem.put('params', JSON.serializePretty(jobItemParams));

    Map<String,String> m = new Map<String,String>();

    for (String key : jobItem.keySet()) {
        m.put(key, (String)jobItem.get(key));
    }

    return m;
  }

    public static Map<String,Object> createSyncMySetupProductsForProductMetricCampaignsJobGroup(Map<String,String> opts) {

        List<Map<String,String>> jobItemList = new List<Map<String,String>>();
        jobItemList.add( createSyncMySetupProductsForProductMetricCampaignsJobItem(opts) );

        Map<String,Object> jobGroup = new Map<String,Object>();
        jobGroup.put('name', 'Sync My Setup Products for Product Metric Campaigns');
        jobGroup.put('jobItemList', jobItemList);

        return jobGroup;
    }

  public static Map<String,String> asyncSyncMySetupProductsForProductMetricCampaigns(Map<String,String> opts) {

    Map<String,Object> result = MSD_CORE_JobQueueService.addJobGroup(createSyncMySetupProductsForProductMetricCampaignsJobGroup(opts));
    MSD_CORE_JobQueueService.run();

    return new Map<String,String>();
  }

    public static Map<String,String> syncMySetupProductsForProductMetricCampaigns(Map<String,String> opts) {
        MSD_CORE_Logger.loggingEnabled = true;

        MSD_CORE_Logger.debug('MSD_CORE_MySetupProductsServices.syncMySetupProductsForProductMetricCampaigns: start ' + JSON.serializePretty(opts));

        Map<String, String> result = new Map<String,String>();

        try {

            Integer batchSize = Integer.valueOf(opts.get('batchSize'));
            String usersToProcessSOQL = opts.get('usersToProcessSOQL');
            String lastUserIdProcessed = opts.get('lastUserIdProcessed');

            String fetchUserBatchSOQL = usersToProcessSOQL;
            if (lastUserIdProcessed != null && lastUserIdProcessed != '') {
                fetchUserBatchSOQL += ' and Id > \'' + lastUserIdProcessed + '\' order by Id limit ' + batchSize;
            } else {
                fetchUserBatchSOQL += ' order by Id limit ' + batchSize;
            }

            opts.put('fetchUserBatchSOQL', fetchUserBatchSOQL);

            List<User> userList = (List<User>)Database.query(fetchUserBatchSOQL);

            Map<Id, Set<Id>> productIdToCampaignProductIdSetMap = getProductIdToCampaignProductIdSetMap();
            Set<Id> allCampaignProductIdSet = new Map<Id, Product_vod__c>([select External_ID_vod__c, External_Product_Type_MRK__c, Id, Master_Product_Id_MRK__c, Name, No_Details_vod__c, No_Metrics_vod__c, Parent_Product_vod__c, Product_info__c, Product_Type_vod__c,RecordTypeId from Product_vod__c where External_Product_Type_MRK__c = 'Campaign' and Active_MRK__c = true]).keySet();

            List<My_Setup_Products_vod__c> mySetupProductAddList = new List<My_Setup_Products_vod__c>();
            Set<Id> mySetupProductAddSet = new Set<Id>();

            for (User u : userList) {
                String userid = u.Id;
                Set<Id> allMysetupProductsIdSet = new Set<Id>();
                for (My_Setup_Products_vod__c msp : [select Id, OwnerId, Product_vod__c from My_Setup_Products_vod__c where OwnerId = :userid]) {
                    allMysetupProductsIdSet.add(msp.Product_vod__c);
                }

                Set<Id> campaignMysetupProductsIdSet = new Set<Id>();
                for (My_Setup_Products_vod__c msp : [select Id, OwnerId, Product_vod__c from My_Setup_Products_vod__c where OwnerId = :userid and Product_vod__r.External_Product_Type_MRK__c = 'Campaign']) {
                    campaignMysetupProductsIdSet.add(msp.Product_vod__c);
                }

                Set<Id> nonCampaignMysetupProductsIdSet = new Set<Id>();
                for (My_Setup_Products_vod__c msp : [select Id, OwnerId, Product_vod__c from My_Setup_Products_vod__c where OwnerId = :userid and Product_vod__r.Product_Type_vod__c = 'Detail']) {
                    nonCampaignMysetupProductsIdSet.add(msp.Product_vod__c);
                }

                MSD_CORE_Logger.debug('allMysetupProductsIdSet:\n' + JSON.serializePretty(allMysetupProductsIdSet));
                MSD_CORE_Logger.debug('campaignMysetupProductsIdSet:\n' + JSON.serializePretty(campaignMysetupProductsIdSet));
                MSD_CORE_Logger.debug('nonCampaignMysetupProductsIdSet:\n' + JSON.serializePretty(nonCampaignMysetupProductsIdSet));

                for (Id productId : nonCampaignMysetupProductsIdSet) {

                    Set<Id> campaignProductIdSet = productIdToCampaignProductIdSetMap.get(productId);

                    if (campaignProductIdSet != null) {

                        for (Id campaignProductId : campaignProductIdSet) {

                            if (!allMysetupProductsIdSet.contains(campaignProductId)) {
                                mySetupProductAddSet.add(campaignProductId);
                                mySetupProductAddList.add(new My_Setup_Products_vod__c(
                                    OwnerId = userid,
                                    Product_vod__c = campaignProductId
                                ));
                            }

                        }

                    }
                }

                // TODO: add remove logic here
            }

            MSD_CORE_Logger.debug('mySetupProductAddList:\n' + JSON.serializePretty(mySetupProductAddList));
            Database.SaveResult[] saveResultList = Database.insert(mySetupProductAddList);

            // TODO: handle error

            if (userList.size() < batchSize) {
                opts.put('done', 'true');
            } else {
                opts.put('done', 'false');
                opts.put('lastUserIdProcessed', userList[userList.size() - 1].Id + '');
            }

            MSD_CORE_Logger.debug('MSD_CORE_MySetupProductsServices.syncMySetupProductsForProductMetricCampaigns: before return' + JSON.serializePretty(result));
        } catch (Exception e) {
            String errString = e + ', line #:' + e.getLineNumber() + '\nStack Trace:\n' + e.getStackTraceString();
            MSD_CORE_Logger.error(errString);
            opts.put('error', errString);
        } finally {
            MSD_CORE_Logger.flush();
        }

        return opts;
    }


    public static Map<Id, Set<Id>> getProductIdToCampaignProductIdSetMap() {
        List<Product_vod__c> campaignProductList = [select External_ID_vod__c, External_Product_Type_MRK__c, Id, Master_Product_Id_MRK__c, Name, No_Details_vod__c, No_Metrics_vod__c, Parent_Product_vod__c, Product_info__c, Product_Type_vod__c,RecordTypeId from Product_vod__c where External_Product_Type_MRK__c = 'Campaign' and Active_MRK__c = true];

        MSD_CORE_Logger.debug('campaignProductList:\n' + JSON.serializePretty(campaignProductList));

        Map<String,Id> campaignNameToCampaignProductIdMap = new Map<String,Id>();
        for (Product_vod__c campaignProduct : campaignProductList) {
            campaignNameToCampaignProductIdMap.put(campaignProduct.Name, campaignProduct.Id);
        }

        List<MSD_CORE_List_Product__c> listProductList = [select Id, MSD_CORE_List__c, MSD_CORE_List__r.MSD_CORE_Name__c, MSD_CORE_Product__c from MSD_CORE_List_Product__c where MSD_CORE_List__r.MSD_CORE_Name__c in :campaignNameToCampaignProductIdMap.keySet()];
        MSD_CORE_Logger.debug('listProductList:\n' + JSON.serializePretty(listProductList));

        Map<Id, Set<Id>> productIdToCampaignProductIdSetMap = new Map<Id, Set<Id>>();

        for (MSD_CORE_List_Product__c listProduct : listProductList) {


            Set<Id> campaignProductIdSet = productIdToCampaignProductIdSetMap.get(listProduct.MSD_CORE_Product__c);
            if (campaignProductIdSet == null) {
                campaignProductIdSet = new Set<Id>();
                productIdToCampaignProductIdSetMap.put(listProduct.MSD_CORE_Product__c, campaignProductIdSet);
            }

            Id campaignProductId = campaignNameToCampaignProductIdMap.get(listProduct.MSD_CORE_List__r.MSD_CORE_Name__c);
            campaignProductIdSet.add(campaignProductId);

        }

        MSD_CORE_Logger.debug('productIdToCampaignProductIdSetMap:\n' + JSON.serializePretty(productIdToCampaignProductIdSetMap));

       return productIdToCampaignProductIdSetMap;
    }


 }