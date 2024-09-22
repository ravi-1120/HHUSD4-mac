global class SamplesHelper{
 //10/15/2012 bjd Added to support Sample Send logic.
 //               Users may update an address offline then record a call with a sample send.
 //               In this situation we need to update the address immediately with the send address from the call.
 //               The standard address changed logic which sets the Address Send status to Unknown should be bypassed.
            private static Boolean avoidUnknownAddressStatusUpdate = false;
 
            global static void setAvoidUnknownAddressStatusUpdate(Boolean shouldAvoid){
                        avoidUnknownAddressStatusUpdate = shouldAvoid;
          }
 
            global static boolean shouldAvoidUnknownAddressStatusUpdate (){
                        return avoidUnknownAddressStatusUpdate;
          }
 
}