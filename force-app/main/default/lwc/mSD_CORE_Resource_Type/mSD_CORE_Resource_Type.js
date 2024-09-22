import { LightningElement } from 'lwc';
import arrowiconimage from '@salesforce/resourceUrl/arrowicon';
import virusshieldimage from '@salesforce/resourceUrl/virusshield';
import dnaimage from '@salesforce/resourceUrl/dna';
import searchimage from '@salesforce/resourceUrl/search';
import documentimage from '@salesforce/resourceUrl/document';
import mheedomain from '@salesforce/label/c.MSD_CORE_MHEE_Domain_URL';
import arrowhovericonimage from '@salesforce/resourceUrl/arrowhovericon';

import resourceTypes from '@salesforce/label/c.MSD_CORE_MHEE_Resource_Types';
import diseaseStateDecks from '@salesforce/label/c.MSD_CORE_MHEE_Disease_State_Decks';
import diseaseDecksDescription from '@salesforce/label/c.MSD_CORE_MHEE_Disease_Decks_Description';
import pipelineInformation from '@salesforce/label/c.MSD_CORE_MHEE_Pipeline_Information';
import pipelineDescription from '@salesforce/label/c.MSD_CORE_MHEE_Pipeline_Description';
import mirSearch from '@salesforce/label/c.MSD_CORE_MHEE_MIR_Search';
import mirSearchDescription from '@salesforce/label/c.MSD_CORE_MHEE_MIR_Search_Description';
import amcpDossiers from '@salesforce/label/c.MSD_CORE_MHEE_AMCP_Dossiers';
import amcpDescription from '@salesforce/label/c.MSD_CORE_MHEE_AMCP_Description';

import diseaseInformationEndpoint from '@salesforce/label/c.MSD_CORE_MHEE_Disease_Information_Endpoint';
import pipelineEndpoint from '@salesforce/label/c.MSD_CORE_MHEE_Pipeline';
import mirSearchUrl from '@salesforce/label/c.MSD_CORE_MHEE_MIR_Search_URL';
import amcpDossiersEndpoint from '@salesforce/label/c.MSD_CORE_MHEE_AMCP_Dossiers_URL';
import httpProtocol from '@salesforce/label/c.MSD_CORE_MHEE_Http_Protocol';

export default class ResourceTypes extends LightningElement {
    virusshieldimage = virusshieldimage;
    dnaimage = dnaimage;
    searchimage = searchimage;
    documentimage = documentimage;
    arrowiconimage = arrowiconimage;
    arrowhovericonimage = arrowhovericonimage;
    mheedomain = mheedomain;

    resourceTypes = resourceTypes;
    diseaseStateDecks = diseaseStateDecks;
    diseaseDecksDescription = diseaseDecksDescription;
    pipelineInformation = pipelineInformation;
    pipelineDescription = pipelineDescription;
    mirSearch = mirSearch;
    mirSearchDescription = mirSearchDescription;
    amcpDossiers = amcpDossiers;
    amcpDescription = amcpDescription;

    navigateToDiseaseStateDecks() {
        this.navigateToUrl(diseaseInformationEndpoint, false);
    }

    navigateToPipelineInformation() {
        this.navigateToUrl(pipelineEndpoint, false);
    }

    navigateToMirSearch() {
        this.navigateToUrl(mirSearchUrl, true);
    }

    navigateToAmcpDossiers() {
        this.navigateToUrl(amcpDossiersEndpoint, false);
    }

    navigateToUrl(endpoint, openInNewTab) {
        const url = endpoint.startsWith(httpProtocol) ? endpoint : `${this.mheedomain}${endpoint}`;

        if (openInNewTab) {
            // Open the URL in a new tab
            const a = document.createElement('a');
            a.href = url;
            a.target = '_blank';
            a.rel = 'noopener noreferrer';
            a.click();
        } else {
            // Open the URL in the same tab
            window.location.href = url;
        }
    }

    handleMouseOver(event) {
        const arrowIcon = event.currentTarget.querySelector('img.arrow');
        if (arrowIcon) {
            arrowIcon.classList.add('hidden');
            arrowIcon.nextElementSibling.classList.remove('hidden');
        }
    }

    handleMouseOut(event) {
        const arrowIcon = event.currentTarget.querySelector('img.arrow');
        if (arrowIcon) {
            arrowIcon.classList.remove('hidden');
            arrowIcon.nextElementSibling.classList.add('hidden');
        }
    }
}