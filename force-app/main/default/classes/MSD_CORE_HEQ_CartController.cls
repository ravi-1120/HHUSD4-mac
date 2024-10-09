/**
* @File Name : MSD_CORE_HEQ_CartController.cls
* @Description : This class handles cart functionality, including adding resources to the cart and displaying cart data in the UI.
* @Author : Gopi Chintamaneni
* @Last Modified By :
* @Last Modified On : October 1, 2024
**/

public class MSD_CORE_HEQ_CartController {

	@AuraEnabled
	public static String addOrUpdateCartRecords(List<Id> customerIds, List<Id> resourceIds, Boolean selfPrint) {
		try {
			if (resourceIds.isEmpty()) {
				throw new AuraHandledException('Resource IDs must be provided.');
			}

			Id ownerId = UserInfo.getUserId();

			// Fetch the AccountIds for the provided customerIds
			Map<Id, Id> customerAccountMap = new Map<Id, Id>();
			if (customerIds != null && !customerIds.isEmpty()) {
				List<User> customerRecords = [
					SELECT Id, AccountId 
					FROM User 
					WHERE Id IN :customerIds
				];
				for (User customer : customerRecords) {
					customerAccountMap.put(customer.Id, customer.AccountId);
				}
			}

			// Fetch existing cart records
			List<MSD_CORE_HEQ_Cart__c> existingCartRecords = [
				SELECT Id, MSD_CORE_Cart_Owner__c, MSD_CORE_Customer__c, MSD_CORE_Resource_Id__c, MSD_CORE_Quantity__c 
				FROM MSD_CORE_HEQ_Cart__c 
				WHERE MSD_CORE_Cart_Owner__c = :ownerId
				AND (MSD_CORE_Customer__c IN :customerIds OR MSD_CORE_Customer__c = null)
				AND MSD_CORE_Resource_Id__c IN :resourceIds
			];

			Map<String, MSD_CORE_HEQ_Cart__c> existingCartMap = new Map<String, MSD_CORE_HEQ_Cart__c>();
			for (MSD_CORE_HEQ_Cart__c cart : existingCartRecords) {
				String key = cart.MSD_CORE_Cart_Owner__c + '-' + String.valueOf(cart.MSD_CORE_Customer__c) + '-' + cart.MSD_CORE_Resource_Id__c;
				existingCartMap.put(key, cart);
			}

			List<MSD_CORE_HEQ_Cart__c> cartRecordsToUpsert = new List<MSD_CORE_HEQ_Cart__c>();

			if (customerIds != null && !customerIds.isEmpty()) {
				for (Id customerId : customerIds) {
					Id accountId = customerAccountMap.get(customerId);
					
					// Fetch primary or first available address for each customer based on AccountId
					List<MSD_CORE_HEQ_Address__c> addresses = [
						SELECT Id 
						FROM MSD_CORE_HEQ_Address__c 
						WHERE MSD_CORE_HEQ_Account__c = :accountId
						AND MSD_CORE_IsActive__c = true
						ORDER BY CreatedDate ASC 
						LIMIT 1
					];
					
					Id selectedAddressId = (addresses.isEmpty()) ? null : addresses[0].Id;

					for (Id resourceId : resourceIds) {
						String key = ownerId + '-' + customerId + '-' + resourceId;
						MSD_CORE_HEQ_Cart__c existingCart = existingCartMap.get(key);

						if (existingCart != null) {
							existingCart.MSD_CORE_Quantity__c += 1;
							cartRecordsToUpsert.add(existingCart);
						} else {
							MSD_CORE_HEQ_Cart__c newCartRecord = new MSD_CORE_HEQ_Cart__c(
								MSD_CORE_Cart_Owner__c = ownerId,
								MSD_CORE_Customer__c = customerId,
								MSD_CORE_Resource_Id__c = resourceId,
								MSD_CORE_Quantity__c = 1,
								MSD_CORE_Address__c = selectedAddressId
							);
							cartRecordsToUpsert.add(newCartRecord);
						}
					}
				}
			}

			// Handle selfPrint scenario
			if (selfPrint) {
				for (Id resourceId : resourceIds) {
					String key = ownerId + '-' + 'null' + '-' + resourceId;
					MSD_CORE_HEQ_Cart__c existingSelfPrintCart = existingCartMap.get(key);

					List<MSD_CORE_HEQ_Address__c> aeAddresses = [
						SELECT Id 
						FROM MSD_CORE_HEQ_Address__c 
						WHERE MSD_CORE_HEQ_User__c = :UserInfo.getUserId()
						AND MSD_CORE_IsActive__c = true
						ORDER BY CreatedDate ASC 
						LIMIT 1
					];
					
					Id selectedAEAddressId = (aeAddresses.isEmpty()) ? null : aeAddresses[0].Id;

					if (existingSelfPrintCart != null) {
						existingSelfPrintCart.MSD_CORE_Quantity__c += 1;
						cartRecordsToUpsert.add(existingSelfPrintCart);
					} else {
						MSD_CORE_HEQ_Cart__c selfPrintCartRecord = new MSD_CORE_HEQ_Cart__c(
							MSD_CORE_Cart_Owner__c = ownerId,
							MSD_CORE_Customer__c = null,
							MSD_CORE_Resource_Id__c = resourceId,
							MSD_CORE_Quantity__c = 1,
							MSD_CORE_Address__c = selectedAEAddressId
						);
						cartRecordsToUpsert.add(selfPrintCartRecord);
					}
				}
			}

			if (!cartRecordsToUpsert.isEmpty()) {
				upsert cartRecordsToUpsert;
			}

		} catch (Exception e) {
			throw new AuraHandledException('Error updating cart records: ' + e.getMessage());
		}

		return 'Success';
	}

