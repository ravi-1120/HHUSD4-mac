global class MSD_CORE_ListServicesSchedulable implements Schedulable {

   global void execute(SchedulableContext sc) {
        if ( MSD_CORE_Setting.getString('LIST_MANAGER', 'identifyAndExpireLists') == 'true' ) {
            MSD_CORE_ListServices.identifyAndExpireLists(null);
        }

        if ( MSD_CORE_Setting.getString('LIST_MANAGER', 'identifyAndActivateLists') == 'true' ) {
            MSD_CORE_ListServices.identifyAndActivateLists(null);
        }

        if ( MSD_CORE_Setting.getString('LIST_MANAGER', 'asyncSyncMySetupProductsForProductMetricCampaigns') == 'true' ) {
            MSD_CORE_MySetupProductsServices.asyncSyncMySetupProductsForProductMetricCampaigns(new Map<String,String>());
        }

        if ( MSD_CORE_Setting.getString('LIST_MANAGER', 'trimLogItemRecords') == 'true' ) {
            try {
                String soql = MSD_CORE_Setting.getString('LIST_MANAGER', 'trimLogItemRecordsSOQL');
                Database.delete(Database.query(soql), false);
            } catch(Exception e) {}
        }

   }


}