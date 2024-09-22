/*
    Created by -  RK Koluri
    Last Modified By - Joshi Jigyasu
    Last Modified Date - 15-05-2023
    Description - Controller class to query Templates 
        and to create many-to-many between Templates and Scheduler admin app
*/
public with sharing class TemplateController {
    public static String className = 'TemplateController';
    public TemplateController() {

    }
    @AuraEnabled(cacheable=true)
    public static Map<String,object> getTemplates(Id schedulerId){
        Map<String,object> returnMap=new Map<String,object>();
        try {
            List<Appointment_Template__c> listTemplates= [Select id, name
                from Appointment_Template__c where IsActive__c = true];
            returnMap.put('listTemplates',listTemplates);

            String askMerckPicklist = 'AskMerck';
            List<MSD_CORE_Product_Payor__c> listProducts= 
                [Select id, name from MSD_CORE_Product_Payor__c where Related_System__c =:askMerckPicklist]; 
            returnMap.put('listProducts',listProducts);

             List<Product_Template__c> listProductTemplates= [Select Id, Name, Appointment_Template__c,
                Appointment_Template__r.Name, Product_Payor__c from Product_Template__c ]; 
            returnMap.put('listProductTemplates',listProductTemplates);
            
            List<Admin_Product__c> listExtProducts= [Select Id, Product_Payor__c, Name, Order__c
                from Admin_Product__c where Scheduler_Configuration__c=:schedulerId];
            returnMap.put('listExtProducts',listExtProducts);
            returnMap.put('existingTemplates',getSchedulerTemplates(schedulerId));

            return returnMap;

        } catch (Exception e) {
            System.debug('ex-->'+ e);
            AMOExceptionHandler.logException(e,className,'getTemplates','','Apex');
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Scheduler_Template__c> getSchedulerTemplates(Id schedulerId){
        try {
            return [Select id, Name, Order__c, Product_Payor__c, Appointment_Template__c, 
                Appointment_Template__r.name, Scheduler_Configuration__c, Scheduler_Configuration__r.name 
                from Scheduler_Template__c where Scheduler_Configuration__c = :schedulerId];
        } catch (Exception e) {
            System.debug('ex-->'+ e);
            AMOExceptionHandler.logException(e,className,'getSchedulerTemplates','','Apex');
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Scheduler_Template__c> createSchedulerTemplates(Id schedulerId, List<Id> templateIds, 
                                List<Map<String,Object>> orderIdMap, List<Map<String,Object>> productIds){

        // Mammet code starts
        List<Id> templateIdsList = new List<Id>();
        Map<String,String> orderMap = new Map<String,String>();
        Map<String,String> templateProdMap = new Map<String,String>();
        for(Map<String,Object> element : orderIdMap){
            orderMap.put(String.valueOf(element.get('id')), String.valueOf(element.get('order')));
            templateProdMap.put(String.valueOf(element.get('id')),String.valueOf(element.get('ProductPayorID')));
            templateIdsList.add(String.valueOf(element.get('id')));
        }
        // Mammet code ends

        //products Code
        delete [select id from Admin_Product__c where Scheduler_Configuration__c=:schedulerId];
        List<Admin_Product__c> productList = new List<Admin_Product__c>();
        for(Map<String,Object> element :productIds){
            productList.add( new Admin_Product__c(Scheduler_Configuration__c=schedulerId,Product_Payor__c=String.valueOf(element.get('id')),Order__c=String.valueOf(element.get('order'))) );
        }
        if(!productList.isEmpty()){
            insert productList;
        }

        Map<Id,Id> existingTemplates=new Map<Id,Id>();
        List<Scheduler_Template__c> deleteList = new List<Scheduler_Template__c>();
        for(Scheduler_Template__c exttemp: [Select id,Product_Payor__c, Appointment_Template__c from Scheduler_Template__c where Scheduler_Configuration__c = :schedulerId]){
            existingTemplates.put(exttemp.Appointment_Template__c,exttemp.id);
            if(!templateIdsList.contains(exttemp.Appointment_Template__c)){
                deleteList.add(new Scheduler_Template__c(Id=exttemp.id));
            }
        }

        List<Scheduler_Template__c> upsertList = new List<Scheduler_Template__c>();
        for(Id tempId : templateIdsList){
            upsertList.add(new Scheduler_Template__c(
                Appointment_Template__c = tempId,
                Scheduler_Configuration__c = schedulerId,
                Order__c = orderMap.get(tempId),
                Product_Payor__c=templateProdMap.get(tempId),
                id=existingTemplates.containsKey(tempId)?existingTemplates.get(tempId): null
            ));
        }

        try {
            upsert upsertList;
            delete deleteList;
            List<String> templateNames = new List<String>();
            List<String> productsList = new List<String>();
            boolean templatesChanged=false;
            integer prodSize=0;
            integer templateSize=0;
            Scheduler_Configuration__c configRecord = [SELECT JSON_Payload__c FROM Scheduler_Configuration__c WHERE Id =: schedulerId ];
            if(configRecord.JSON_Payload__c!=null){
                ScheduleRequest payload = (ScheduleRequest)JSON.deserialize(configRecord.JSON_Payload__c, ScheduleRequest.class);
                for(ScheduleRequest.templates str : payload.templates){
                    templateNames.add(str.label.replace(',','&'));
                }
                for(ScheduleRequest.products pro : payload.products){
                    productsList.add(pro.label);
                }
                for(Admin_Product__c product:[Select Product_Payor__r.Name from Admin_Product__c where Scheduler_Configuration__c=:schedulerId]){
                    if(!productsList.contains(product.Product_Payor__r.Name)){
                        templatesChanged=true;
                        break;
                    }
                    prodSize++;
                }
                system.debug('templateNames :'+templateNames);
                for(Scheduler_Template__c schTemplate: [ Select Id,Appointment_Template__r.name from Scheduler_Template__c where Scheduler_Configuration__c = :schedulerId]){
                    
                    system.debug('template name :'+schTemplate.Appointment_Template__r.name.replace(',','&'));
                    if(!templateNames.contains(schTemplate.Appointment_Template__r.name.replace(',','&'))){
                        system.debug('template name inside if :'+schTemplate.Appointment_Template__r.name.replace(',','&'));
                        templatesChanged=true;
                        break;
                    }
                    templateSize++;
                }
                system.debug('productsList:'+productsList.size());
                system.debug('templateNames:'+templateNames.size());
                system.debug('prodSize:'+prodSize);
                system.debug('templateSize:'+templateSize);
                if(productsList.size()!=prodSize ||templateNames.size()!=templateSize){
                    templatesChanged=true;
                }
            }else{
                templatesChanged=true;
            }
            system.debug('templatesChanged:'+templatesChanged);
            if(templatesChanged ){
                SchedulerPayloadGenerator.generateJSON(new set<Id>{schedulerId},true);
            }
            return upsertList;
        } catch (Exception e) {
            System.debug('ex-->'+ e);
            System.debug('ex-line->'+ e.getLineNumber());
            System.debug('ex-line->'+ e.getStackTraceString());
            AMOExceptionHandler.logException(e,className,'createSchedulerTemplates','','Apex');
            throw new AuraHandledException(e.getMessage());
        }
    }
  
}