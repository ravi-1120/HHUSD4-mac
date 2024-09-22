import { LightningElement, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import banner from '@salesforce/resourceUrl/PurpleBanner';
import getAllSiteNameAndAPINames from '@salesforce/apex/MSD_CORE_MHEESitePageConfiguration.getAllSiteNameAndAPINames';
import USER_ID from "@salesforce/user/Id";
import domainurl from '@salesforce/label/c.MSD_CORE_Domain_URL';

export default class MSD_CORE_AMCP_Dossiers extends LightningElement {
bannerimg = banner;
    siteAPINames;
    siteNames;
    domainurl = domainurl;
    
    @wire(CurrentPageReference)
    handlePageReference() {
        // Handle page reference if needed
    }

    @wire(getAllSiteNameAndAPINames)
    handleSiteNames({ error, data }) {
        if (data) {
            this.siteAPINames = data.siteAPINames;
            this.siteNames = data.siteNames;
        } else if (error) {
            console.error('Error fetching site names:', error);
        }
    }

    handleNavigateDashboard() {
        this.fireDataClickEvent(
            "top_nav_breadcrumb",
            '',
            'Dashboard',
            'navigation',
            this.siteNames.Dashboard,
            this.siteAPINames.Dashboard
        );
    }

    handleNavigateAllResources() {
       var url = this.domainurl+'/all-resources';
       window.location.href = url;
    }

    fireDataClickEvent(category, action, label, module, linkedtext, linkedurl) {
        this.dispatchEvent(new CustomEvent('fireDataClickEvent', {
            detail: {
                data_design_category: category,
                data_design_action: action,
                data_design_label: label,
                data_design_module: module,
                page_type: 'resource',
                page_purpose: 'product listing',
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
                page_url: window.location.href,
                page_title: 'pipeline',
            },
            bubbles: true,
            composed: true
        }));
    }
}