public class MSD_CORE_AERTBCustomIterator implements Iterator<MSD_CORE_AERequest.ServiceCloudSafetyCase>{ 
    
    private List<MSD_CORE_AERequest.ServiceCloudSafetyCase> aeCases;
    private Integer currentIndex;
    
    public MSD_CORE_AERTBCustomIterator(List<MSD_CORE_AERequest.ServiceCloudSafetyCase> aeCases){
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
    
    public MSD_CORE_AERequest.ServiceCloudSafetyCase next(){
        if(hasNext()) {
            currentIndex++;
            return aeCases[currentIndex - 1];
        } else {
            throw new NoSuchElementException();
            //return aeCases[currentIndex];
        }
    } 
}