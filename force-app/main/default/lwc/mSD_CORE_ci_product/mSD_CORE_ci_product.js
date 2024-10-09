import { LightningElement, track, api } from 'lwc';
import getProducts from '@salesforce/apex/MSD_CORE_ci_PortalStageHandler.getProducts';
import getFilteredProductIndications from '@salesforce/apex/MSD_CORE_ci_PortalStageHandler.getFilteredProductIndications';
import Product from '@salesforce/label/c.MSD_CORE_ci_Product';
import ProductCatalog from '@salesforce/label/c.MSD_CORE_ci_ProductCatalog';
import CompetitiveSource from '@salesforce/label/c.MSD_CORE_ci_CompetitiveSource';
import OtherDetails from '@salesforce/label/c.MSD_CORE_ci_OtherDetails';
import AcknowledgePolicy from '@salesforce/label/c.MSD_CORE_ci_acknowledgePolicy';
import PolicyStatement from '@salesforce/label/c.MSD_CORE_ci_policystatement';
import infoProduct from '@salesforce/label/c.MSD_CORE_ci_infoProduct';
import infoProductCatalog from '@salesforce/label/c.MSD_CORE_ci_infoProductCatalog';
import Previous from '@salesforce/label/c.MSD_CORE_ciportal_prevnavi';
import Next from '@salesforce/label/c.MSD_CORE_ciportal_nextnavi';



export default class MSD_CORE_ci_product extends LightningElement {
    @api caseDetails;
    @track inputValues = {};
    @track searchTerm = '';
    @track picklistOrdered = [];
    @track searchResults = null;
    @track currentProduct = {
        values: {
            Product: '',
            ProductId: '',
        },
    };
    @track ProductCatalog = false;
    @track CatalogResults = [];
    @track showPolicyStatement = false;
    @track showOtherDetails = false;
    @api portalSetting;
    @api
    label = {
        Product,
        ProductCatalog,
        CompetitiveSource,
        OtherDetails,
        AcknowledgePolicy,
        PolicyStatement,
        infoProduct,
        infoProductCatalog,
        Next,
        Previous
    };
    @api
    validateAndDispatch() {
        const isValid = this.isValid();
        this.dispatchEvent(new CustomEvent('stagevalidation', {
            detail: { isValid, stage: this.currentStage }
        }));
        if (isValid) {
            this.dispatchCaseDetails();
        }
        return isValid;
    }

    @api
    dispatchCaseDetails() {
        const stageDetailsEvent = new CustomEvent('stagedetails', {
            detail: {
                stageInputs: {
                    ...this.inputValues,
                    ProductId: this.currentProduct.values.ProductId
                },
                isValid: this.isValid()
            }
        });
        console.log('Child Component: Dispatching Case Details =', JSON.stringify(stageDetailsEvent.detail));
        this.dispatchEvent(stageDetailsEvent);
    }
    connectedCallback() {
        this.prepopulateInputs();
    }
    get competitiveSourceOptions() {
        return this.processOptions(this.portalSetting.Compet__c, ';');
    }

    processOptions(rawOptions, delimiter) {
        return rawOptions ? rawOptions.split(delimiter).map(option => {
            const [label, value] = option.split(':');
            return { label: label?.trim(), value: value?.trim() || label?.trim() };
        }) : [];
    }
    prepopulateInputs() {
        if (this.caseDetails !== undefined) {
            this.inputValues = Object.assign(this.inputValues, this.caseDetails.stage2);
            this.searchTerm = this.inputValues.Product || '';
            this.currentProduct.values = {
                Product: this.inputValues.Product || '',
                ProductId: this.inputValues.ProductId || ''
            };
            this.ProductCatalog = ['KEYTRUDA', 'LYNPARZA', 'LENVIMA'].includes(this.inputValues.Product);
        }
        if (this.inputValues) {
            this.showOtherDetails = this.inputValues.showOtherDetails || false;
            this.showPolicyStatement = this.inputValues.showPolicyStatement || false;
        }
    }
    get hasCatalogResults() {
        return this.CatalogResults && this.CatalogResults.length > 0;
    }

