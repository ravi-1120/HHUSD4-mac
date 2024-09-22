import { LightningElement, track,api } from 'lwc';
// import getBannerConfigs from '@salesforce/apex/HEQ_BannerController.getBannerConfigs';
// import getUserProfileName from '@salesforce/apex/HEQ_BannerController.getUserProfileName';
// import USER_ID from '@salesforce/user/Id';
// import getUser from '@salesforce/apex/HEQ_HeaderController.getuser';
// import getStaticResourceURL from '@salesforce/apex/HEQ_BannerController.getStaticResourceURL';
import BANNER_STYLES from '@salesforce/resourceUrl/hEQ_Carousel';
import { loadStyle } from 'lightning/platformResourceLoader';
// import { loadScript } from 'lightning/platformResourceLoader';
import HEQ_Banner_1 from '@salesforce/resourceUrl/HEQ_Banner_1'

export default class HEQ_Carousel extends LightningElement {
//     @track banners = [];
//     @track error;
//     userId = USER_ID;
        HEQ_Banner_1= HEQ_Banner_1;

        connectedCallback() {
            this.loadStyles();
        }
    
    

//     connectedCallback() {
//         this.loadStyles();
//         console.log('USER_ID->' + USER_ID);
//         getUser({ userId: USER_ID })
//             .then(result => {
//                 console.log('result for Carousel Component ->' + JSON.stringify(result));
//                 console.log('profile name for Carousel Component' + result.Profile.Name);
//                 this.fetchBannerConfigs(result.Profile.Name);
//             })
//             .catch(error => {
//                 console.error('Error in getUser for Carousel Component:', error);
//                 this.fetchBannerConfigs(null);
//             });
//             console.log('HEQ_Banner_1' +HEQ_Banner_1);
//     }

//     loadStaticResource(resourceName) {
//         loadScript(this, resourceName)
//             .then((url) => {
//                 this.resourceUrl = url;
//                 console.log('Resource URL:', this.resourceUrl);
//             })
//             .catch((error) => {
//                 console.error('Error loading script:', error);
//             });
//     }


    loadStyles() {
        loadStyle(this, BANNER_STYLES)
            .then(() => {
                console.log('Styles loaded successfully for Carousel Component.');
            })
            .catch(error => {
                console.error('Error loading styles for Carousel Component:', error);
            });
    }

//     fetchBannerConfigs(userProfileName) {
//         console.log('userProfileName for fetchBannerConfigs for Carousel Component', userProfileName);
//         getBannerConfigs()
//             .then(bannerConfigs => {
//                 console.log('Banner Configs for Carousel Component:', JSON.stringify(bannerConfigs));
//                 this.banners = bannerConfigs.filter(banner =>
//                     banner.Profile__c && banner.Profile__c.split(',').includes(userProfileName)
//                 ).map(banner => {
//                     return this.getBannerWithImageUrl(banner);
//                 });
//                 console.log('Filtered Banners for Carousel Component:', JSON.stringify(this.banners));
//                 this.loadStaticResource('HEQ_Banner_1');

//                 let filteredObjects = bannerConfigs.filter(obj => obj.Profile__c === userProfileName);
// let urls = filteredObjects.map(obj => obj.Banner_URL__c);
// console.log('Let Urls'+ urls);
//             })
//             .catch(error => {
//                 this.error = 'Error in getBannerConfigs for Carousel Component: ' + error.body.message;
//                 console.error('Error in getBannerConfigs for Carousel Component:', error);
//             });
//     }

//     async getBannerWithImageUrl(banner) {
//         let imageUrl = await this.getImageUrlForDevice(banner);
//         return {
//             ...banner,
//             imageUrl
//         };
//     }

//     async getImageUrlForDevice(banner) {
//         let width = window.innerWidth;
//         let imageUrl;
//         if (width <= 767) {
//             imageUrl = await getStaticResourceURL({ resourceName: banner.Mobile_Image_URL__c });
//         } else if (width >= 768 && width <= 1027) {
//             imageUrl = await getStaticResourceURL({ resourceName: banner.Tab_Image_URL__c });
//         } else {
//             imageUrl = await getStaticResourceURL({ resourceName: banner.Banner_URL__c });
//         }
//         console.log('Static Resource URL for device:', imageUrl);
//         return imageUrl;
//     }

//     getUrlParamValue(url, key) {
//         return new URL(url).searchParams.get(key);
//     }
}