	@AuraEnabled
	public static List<CartWrapper> getCartRecords() {
		List<CartWrapper> cartData = new List<CartWrapper>();

		try {
			List<MSD_CORE_HEQ_Cart__c> cartRecords = [
				SELECT Id, MSD_CORE_Customer__c, MSD_CORE_Resource_Id__c, MSD_CORE_Quantity__c,
					MSD_CORE_Cart_Owner__c,
					MSD_CORE_Address__c,
					MSD_CORE_Cart_Owner__r.Name,
					MSD_CORE_Cart_Owner__r.Email
				FROM MSD_CORE_HEQ_Cart__c
				WHERE MSD_CORE_Cart_Owner__c = :UserInfo.getUserId()
			];

			if (cartRecords.isEmpty()) {
				return cartData;
			}

			Set<Id> resourceIds = new Set<Id>();
			Set<Id> customerIds = new Set<Id>();
			Set<Id> addressIds = new Set<Id>();

			for (MSD_CORE_HEQ_Cart__c cart : cartRecords) {
				resourceIds.add(cart.MSD_CORE_Resource_Id__c);
				if (cart.MSD_CORE_Customer__c != null) {
					customerIds.add(cart.MSD_CORE_Customer__c);
				}
				if (cart.MSD_CORE_Address__c != null) {
					addressIds.add(cart.MSD_CORE_Address__c);
				}
			}

			Map<Id, ContentVersion> resourceMap = new Map<Id, ContentVersion>([
				SELECT Id, Title, MSD_CORE_Resource_Code__c FROM ContentVersion WHERE Id IN :resourceIds
			]);

			Map<Id, User> customerMap = new Map<Id, User>([
				SELECT Id, FirstName, LastName, AccountId, Email FROM User WHERE Id IN :customerIds
			]);

			// Fetch addresses for customers
			Map<Id, MSD_CORE_HEQ_Address__c> addressMap = new Map<Id, MSD_CORE_HEQ_Address__c>([
				SELECT Id, MSD_CORE_HEQ_Address_1__c, MSD_CORE_HEQ_Address_2__c, MSD_CORE_HEQ_Address_3__c,
					MSD_CORE_HEQ_City__c, MSD_CORE_HEQ_Country__c,
					MSD_CORE_HEQ_State__c, MSD_CORE_HEQ_Zip_Code__c
				FROM MSD_CORE_HEQ_Address__c
				WHERE Id IN :addressIds
				ORDER BY CreatedDate ASC
			]);

			// Fetch current user's address for self-print
			Id ownerId = UserInfo.getUserId();
			
			User owner = [SELECT Id, Name, FirstName, LastName, Email FROM User WHERE Id = :ownerId LIMIT 1];
			Map<Id, CartWrapper> cartMap = new Map<Id, CartWrapper>();

			for (MSD_CORE_HEQ_Cart__c cart : cartRecords) {
				User customer = customerMap.get(cart.MSD_CORE_Customer__c);
				ContentVersion resource = resourceMap.get(cart.MSD_CORE_Resource_Id__c);
				MSD_CORE_HEQ_Address__c address = null;

				Boolean isSelfPrint = (cart.MSD_CORE_Customer__c == null);
				if (isSelfPrint) {
					address = addressMap.get(cart.MSD_CORE_Address__c);
				} else {
					address = addressMap.get(cart.MSD_CORE_Address__c);
				}

				String customerAddress = (address != null) 
					? ((address.MSD_CORE_HEQ_Address_1__c != null) ? address.MSD_CORE_HEQ_Address_1__c + ', ' : '') +
					((address.MSD_CORE_HEQ_Address_2__c != null) ? address.MSD_CORE_HEQ_Address_2__c + ', ' : '') +
					((address.MSD_CORE_HEQ_City__c != null) ? address.MSD_CORE_HEQ_City__c + ', ' : '') +
					((address.MSD_CORE_HEQ_State__c != null) ? address.MSD_CORE_HEQ_State__c + ', ' : '') +
					((address.MSD_CORE_HEQ_Zip_Code__c != null) ? address.MSD_CORE_HEQ_Zip_Code__c + ', ' : '') +
					((address.MSD_CORE_HEQ_Country__c != null) ? address.MSD_CORE_HEQ_Country__c : '')
					: '';

				String displayName = (customer != null) ? customer.FirstName + ' ' + customer.LastName : owner.FirstName + ' ' + owner.LastName;
				String displayEmail = (customer != null) ? customer.Email : owner.Email;

				CartWrapper cartWrapper;
				Id key = (cart.MSD_CORE_Customer__c != null) ? cart.MSD_CORE_Customer__c : ownerId; // Use ownerId for self-print

				if (!cartMap.containsKey(key)) {
					cartWrapper = new CartWrapper(displayName, displayEmail, key, isSelfPrint, customerAddress, (customer != null) ? customer.AccountId : null);
					cartMap.put(key, cartWrapper);
				} else {
					cartWrapper = cartMap.get(key);
				}


				ResourceDetail resourceDetail = new ResourceDetail(resource.Title, resource.MSD_CORE_Resource_Code__c, resource.Id, cart.Id, cart.MSD_CORE_Quantity__c);
				cartWrapper.resources.add(resourceDetail);
			}

			cartData.addAll(cartMap.values());

		} catch (Exception e) {
			throw new AuraHandledException('Error in getCartRecords: ' + e.getMessage());
		}

		return cartData;
	}


