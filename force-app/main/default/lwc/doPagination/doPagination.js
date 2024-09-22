import { LightningElement, api, wire, track } from 'lwc';

import pagination from '@salesforce/resourceUrl/pagination';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import USER_ID from "@salesforce/user/Id";
import getContactRole from '@salesforce/apex/MSD_CORE_ProductList.getContactRole';

export default class Pagination extends LightningElement {
  @api pageSize;
  @api totalCount
  @api productName;
  @api parentname;
  @track contactrole = '';
  @track pagetype;
  @track pagepurpose;
  //pageNumber;
  connectedCallback() {

    console.log('productName in Pagination--->', this.productName);
    console.log('parentname>>>>>', this.parentname);

    Promise.all([
      loadStyle(this, pagination + '/pagination/pagination.css'),
      loadScript(this, pagination + '/pagination/jquery-1.8.2.min.js'),


    ]).then(() => {
      loadScript(this, pagination + '/pagination/pagination.min.js'),

        setTimeout(() => {
          this.nextclick();
        }, 1000);

      console.log('CSS Added in catalog');
      setTimeout(() => {
        const { host, hostname, href, origin, pathname, port, protocol, search } = window.location;
        console.log('---url--', pathname)
        let urltext = pathname.split('/');
        let linktext = urltext[urltext.length-1]+'__c';
        console.log({linktext});
        this.initializePagination(this, this.pageSize, parseInt(this.totalCount), this.productName, pathname,linktext);
      }, 1000);

    });

  }



  @wire(getContactRole, { userId: USER_ID })
  wiredgetContactRole(value) {
    console.log({ value });
    const { data, error } = value;
    if (data) {
      console.log({ data });
      this.contactrole = data;
    }
    if (error) {
      console.log({ error });
    }
  }

  nextclick() {
    console.log('nextclick method called');
    const nextEle = this.template.querySelector('.nextText[c-doPagination_doPagination]');
    console.log({ nextEle });
    const nextEle1 = this.template.querySelector('nextText[c-doPagination_doPagination]');
    console.log({ nextEle1 });
    const nextEle2 = this.template.querySelectorAll('.paginationjs-next.J-paginationjs-next');
    console.log({ nextEle2 });
    const nextEle3 = this.template.querySelectorAll('paginationjs-next.J-paginationjs-next');
    console.log({ nextEle3 });
    nextbuttonclick();
    function nextbuttonclick() {
      $(nextEle).click(function () {
        console.log('next clicked');
      });
    }
  }

  displayEvent(pageNumber) {
    console.log('LWC ' + pageNumber);
    //this.pageNumber=pageNumber;
    console.log('connected call back');
    console.log('pname in do pagination 2>>', this.productName);
    this.changeHandler(pageNumber, this.productName);

  }

  initializePagination(lwcInstance, pageSize, totalCount, productName, url, urltext) {
    const paginationelement = this.template.querySelector('div.pagination-container');
    console.log({ paginationelement });
    let pageCollections = [];
    for (let ctr = 1; ctr <= totalCount; ctr++) {
      pageCollections.push(ctr);
    }
    //let jq = windows.$.noConflict();
    //let jq= $.noConflict();
    jQuery(function () {
      jQuery(paginationelement).pagination({
        dataSource: pageCollections,
        pageSize: pageSize,
        callback: function (data, currentPage, nextText, nextText1, eventName, productName, url, urltext) {
          window.console.log('JSON STRING>>>', JSON.stringify(nextText));
          window.console.log({ nextText });
          window.console.log({ nextText1 });
          window.console.log({ data });
          window.console.log({ currentPage });
          window.console.log({ eventName });
          window.console.log({ productName });
          window.console.log({url})
          window.console.log({urltext})
          window.displayPageNO = currentPage.pageNumber;
          lwcInstance.displayEvent(displayPageNO);
          if (eventName != undefined) {
            let _eventName = '';
            if (eventName == 'pagenumber') {
              _eventName = currentPage.pageNumber;
            } else {
              _eventName = eventName;
            }
            lwcInstance.fireDataClickEvent("pagination", '', _eventName, '', urltext, url, productName);
          }
        },
        // productName:this.productName
        productName: productName,
        url: url,
        urltext: urltext
      })
    });
  }
  changeHandler(pageNumber, productName) {
    const selectedEvent = new CustomEvent("mycustomevent", {
      detail: pageNumber,
      proddetail: productName
    });
    console.log('do Pagination Line No.59', pageNumber);

    // this.fireDataClickEvent("pagination",'',pageNumber,'','','',this.productName);
    // Dispatches the event.
    this.dispatchEvent(selectedEvent);
  }

  fireDataClickEvent(category, action, label, module, linkedtext, linkedurl, prdtname) {
    console.log('event triggered');
    if (this.parentname == 'mheenotification'){
      this.pagetype = 'menu';
      this.pagepurpose = 'notifications';
    }else {
      this.pagetype = 'resource';
      this.pagepurpose = 'product resource';
    }
    this.dispatchEvent(new CustomEvent('fireDataClickEvent', {

      detail: {
        data_design_category: category,
        data_design_action: action,
        data_design_label: label,
        data_design_module: module,
        page_type: this.pagetype,
        page_purpose: this.pagepurpose,
        page_audience: 'payor',
        page_marketname: 'united_states',
        page_region: 'us',
        page_contentclassification: 'non-commercial',
        link_text: linkedtext,
        link_url: linkedurl,
        content_count: '',
        content_saved: '',
        content_appointments: '',
        content_requests: '',
        content_name: '',
        page_localproductname: '',
        sfmc_id: USER_ID,
        sfmc_audience: this.contactrole,
        page_url: location.href,
        page_title: 'pagination',

      },
      bubbles: true,
      composed: true
    }));
  }
  @api
  passAPICall(totalCount){
    this.totalCount = totalCount;
    let pathname = '';
    let linktext = '';
    this.initializePagination(this, this.pageSize, parseInt(this.totalCount), this.productName, pathname,linktext);
    console.log('passAPICall');
  }
}