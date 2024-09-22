import { LightningElement, track } from 'lwc';
import getEmployeeDetails from '@salesforce/apex/MSD_CORE_ci_PortalStageHandler.getEmployeeDetails';

export default class MSD_CORE_ci_empValidation extends LightningElement {
    @track empNumber = '';
    @track lastName = '';

    handleEmpNumberChange(event) {
        this.empNumber = event.target.value;
    }

    handleLastNameChange(event) {
        this.lastName = event.target.value;
    }

    handleValidate(event) {
        event.preventDefault();
        getEmployeeDetails({ winId: 'WIN-' + this.empNumber, lastName: this.lastName })
        .then(result => {
            if (result && result.length > 0) {
                console.log('Employee details: ' + JSON.stringify(result));
                this.dispatchEvent(
                    new CustomEvent('showtoast', {
                        detail: { type: 'success', message: 'Employee Validation Successful!' },
                        bubbles: true,
                        composed: true
                    })
                );
                this.dispatchEvent(
                    new CustomEvent('validationcomplete', {
                        detail: { success: true, data: result[0] }
                    })
                );
            } else {
                this.dispatchEvent(
                    new CustomEvent('showtoast', {
                        detail: { type: 'error', message: 'Please enter valid Employee details!' },
                        bubbles: true,
                        composed: true
                    })
                );
                this.dispatchEvent(
                    new CustomEvent('validationcomplete', {
                        detail: { success: false }
                    })
                );
                console.log('Employee not found!');
            }
        })
        .catch(error => {
            console.log('Error in fetching employee details: ' + error.body.message);
            this.dispatchEvent(
                new CustomEvent('showtoast', {
                    detail: { type: 'error', message: 'Error fetching employee details!' },
                    bubbles: true,
                    composed: true
                })
            );
        });
    }
}