    debounce(callback, delay = 300) {
        let timeout;
        return (...args) => {
            clearTimeout(timeout);
            timeout = setTimeout(() => callback(...args), delay);
        };
    }

    searchProducts = this.debounce((value) => {
        getProducts({ searchTerm: value })
            .then((result) => {
                const otherProductOption = { label: 'OTHER COMPANY PRODUCT', value: 'OTHER COMPANY PRODUCT' };
                const searchTermLower = value.toLowerCase();
                this.picklistOrdered = result.map(record => ({
                    label: record.Name,
                    value: record.Id
                }));
                if ('other company product'.includes(searchTermLower)) {
                    this.picklistOrdered.push(otherProductOption);
                }
                this.picklistOrdered.sort((a, b) => this.sortByRelevance(a.label, b.label, searchTermLower));
                this.searchResults = this.picklistOrdered.slice(0, 50);
            })
            .catch((error) => {
                console.error('Error fetching products:', error);
            });
    });

    fetchProductCatalog = this.debounce((searchTerm) => {
        getFilteredProductIndications({ searchTerm })
            .then(result => {
                this.CatalogResults = result
                    .filter(record => record.Name.toLowerCase().includes(searchTerm.toLowerCase()))
                    .map(record => ({
                        label: record.Name,
                        Id: record.Id
                    }));
                this.CatalogResults.sort((a, b) => this.sortByRelevance(a.label, b.label, searchTerm));
            })
            .catch(error => {
                console.error('Error fetching product catalog:', error);
                this.CatalogResults = [];
            });
    });

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

    handleInput(event) {
        const field = event.target.name;
        let value = event.target.value;
        if (event.target.type === 'checkbox') {
            value = event.target.checked;
        }
        this.inputValues[field] = value;
        if (field === 'Product') {
            this.handleProductInput(event, value);
            this.inputValues.ProductCatalog = null;
        } else if (field === 'ProductCatalog') {
            this.handleProductCatalogInput(event, value);
        } else if (field === 'CompetitiveSource') {
            this.handleSource();
        }
        
        this.inputValues.showOtherDetails = this.showOtherDetails;
        this.inputValues.showPolicyStatement = this.showPolicyStatement;
    }
    handleSource() {
        if (this.inputValues.CompetitiveSource === 'Other') {
            this.showOtherDetails = true;
            this.showPolicyStatement = false;
        } else if (this.inputValues.CompetitiveSource === 'Competitive Representative') {
            this.showPolicyStatement = true;
            this.showOtherDetails = false;
        } else {
            this.showOtherDetails = false;
            this.inputValues.OtherDetails = null;
            this.inputValues.acknowledgePolicy = false;
            this.showPolicyStatement = false;
        }
    }

    handleProductInput(event, value) {
        this.hideCustomValidity(event);
        this.searchTerm = value;
        this.currentProduct.values = {
            Product: '',
            ProductId: ''
        };

        this.ProductCatalog = ['KEYTRUDA', 'LYNPARZA', 'LENVIMA'].includes(value);
        value ? this.searchProducts(value.toLowerCase()) : this.clearSearchResults();
    }

    handleProductCatalogInput(event, value) {
        this.hideCustomValidity(event);
        if (value) {
            this.fetchProductCatalog(value.toLowerCase());
        } else {
            this.clearProductCatalogResults();
        }
    }

    handleSelectSearch(event) {
        const selectedProdId = event.currentTarget.dataset.value;
        const selectedSearchResult = this.searchResults.find(
            (picklistOption) => picklistOption.value === selectedProdId
        );
        this.selectProduct(selectedSearchResult.label, selectedProdId);
    }

    selectProduct(label, productId) {
        this.searchTerm = label;
        this.inputValues.Product = label;
        this.currentProduct.values = {
            Product: label,
            ProductId: productId
        };
        this.ProductCatalog = ['KEYTRUDA', 'LYNPARZA', 'LENVIMA'].includes(label);
        this.clearSearchResults();
    }

