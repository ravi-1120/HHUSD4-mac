import { LightningElement, track, api, wire } from 'lwc';
import getProducts from '@salesforce/apex/MSD_CORE_ae_PortalStageHandler.getProducts';
import getPicklist from '@salesforce/apex/MSD_CORE_ae_PortalStageHandler.getPicklist';
import NEXTBUTTON from '@salesforce/label/c.MSD_CORE_ae_Next_Button';
import PREVIOUSBUTTON from '@salesforce/label/c.MSD_CORE_ae_Previous_Button';
import PRODUCTS from '@salesforce/label/c.MSD_CORE_ae_Products';
import ADDPRODUCTBUTTON from '@salesforce/label/c.MSD_CORE_ae_Add_Product_Button';
import PRODUCTNAME from '@salesforce/label/c.MSD_CORE_ae_Product_Name';
import DOSEFREQUENCY from '@salesforce/label/c.MSD_CORE_ae_Dose_Frequency';
import LOTNUMBER from '@salesforce/label/c.MSD_CORE_ae_Lot_Number';
import EXPIRATIONDATE from '@salesforce/label/c.MSD_CORE_ae_Expiration_Date';
import WHOADMINISTEREDTHEPRODUCT from '@salesforce/label/c.MSD_CORE_ae_Who_administered_the_product';
import UNIQUEIDENTIFIER from '@salesforce/label/c.MSD_CORE_ae_Unique_Identifier';
import MODELNUMBER from '@salesforce/label/c.MSD_CORE_ae_Model_Number';
import CATALOGNUMBER from '@salesforce/label/c.MSD_CORE_ae_Catalog_Number';
import SERIALNUMBER from '@salesforce/label/c.MSD_CORE_ae_Serial_Number';
import SAVEANDNEWADDITIONALPRODUCT from '@salesforce/label/c.MSD_CORE_ae_Save_and_Add_New_Additional_product';
import WARNINGMESSAGE from '@salesforce/label/c.MSD_CORE_ae_warning_Message';
import SKIPTOREVIEW from '@salesforce/label/c.MSD_CORE_ae_Skip_to_Review';
import CANCELBUTTON from '@salesforce/label/c.MSD_CORE_ae_Cancel';
import SAVEBUTTON from '@salesforce/label/c.MSD_CORE_ae_Save';
import WARNINGMESSAGE1 from '@salesforce/label/c.MSD_CORE_ae_product_WarningMessage';
import SELECTPRODUCT from '@salesforce/label/c.MSD_CORE_ae_Select_Product';
import IFKNOWN from '@salesforce/label/c.MSD_CORE_ae_If_Known';
import helpText from '@salesforce/label/c.MSD_CORE_ae_Help_Text_Product_Information';

export default class MSD_CORE_ae_productInformation extends LightningElement {
  @track savedProductSets = [];
  @track currentProduct = {};
  @track selectedProducts = [];
  @track picklistOrdered = [];
  @track formattedDate = '';
  @track activeSections = ['1', '2'];
  @api caseDetails;
  @api stageId;
  @api editedSection;
  @api portalSetting;
  @track showErrorMessage = false;
  @track productTypes = [];
  searchTimeout;
  searchTerm = '';
  showModal = false;
  searchResults = null;
  focusedIndex = -1;

  get showSkipButton() {
    return this.editedSection === this.stageId;
  }

  label = {
    NEXTBUTTON,
    PREVIOUSBUTTON,
    helpText,
    PRODUCTS,
    ADDPRODUCTBUTTON,
    PRODUCTNAME,
    DOSEFREQUENCY,
    LOTNUMBER,
    EXPIRATIONDATE,
    WHOADMINISTEREDTHEPRODUCT,
    UNIQUEIDENTIFIER,
    MODELNUMBER,
    CATALOGNUMBER,
    SERIALNUMBER,
    SAVEANDNEWADDITIONALPRODUCT,
    WARNINGMESSAGE,
    SKIPTOREVIEW,
    CANCELBUTTON,
    SAVEBUTTON,
    WARNINGMESSAGE1,
    SELECTPRODUCT,
    IFKNOWN,
  }