	@AuraEnabled
	public static void updateCartQuantity(Id recordId, Integer newQuantity) {
		try {
			if (recordId == null || newQuantity < 0) {
				throw new AuraHandledException('Invalid parameters provided.');
			}

			List<MSD_CORE_HEQ_Cart__c> cartRecords = [
				SELECT Id, MSD_CORE_Quantity__c
				FROM MSD_CORE_HEQ_Cart__c
				WHERE Id = :recordId
				AND MSD_CORE_Cart_Owner__c = :UserInfo.getUserId()
				LIMIT 1
			];

			if (cartRecords.isEmpty()) {
				throw new AuraHandledException('No cart record found for the given resource ID.');
			}

			MSD_CORE_HEQ_Cart__c cartRecord = cartRecords[0];
			cartRecord.MSD_CORE_Quantity__c = newQuantity;

			update cartRecord;

		} catch (Exception e) {
			throw new AuraHandledException('An error occurred while updating the resource quantity: ' + e.getMessage());
		}
	}

	@AuraEnabled
	public static String deleteCartItem(Id cartItemId) {

		if (cartItemId == null) {
			throw new AuraHandledException('cartItemId not found.');
		}

		try {
			MSD_CORE_HEQ_Cart__c cartItem = [
				SELECT Id FROM MSD_CORE_HEQ_Cart__c 
				WHERE Id = :cartItemId 
				AND MSD_CORE_Cart_Owner__c = :UserInfo.getUserId() 
				LIMIT 1
			];

			if (cartItem != null) {
				delete cartItem;
			}

		} catch (DmlException e) {
			throw new AuraHandledException('Error deleting cart item: ' + e.getMessage());
		} catch (QueryException e) {
			throw new AuraHandledException('Cart item not found or does not belong to the user.');
		} catch (Exception e) {
			throw new AuraHandledException('Unexpected error: ' + e.getMessage());
		}

		return 'Success';
	}