    clearSearchResults() {
        this.searchResults = null;
    }

    clearProductCatalogResults() {
        this.CatalogResults = [];
    }

    handleFocus(event) {
        const { name } = event.target;
        if (name === 'Product' && this.searchTerm) {
            this.hideCustomValidity(event);
            this.searchResults = this.picklistOrdered;
        }
        if (name === 'ProductCatalog') {
            this.inputValues.ProductCatalog ? this.CatalogResults = [] : this.clearProductCatalogResults();
        }
    }

    handleBlur(event) {
        const { name } = event.target;
        name === 'Product' ? this.clearSearchResults() : this.clearProductCatalogResults();
        this.validateField(event.target);
    }

    validateField(field) {
        if (this.OtherProduct || this.currentProduct.values.Product) {
            field.setCustomValidity('');
        } else {
            field.setCustomValidity('Please select a Product from the dropdown.');
        }
        field.reportValidity();
    }

    handleKeydown(event) {
        if (!this.searchResults || !this.searchResults.length) {
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
            default:
                break;
        }
    }

    updateFocusedItem() {
        const listItems = this.template.querySelectorAll('.slds-listbox__item');
        listItems.forEach((item, index) => {
            item.classList.toggle('slds-has-focus', index === this.focusedIndex);
            if (index === this.focusedIndex) {
                item.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
            }
        });
    }

    hideCustomValidity(event) {
        const productField = event.target;
        productField.setCustomValidity('');
        productField.reportValidity();
    }

    isValid() {
        const inputElements = Array.from(this.template.querySelectorAll('lightning-input, lightning-combobox'));
        return inputElements.every(input => {
            if (input.required) {
                input.reportValidity(); // Show validity messages
                return input.checkValidity();
            }
            return true;
        });
    }
    handlePrevNext(event) {
        const choice = event.target.name;
        let isValid = true;
        let invalidElement = null;
        if (choice === 'Next') {
            // Collect all input elements that need validation
            const inputElements = Array.from(this.template.querySelectorAll('lightning-input, lightning-combobox'));
            // Validate each input element
            inputElements.forEach(input => {
                if (input.required && !input.checkValidity()) {
                    isValid = false;
                    if (!invalidElement) {
                        invalidElement = input;
                    }
                }
            });
            // Specific validation for the acknowledgePolicy checkbox
            const acknowledgeCheckbox = this.template.querySelector('lightning-input[name="acknowledgePolicy"]');
            if (acknowledgeCheckbox && acknowledgeCheckbox.required && !acknowledgeCheckbox.checked) {
                isValid = false;
                if (!invalidElement) {
                    invalidElement = acknowledgeCheckbox;
                }
            }
            // If any validation fails, show a warning toast and focus on the first invalid element
            if (!isValid) {
                this.dispatchEvent(
                    new CustomEvent('showtoast', {
                        detail: { type: 'warning', message: 'Provide all the mandatory values before proceeding!' },
                        bubbles: true,
                        composed: true
                    })
                );
                if (invalidElement) {
                    invalidElement.scrollIntoView({ behavior: 'smooth', block: 'center' });
                    invalidElement.focus();
                }
                return; // Stop further execution if inputs are invalid
            }
        }
        // Dispatch the event with the appropriate stage details and validity status
        const stageDetailsEvent = new CustomEvent("stagedetails", {
            detail: {
                stageInputs: this.inputValues, // Pass the input values directly
                action: choice, // Next or Previous
                isValid: isValid // Pass the validation status
            }
        });
        this.dispatchEvent(stageDetailsEvent);
    }
    handleSelectProductCatalog(event) {
        const selectedCatalogId = event.currentTarget.dataset.id;
        const selectedCatalog = this.CatalogResults.find(item => item.Id === selectedCatalogId);
        this.inputValues.ProductCatalog = selectedCatalog ? selectedCatalog.label : '';
    }
}