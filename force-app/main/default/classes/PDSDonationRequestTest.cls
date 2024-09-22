@IsTest
public class PDSDonationRequestTest {
    @IsTest
    static void testPDSDonationRequest() {
        PDSDonationRequest donationRequest = new PDSDonationRequest();
        
        donationRequest.donationReqId = 'DR001';
        donationRequest.recordTypeName = 'Standard Donation';
        donationRequest.destinationValue = 'USA';
        donationRequest.taxValue = 'Exempt';
        donationRequest.indicationValue = 'Research';
        donationRequest.applicationNumber = 'APP12345';
        donationRequest.doneeId = 'D001';
        donationRequest.donationType = 'Medical Supplies';
        donationRequest.applicantName = 'John Doe';
        donationRequest.applicantIns = 'XYZ Institute';
        donationRequest.approvalDate = '2024-06-10';
        donationRequest.fwdAgent = 'Forwarding Agent';
        donationRequest.addInfoValue = 'Additional Info';
        donationRequest.consignee = 'Consignee Name';
        donationRequest.finalRecipient = 'Final Recipient';
        donationRequest.shipNotify = 'Notification';
        donationRequest.requestSubmitDate = '2024-06-01';
        donationRequest.requestStatus = 'Pending';
        donationRequest.shippingStatus = 'Not Shipped';
        donationRequest.approver = 'Approver Name';
        donationRequest.reviewer = 'Reviewer Name';
        donationRequest.proposalDocument = 'Proposal Document';
        donationRequest.proposalDocName = 'Proposal.pdf';
        donationRequest.approvalLetter = 'Approval Letter';
        donationRequest.approvalLetterName = 'Approval.pdf';
        donationRequest.poNumber = 'PO12345';
        donationRequest.totalValue = 10000.00;
        donationRequest.minExpDate = '2025-06-10';
        donationRequest.updateNotify = 'Update Notification';
        donationRequest.proposalId = 'P001';

        PDSDonationRequest.ProductLineItem productLineItem = new PDSDonationRequest.ProductLineItem();
        productLineItem.lineItemId = 'LI001';
        productLineItem.productId = 'P001';
        productLineItem.country = 'USA';
        productLineItem.shippingStatus = 'Pending';
        productLineItem.tabletsReq = 500;
        productLineItem.localPartner = 'Local Partner';
        productLineItem.batchNumber = 'B001';
        productLineItem.expDate = '2025-12-31';
        
        donationRequest.productLineItems = new List<PDSDonationRequest.ProductLineItem>{ productLineItem };
        
        PDSDonationRequest.ProductLineItem pli = donationRequest.productLineItems[0];
        
    }
}