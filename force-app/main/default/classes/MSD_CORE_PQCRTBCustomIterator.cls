public class MSD_CORE_PQCRTBCustomIterator implements Iterator<MSD_CORE_PQCRequest.ServiceCloudSafetyCase>{ 
    
    private List<MSD_CORE_PQCRequest.ServiceCloudSafetyCase> aeCases;
    private Integer currentIndex;
    
    public MSD_CORE_PQCRTBCustomIterator(List<MSD_CORE_PQCRequest.ServiceCloudSafetyCase> aeCases){
        this.aeCases = aeCases;
        this.currentIndex = 0; 
    }
    
    public boolean hasNext(){ 
        if(currentIndex >= aeCases.size()) {
            return false;
        } else {
            return true;
        }
    }    
    
    public MSD_CORE_PQCRequest.ServiceCloudSafetyCase next(){
        if(hasNext()) {
            currentIndex++;
            return aeCases[currentIndex - 1];
        } else {
            throw new NoSuchElementException();
            //return aeCases[currentIndex];
        }
    } 
}