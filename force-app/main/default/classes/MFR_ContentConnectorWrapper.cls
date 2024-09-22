/**
 * Component Name: MFR_ContentConnectorWrapper
 * Created By: Focal CXM
 * @description MFR_ContentConnectorWrapper
 */
public class MFR_ContentConnectorWrapper {
     public String documentNumber; //1010101010101010
     public String documentId;
     public String version;
     public String globalVersionId;
     public String globalId;
     public String expirationDate;
     public String documentStatus;
     public String HCEIStatus;
     public DocumentVersionViewableRenditions[] documentVersionViewableRenditions;
    class DocumentVersionViewableRenditions {
        public String bucket;  
        public String key;     
    }
    public List<String> audience;
    public List<String> methodOfDelivery;
    public List<String> deliveryPlatform;
    public List<String> productId;
    public List<String> productFamilyId;
    public String name;
    public string resourceTitle;
    public Cls_owner owner; 
    /**
     * @description owner
     */
    public class Cls_owner {
    /**
     * @description 
     * @param json
     * @return (MFR_ContentConnectorWrapper) System.JSON.deserialize(json, MFR_ContentConnectorWrapper.class)
    */
        public List<String> users;
    }
    public static MFR_ContentConnectorWrapper parse(String json){

        return (MFR_ContentConnectorWrapper) System.JSON.deserialize(json, MFR_ContentConnectorWrapper.class);
    }

}