import { LightningElement, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import banner from '@salesforce/resourceUrl/PurpleBanner';
import getAllSiteNameAndAPINames from '@salesforce/apex/MSD_CORE_MHEESitePageConfiguration.getAllSiteNameAndAPINames';
import USER_ID from "@salesforce/user/Id";
import DASHBOARD_LABEL from '@salesforce/label/c.MSD_CORE_MHEE_Dashboard_Label';
import ALL_RESOURCES_LABEL from '@salesforce/label/c.MSD_CORE_MHEE_All_Resources_Label';
import RESOURCE_CATALOG_LABEL from '@salesforce/label/c.MSD_CORE_MHEE_Resource_Catalog';
import RESOURCES_DESCRIPTION_LABEL from '@salesforce/label/c.MSD_CORE_MHEE_Resources_Description';
import RESOURCES_CATALOG_DESCRIPTION_LABEL from '@salesforce/label/c.MSD_CORE_MHEE_Resource_Catalog_Desc';

export default class MSD_CORE_Resource_Catalog extends NavigationMixin(LightningElement) {
    bannerimg = banner;
    siteAPINames;
    siteNames;

    dashboard = DASHBOARD_LABEL;
    allResources = ALL_RESOURCES_LABEL;
    resourceCatalog = RESOURCE_CATALOG_LABEL;
    resourcesDescription = RESOURCES_DESCRIPTION_LABEL;
    resourcesCatalogDescription = RESOURCES_CATALOG_DESCRIPTION_LABEL;

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