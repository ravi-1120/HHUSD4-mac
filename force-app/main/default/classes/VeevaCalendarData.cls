public abstract class VeevaCalendarData {
    private Set<String> queryFields;
    private String ownerId;
    private String objectType;

    public List<String> fields;
    public Date startDate;
    public Date endDate;
    public Datetime startDateTime;
    public Datetime endDateTime;

    public VeevaCalendarData(Set<String> queryFields, String ownerId, String objectType, Datetime startDateTime, Datetime endDateTime) {
        this.queryFields = queryFields;
        this.ownerId = ownerId;
        this.objectType = objectType;

        this.fields = new List<String>();
        this.startDateTime = startDateTime;
        this.endDateTime = endDateTime;
        this.startDate = date.newInstance(startDateTime.yearGmt(), startDateTime.monthGmt(), startDateTime.dayGmt());
        this.endDate = date.newInstance(endDateTime.yearGmt(), endDateTime.monthGmt(), endDateTime.dayGmt());
    }

    public void adjustStartDate(Integer daysToAdd) {
        this.startDate = this.startDate.addDays(daysToAdd);
    }

    public String getCalendarOwnerId() {
        if (this.ownerId == null) {
            return '';
        }
        return this.ownerId;
    }

    public String getObjectType() {
        if (this.objectType == null) {
            return '';
        }
        return this.objectType;
    }

    public Set<String> getQueryFields() {
        if (this.queryFields == null) {
            return new Set<String>();
        }
        return this.queryFields;
    }

    public Boolean isFieldAccessible(String fieldName) {
        return this.fields.contains(fieldName);
    }

    public static List<String> filterFields(Map<String, SObjectField> descr, Set<String> names) {
		List<String> fields = new List<String>();
		for (String name : names) {
            String parsedName = name.removeStartIgnoreCase('toLabel(').substringBefore(')');
			SObjectField field = descr.get(parsedName.contains('__r') ? parsedName.substringBefore('__r') + '__c' : parsedName);
			if (name.containsIgnoreCase('RecordType') || (field != null && field.getDescribe().isAccessible()) || (name.containsIgnoreCase('Owner'))) {
				fields.add(name);
			}
		}
		return fields;
	}

    public virtual List<VeevaCalendarEvent> getEventsForRecordIds(List<Id> recordIds) {
        String queryStmt = 'Select ' + String.join(this.fields, ',') + ' from ' + this.objectType + ' where Id IN :recordIds';
        return this.convertToEvents(new List<SObject>{Database.query(queryStmt)});
    }

    public List<VeevaCalendarEvent> getEvents() {
        return this.convertToEvents(this.fetchData());
    }

    @TestVisible
    protected abstract List<SObject> fetchData();
    
    @TestVisible
    protected abstract List<VeevaCalendarEvent> convertToEvents(List<SObject> objectList);
}