	// @AuraEnabled
	// public static List<Id> submitPrintOrder() {
	// 	List<Id> orderIds = new List<Id>();
	// 	List<MSD_CORE_HEQ_Order__c> ordersToInsert = new List<MSD_CORE_HEQ_Order__c>();
	// 	List<MSD_CORE_HEQ_Order__c> selfOrdersToInsert = new List<MSD_CORE_HEQ_Order__c>();
	// 	List<MSD_CORE_HEQ_Order_Items__c> orderItemsToInsert = new List<MSD_CORE_HEQ_Order_Items__c>();
	// 	List<MSD_CORE_HEQ_Order_Items__c> selfOrderItemsToInsert = new List<MSD_CORE_HEQ_Order_Items__c>();

	// 	try {
	// 		List<MSD_CORE_HEQ_Cart__c> cartRecords = [
	// 			SELECT Id, MSD_CORE_Customer__c, MSD_CORE_Resource_Id__c, MSD_CORE_Quantity__c,
	// 				MSD_CORE_Cart_Owner__c, MSD_CORE_Address__c
	// 			FROM MSD_CORE_HEQ_Cart__c
	// 			WHERE MSD_CORE_Cart_Owner__c = :UserInfo.getUserId()
	// 		];

	// 		Map<Id, List<MSD_CORE_HEQ_Cart__c>> cartByCustomer = new Map<Id, List<MSD_CORE_HEQ_Cart__c>>();

	// 		for (MSD_CORE_HEQ_Cart__c cart : cartRecords) {
	// 			if (!cartByCustomer.containsKey(cart.MSD_CORE_Customer__c)) {
	// 				cartByCustomer.put(cart.MSD_CORE_Customer__c, new List<MSD_CORE_HEQ_Cart__c>());
	// 			}
	// 			cartByCustomer.get(cart.MSD_CORE_Customer__c).add(cart);
	// 		}

	// 		for (Id customerId : cartByCustomer.keySet()) {
	// 			List<MSD_CORE_HEQ_Cart__c> customerCarts = cartByCustomer.get(customerId);
	// 			MSD_CORE_HEQ_Order__c order = new MSD_CORE_HEQ_Order__c(
	// 				MSD_CORE_Customer__c = customerId,
	// 				MSD_CORE_HEQ_Address__c = customerCarts[0].MSD_CORE_Address__c,
	// 				MSD_CORE_Integration_Status__c = 'Submitted'
	// 			);
	// 			ordersToInsert.add(order);
	// 		}

	// 		insert ordersToInsert;

	// 		for (Integer i = 0; i < ordersToInsert.size(); i++) {
	// 			MSD_CORE_HEQ_Order__c order = ordersToInsert[i];
	// 			List<MSD_CORE_HEQ_Cart__c> customerCarts = cartByCustomer.get(order.MSD_CORE_Customer__c);
	// 			for (MSD_CORE_HEQ_Cart__c cart : customerCarts) {
	// 				MSD_CORE_HEQ_Order_Items__c orderItem = new MSD_CORE_HEQ_Order_Items__c(
	// 					MSD_CORE_Resource_Id__c = cart.MSD_CORE_Resource_Id__c,
	// 					MSD_CORE_Item_Quantity__c = cart.MSD_CORE_Quantity__c,
	// 					MSD_CORE_HEQ_Order__c = order.Id // Now order.Id is correctly referenced
	// 				);
	// 				orderItemsToInsert.add(orderItem);
	// 			}
	// 		}

	// 		insert orderItemsToInsert;

	// 		List<MSD_CORE_HEQ_Cart__c> selfPrintCarts = [
	// 			SELECT Id, MSD_CORE_Resource_Id__c, MSD_CORE_Quantity__c, MSD_CORE_Address__c
	// 			FROM MSD_CORE_HEQ_Cart__c
	// 			WHERE MSD_CORE_Cart_Owner__c = :UserInfo.getUserId() AND MSD_CORE_Customer__c = null
	// 		];

