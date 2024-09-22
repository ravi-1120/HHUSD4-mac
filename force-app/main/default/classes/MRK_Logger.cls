global class MRK_Logger {

		public static boolean loggingEnabled = false;

		static final String REMOTE_LOG_SERVICE_ENDPOINT = 'https://vhub.herokuapp.com/services/development/v1.0/logger';


    private static List<Map<String,String>> messages = new List<Map<String,String>>();

    global static void error(String msg) {
        log('error', msg);
    }

    global static void warn(String msg) {
        log('warn', msg);
    }

    global static void info(String msg) {
        log('info', msg);
    }

    
    global static void debug(String msg) {
        log('debug', msg);
    }

    global static void fine(String msg) {
        log('fine', msg);
    }

    global static void finer(String msg) {
        log('finer', msg);
    }
    
    global static void finest(String msg) {
        log('finest', msg);
    }
    
    private static void log(String level, String msg) {

    	if (loggingEnabled == false) {
    		return;
    	}

      // log to standard logging facilities also
      System.debug(msg);
      
      Map<String,String> m = new Map<String,String>();
      m.put('timestamp', DateTime.now().formatLong()); // user-friendly timestamp
      m.put('time', DateTime.now().getTime() + ''); //  milliseconds since January 1, 1970, 00:00:00 GMT 
      m.put('username', UserInfo.getUserName());
      m.put('seq', messages.size() + '');
      m.put('level', level);
      m.put('body', msg);
      messages.add(m);
    }

    @future (callout=true)
		private static void remoteLog() {
			String url = REMOTE_LOG_SERVICE_ENDPOINT;
			Http http = new Http();
			HttpRequest req = new HttpRequest();
			HttpResponse res = null;

			// request vf pdf page
			req.setMethod('POST');
			req.setEndpoint(url);
			req.setBody(JSON.serialize(messages));
			res = http.send(req);
		}
    
    // TODO: figure out how to get rid of having to call this. deallocator / deconstructor?, execution context end event?
    global static void flush() {
        try {
            Log_MRK__c l = new Log_MRK__c(Body_MRK__c=JSON.serialize(messages));
            insert l;
            messages.clear();
        } catch (Exception e) {
            // mute any logging errors
        }
    }
    
}