public inherited sharing virtual class VeevaMySetupService {
    private VeevaBaseObject productBaseObject;
    private VeevaBaseObject mySetupProductsBaseObject;

    public VeevaMySetupService() {
        this.productBaseObject = VeevaBaseObject.create(Product_vod__c.getSObjectType());
        this.mySetupProductsBaseObject = VeevaBaseObject.create(My_Setup_Products_vod__c.getSObjectType());
    }

    public Map<String, List<Product_vod__c>> getMySetupProductsByProductType(Set<String> additionalQueryFields, Id ownerId) {
        if (!doesUserHaveAccessToProductType()) {
            return new Map<String, List<Product_vod__c>>();
        }
        
        additionalQueryFields.add('Product_Type_vod__c');
        List<Product_vod__c> mySetupProducts = getMySetupProducts(additionalQueryFields, ownerId);

        Map<String, List<Product_vod__c>> mySetupProductsByProductType = new Map<String, List<Product_vod__c>>();
        for (Product_vod__c mySetupProduct : mySetupProducts) {
            String productType = mySetupProduct.Product_Type_vod__c;
            if (productType != null) {
                List<Product_vod__c> productsForProductType = mySetupProductsByProductType.get(productType);
                if (productsForProductType == null) {
                    productsForProductType = new List<Product_vod__c>();
                    mySetupProductsByProductType.put(productType, productsForProductType);
                }
                productsForProductType.add(mySetupProduct);
            }
        }
        return mySetupProductsByProductType;
    }

    public List<Product_vod__c> getMySetupProducts(Set<String> additionalQueryFields, Id ownerId) {
        if (!doesUserHaveAccessToQueryMySetupProducts()) {
            return new List<Product_vod__c>();
        }

        Set<String> accessibleProductFields = getAccessibleProductFields(additionalQueryFields); 
        accessibleProductFields.add('Id');
        accessibleProductFields.add('Name');
        String productFieldsToQuery = String.join(new List<String>(accessibleProductFields), ',');
        return Database.query(
            String.format(
                'SELECT {0} FROM Product_vod__c WHERE Id IN (SELECT Product_vod__c FROM My_Setup_Products_vod__c WHERE OwnerId = :ownerId)',
                new List<String>{productFieldsToQuery}
        ));
    }

    protected virtual Set<String> getAccessibleProductFields(Set<String> fields) {
        return productBaseObject.getAccessibleFields(fields);
    }

    protected virtual boolean doesUserHaveAccessToQueryMySetupProducts() {
        return productBaseObject != null && productBaseObject.getDescribe().isQueryable()
            && mySetupProductsBaseObject != null && mySetupProductsBaseObject.getDescribe().isQueryable();
    }

    protected virtual boolean doesUserHaveAccessToProductType() {
        return productBaseObject != null && productBaseObject.getAccessibleField('Product_Type_vod__c', false, false) != null;
    }
}