	// 		if (!selfPrintCarts.isEmpty()) {
	// 			MSD_CORE_HEQ_Order__c selfPrintOrder = new MSD_CORE_HEQ_Order__c(
	// 				MSD_CORE_Requestor__c = UserInfo.getUserId(),
	// 				MSD_CORE_HEQ_Address__c = selfPrintCarts[0].MSD_CORE_Address__c,
	// 				MSD_CORE_Integration_Status__c = 'Submitted'
	// 			);

	// 			selfOrdersToInsert.add(selfPrintOrder);
	// 			insert selfOrdersToInsert;

	// 			for (MSD_CORE_HEQ_Cart__c cart : selfPrintCarts) {
	// 				MSD_CORE_HEQ_Order_Items__c orderItem = new MSD_CORE_HEQ_Order_Items__c(
	// 					MSD_CORE_Resource_Id__c = cart.MSD_CORE_Resource_Id__c,
	// 					MSD_CORE_Item_Quantity__c = cart.MSD_CORE_Quantity__c,
	// 					MSD_CORE_HEQ_Order__c = selfPrintOrder.Id
	// 				);
	// 				selfOrderItemsToInsert.add(orderItem);
	// 			}

	// 			insert selfOrderItemsToInsert;
	// 		}
	// 	} catch (Exception e) {
	// 		throw new AuraHandledException('Error in createOrdersFromCart: ' + e.getMessage());
	// 	}

	// 	for (MSD_CORE_HEQ_Order__c order : ordersToInsert) {
	// 		orderIds.add(order.Id);
	// 	}

	// 	for (MSD_CORE_HEQ_Order__c order : selfOrdersToInsert) {
	// 		orderIds.add(order.Id);
	// 	}

	// 	return orderIds;
	// }

