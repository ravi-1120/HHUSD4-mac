public class MSD_CORE_Process_Edited_Goals_Helper {

   //Kevin Brace Release 8.0 7/13/2016 
    
   private static boolean run = true;
   
   public static boolean runOnce(){
      if(run){
        run=false;
        return true;
      }else{
        return run;
      }
   }
    
    
}