/*
KRB 9/2/2020 - Assessments - calculates the Temp Range String on the Temp Excursion Product Record. 

Testing in isolation:

*/


global with sharing class MSD_CORE_CalcNewTEPCaseNotes {
    
    @InvocableMethod
    public static List<Results> calculateNewTEPCaseNote(List<Requests> requests){

       List <String> currentExcursionsList = new List <String>();
        
       currentExcursionsList = requests[0].currentExposureListOverflow;
        
       Results curResults = new Results();
       curResults.newCaseNotesText = '';

       if(currentExcursionsList.isEmpty()){
           List<Results> resultsList = new List<results>();
           resultsList.add(curResults);
           return resultsList;
        }
       
        curResults.newCaseNotesText = 'Overflow of Current Excursions from Temperature Excursion Product Record - ' + requests[0].caseNumber + ':';
           
        for(String excursionText : currentExcursionsList){
           curResults.newCaseNotesText = curResults.newCaseNotesText + '' + excursionText + '  '; 
        }
         
        List<Results> resultsList = new List<results>();
        resultsList.add(curResults);
        return resultsList;

    }
    
    global class Requests{
        @InvocableVariable
        global List <String> currentExposureListOverflow;
        @InvocableVariable
        global String caseNumber;
    }
    
    global class Results{
        
        @InvocableVariable
        global String newCaseNotesText = '';

    }
    

}