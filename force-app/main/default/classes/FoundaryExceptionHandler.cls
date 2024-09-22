Public Interface FoundaryExceptionHandler {

    void logException(Exception ex);
    void logException(Exception ex, String className, String methodName);

    void futureLogException(String exstr, String className, String methodName, String feature); 
}