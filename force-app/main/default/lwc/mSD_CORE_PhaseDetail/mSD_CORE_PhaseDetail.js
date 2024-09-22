import { LightningElement, api,  track } from 'lwc';

export default class MSD_CORE_PhaseDetail extends LightningElement {

    @api phaseDetail
    content;

    connectedCallback() {
        this.displayPhaseDetail(this.phaseDetail);
    }
    displayPhaseDetail(phaseDetail) {
        console.log('_width ' + phaseDetail.length)

        let html = "<p class='content-heder'>" + phaseDetail.Name + "</p>";
        let bgcolor= ''
        let fontcolor = ''
        if(phaseDetail.MSD_CORE_Medical_Therapeutic_Area__r == undefined || phaseDetail.MSD_CORE_Medical_Therapeutic_Area__r == null){
            bgcolor = '#FFFFFF';
            fontcolor = '#000000';
        }else{
            bgcolor = phaseDetail.MSD_CORE_Medical_Therapeutic_Area__r.MSD_CORE_BG_color__c;
            fontcolor = phaseDetail.MSD_CORE_Medical_Therapeutic_Area__r.MSD_CORE_Text_color__c;
        }
        let isRespDisease = false;
        if(phaseDetail.MSD_CORE_Therapeutic__c.indexOf('Respiratory')>-1){
            isRespDisease = true;
        }
        html += "<p class='content-bottom-div' style='background-color: " + bgcolor + ";width:" + this.getCalculatedWidth(phaseDetail.MSD_CORE_Therapeutic__c.length,isRespDisease) + "px'><span class='content-bottom' style='color:" + fontcolor + "'> " + phaseDetail.MSD_CORE_Therapeutic__c + " </span></p>";

        setTimeout(() => {
            let element = this.template.querySelector('.phasedetail')
            element.innerHTML = html

        }, 50);

    }
    getCalculatedWidth(width,isRespDisease){
        let _width = 0;
        _width = width;

        if (_width < 9) {
            _width = (width * 10) + 4;
        }
        else if (_width < 14) {
            _width = (width * 10) - 12;
        } else if (_width < 19) {
            _width = (width * 10) - 32;
        } else if (_width < 23) {
            _width = (width * 8) - 0;
        } else if (_width < 27) {
            if(isRespDisease){
                _width = (width * 9) - 13;
            }else{
            _width = (width * 9) - 20;
            }
        } else {
            _width = (width * 10) - 35;
        }
        return _width;
    }

}