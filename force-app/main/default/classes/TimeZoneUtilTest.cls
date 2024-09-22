@isTest
private class TimeZoneUtilTest {

    /*@isTest
    static void testConfigureTimeSlots() {
        Map<String, Object> result = TimeZoneUtil.configureTimeSlots('16:00', '20:00');
        System.assertEquals(result.get('configSlotHours'), '00');
        System.assertEquals(result.get('configSlotMinutes'), '15');
        System.assertEquals(result.get('configSlotPreparation'), '00');
        List<Object> timeArr = (List<Object>)result.get('timeArr');
        System.assertNotEquals(timeArr.isEmpty(), true);
        Map<String, Object> timeArrObj = (Map<String, Object>)timeArr.get(0);
        System.assertEquals(timeArrObj.get('startTime'), '16:00');
        System.assertEquals(timeArrObj.get('endTime'), '20:00');
    } */

    @isTest
    static void testGetTimeSlots() {
        List<Object> timeSlotsObjLst = new List<Object> {
            new Map<String, Object> {
                'value' => '16:00',
                'timeSlotAvialable' => null
            },
            new Map<String, Object> {
                'value' => '16:15',
                'timeSlotAvialable' => null
            }
        };
            
        Map<String,Object> schMap = TestDataFactory_MODTest.schedulerSaveResponseTest();
        List<Object> result = TimeZoneUtil.getTimeSlots('OREG',String.valueOf(Date.Today()), timeSlotsObjLst);
        System.assertNotEquals(result.isEmpty(), true);
        Map<String, Object> firstResult = (Map<String, Object>)result.get(0);
        Map<String, Object> secondResult = (Map<String, Object>)result.get(1);
        System.assertEquals(firstResult.get('value'), '16:00');
        //System.assertEquals(firstResult.get('timeSlotAvialable'), true);
        System.assertEquals(secondResult.get('value'), '16:15');
        //System.assertEquals(secondResult.get('timeSlotAvialable'), true);
    }

    @isTest
    static void testGenerateTimeSlots() {
        Map<String, Object> scheduleDetails = new Map<String, Object> {
            'timeZone' => 'UTC',
            'year' => 2023,
            'month' => 2,
            'date' => 10,
            'startHours' => 16,
            'startMinutes' => 0,
            'startSeconds' => 0,
            'endHours' => 20,
            'endMinutes' => 0,
            'endSeconds' => 0
        };
        List<Object> result = TimeZoneUtil.generateTimeSlots(scheduleDetails);
        //System.assertNotEquals(result.isEmpty(), true);
    }
    
   /* static testMethod void testDateTimeConversion(){
		TimeZoneUtil.DateTimeConversion(2022,4,1,8,0,0);
	}
	
	static testMethod void testConvertGMTtoTargetTimeZone(){
		TimeZoneUtil.convertGMTtoTargetTimeZone(2022,4,1,8,0,0);
	}
    
    static testMethod void testGetDateTimeGmt(){
		Datetime test = TimeZoneUtil.getDateTimeGmt('UTC', Date.newInstance(2020,12,1), Time.newInstance(12,15,30,0));
		System.assertEquals(test.hourGmt(), 12);
		System.assertEquals(test.minuteGmt(), 15);
		System.assertEquals(test.secondGmt(), 30);
	} */
    



}