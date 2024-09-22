import { LightningElement } from 'lwc';
import bannerLogo from '@salesforce/resourceUrl/banner';
import SignupSubmit_Logo from '@salesforce/resourceUrl/SignupSubmit_Logo';
import SignupSubmit_Logo1 from '@salesforce/resourceUrl/SignupSubmit_Logo1';
import getSiteNameAndAPIName from '@salesforce/apex/MSD_CORE_MFRSitePageConfiguration.getSiteNameAndAPIName'; // to bring api names and urls of all pages dynamically
export default class MSD_CORE_Reset_Success extends LightningElement {
    bannerLogo = bannerLogo;
    SignupSubmit_Logo = SignupSubmit_Logo;
    SignupSubmit_Logo1= SignupSubmit_Logo1;
    navigatelearnmore;
    navigatelearnmorename;
    navigatesingup;
    navigatesingupname;
    navigatelogin;
    navigateloginname;
    navigateWelcome;
    navigateWelcomeName;

    connectedCallback() {
        this.getsitename(); // to bring api names and urls of all pages dynamically
    }

    getsitename() {
        eNameAndAPIName({ pageName: 'Learnmore' })
        .then((result) => {
            console.log({ result });
            this.navigatelearnmore = result.siteAPIName;
            this.navigatelearnmorename = result.siteName;
        })
        .catch((error) => {
            console.log(' User Calling Error' + JSON.stringify(error));
            this.error = error;
        });

        getSiteNameAndAPIName({ pageName: 'Signup' })
        .then((result) => {
            console.log({ result });
            this.navigatesingup = result.siteAPIName;
            this.navigatesingupname = result.siteName;
        })
        .catch((error) => {
            console.log(' User Calling Error' + JSON.stringify(error));
            this.error = error;
        });

        getSiteNameAndAPIName({ pageName: 'login' })
        .then((result) => {
            console.log({ result });
            this.navigatelogin = result.siteAPIName;
            this.navigateloginname = result.siteName;
        })
        .catch((error) => {
            console.log(' User Calling Error' + JSON.stringify(error));
            this.error = error;
        });

        getSiteNameAndAPIName({ pageName: 'Welcomepage' })
        .then((result) => {
            console.log({ result });
            this.navigateWelcome = result.siteAPIName;
            this.navigateWelcomeName = result.siteName;
        })
        .catch((error) => {
            console.log('User Calling Error' + JSON.stringify(error));
            this.error = error;
        });
    } 

    welcomePageClick() {
        window.location.href = this.navigateWelcome;
    }

    // for onlclick on singup button
    sinupclick(){
        window.location.href = this.navigatesingup;
    }
    
    // for onlclick on login button
    loginclick(){
        window.location.href = this.navigatelogin;
    }
}