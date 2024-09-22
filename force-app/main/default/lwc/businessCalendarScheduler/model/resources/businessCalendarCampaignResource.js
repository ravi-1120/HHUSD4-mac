import BusinessCalendarResource from './businessCalendarResource';

export default class BusinessCalendarCampaignResource extends BusinessCalendarResource {
  constructor(eventData, messages) {
    super(createCampaignResourceId(eventData.Product_vod__c, eventData.Detail_Group_vod__c), 'Campaign_vod__c', 2);
    this.productName = eventData.Product_vod__r?.Name;
    this.detailGroupName = eventData.Detail_Group_vod__r?.Name;
    this.name = this.createCampaignName(messages);
  }

  get hasProduct() {
    return this.productName != null;
  }

  get hasDetailGroup() {
    return this.detailGroupName != null;
  }

  get hasProductAndDetailGroup() {
    return this.hasProduct && this.hasDetailGroup;
  }

  createCampaignName(messages) {
    if (this.productName && this.detailGroupName) {
      return `${this.productName}, ${this.detailGroupName}`;
    }

    if (this.productName) {
      return this.productName;
    }

    return messages.noProduct;
  }

  compareTo(otherResource) {
    if (!(otherResource instanceof BusinessCalendarCampaignResource)) {
      return super.compareTo(otherResource);
    }

    // Prioritize campaigns that have both Product and Detail Group set. Sort on Product name first, the Detail Group name.
    if (this.hasProductAndDetailGroup && otherResource.hasProductAndDetailGroup) {
      const productComparison = this.productName.localeCompare(otherResource.productName);
      return productComparison !== 0 ? productComparison : this.detailGroupName.localeCompare(otherResource.detailGroupName);
    }
    if (this.hasProductAndDetailGroup) {
      return -1;
    }
    if (otherResource.hasProductAndDetailGroup) {
      return 1;
    }

    // Next, prioritize campaigns that have at least Product set. Sort on Product name.
    if (this.hasProduct && otherResource.hasProduct) {
      return this.productName.localeCompare(otherResource.productName);
    }
    if (this.productName) {
      return -1;
    }
    if (otherResource.productName) {
      return 1;
    }

    // If campaign has no Product set, then sort it last.
    return 1;
  }
}

function createCampaignResourceId(productId, detailGroupId) {
  if (productId && detailGroupId) {
    return `${productId}_${detailGroupId}`;
  }

  if (productId) {
    return productId;
  }

  return 'Campaign_vod__c';
}