  connectedCallback() {
    if (this.caseDetails != undefined && Object.keys(this.caseDetails).length != 0) {
      this.populateInputs();

    }
    if (this.portalSetting) {
      this.processProductTypes();
    }
    // this.focusedIndex = -1;
    this.configurePicklist();
    // this.keyboardNavigation();
  }
  populateInputs() {
    this.savedProductSets = Object.assign(this.savedProductSets, this.caseDetails.stage4);
  }


  addProductSet() {
    this.searchTerm = '';
    this.searchResults = null;
    this.picklistOrdered = [];
    this.currentProduct = {
      values: {
        Product: '',
        ProductId: '',
        UniqueIdentifier: '',
        ModelNumber: '',
        ExpirationDate: '',
        SerialNumber: '',
        DoseFrequency: '',
        LotNumber: '',
        CatalogNumber: '',
        OperatorOfDevice: '',
        formattedDate: ''
      }
    };
    this.showModal = true;
    this.disableBodyScroll();
  }

  handleInput(event) {
    const field = event.target.name;
    let value = event.target.value;

    // if (field === 'ExpirationDate') {
    //   this.handleExpDateChange(event);
    // } 

    if (field === 'Product') {
      this.hideCustomValidity(event);
      this.searchTerm = value;
      this.currentProduct.values[field] = '';
      this.currentProduct.values['ProductId'] = '';
      if (value) {
        this.debounce(value.toLowerCase());
      } else {
        this.clearSearchResults();
      }
    } else {
      this.currentProduct.values[field] = value;
    }
  }
    handleExpDateChange(event) {
    let value = event.target.value;
    const localDateStr = value + 'T00:00';
    // console.log("Local date string:", localDateStr);
    if (value && !isNaN(Date.parse(localDateStr))) {
      // console.log("Value is not empty and date is valid");
      const date = new Date(localDateStr);
      // console.log("Date object:", date);
        this.formattedDate = date.toLocaleDateString('en-US', {
          year: 'numeric',
          month: 'short',
          day: '2-digit'
        });
        // console.log("Formatted date:", this.formattedDate);
  
        this.currentProduct.values.ExpirationDate = value;
        this.currentProduct.values.formattedDate = this.formattedDate;
        event.target.setCustomValidity('');      
    } else {
      this.resetDateFields();
    }
    event.target.reportValidity();
  }




  
  resetDateFields() {
    // console.log("resetDateFields called");
  
    if (this.currentProduct && this.currentProduct.values) {
       this.formattedDate = '';
       this.currentProduct.values.ExpirationDate = '';
       this.currentProduct.values.formattedDate = '';
     }
  }
  
  

