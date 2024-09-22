import { LightningElement } from 'lwc';
import comingsoonbannericon from '@salesforce/resourceUrl/comingsoonbanner';
import arrowupperrighticon from '@salesforce/resourceUrl/arrowupperright';
import mirSearchUrl from '@salesforce/label/c.MSD_CORE_MHEE_MIR_Search_URL';
import CANT_FIND_LABEL from '@salesforce/label/c.MSD_CORE_MHEE_Can_There_Label';
import MIR_REQUEST_LABEL from '@salesforce/label/c.MSD_CORE_MHEE_MIR_Request_Label';
import MIR_DATABASE_LABEL from '@salesforce/label/c.MSD_CORE_MHEE_MIR_Description_Label';
import MIR_DATABASE_DESCRIPTION_LABEL from '@salesforce/label/c.MSD_CORE_MHEE_MIR_Database_Description_Label';

export default class MSD_CORE_Coming_Soon_Banner extends LightningElement {
    comingsoonbanner = comingsoonbannericon;
    arrowupperright = arrowupperrighticon;

    cantfind = CANT_FIND_LABEL;
    mirRequest = MIR_REQUEST_LABEL;
    mirDescription = MIR_DATABASE_LABEL;
    mirDatabaseDescription = MIR_DATABASE_DESCRIPTION_LABEL;

    navigateToMirSearch() {
        this.navigateToUrl(mirSearchUrl, true);
    }

    navigateToUrl(endpoint, openInNewTab) {
        const url = endpoint.startsWith('http') ? endpoint : `https://${endpoint}`;

        if (openInNewTab) {
            const a = document.createElement('a');
            a.href = url;
            a.target = '_blank';
            a.rel = 'noopener noreferrer';
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
        } else {
            window.location.href = url;
        }
    }
}