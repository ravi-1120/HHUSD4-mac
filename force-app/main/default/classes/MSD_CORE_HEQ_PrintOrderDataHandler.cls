/**
* 	Class		:	MSD_CORE_HEQ_PrintOrderDataHandler.cls
*	Author		:	Ambadas Joshi (joshi.ambadas@merck.com)
* 	Purpose 	:	Request and response handler for the Print order integration
* 	Date Creaed	:	05-Oct-2024
* 
**/

public class MSD_CORE_HEQ_PrintOrderDataHandler {
	public class PrintOrderRequest{
		public String customerOrderNumber;
        public String attribute1;
        public PrintOrderItemRequest[] allItems;
        public String serviceType;
        public String customerNumber;
        public String wmsWarehouseId;
		public String billToAddress1;
        public String billToCity;
        public String billToCountry;
        public String billToEmailAddress;
        public String billToFirstName;
        public String billToLastName;
        public String billToZipCode;
        public String billToState;  
        public PrintOrderItemRequest[] orderItems;        
        public String shipToAddress1;
        public String shipToCity;
        public String shipToCountry;
        public String shipToEmailAddress;
        public String shipToFirstName;
        public String shipToHomePhone;
        public String shipToLastName;
        public String shipToPhone;
        public String shipToZipCode;
        public String shipToState;
    }
    
    public class PrintOrderItemRequest {
        public Integer itemQty;	
        public String itemId;	
        public String printFilename;	
        public String printFileContent;	
    }

	public class PrintOrderResponse{
		String status;
		String orderPlacementId;
		String customerOrderNumber;
		String orderNumber;
		String errorMessage;
	}

public class RetrieveOrderDetails{
	public String status;	//success
	public RetrieveOrderDetailsResponse responseBody;
	public String errorMessage;
}
	class RetrieveOrderDetailsResponse {
		public Integer orderEntryId;
		public String customerOrderNumber;
		public String orderNumber;
		public String currentOrderStatus;
		public String orderType;
		public String orderedDate;
		public String createdOn;
		public Integer createdBy;
		public Integer updatedBy;
		public String updatedOn;
		public OrderAdditionalInfo additionalInfo;
		public allItems[] allItems;
		public String wmsWarehouseId;
		public String serviceType;
		public String billToFirstName;
		public String billToLastName;
		public String billToAddress1;
		public String billToAddress2;
		public String billToCity;
		public String billToState;
		public String billToCountry;
		public String billToZipCode;
		public String billToCompanyName;
		public String billToEmailAddress;
		public String shipToFirstName;
		public String shipToLastName;
		public String shipToAddress1;
		public String shipToAddress2;
		public String shipToCity;
		public String shipToState;
		public String shipToCountry;
		public String shipToZipCode;
		public String shipToCompanyName;
		public String shipToEmailAddress;
		public String shipToPhone;
		public String shippedDate;
		public shipmentList[] shipmentList;
	}
	class OrderAdditionalInfo {
		public Integer orderAddlInfoId;
		public Integer createdBy;
		public String createdOn;
		public String updatedBy;
		public String updatedOn;
		public String shippingAmount;
		public String discountAmount;
		public String participantId;
		public String paymentDetail;
		public String coupon;
		public String couponCode;
		public String salesPrice;
		public String salesTax;
		public String salesTotal;
		public String shipping;
		public String subTotal;
		public String total;
		public String orderPlacedDate;
		public String orderReleasedDate;
	}

	class allItems {
		public Integer orderEntryLineId;
		public Integer itemId;
		public String itemNumber;
		public Integer itemQty;	
		public String lineNumber;
		public Integer warehouseId;
		public Integer warehouseNumber;
		public String warehouseName;
		public String wmsWarehouseId;
	}
	class shipmentList {
		public String cartonId;
		public String trackNo;
		public String carrierCode;
		public String serviceLevel;	
		public Integer shipWgt;	
		public Integer grossWgt;
		public String totalCharge;
		public String packageType;
		public String packDate;
		public String meterNum;
		public orderLines[] lines;
	}

	class orderLines {
		public String itemNumber;
		public Integer shippedQuantity;
		public String lotNumber;
		public String shippedUOM;
	}
    
	/*public static fromJSON parse(String json){
		return (fromJSON) System.JSON.deserialize(json, fromJSON.class);
	}*/

	}