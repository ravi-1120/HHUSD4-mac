import { LightningElement, track, wire } from 'lwc';
//import getProductNames from '@salesforce/apex/PDS_EntityDonationController.getProductNames';
export default class PdsEntityDonation extends LightningElement {

    @track productOptions = [];
    @track entityForm = false;
    products = [
              {
            id: Date.now(), // Automatically display the first product section
            nameAndDosage: '', 
            marketValue: '',
            size: '',
            quantity: '',
            expirationDate: ''
        }
    ];

    addProduct() {
        const newProduct = {
            id: Date.now(),
            nameDosage: '',  // Combined field for product name and dosage
            marketValue: '',
            size: '',
            quantity: '',
            expirationDate: ''
        };
        this.products = [...this.products, newProduct];
    }

    handleChange(event) {
        const { value, dataset } = event.target;
        const productId = dataset.id;
        this.products = this.products.map(product => {
            if (product.id === parseInt(productId)) {
                return { ...product, [event.target.label.toLowerCase().replace(/\s/g, '')]: value };
            }
            return product;
        });
    }
    removeProduct(event) {
        const productId = event.currentTarget.dataset.id;
        this.products = this.products.filter(product => product.id !== parseInt(productId));
    }
    get taxOptions() {
        return [
            { label: 'Yes', value: 'Yes' },
            { label: 'No', value: 'No' },
        ];
    }
    // @wire(getProductNames)
    // wiredProducts({ error, data }) {
    //     if (data) {
    //         // Map the product names into combobox options
    //         this.productOptions = data.map(productName => {
    //             return { label: productName, value: productName };
    //         });
    //     } else if (error) {
    //         console.error('Error fetching product names:', error);
    //     }
    // }
    onSubmit(){
        this.entityForm = true;
    }
}