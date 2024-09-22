global with sharing class EmSpeakerSelection {

    static final Set<String> SOSL_RESERVED_CHARACTERS_SET = new Set<String>{'?','&','|','!','{','}','[',']','(',')','^','~','*',':','\\','"','\'','+','-'};

    @AuraEnabled
    public static List<EM_Speaker_vod__c> querySpeakers(List<String> fields, List<String> services, List<String> trainings, List<String> status, List<String> tier, String orderBy, String orderDirection, Integer qLimit, Integer offset) {
		List<Id> qualifiedSpeakers;
        if ((services != null && !services.isEmpty()) || (trainings != null && !trainings.isEmpty())) {
            qualifiedSpeakers = getQualifiedSpeakerIdList(services, trainings);
            if (qualifiedSpeakers.isEmpty()) {
                return new List<EM_Speaker_vod__c>();
            }
        }
        return querySpeakers(fields, qualifiedSpeakers, status, tier, orderBy, orderDirection, qLimit, offset);
    }

    private static List<Em_Speaker_vod__c> querySpeakers(List<String> fields, List<Id> qualifiedSpeakers, List<String> status, List<String> tier, String orderBy, String orderDirection, Integer qLimit, Integer offset) {
    	String soqlTemplate = 'SELECT {0} FROM EM_Speaker_vod__c {1}';
        List<Object> templateParameters = new List<Object> {String.escapeSingleQuotes(String.join(applyLabel(fields), ','))};
        String whereOrderByLimitClause = createWhereOrderByLimitClause(qualifiedSpeakers, status, tier, orderBy, orderDirection, qLimit, offset);
        templateParameters.add(whereOrderByLimitClause);
        String soql = String.format(soqlTemplate, templateParameters);
        List<EM_Speaker_vod__c> results = Database.query(soql);
        return results;
    }

    @AuraEnabled
    public static List<EM_Speaker_vod__c> searchSpeakers(String searchTerm, List<String> fields, List<String> services, List<String> trainings, List<String> status, List<String> tier, String orderBy, String orderDirection, Integer qLimit, Integer offset) {
        if (String.isBlank(searchTerm)) {
            return new List<EM_Speaker_vod__c>();
        }
        List<Id> qualifiedSpeakers;
        if ((services != null && !services.isEmpty()) || (trainings != null && !trainings.isEmpty())) {
            qualifiedSpeakers = getQualifiedSpeakerIdList(services, trainings);
            if (qualifiedSpeakers.isEmpty()) {
                return new List<EM_Speaker_vod__c>();
            }
        }
        return searchSpeakers(searchTerm, fields, qualifiedSpeakers, status, tier, orderBy, orderDirection, qLimit, offset);
    }

    private static List<Em_Speaker_vod__c> searchSpeakers(String searchTerm, List<String> fields, List<Id> qualifiedSpeakers, List<String> status, List<String> tier, String orderBy, String orderDirection, Integer qLimit, Integer offset) {
        SOSLQueryHelper helper = new SOSLQueryHelper();
    	String soslTemplate = 'FIND {0} IN ALL FIELDS RETURNING EM_Speaker_vod__c ({1})';
        searchTerm = helper.escapeSpecialCharacters(searchTerm);
        List<String> terms = searchTerm.split('\\s+');
        terms = helper.addWildcardToTerms(terms);
        String term = String.join(terms, ' AND ');
        List<Object> templateParameters = new List<Object> {'{'+ term +'}'};
        String returnFields = String.escapeSingleQuotes(String.join(applyLabel(fields), ','));
        String whereOrderByLimitClause = createWhereOrderByLimitClause(qualifiedSpeakers, status, tier, orderBy, orderDirection, qLimit, offset);
		returnFields += whereOrderByLimitClause;
        templateParameters.add(returnFields);
        String sosl = String.format(soslTemplate, templateParameters);
        List<List<EM_Speaker_vod__c>> results = search.query(sosl);
        return results.get(0);
    }

    private static List<Id> getQualifiedSpeakerIdList(List<String> services, List<String> trainings) {
        Map<String,Schema.RecordTypeInfo> speakerQualificationRtMap = EM_Speaker_Qualification_vod__c.sObjectType.getDescribe()?.getRecordTypeInfosByDeveloperName();
        Id qualificationServiceRecordTypeId = speakerQualificationRtMap?.get('Speaker_Service_vod')?.getRecordTypeId();
        Id qualificationTrainingRecordTypeId = speakerQualificationRtMap?.get('Speaker_Training_vod')?.getRecordTypeId();

        Integer recordTypeCount = 0;

        String query = 'SELECT Speaker_vod__c FROM EM_Speaker_Qualification_vod__c';
        List<String> whereClauses = new List<String>();
        if (services != null && !services.isEmpty()) {
            whereClauses.add('(Qualification_vod__c IN :services AND RecordTypeId = \''+qualificationServiceRecordTypeId+'\' AND (Contract_Partner_Status_vod__c = null OR Contract_Partner_Status_vod__c = \'Activated_vod\') AND (Contract_Status_vod__c = null OR Contract_Status_vod__c = \'Activated_vod\'))');
            recordTypeCount++;
        }
        if (trainings!= null && !trainings.isEmpty()) {
            whereClauses.add('(Qualification_vod__c IN :trainings AND RecordTypeId = \''+qualificationTrainingRecordTypeId+'\')');
            recordTypeCount++;
        }
        if (whereClauses.size() > 0) {
            query += ' WHERE (Start_Date_vod__c = null OR Start_Date_vod__c <= TODAY) AND (End_Date_vod__c = null OR End_Date_vod__c >= TODAY) AND ('+String.join(whereClauses, ' OR ')+ ')';
        }
        query += ' GROUP BY Speaker_vod__c HAVING COUNT_DISTINCT(RecordTypeId) = ' + recordTypeCount;
        List<AggregateResult> qualifications = Database.query(query);
        List<Id> qualifiedSpeakers = new List<Id>();
        for (AggregateResult qualification : qualifications) {
            qualifiedSpeakers.add((Id) qualification.get('Speaker_vod__c'));
        }
        return qualifiedSpeakers;
    }

    private static String createWhereOrderByLimitClause(List<String> qualifiedSpeakers, List<String> status, List<String> tier, String orderBy, String orderDirection, Integer qLimit, Integer offset) {
        String clause = '';
        List<String> whereClauses = new List<String>();
        if (qualifiedSpeakers != null && !qualifiedSpeakers.isEmpty()) {
            whereClauses.add('Id IN :qualifiedSpeakers');
        }
        if (status != null && !status.isEmpty()) {
            whereClauses.add('Status_vod__c IN :status');
        }
        if (tier != null && !tier.isEmpty()) {
            whereClauses.add('Tier_vod__c IN :tier');
        }
        if (!whereClauses.isEmpty()) {
            clause += ' WHERE ' + String.join(whereClauses, ' AND ');
        }
        if (String.isNotBlank(orderBy) && String.isNotBlank(orderDirection)) {
            clause += ' ORDER BY '+String.escapeSingleQuotes(orderBy(orderBy)+' '+orderDirection)+' NULLS LAST';
        }
        if (qLimit != null && offset != null) {
            clause += ' LIMIT :qLimit OFFSET :offset';
        }
        return clause;
    }

    // LEX Changes

    static final Set<String> SPEAKER_FIELD_KEYWORDS = new Set<String>{'CV','RecentEvents', 'Training', 'Services'};
    static final String STATUS = 'Status_vod__c';
    static final String RECORD_TYPE_ID = 'RecordTypeId';
    static final String STATUS_ALIAS = 'statusLabel';
    static final String NEXT_YEAR_RESET_DATE = 'Next_Year_Reset_Date_vod__c';
    static final String NEXT_YEAR_RESET_DATE_ALIAS = 'nextYearResetLabel';
    static final String NEXT_YEAR_STATUS = 'Next_Year_Status_vod__c';
    static final String NEXT_YEAR_STATUS_ALIAS = 'nextYearStatusLabel';
    static Map<String, String> rawFieldsToInclude = new Map<String, String> {
        NEXT_YEAR_RESET_DATE => 'FORMAT('+NEXT_YEAR_RESET_DATE+') ' + NEXT_YEAR_RESET_DATE_ALIAS,
        NEXT_YEAR_STATUS => 'toLabel('+NEXT_YEAR_STATUS+') ' + NEXT_YEAR_STATUS_ALIAS
    };

    @AuraEnabled
    public static List<EM_Speaker_vod__c> querySpeakersLex(List<String> fields, List<String> filterRules, DateTime startTime, String topicId, String orderBy, String orderDirection, Integer qLimit, Integer offset) {
        if (!fields.contains(STATUS)) {
            fields.add(STATUS);
        }
        List<Object> parameters = new List<Object> {String.escapeSingleQuotes(String.join(applyLabel(fields, rawFieldsToInclude), ','))};
        String soqlTemplate = 'SELECT {0} FROM EM_Speaker_vod__c';
        if (filterRules != null && !filterRules.isEmpty()) {
            List<Id> qualifiedSpeakers = getQualifiedSpeakerIdList(startTime, topicId, filterRules);
            if (qualifiedSpeakers.isEmpty()) {
                return new List<EM_Speaker_vod__c>();
            }
            soqlTemplate += ' WHERE Id IN :qualifiedSpeakers';
        }
        if (String.isNotBlank(orderBy) && String.isNotBlank(orderDirection)) {
            soqlTemplate += ' ORDER BY {1} {2}';
            parameters.add(String.escapeSingleQuotes(orderBy(orderBy)));
            if ('desc'.equalsIgnoreCase(orderDirection)) {
                orderDirection += ' NULLS LAST';
            }
            parameters.add(String.escapeSingleQuotes(orderDirection));
        }
        if (qLimit != null && offset != null) {
            soqlTemplate += ' LIMIT :qLimit OFFSET :offset';
        }
        String soql = String.format(soqlTemplate, parameters);
        List<EM_Speaker_vod__c> results = Database.query(soql);
        return results;
    }

    @AuraEnabled
    public static List<EM_Speaker_vod__c> searchSpeakersLex(String termString, List<String> fields, List<String> filterRules, DateTime startTime, String topicId, String orderBy, String orderDirection, Integer qLimit, Integer offset) {
        if (String.isBlank(termString)) {
            return new List<EM_Speaker_vod__c>();
        }
        if (!fields.contains(STATUS)) {
            fields.add(STATUS);
        }
        SOSLQueryHelper helper = new SOSLQueryHelper();
        termString = helper.escapeSpecialCharacters(termString);
        List<String> terms = termString.split('\\s+');
        terms = helper.addWildcardToTerms(terms);
        String term = String.join(terms, ' AND ');
        String returnFields = String.escapeSingleQuotes(String.join(applyLabel(fields, rawFieldsToInclude), ','));
        if (filterRules != null && !filterRules.isEmpty()) {
            List<Id> qualifiedSpeakers = getQualifiedSpeakerIdList(startTime, topicId, filterRules);
            if (qualifiedSpeakers.isEmpty()) {
                return new List<EM_Speaker_vod__c>();
            }
            returnFields += ' WHERE Id IN :qualifiedSpeakers';
        }
        if (String.isNotBlank(orderBy) && String.isNotBlank(orderDirection)) {
            returnFields += ' ORDER BY '+String.escapeSingleQuotes(orderBy(orderBy)+' '+orderDirection);
            if ('desc'.equalsIgnoreCase(orderDirection)) {
                returnFields += ' NULLS LAST';
            }
        }
        if (qLimit != null && offset != null) {
            returnFields += ' LIMIT :qLimit OFFSET :offset';
        }
        List<Object> parameters = new List<Object> {'{'+term+'}', returnFields};
        String soslTemplate = 'FIND {0} IN ALL FIELDS RETURNING EM_Speaker_vod__c ({1})';

        String sosl = String.format(soslTemplate, parameters);
        List<List<EM_Speaker_vod__c>> results = search.query(sosl);
        return results.get(0);
    }

    static List<String> applyLabel(List<String> fields) {
        return applyLabel(fields, new Map<String, String>());
    }

    static List<String> applyLabel(List<String> fields, Map<String, String> fieldsWithRawValues) {
        Set<String> labeledFields = new Set<String>();
        Map<String, Schema.SObjectField> fieldsMap = EM_Speaker_vod__c.sObjectType.getDescribe()?.fields.getMap();
        if (fieldsMap != null) {
            for (String field: fields) {
                Schema.DisplayType fieldType = fieldsMap.get(field).getDescribe()?.getType();
                if (fieldType == null) {
                    continue;
                }
                if (STATUS.equals(field)) {
                    labeledFields.add(field);
                    labeledFields.add('toLabel('+field+') '+STATUS_ALIAS);
                } else if (fieldsWithRawValues.containsKey(field)) {
                    labeledFields.add(field);
                    labeledFields.add(fieldsWithRawValues.get(field));
                } else if (RECORD_TYPE_ID.equals(field)) {
                    labeledFields.add('toLabel('+fieldsMap.get(field).getDescribe().getRelationshipName()+'.Name)');
                } else if (fieldType == Schema.DisplayType.PICKLIST || fieldType == Schema.DisplayType.MULTIPICKLIST) {
                    labeledFields.add('toLabel('+field+')');
                } else if (fieldType == Schema.DisplayType.REFERENCE) {
                    labeledFields.add(fieldsMap.get(field).getDescribe().getRelationshipName()+'.Name');
                } else if (fieldType == Schema.DisplayType.CURRENCY || fieldType == Schema.DisplayType.DATE || fieldType == Schema.DisplayType.TIME || fieldType == Schema.DisplayType.DATETIME) {
                    labeledFields.add('FORMAT('+field+')');
                } else {
                    labeledFields.add(field);
                }
            }
        }
        return new List<String> (labeledFields);
    }

    static String orderBy(String field) {
        String orderByField = field;
        Map<String, Schema.SObjectField> fieldsMap = EM_Speaker_vod__c.sObjectType.getDescribe()?.fields.getMap();
        if (STATUS_ALIAS.equals(field)) {
            orderByField = STATUS;
        } else if (fieldsMap.get(field)?.getDescribe()?.getType() == Schema.DisplayType.REFERENCE) {
            orderByField = fieldsMap.get(field).getDescribe().getRelationshipName()+'.Name';
        }
        return orderByField;
    }

    static List<Id> getQualifiedSpeakerIdList(DateTime startTime, String topicId, List<String> eventRuleIds) {
        Date startDate = startTime?.date();
        List<EM_Event_Rule_vod__c> eventRules = [SELECT RecordTypeId, Qualification_vod__c, Qualification_vod__r.RecordTypeId FROM EM_Event_Rule_vod__c WHERE Id in :eventRuleIds];
        if (eventRules.isEmpty()) {
            return new List<Id>();
        }

        Map<String,Schema.RecordTypeInfo> catalogRtMap = EM_Catalog_vod__c.sObjectType.getDescribe()?.getRecordTypeInfosByDeveloperName();
        Id catalogEventTopicRecordTypeId = catalogRtMap?.get('Event_Topic_vod')?.getRecordTypeId();
        Id catalogGeneralTopicRecordTypeId = catalogRtMap?.get('General_Topic_vod')?.getRecordTypeId();
        Id catalogSpeakerServiceRecordTypeId = catalogRtMap?.get('Speaker_Service_vod')?.getRecordTypeId();
        Map<String,Schema.RecordTypeInfo> speakerQualificationRtMap = EM_Speaker_Qualification_vod__c.sObjectType.getDescribe()?.getRecordTypeInfosByDeveloperName();
        Id qualificationServiceRecordTypeId = speakerQualificationRtMap?.get('Speaker_Service_vod')?.getRecordTypeId();
        Id qualificationTrainingRecordTypeId = speakerQualificationRtMap?.get('Speaker_Training_vod')?.getRecordTypeId();


        Id eventTopic = null;
        List<Id> generalTopicQualifications = new List<Id>();
        List<Id> speakerServiceQualifications = new List<Id>();
        for (EM_Event_Rule_vod__c rule : eventRules) {
            if (rule.Qualification_vod__r.RecordTypeId == catalogGeneralTopicRecordTypeId) {
                generalTopicQualifications.add(rule.Qualification_vod__c);
            } else if (rule.Qualification_vod__r.RecordTypeId == catalogSpeakerServiceRecordTypeId) {
                speakerServiceQualifications.add(rule.Qualification_vod__c);
            } else if (rule.Qualification_vod__c == null) { //null means Event Topic
                eventTopic = topicId;
            }
        }

        Integer qualificationsCount = 0;

        String query = 'SELECT Speaker_vod__c FROM EM_Speaker_Qualification_vod__c';
        List<String> whereClauses = new List<String>();
        if (!speakerServiceQualifications.isEmpty()) {
            whereClauses.add('(Qualification_vod__c IN (\''+String.join(speakerServiceQualifications,'\',\'')+'\') AND RecordTypeId = \''+qualificationServiceRecordTypeId+'\' AND (Contract_Partner_Status_vod__c = null OR Contract_Partner_Status_vod__c = \'Activated_vod\') AND (Contract_Status_vod__c = null OR Contract_Status_vod__c = \'Activated_vod\'))');
            qualificationsCount += speakerServiceQualifications.size();
        }
        if (!generalTopicQualifications.isEmpty()) {
            whereClauses.add('(Qualification_vod__c IN (\''+String.join(generalTopicQualifications,'\',\'')+'\') AND RecordTypeId = \''+qualificationTrainingRecordTypeId+'\')');
            qualificationsCount += generalTopicQualifications.size();
        }
        if (eventTopic != null) {
            whereClauses.add('(Qualification_vod__c = \''+eventTopic+'\' AND Qualification_vod__r.RecordTypeId = \''+catalogEventTopicRecordTypeId+'\')');
            qualificationsCount++;
        }
        if (whereClauses.size() > 0) {
            query += ' WHERE (Start_Date_vod__c = null OR Start_Date_vod__c <= :startDate) AND (End_Date_vod__c = null OR End_Date_vod__c >= :startDate) AND ('+String.join(whereClauses, ' OR ')+ ')';
        }
        query += ' GROUP BY Speaker_vod__c HAVING COUNT_DISTINCT(Qualification_vod__c) = '+qualificationsCount;
        List<AggregateResult> qualifications = Database.query(query);
        List<Id> qualifiedSpeakers = new List<Id>();
        for (AggregateResult qualification : qualifications) {
            qualifiedSpeakers.add((Id) qualification.get('Speaker_vod__c'));
        }
        return qualifiedSpeakers;
    }

    @AuraEnabled
    public static List<SpeakerService> getServices(String speakerId, DateTime startTime) {
        List<SpeakerService> speakerServices = new List<SpeakerService>();
        Date startDate = startTime?.date();

        Map<String, Schema.SObjectField> qualificationFieldsMap = EM_Speaker_Qualification_vod__c.sObjectType.getDescribe()?.fields.getMap();
        List<String> qualificationQueryFields = new List<String>{'Rate_vod__c','Rate_Type_vod__c'};
        Map<String, Schema.SObjectField> catalogFieldsMap = EM_Catalog_vod__c.sObjectType.getDescribe()?.fields.getMap();
        if (String.isBlank(speakerId) || startDate == null || (!hasFlsToAll(qualificationFieldsMap, qualificationQueryFields) && !hasFls(catalogFieldsMap, 'Name_vod__c'))) {
            return speakerServices;
        }
        List<EM_Speaker_Qualification_vod__c> services = [SELECT Qualification_vod__r.Name_vod__c, FORMAT(Rate_vod__c) formattedRate, toLabel(Rate_Type_vod__c)
               FROM EM_Speaker_Qualification_vod__c
               WHERE Speaker_vod__c = :speakerId
                AND RecordType.Name = 'Speaker_Service_vod'
                AND (Contract_Partner_Status_vod__c = null OR Contract_Partner_Status_vod__c = 'Activated_vod')
                AND (Contract_Status_vod__c = null OR Contract_Status_vod__c = 'Activated_vod')
                AND (Start_Date_vod__c = null OR Start_Date_vod__c <= :startDate)
                AND (End_Date_vod__c = null OR End_Date_vod__c >= :startDate)
               ORDER BY Qualification_vod__r.Name_vod__c LIMIT 50];

        String serviceRateMsg = VOD_VEEVA_MESSAGE.getMsgWithDefault('SERVICE_RATE','EVENT_MANAGEMENT','{0}/{1}');
        for (EM_Speaker_Qualification_vod__c service : services) {
            String serviceRate = '';
            if (String.isNotBlank((String)service.get('formattedRate')) && String.isNotBlank(service.Rate_Type_vod__c)) {
                List<Object> parameters = new List<Object> {service.get('formattedRate'), service.Rate_Type_vod__c};
                serviceRate = String.format(serviceRateMsg, parameters);
            }
            speakerServices.add(new SpeakerService(service.Id, service.Qualification_vod__r.Name_vod__c, serviceRate));
        }
        return speakerServices;
    }

    private class SpeakerService {
        @AuraEnabled
        public Id serviceId {get;set;}
        @AuraEnabled
        public String name {get;set;}
        @AuraEnabled
        public String rate {get;set;}

        SpeakerService(Id serviceId, String name, String rate) {
            this.serviceId = serviceId;
            this.name = name;
            this.rate = rate;
        }
    }

    @AuraEnabled
    public static List<SpeakerTraining> getTraining(String speakerId, DateTime startTime) {
        List<SpeakerTraining> speakerTraining = new List<SpeakerTraining>();
        Date startDate = startTime?.date();

        Map<String, Schema.SObjectField> qualificationFieldsMap = EM_Speaker_Qualification_vod__c.sObjectType.getDescribe()?.fields.getMap();
        Map<String, Schema.SObjectField> catalogFieldsMap = EM_Catalog_vod__c.sObjectType.getDescribe()?.fields.getMap();
        if (String.isBlank(speakerId) || startDate == null || (!hasFls(qualificationFieldsMap, 'End_Date_vod__c') && !hasFls(catalogFieldsMap, 'Name_vod__c'))) {
            return speakerTraining;
        }
        List<EM_Speaker_Qualification_vod__c> trainings = [SELECT Qualification_vod__r.Name_vod__c, FORMAT(End_Date_vod__c) endDate
               FROM EM_Speaker_Qualification_vod__c
               WHERE Speaker_vod__c = :speakerId
                AND RecordType.Name = 'Speaker_Training_vod'
                AND (Start_Date_vod__c = null OR Start_Date_vod__c <= :startDate)
                AND (End_Date_vod__c = null OR End_Date_vod__c >= :startDate)
               ORDER BY Qualification_vod__r.Name_vod__c LIMIT 50];

        for (EM_Speaker_Qualification_vod__c training : trainings) {
            speakerTraining.add(new SpeakerTraining(training));
        }
        return speakerTraining;
    }

    private class SpeakerTraining {
        @AuraEnabled
        public Id trainingId {get;set;}
        @AuraEnabled
        public String name {get;set;}
        @AuraEnabled
        public String endDate {get;set;}

        SpeakerTraining(EM_Speaker_Qualification_vod__c training) {
            this.trainingId = training.Id;
            this.name = training.Qualification_vod__r.Name_vod__c;
            this.endDate = (String) training.get('endDate');
        }
    }

    @AuraEnabled
    public static List<SpeakerFilterGroup> getSpeakerFilters(String eventId) {
        List<SpeakerFilterGroup> filters = new List<SpeakerFilterGroup>();

        EM_Event_vod__c event = [SELECT Id, Country_vod__c, Event_Configuration_vod__c, Topic_vod__c, Topic_vod__r.Name_vod__c, Topic_vod__r.RecordTypeId FROM EM_Event_vod__c WHERE Id = :eventId];
        if (event != null) {
            String eventConfigId = event.Event_Configuration_vod__c;
            String countryId = event.Country_vod__c;

            Id speakerQualificationRecordTypeId = EM_Event_Rule_vod__c.sObjectType.getDescribe()?.getRecordTypeInfosByDeveloperName().get('Speaker_Qualification_vod')?.getRecordTypeId();
            Map<String,Schema.RecordTypeInfo> rtMap = EM_Catalog_vod__c.sObjectType.getDescribe()?.getRecordTypeInfosByDeveloperName();
            Id eventTopicRecordTypeId = rtMap?.get('Event_Topic_vod')?.getRecordTypeId();
            Id generalTopicRecordTypeId = rtMap?.get('General_Topic_vod')?.getRecordTypeId();
            Id speakerServiceRecordTypeId = rtMap?.get('Speaker_Service_vod')?.getRecordTypeId();

            if (speakerQualificationRecordTypeId != null && eventTopicRecordTypeId != null && generalTopicRecordTypeId != null && speakerServiceRecordTypeId != null) {
                SpeakerFilterGroup services = new SpeakerFilterGroup(VOD_VEEVA_MESSAGE.getMsgWithDefault('SERVICES_FILTER','EVENT_MANAGEMENT','Services'));
                SpeakerFilterGroup training = new SpeakerFilterGroup(VOD_VEEVA_MESSAGE.getMsgWithDefault('TRAINING_FILTER','EVENT_MANAGEMENT','Training'));

                List<EM_Event_Rule_vod__c> qualificationRules = [SELECT Id, Filter_Type_vod__c, Qualification_vod__c, Qualification_vod__r.Name_vod__c, Qualification_vod__r.RecordTypeId
                                                                 FROM EM_Event_Rule_vod__c
                                                                 WHERE Event_Configuration_vod__c = :eventConfigId
                                                                     AND (Country_Override_vod__c = NULL OR (Country_Override_vod__r.Country_vod__c = :countryId AND Country_Override_vod__r.Event_Configuration_vod__c = :eventConfigId))
                                                                     AND RecordTypeId = :speakerQualificationRecordTypeId
                                                                 ORDER BY Qualification_vod__r.Name_vod__c ASC];
                for (EM_Event_Rule_vod__c rule : qualificationRules) {
                   if (rule.Qualification_vod__c != null) {
                       Id qualificationRecordTypeId = rule.Qualification_vod__r.RecordTypeId;
                       if (qualificationRecordTypeId == speakerServiceRecordTypeId) {
                           services.addFilter(new SpeakerFilter(rule));
                       } else if (qualificationRecordTypeId == generalTopicRecordTypeId) {
                           training.addFilter(new SpeakerFilter(rule));
                       }
                   } else if (event.Topic_vod__c != null && eventTopicRecordTypeId == event.Topic_vod__r.RecordTypeId) {
                       training.addFilter(new SpeakerFilter(rule.Id, event.Topic_vod__r.Name_vod__c, rule.Filter_Type_vod__c));
                   }
                }
                if (!services.options.isEmpty()) {
                    filters.add(services);
                }
                if (!training.options.isEmpty()) {
                    filters.add(training);
                }
            }
        }
        return filters;
    }

    private class SpeakerFilterGroup {
        @AuraEnabled
        public String label {get;set;}
        @AuraEnabled
        public List<SpeakerFilter> options {get;set;}

        public SpeakerFilterGroup(String label) {
            this.label = label;
            this.options = new List<SpeakerFilter>();
        }

        public void addFilter(SpeakerFilter filter) {
            options.add(filter);
        }
    }

    private class SpeakerFilter {
        @AuraEnabled
        public String value {get;set;}
        @AuraEnabled
        public String label {get;set;}
        @AuraEnabled
        public String filterType {get;set;}

        public SpeakerFilter(EM_Event_Rule_vod__c rule) {
            this.value = rule.Id;
            this.label = rule.Qualification_vod__r.Name_vod__c;
            this.filterType = rule.Filter_Type_vod__c;
        }

        public SpeakerFilter(String value, String label, String filterType) {
            this.value = value;
            this.label = label;
            this.filterType = filterType;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<SpeakerField> getSpeakerFields(String eventConfigId, String countryId) {
        Map<String, Schema.SObjectField> eventRuleFieldMap = EM_Event_Rule_vod__c.sObjectType.getDescribe()?.fields.getMap();
        EM_Event_Rule_vod__c speakerFieldRule;
        if (hasFlsToAll(eventRuleFieldMap, new List<String>{'Speaker_Fields_vod__c', 'Country_Override_vod__c'})) {
            List<EM_Event_Rule_vod__c> speakerFieldsRules = [
                SELECT Speaker_Fields_vod__c, Country_Override_vod__c
                FROM EM_Event_Rule_vod__c
                WHERE RecordType.DeveloperName = 'Speaker_Fields_vod'
                AND Event_Configuration_vod__c = :eventConfigId
                AND (Country_Override_vod__c = NULL OR (Country_Override_vod__r.Country_vod__c = :countryId AND Country_Override_vod__r.Event_Configuration_vod__c = :eventConfigId))
            ];

            if (speakerFieldsRules.size() > 1) {
                for (EM_Event_Rule_vod__c rule : speakerFieldsRules) {
                    if (rule.Country_Override_vod__c != null) {
                        speakerFieldRule = rule;
                        break;
                    }
                }
            } else if (speakerFieldsRules.size() == 1) {
                speakerFieldRule = speakerFieldsRules.get(0);
            }
        }

        List<SpeakerField> speakerFields = new List<SpeakerField>();
        Set<String> seen = new Set<String>();
        Schema.DescribeSObjectResult emSpeakerDescribe = EM_Speaker_vod__c.sObjectType.getDescribe();
        if (speakerFieldRule != null && String.isNotBlank(speakerFieldRule.Speaker_Fields_vod__c) && emSpeakerDescribe != null) {
            Map<String, Schema.SObjectField> emSpeakerDescribeFields = emSpeakerDescribe.fields.getMap();
            for (String speakerField : speakerFieldRule.Speaker_Fields_vod__c.split(';;')) {
                if (String.isNotBlank(speakerField)) {
                    String field = speakerField.trim();
                    if (SPEAKER_FIELD_KEYWORDS.contains(field) && !seen.contains(field)) {
                        seen.add(field);
                        speakerFields.add(new SpeakerField(field));
                    } else {
                        if (!RECORD_TYPE_ID.equals(field) && !field.endsWith('__c')) {
                            field += '__c';
                        }
                        if (!seen.contains(field) && hasFls(emSpeakerDescribeFields, field)) {
                            seen.add(field);
                            speakerFields.add(new SpeakerField(emSpeakerDescribeFields.get(field).getDescribe()));
                        }
                    }
                }
            }
        }
        return speakerFields;
    }

    private class SpeakerField {
        @AuraEnabled
        public String apiName {get;set;}
        @AuraEnabled
        public String label {get;set;}
        @AuraEnabled
        public boolean isKeyword {get;set;}

        public SpeakerField(String field) {
            this.apiName = field;
            this.isKeyword = true;
        }

        public SpeakerField(Schema.DescribeFieldResult describe) {
            this.apiName = describe.getName();
            this.label = describe.getLabel();
        }
    }

    static Boolean hasFlsToAll(Map<String, Schema.SObjectField> fieldsMap, List<String> fields) {
        for (String field : fields) {
            if (!hasFls(fieldsMap, field)) {
                return false;
            }
        }
        return true;
    }

    static Boolean hasFls(Map<String, Schema.SObjectField> fieldsMap, String fieldName) {
        Schema.DescribeFieldResult fieldDescribe = fieldsMap?.get(fieldName)?.getDescribe();
        return fieldDescribe != null && fieldDescribe.isAccessible();
    }
}