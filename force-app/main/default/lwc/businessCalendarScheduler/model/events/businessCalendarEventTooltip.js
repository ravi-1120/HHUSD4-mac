export default class BusinessCalendarEventTooltip {
  constructor(headerLabel, bodyLabelsToValues, moreDetailsMsg, detailPageUrl) {
    this.headerLabel = headerLabel;
    this.bodyLabelsToValues = bodyLabelsToValues;
    this.moreDetailsMsg = moreDetailsMsg;
    this.detailPageUrl = detailPageUrl;
  }

  get domConfig() {
    return {
      tag: 'div',
      children: [
        {
          tag: 'div',
          class: 'event-tooltip',
          children: [this.headerDomConfig, this.separatorDomConfig, this.bodyDomConfig, this.separatorDomConfig, this.footerDomConfig],
        },
      ],
    };
  }

  get headerDomConfig() {
    return {
      tag: 'div',
      class: 'header',
      text: this.headerLabel,
    };
  }

  get separatorDomConfig() {
    return {
      tag: 'hr',
    };
  }

  get bodyDomConfig() {
    return {
      tag: 'div',
      class: 'body',
      children: Object.entries(this.bodyLabelsToValues).map(([label, value]) => ({
        tag: 'div',
        class: 'line-container',
        children: [
          {
            tag: 'span',
            class: 'label',
            text: label,
            title: label, // Setting the title ensures truncated text can be viewed on hover
          },
          {
            tag: 'span',
            class: 'value',
            text: value,
            title: value, // Setting the title ensures truncated text can be viewed on hover
          },
        ],
      })),
    };
  }

  get footerDomConfig() {
    return {
      tag: 'a',
      href: this.detailPageUrl,
      target: '_blank',
      text: this.moreDetailsMsg,
      class: 'footer',
    };
  }

  getNestedPropertyValue(propertyName) {
    return propertyName.split('.').reduce((fieldValue, fieldName) => (fieldValue ? fieldValue[fieldName] : ''), this.eventObject);
  }
}