	@AuraEnabled
	public static List<Id> submitPrintOrder() {
		List<Id> orderIds = new List<Id>();
		List<MSD_CORE_HEQ_Order__c> ordersToInsert = new List<MSD_CORE_HEQ_Order__c>();
		List<MSD_CORE_HEQ_Order__c> selfOrdersToInsert = new List<MSD_CORE_HEQ_Order__c>();
		List<MSD_CORE_HEQ_Order_Items__c> orderItemsToInsert = new List<MSD_CORE_HEQ_Order_Items__c>();
		
		try {
			// Fetch cart records for the current user
			List<MSD_CORE_HEQ_Cart__c> cartRecords = [
				SELECT Id, MSD_CORE_Customer__c, MSD_CORE_Resource_Id__c, MSD_CORE_Quantity__c,
					MSD_CORE_Cart_Owner__c, MSD_CORE_Address__c
				FROM MSD_CORE_HEQ_Cart__c
				WHERE MSD_CORE_Cart_Owner__c = :UserInfo.getUserId()
			];

			Map<Id, List<MSD_CORE_HEQ_Cart__c>> cartByCustomer = new Map<Id, List<MSD_CORE_HEQ_Cart__c>>();

			// Group cart records by customer
			for (MSD_CORE_HEQ_Cart__c cart : cartRecords) {
				if (cart.MSD_CORE_Customer__c != null) {
					if (!cartByCustomer.containsKey(cart.MSD_CORE_Customer__c)) {
						cartByCustomer.put(cart.MSD_CORE_Customer__c, new List<MSD_CORE_HEQ_Cart__c>());
					}
					cartByCustomer.get(cart.MSD_CORE_Customer__c).add(cart);
				}
			}

			// Create orders for each customer
			for (Id customerId : cartByCustomer.keySet()) {
				List<MSD_CORE_HEQ_Cart__c> customerCarts = cartByCustomer.get(customerId);
				MSD_CORE_HEQ_Order__c order = new MSD_CORE_HEQ_Order__c(
					MSD_CORE_Customer__c = customerId,
					MSD_CORE_HEQ_Address__c = customerCarts[0].MSD_CORE_Address__c,
					MSD_CORE_Integration_Status__c = 'Submitted'
				);
				ordersToInsert.add(order);
			}

			// Insert customer orders
			insert ordersToInsert;

			// Create order items for customer orders
			for (Integer i = 0; i < ordersToInsert.size(); i++) {
				MSD_CORE_HEQ_Order__c order = ordersToInsert[i];
				List<MSD_CORE_HEQ_Cart__c> customerCarts = cartByCustomer.get(order.MSD_CORE_Customer__c);
				for (MSD_CORE_HEQ_Cart__c cart : customerCarts) {
					MSD_CORE_HEQ_Order_Items__c orderItem = new MSD_CORE_HEQ_Order_Items__c(
						MSD_CORE_Resource_Id__c = cart.MSD_CORE_Resource_Id__c,
						MSD_CORE_Item_Quantity__c = cart.MSD_CORE_Quantity__c,
						MSD_CORE_HEQ_Order__c = order.Id // Correctly referencing the order ID
					);
					orderItemsToInsert.add(orderItem);
				}
			}

			// Insert order items for customer orders
			insert orderItemsToInsert;

			// Handle self-print orders
			List<MSD_CORE_HEQ_Cart__c> selfPrintCarts = [
				SELECT Id, MSD_CORE_Resource_Id__c, MSD_CORE_Quantity__c, MSD_CORE_Address__c
				FROM MSD_CORE_HEQ_Cart__c
				WHERE MSD_CORE_Cart_Owner__c = :UserInfo.getUserId() AND MSD_CORE_Customer__c = null
			];

			if (!selfPrintCarts.isEmpty()) {
				MSD_CORE_HEQ_Order__c selfPrintOrder = new MSD_CORE_HEQ_Order__c(
					MSD_CORE_Requestor__c = UserInfo.getUserId(), // Ensure requestor is populated
					MSD_CORE_HEQ_Address__c = selfPrintCarts[0].MSD_CORE_Address__c,
					MSD_CORE_Integration_Status__c = 'Submitted'
				);

				// Add the self-print order to the list
				selfOrdersToInsert.add(selfPrintOrder);
				insert selfOrdersToInsert;

				// Create order items for self-print order
				List<MSD_CORE_HEQ_Order_Items__c> selfOrderItemsToInsert = new List<MSD_CORE_HEQ_Order_Items__c>();
				for (MSD_CORE_HEQ_Cart__c cart : selfPrintCarts) {
					MSD_CORE_HEQ_Order_Items__c orderItem = new MSD_CORE_HEQ_Order_Items__c(
						MSD_CORE_Resource_Id__c = cart.MSD_CORE_Resource_Id__c,
						MSD_CORE_Item_Quantity__c = cart.MSD_CORE_Quantity__c,
						MSD_CORE_HEQ_Order__c = selfPrintOrder.Id
					);
					selfOrderItemsToInsert.add(orderItem);
				}

				// Insert order items for self-print order
				insert selfOrderItemsToInsert;
			}
		} catch (Exception e) {
			throw new AuraHandledException('Error in submitPrintOrder: ' + e.getMessage());
		}

		// Collect all order IDs to return
		for (MSD_CORE_HEQ_Order__c order : ordersToInsert) {
			orderIds.add(order.Id);
		}

		for (MSD_CORE_HEQ_Order__c order : selfOrdersToInsert) {
			orderIds.add(order.Id);
		}

		return orderIds;
	}

	public class CartWrapper {
		@AuraEnabled public String customerName { get; set; }
		@AuraEnabled public String customerEmail { get; set; }
		@AuraEnabled public Id cartId { get; set; }
		@AuraEnabled public Boolean isSelfPrint { get; set; }
		@AuraEnabled public String customerAddress { get; set; }
		@AuraEnabled public Id accountId { get; set; }
		@AuraEnabled public List<ResourceDetail> resources { get; set; }

		public CartWrapper(String customerName, String customerEmail, Id cartId, Boolean isSelfPrint, String customerAddress, Id accountId) {
			this.customerName = customerName;
			this.customerEmail = customerEmail;
			this.cartId = cartId;
			this.isSelfPrint = isSelfPrint;
			this.customerAddress = customerAddress;
			this.accountId = accountId;
			this.resources = new List<ResourceDetail>();
		}
	}

	public class ResourceDetail {
		@AuraEnabled public String resourceName { get; set; }
		@AuraEnabled public String resourceCode { get; set; }
		@AuraEnabled public Id resourceId { get; set; }
		@AuraEnabled public Id cartId { get; set; }
		@AuraEnabled public Decimal quantity { get; set; }

		public ResourceDetail(String resourceName, String resourceCode, Id resourceId, Id cartId, Decimal quantity) {
			this.resourceName = resourceName;
			this.resourceCode = resourceCode;
			this.resourceId = resourceId;
			this.cartId = cartId;
			this.quantity = quantity;
		}
	}

}