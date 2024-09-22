import { LightningElement, track, api } from 'lwc';
import getPicklist from '@salesforce/apex/HEQ_Addmore.getPicklist';
import HEQ_Icon_1 from '@salesforce/resourceUrl/HEQ_Icon_1';
import closeIcon from '@salesforce/resourceUrl/HEQ_Utility_Icon_1';
//import getUser from '@salesforce/apex/HEQ_HeaderController.getuser';
import saveUserPreferences from '@salesforce/apex/HEQ_Addmore.saveUserPreferences';
import getUserPreferences from '@salesforce/apex/HEQ_Addmore.getUserPreferences';
import HEQ_Topics from '@salesforce/resourceUrl/HEQ_Topics';
import HEQ_Therapeutic_Area from '@salesforce/resourceUrl/HEQ_Therapeutic_Area';
import HEQ_New from '@salesforce/resourceUrl/HEQ_New';
import HEQ_Expiring_Soon from '@salesforce/resourceUrl/HEQ_Expiring_Soon';
import HEQ_Collections from '@salesforce/resourceUrl/HEQ_Collections';
import HEQ_DI_Artbanks from '@salesforce/resourceUrl/HEQ_DI_Artbanks';

export default class HEQ_AddMore extends LightningElement {
    @track isModalOpen = false;
    @track heqCategoriesOptions = [];
    @track selectedCategories = [];
    @track savedCategories = [];
    @api profileName;
    closeIconUrl = closeIcon;
    hasUnsavedChanges = false;
    HEQ_Icon_1 = HEQ_Icon_1;
    HEQ_New = HEQ_New;
    HEQ_Expiring_Soon = HEQ_Expiring_Soon;
    HEQ_Topics = HEQ_Topics;
    HEQ_Therapeutic_Area = HEQ_Therapeutic_Area;
    HEQ_Collections = HEQ_Collections;
    HEQ_DI_Artbanks = HEQ_DI_Artbanks;

    categoryIcons = {
        'Topic': HEQ_Topics,
        'Therapeutic Area': HEQ_Therapeutic_Area,
        'New': HEQ_New,
        'Expiring soon': HEQ_Expiring_Soon,
        'Health Equity': HEQ_Therapeutic_Area,
        'Collections': HEQ_Collections,
        'D&I Artbanks': HEQ_DI_Artbanks,
    };

     connectedCallback() {
        console.log('Connected Callback of Add More');
        this.fetchFieldValuesByProfile(this.profileName);
        this.fetchUserPreferences();
     }

    fetchUserPreferences() {
        const userId = this.getUrlParamValue(window.location.href, 'Id');
        getUserPreferences({ userId: userId })
            .then((result) => {
                if (result) {
                    this.savedCategories = result.split(',');
                    this.selectedCategories = [...this.savedCategories];
                    this.updateSelectedCategories();
                }
            })
            .catch((error) => {
                console.error('Error fetching user preferences:', error);
            });
    }

    updateSelectedCategories() {
        this.heqCategoriesOptions = this.heqCategoriesOptions.map(category => ({
            ...category,
            selected: this.savedCategories.includes(category.value)
        }));
    }

    fetchFieldValuesByProfile(profileName) {
        if (!profileName) {
            console.warn('Profile name is null. Skipping fetchFieldValuesByProfile.');
            return;
        }

        const metadataType = 'HEQ_Portal_Setting__mdt';
        const fieldNames = ['HEQ_Categories__c'];

        getPicklist({ metadataType, recordApiName: profileName, fieldNames })
            .then(result => {
                console.log('Fetched Add More Component field values:', JSON.stringify(result));
                if (result.HEQ_Categories__c) {
                    this.heqCategoriesOptions = this.processFieldValues(result.HEQ_Categories__c);
                    console.log('HEQ_Categories__c:', this.heqCategoriesOptions);
                    this.selectedCategories.forEach(selectedCategory => {
                        const category = this.heqCategoriesOptions.find(cat => cat.value === selectedCategory);
                        if (category) {
                            category.selected = true;
                            console.log('Marked category as selected:', category);
                        }
                        this.savedCategories = [...this.selectedCategories];
                    });
                } else {
                    console.warn('HEQ_Categories__c is not present in the result:', result);
                }
            })
            .catch(error => {
                console.error('Error fetching field values:', error);
            });
    }

    processFieldValues(fieldValue) {
        if (!fieldValue) {
            console.warn('Field value is null or undefined:', fieldValue);
            return [];
        }
        return fieldValue.split(',').map(value => {
            const trimmedValue = value.trim();
            console.log(`Processing value: ${trimmedValue}`);
            return {
                label: trimmedValue,
                value: trimmedValue,
                icon: this.categoryIcons[trimmedValue] || HEQ_Icon_1,
                selected: false
            };
        });
    }

    openModal() {
    this.isModalOpen = true;
    setTimeout(() => {
        this.SavedCategories();
    }, 0);
}

SavedCategories() {
    this.template.querySelectorAll('button[data-value]').forEach(button => {
        const categoryValue = button.getAttribute('data-value');
        const isSelected = this.savedCategories.includes(categoryValue);
        button.style.backgroundColor = isSelected ? "#F3FFFE" : "";
        if (isSelected) {
            console.log('Highlighted saved category button:', categoryValue);
        }
    });
}

    closeModal() {
    if (this.hasUnsavedChanges) {
        // Show confirmation toast
        this.showNotification('warning', 'You have unsaved changes.');
        this.isModalOpen= false;
    } else {
        this.isModalOpen = false;
    }
}

handleCategoryClick(event) {
    const categoryValue = event.currentTarget.dataset.value;
    const category = this.heqCategoriesOptions.find(cat => cat.value === categoryValue);
    if (category.selected) {
        category.selected = false;
        this.selectedCategories = this.selectedCategories.filter(cat => cat !== categoryValue);
    } else {
        if (this.selectedCategories.length < 4) {
            category.selected = true;
            this.selectedCategories.push(categoryValue);
        } else {
            this.showNotification('error', 'You can select a maximum of 4 categories');
        }
    }
    this.hasUnsavedChanges = true;
    this.heqCategoriesOptions = [...this.heqCategoriesOptions];
    this.updateCategoryBackgroundColor(categoryValue, category.selected);
}

updateCategoryBackgroundColor(categoryValue, isSelected) {
    const categoryButton = this.template.querySelector(`button[data-value="${categoryValue}"]`);
    if (categoryButton) {
        categoryButton.style.backgroundColor = isSelected ? "#F3FFFE" : "";
    }
}
handleSave() {
    this.selectedCategories = this.heqCategoriesOptions.filter(cat => cat.selected).map(cat => cat.value);
    console.log('Selected categories:', JSON.stringify(this.selectedCategories));
    this.hasUnsavedChanges = false;
    this.savedCategories = [...this.selectedCategories];
    this.closeModal();
    const paramValue = this.getUrlParamValue(window.location.href, 'Id');
    saveUserPreferences({ userId: paramValue, selectedCategories: this.selectedCategories })
        .then(() => {
            this.showNotification('success', 'Preferences saved successfully.');
        })
        .catch(error => {
            console.error('Error saving preferences:', error);
            // this.showNotification('error', 'Failed to save preferences.');
        });
    const selectedCategoriesEvent = new CustomEvent('selectedcategories', {
        detail: {
            categories: this.selectedCategories
        }
    });
    this.dispatchEvent(selectedCategoriesEvent);
}

    showNotification(type, message) {
        this.template.querySelector('c-custom-toast').showToast(type, message);
    }

    getUrlParamValue(url, key) {
        return new URL(url).searchParams.get(key);
    }
}