  // keyboardNavigation() {
  //   this.template.addEventListener('keydown', this.handleKeydown.bind(this));
  //   console.log('Keyboard navigation listeners added');
  // }
  debounce(value) {
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout);
    }

    this.searchTimeout = setTimeout(() => {
      this.searchProducts(value);
    }, 300);
  }
  processProductTypes() {
    if (this.portalSetting && this.portalSetting.Product_Types__c) {
      this.productTypes = this.portalSetting.Product_Types__c.split(';')
        .map(type => type.split(':')[0]);
      console.log('Processed Product Types:', JSON.stringify(this.productTypes));
    }
  }

  // searchProducts(value) {

  //   console.log('Parsed Product Types:', JSON.stringify(this.productTypes));
  //   getProducts({ searchTerm: value, productTypes: this.productTypes })
  //     .then((result) => {
  //       if (result.length) {
  //         this.picklistOrdered = result.map(record => ({
  //           label: record.Name,
  //           value: record.Id
  //         }));
  //         this.picklistOrdered.sort((a, b) => {
  //           if (a.label < b.label) return -1;
  //           if (a.label > b.label) return 1;
  //           return 0;
  //         });
  //       } else {
  //         this.picklistOrdered = [];
  //         let freeProduct = { label: this.searchTerm + " (+Add New)", value: "OtherProductField" };
  //         this.picklistOrdered = [freeProduct, ...this.picklistOrdered];
  //       }
  //       this.searchResults = this.picklistOrdered;
  //     })
  //     .catch((error) => {
  //       console.error('Error fetching products:', error);
  //     });
  // }
  searchProducts(value) {
    console.log('Parsed Product Types:', JSON.stringify(this.productTypes));
    getProducts({ searchTerm: value, productTypes: this.productTypes })
      .then((result) => {
        if (result.length) {
          this.picklistOrdered = result.map(record => ({
            label: record.Name,
            value: record.Id
          }));
          this.picklistOrdered.sort((a, b) => this.sortByRelevance(a.label, b.label, value));
          this.picklistOrdered = this.picklistOrdered.slice(0, 50);
        } else {
          this.picklistOrdered = [];
          let freeProduct = { label: this.searchTerm + " (+Add New)", value: "OtherProductField" };
          this.picklistOrdered = [freeProduct, ...this.picklistOrdered];
        }
        this.searchResults = this.picklistOrdered;
      })
      .catch((error) => {
        console.error('Error fetching products:', error);
      });
  }

  sortByRelevance(labelA, labelB, searchTerm) {
    const normalize = (str) => str.toLowerCase().replace(/[^a-z0-9]/g, '');
    const searchTermNormalized = normalize(searchTerm);
    const labelANormalized = normalize(labelA);
    const labelBNormalized = normalize(labelB);

    const score = (label) => {
      if (label === searchTermNormalized) return 3;
      if (label.startsWith(searchTermNormalized)) return 2;
      if (label.includes(searchTermNormalized)) return 1;
      return 0;
    };

    const scoreA = score(labelANormalized);
    const scoreB = score(labelBNormalized);

    if (scoreA === scoreB) {
      return labelA.localeCompare(labelB);
    }

    return scoreB - scoreA;
  }

  blurEvent(event) {
    this.clearSearchResults();
    let productField = event.target;
    if (this.currentProduct.values['Product'] !== '') {
      productField.setCustomValidity('');
    } else {
      productField.setCustomValidity("Please select a Product from the dropdown.");
    }
    productField.reportValidity();
  }

  handleKeydown(event) {
    // console.log('Keydown event detected: keyCode=', event.keyCode);
    if (!this.searchResults || this.searchResults.length === 0) {
      return;
    }
    switch (event.keyCode) {
      case 38: // Up arrow
        this.focusedIndex = Math.max(this.focusedIndex - 1, 0);
        this.updateFocusedItem();
        break;
      case 40: // Down arrow
        this.focusedIndex = Math.min(this.focusedIndex + 1, this.searchResults.length - 1);
        this.updateFocusedItem();
        break;
      case 13: // Enter key
        if (this.focusedIndex >= 0) {
          const selectedProd = this.searchResults[this.focusedIndex];
          this.handleSelectSearch({ currentTarget: { dataset: { value: selectedProd.value } } });
        }
        break;
      default: break;
    }
  }

  updateFocusedItem() {
    // console.log('Updating focused item, index=', this.focusedIndex);
    const listItems = this.template.querySelectorAll('.slds-listbox__item');
    listItems.forEach((item, index) => {
      if (index === this.focusedIndex) {
        item.classList.add('slds-has-focus');
        item.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
      } else {
        item.classList.remove('slds-has-focus');
      }
    });
  }

  configurePicklist() {
    getPicklist({ objectApiName: 'MSD_CORE_AE_Product__c', fieldApiName: 'MSD_Core_Product_Operator_of_Device__c' })
      .then(result => {
        this.operatorOptions = result.map(entry => ({ label: entry.label, value: entry.value }));
      })
      .catch(error => {
        console.error('Error retrieving operatorOptions picklist values', error);
      });
  }

  handleModalCancel() {
    this.currentProduct = {};
    this.showModal = false;
    this.enableBodyScroll();
  }

  handleProductDelete(event) {
    const prodId = event.currentTarget.dataset.id
    this.savedProductSets = this.savedProductSets.filter(p => p.id !== Number(prodId));
  }

  handleModalSave() {
    if (!this.currentProduct.values['Product']) {
      this.isInputValid();
      return;
    }
    if (this.currentProduct.id) {
      const index = this.savedProductSets.findIndex(prod => prod.id === this.currentProduct.id);
      if (index !== -1) {
        this.savedProductSets[index] = JSON.parse(JSON.stringify(this.currentProduct));
      }
    } else {
      const newId = this.savedProductSets.length ? Math.max(...this.savedProductSets.map(p => p.id)) + 1 : 1;
      this.currentProduct.id = newId;
      this.savedProductSets.push(this.currentProduct);
    }
    this.showModal = false;
    this.enableBodyScroll();
    this.currentProduct = {};
    // console.log('savedProductSets->' + JSON.stringify(this.savedProductSets));
  }

  handleModalSaveAndNew() {
    this.handleModalSave();
    this.addProductSet();
  }

  handleSelectSearch(event) {
    const selectedProdId = event.currentTarget.dataset.value;
    let selectedSearchResult = this.searchResults.find(
      (picklistOption) => picklistOption.value === selectedProdId
    );
    let label = selectedSearchResult.label;
    if (selectedProdId === 'OtherProductField') {
      label = label.replace(' (+Add New)', '');
    }
    this.searchTerm = label;
    this.currentProduct.values['Product'] = label;
    this.currentProduct.values['ProductId'] = selectedProdId;
    this.clearSearchResults();
    this.focusedIndex = -1;
  }

  clearSearchResults() {
    this.searchResults = null;
  }

  handleFocus(event) {
    if (this.searchTerm) {
      this.hideCustomValidity(event);
      this.searchResults = this.picklistOrdered;
      this.focusedIndex = -1;
    }
  }

  hideCustomValidity(event) {
    let productField = event.target;
    productField.setCustomValidity('');
    productField.reportValidity();
  }

  disableBodyScroll() {
    const addClipClass = new CustomEvent("modalaction", {
      detail: 'ModalOpen'
    });
    this.dispatchEvent(addClipClass);
    // document.body.classList.add('slds-backdrop');
    // document.body.classList.add('slds-backdrop_open');
  }

  enableBodyScroll() {
    const removeClipClass = new CustomEvent("modalaction", {
      detail: 'ModalClose'
    });
    this.dispatchEvent(removeClipClass);
    // document.body.classList.remove('slds-backdrop');
    // document.body.classList.remove('slds-backdrop_open');
  }

  handleProductEdit(event) {
    const prodId = event.currentTarget.dataset.id;
    const clickedProduct = this.savedProductSets.find(product => product.id == prodId);
    this.currentProduct = { ...clickedProduct };
    this.currentProduct.values = { ...clickedProduct.values };
    this.searchTerm = this.currentProduct.values['Product'];
    this.showModal = true;
    this.disableBodyScroll();
  }

  isInputValid() {
    const allRequiredFields = [...this.template.querySelectorAll('.requiredField')];
    let isValid = allRequiredFields.every(field => {
      return field.reportValidity();
    });
    return isValid;
  }

  handlePrevNext(event) {
    let choice = event.target.name;
    if (choice === 'Next' || choice === 'Skip') {
      if (this.savedProductSets.length > 0) {
        this.showErrorMessage = false;
        this.dispatchStageDetails(choice);
      } else {
        this.showErrorMessage = true;
      }
    } else if (choice === 'Previous') {
      this.showErrorMessage = false;
      this.dispatchStageDetails(choice);
    }
  }

  dispatchStageDetails(choice) {
    const stage4DetailsEvent = new CustomEvent("stagedetails", {
      detail: {
        'stageInputs': {
          'stage4': this.savedProductSets,
        },
        'action': choice,
      }
    });

    this.dispatchEvent(stage4DetailsEvent);
  }

}