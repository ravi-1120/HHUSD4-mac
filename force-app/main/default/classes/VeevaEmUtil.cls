/******************************************************************************
 *
 *               Confidentiality Information:
 *
 * This module is the confidential and proprietary information of
 * Veeva Systems, Inc.; it is not to be copied, reproduced, or transmitted
 * in any form, by any means, in whole or in part, nor is it to be used
 * for any purpose other than that for which it is expressly provided
 * without the written permission of Veeva Systems, Inc.
 *
 * Copyright (c) 2022 Veeva Systems, Inc.  All Rights Reserved.
 *
 *******************************************************************************/

/**
 * VeevaEmUtil provides common functions to be shared.
 */
global without sharing class VeevaEmUtil {

    public static final Integer SFDC_CHUNK_LIMIT = 10;
    
    // https://developer.salesforce.com/forums/?id=906F000000090nUIAQ
    public static void insertSobjectsWithSafeChunkSize(List <Sobject> toUpsert) {
            Map<String, List<Sobject>> sortedMapPerObjectType = new Map<String, List<Sobject>>();
            Map<String, Integer> numberOf200ChunkPerObject = new Map<String, Integer>();
            for (Sobject obj : toUpsert) {
                String objTypeREAL = String.valueOf(obj.getSObjectType());
                if (!numberOf200ChunkPerObject.containsKey(objTypeREAL)){
                    numberOf200ChunkPerObject.put(objTypeREAL, 1);
                }
                Integer numnberOf200Record = numberOf200ChunkPerObject.get(objTypeREAL);
                String objTypeCURRENT = String.valueOf(obj.getSObjectType()) + String.valueOf(numnberOf200Record);
                List<sObject> currentList = sortedMapPerObjectType.get(objTypeCURRENT);
                if (currentList == null || currentList.size() > 199) {
                   if(currentList != null && currentList.size() > 199){
                        numberOf200ChunkPerObject.put(objTypeREAL, numnberOf200Record+1);
                        objTypeCURRENT = String.valueOf(obj.getSObjectType()) + String.valueOf(numnberOf200Record+1);
                    }
                    sortedMapPerObjectType.put(objTypeCURRENT, new List<Sobject>());
                }
                sortedMapPerObjectType.get(objTypeCURRENT).add(obj);
            }
            while(sortedMapPerObjectType.size() > 0) {
                List<Sobject> safeListForChunking = new List<Sobject>();
                List<String> keyListSobjectType = new List<String>(sortedMapPerObjectType.keySet());
                for (Integer i = 0;i<SFDC_CHUNK_LIMIT && !sortedMapPerObjectType.isEmpty();i++) {
                    List<Sobject> listSobjectOfOneType = sortedMapPerObjectType.remove(keyListSobjectType.remove(0));
                    safeListForChunking.addAll(listSobjectOfOneType);
                }
                Database.insert(safeListForChunking, false);
            }
        }
}