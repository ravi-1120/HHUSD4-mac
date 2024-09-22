import { LightningElement, track, wire, api } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import USERPROFILE_Name from '@salesforce/schema/User.Profile.Name';
import getSearchCategory from '@salesforce/apex/HEQ_SearchCategoryController.getSearchCategory';

export default class HEQ_SearchCategory extends LightningElement {

    @track searchCategory;
    currentUserProfileId;

    // Get logged in User Profile
    @wire(getRecord, { recordId: USER_ID, fields: [USERPROFILE_Name]}) 
    userDetails({error, data}) {
        if (data) {
            console.log('data>>',data);
            this.currentUserProfileId = data.fields.Profile.displayValue;
            console.log('this.currentUserProfileId>>',this.currentUserProfileId);
            this.getSearchCategory();
        } else if (error) {
            console.log('error>>>',error);
        }
    }

    updateIsChecked(categories, ref) {
        for (let category of categories) {
            if (ref.includes(category.developerName)) {
                category.isChecked = true;
            }else{
                category.isChecked = false;
            }
            if (category.childCategories.length > 0) {
                this.updateIsChecked(category.childCategories, ref);
            }
        }
    }

    @api
    loadCheckedCategories(categories){
        console.log('categories->'+categories);
        console.log('searchCategory->'+JSON.stringify(this.searchCategory));
        this.updateIsChecked(this.searchCategory,categories);
    }

    // Get Search Category Metadata
    getSearchCategory(){
        getSearchCategory({profile:this.currentUserProfileId})
        .then(result => {
            console.log('result>>',result);
            this.searchCategory = result.map(category => ({
                ...category,
                isOpen: false,
                isChecked: false,
                isIconVisible: category.childCategories.length==0 ? false : true,
                iconName: this.getIconName(category.isOpen),
                childCategories: category.childCategories.map(child => ({
                    ...child,
                    isOpen: false,
                    isChecked: false,
                    iconName: this.getIconName(child.isOpen),
                    isIconVisible: child.childCategories.length==0 ? false : true,
                    childCategories: child.childCategories.map(grandChild => ({
                        ...grandChild,
                        isOpen: false,
                        isChecked: false,
                        isIconVisible: grandChild.childCategories.length==0 ? false : true,
                        iconName: this.getIconName(grandChild.isOpen)
                    }))
                }))
            }));
            console.log('cat>>>'+JSON.stringify(this.searchCategory));
        })
        .catch(error => {
            console.log('error>>',error);
        })
    }

    toggleSection(event) {
        const sectionName = event.currentTarget.dataset.id;
        this.toggleChildCategories(sectionName, this.searchCategory);
    }

    toggleChildCategories(sectionName, categories) {
        for (let category of categories) {
            if (category.id === sectionName) {
                category.isOpen = !category.isOpen;
                category.iconName = this.getIconName(category.isOpen);
            } else if (category.childCategories) {
                this.toggleChildCategories(sectionName, category.childCategories);
            }
        }
    }

    handleCheck(event) {
        console.log('handleCheck');
        const categoryName = event.currentTarget.dataset.id;
        const isChecked = event.detail.checked;
        this.updatechildCheckbox(categoryName,isChecked,this.searchCategory);
        this.updateParentCheckboxes(this.searchCategory);

        // console.log('this.c/hEQ_SearchCategory_>'+JSON.stringify(this.searchCategory));
    }

    updatechildCheckbox(categoryName,isChecked,categories) {
        for(let category of categories){
            // console.log('category.id->'+category.id+'--'+categoryName);
            if(category.id === categoryName){
                category.isChecked = isChecked;
                if (category.childCategories.length>0) {
                    for(let child of category.childCategories) {
                        child.isChecked = isChecked;
                        console.log('child>>',child.isChecked);
                        if(child.childCategories.length>0){
                            for(let grandchild of child.childCategories) {
                                console.log('grandchild>>>',grandchild.isChecked);
                                grandchild.isChecked = isChecked;
                            }
                        }
                    }
                }
            } else {
                // console.log('category.childCategories->'+JSON.stringify(category.childCategories));
                if(category.childCategories.length>0){
                    this.updatechildCheckbox(categoryName,isChecked,category.childCategories);
                }
            }
        }
        this.searchCategory = [...this.searchCategory];
    }

    updateParentCheckboxes(categories) {
        for (let category of categories) {
            if (category.childCategories.length > 0) {
                let allChildrenChecked = true;
                let anyChildChecked = false;
    
                for (let child of category.childCategories) {
                    if (!child.isChecked) {
                        allChildrenChecked = false;
                    } else {
                        anyChildChecked = true;
                    }
                }
    
                if (!allChildrenChecked) {
                    category.isChecked = false;
                } else {
                    category.isChecked = true;
                }
    
                // Recursively update the parent categories
                this.updateParentCheckboxes(category.childCategories);
            }
        }
        this.searchCategory = [...this.searchCategory];
    }

    getIconName(isOpen) {
        return isOpen ? 'utility:chevrondown' : 'utility:chevronright';
    }

    handleSubmit() {
        console.log('Handle submit');
        let selectedcategoriesid = this.extractCheckedCategoryNames(this.searchCategory);
        console.log('>>>selectedcategoriesid>>>',JSON.stringify(selectedcategoriesid));

        this.dispatchEvent(new CustomEvent('categoriesid', {
            detail: selectedcategoriesid,
            bubbles: true,
            composed: true
        }));   
        
        let selectedCategories = this.extractChilds(this.searchCategory);
        console.log('>>>>> selectedCategories in handleSubmit >>>>>',JSON.stringify(selectedCategories));
        
        this.dispatchEvent(new CustomEvent('selectedcategories', {
            detail: selectedCategories,
            bubbles: true,
            composed: true
        }));     
    }

    handleClear() {
        function traverse(categoryList) {
            categoryList.forEach(category => {
                category.isChecked = false;

                if (category.childCategories && category.childCategories.length > 0) {
                    traverse(category.childCategories);
                }
            });
        }
        traverse(this.searchCategory);

        let selectedcategoriesid = this.extractCheckedCategoryNames(this.searchCategory);
        console.log('>>>selectedcategoriesid>>>',JSON.stringify(selectedcategoriesid));

        this.dispatchEvent(new CustomEvent('categoriesid', {
            detail: selectedcategoriesid,
            bubbles: true,
            composed: true
        }));
    }

    extractChilds(categories) {
        return categories
            .filter(category => category.isChecked || (category.childCategories && category.childCategories.some(child => this.isAnyChildChecked(child))))
            .map(category => ({
                name: category.name,
                isChecked: category.isChecked,
                childCategories: this.extractChilds(category.childCategories)
            }));
    }

    isAnyChildChecked(category) {
        if (category.isChecked) {
            return true;
        }
    
        if (category.childCategories && category.childCategories.length > 0) {
            return category.childCategories.some(child => this.isAnyChildChecked(child));
        }
    
        return false;
    }
    // extractChilds(categories) {
    //     return categories
    //         .filter(category => category.isChecked || (category.childCategories && category.childCategories.some(child => child.isChecked)))
    //         .map(category => ({
    //             name: category.name,
    //             isChecked: category.isChecked,
    //             childCategories: this.extractChilds(category.childCategories)
    //         }));
    // }

    extractCheckedCategoryNames(categories) {
        let names = [];
        function traverse(categoryList) {
            categoryList.forEach(category => {
                if (category.isChecked) {
                    names.push(category.id);
                }

                if (category.childCategories && category.childCategories.length > 0) {
                    traverse(category.childCategories);
                }
            });
        }

        traverse(categories);
        return names;
    }

}