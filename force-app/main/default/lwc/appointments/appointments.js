import { LightningElement, track, api, wire } from 'lwc';
import arrow from '@salesforce/resourceUrl/rightarrow2';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import USER_ID from "@salesforce/user/Id";
import defaultTimeZone from '@salesforce/label/c.defaulttimezone';
import getUserInfo from '@salesforce/apex/MSD_CORE_ProductList.getUserInfo';
import warrow from '@salesforce/resourceUrl/whitearrow';
import getSiteNameAndAPIName from '@salesforce/apex/MSD_CORE_MFRSitePageConfiguration.getSiteNameAndAPIName';

/**Apex Class */
import getRequest from '@salesforce/apex/MSD_CORE_RequestController.getRequest';
const monthNames = ["January", "February", "March", "April", "May", "June",
										"July", "August", "September", "October", "November", "December"
									 ];
const monthShortNames = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN",
												 "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"
												];
export default class Appointments extends NavigationMixin(LightningElement) {
		rightarrow = arrow
		error;
		@track norecordsfound;
		@track recordsToDisplay
		@api requestType
		@api totalCount
		@track prodlstpage;
		@track prodlstpageapi;
		pageSize = 6
		pageNumber = 1
		isLoading = false;
		userId = USER_ID;
		Whitearrow = warrow;
		@api prodid;
		urlStateParameters;
		pending = false;
		closed = false;
		appointment = false;
		@track singledate;
		@track labelvalTime = true;
		@track isrecordsToDisplay;
		@track setDefaultime;
		@track timezonetype;
		@track contactrole = '';

		@track noTitle = false;

		@track pagelabel;
		@track productName;
		// @wire(CurrentPageReference)
		// getStateParameters(currentPageReference) {
		//     if (currentPageReference) {
		//         this.urlStateParameters = currentPageReference.state;
		//         console.log('urlStateParameters-->',this.urlStateParameters);
		//         this.ProdId = this.urlStateParameters.recordId;
		//         console.log('this.ProdId' + this.ProdId);
		//     }
		// }
		@wire(getUserInfo, { userId: USER_ID })
		wireuser({ error, data }) {
				if (error) {
						this.error = error;
				} else if (data) {
						console.log('inside wire' + data);
						console.log(JSON.stringify(data));
						this.setDefaultime = data.TimeZoneSidKey;
						console.log('this.setDefaultime' + this.setDefaultime);
						this.timezonetype = 'short';
				}
		}
		connectedCallback() {
				this.gesitename();
				if (this.requestType == 'Pending') {
						console.log('iff');
						this.pending = true;
						this.pagelabel = "view request";
						console.log('this.pending==>', this.pending);
				} else if (this.requestType == 'Rejected') {
						console.log('else');
						this.closed = true;
						this.pagelabel = "view request";
						console.log('this.closed-->', this.closed);
				} else {
						this.pagelabel = "view appointments";
						this.appointment = true;
				}
				this.contactrole = sessionStorage.getItem('SFMC_Audience');
		}

		@wire(getRequest, { requestType: '$requestType', pageSize: '$pageSize', pageNumber: '$pageNumber', product: '$prodid', userid: USER_ID })
		wiredGetRequest(value) {
				console.log('Wired Called');
				console.log({ value });
				console.log('aa');
				const { data, error } = value;
				if (data) {
						if(data.length > 0){
								this.isrecordsToDisplay = true;
								console.log('Data Length in appointment is '+data.length);
								console.log({ data });
								this.productName = data[0].MSD_CORE_Product_Payor__r.Name;
								console.log('this.productName->'+this.productName+'--'+this.productName.includes('KEYTRUDA'));
								if(data[0].MSD_CORE_Product_Payor__r.MSD_CORE_Remove_Title_Description__c){
									this.noTitle = true;
								}
								this.isLoading = true;
								console.log('mkmkm');
								for (var key in data) {
										console.log({ key });
										if (data[key].Meeting_Times__r) {
												console.log('TEST Meeting times entry-->' + JSON.stringify(data[key].Meeting_Times__r));
												console.log('TEST Meeting times entry length-->' + JSON.stringify(data[key].Meeting_Times__r.length));
												console.log('MEET TIme');
												if (data[key].Meeting_Times__r.length == 1) {
														console.log('IFFFF');
														this.singledate = true;
														console.log('this.singledate-->', this.singledate);
												} else {
														this.singledate = false;
												}
										}
										else {
												this.singledate = false;
										}
								}

								for (var key in this.recordsToDisplay) {
										var nameval = this.recordsToDisplay[key].Name;
										nameval = nameval.slice(3);;
										console.log({ nameval });
										nameval = '#' + nameval;
										this.recordsToDisplay[key].Name = nameval;
								}
								this.recordsToDisplay = this.getRequestMappedValue(data);
								console.log('this.recordsToDisplay===>', this.recordsToDisplay);
								document.body.scrollTop = document.documentElement.scrollTop = 0;
								// rootElement.scrollTo({
								//     top: 0,
								//     behavior: "smooth"
								//   })

								/** RR E2ESE-1011 - Add property isViewUponReq in data set */
								this.recordsToDisplay = this.recordsToDisplay.map(row => ({
										...row,
										isViewUponReq: row.MSD_CORE_Resource__r.MSD_CORE_Delivery_Framework__c === 'View upon Request'
								}));
								if(this.recordsToDisplay.length > 0){
										this.isrecordsToDisplay = true;
								}else if(this.recordsToDisplay.length === 0){
										this.isrecordsToDisplay = false;
								}

						}else if(data.length === 0){
								if(this.requestType == 'Approved'){
										this.norecordsfound = 'You don\'t have any appointments at this time.';
										this.isrecordsToDisplay = false;
								}else if(this.requestType == 'Pending'){
										this.norecordsfound = 'You don\'t have any pending requests at this time.';
										this.isrecordsToDisplay = false;
								}else if(this.requestType == 'Rejected'){
										this.norecordsfound ='You don\'t have any closed requests at this time.';
										this.isrecordsToDisplay = false;
								}
						}

						this.isLoading = false;
				} else if (error) {
						console.log('ERROR ::::');
						console.log({ error });
						this.error = error;
						console.log(this.error);
				}
		}

		viewRequest(event) {
				console.log('INside View Request');
				var appointmentId = event.currentTarget.dataset.id;
				console.log('appointmentId--->', appointmentId);
				var resourcename = event.currentTarget.dataset.mname;
				console.log({resourcename});
				console.log({ event });

				if (appointmentId.length != 0 || appointmentId != null || appointmentId != undefined) {
						this.fireDataLayerEvent('button','', this.pagelabel,'','detail__c','/library/detail',resourcename); 
						console.log("id is available");
						// let toNavigateUrl = '/library/viewschedule?recordId='+`${appointmentId}`;
						// console.log('entered')
						// this.navigateToNewRecordPage(toNavigateUrl);

						var pageapi;
						var pagename;
						getSiteNameAndAPIName({ pageName: 'viewschedule' })
								.then((result) => {
								console.log('getSiteNameAndAPIName-->' + JSON.stringify(result));
								pageapi = result.siteName;
								pagename = result.siteAPIName;
								// pageapi = 'viewschedule__c';
								// pagename = '/library/viewschedule';
								//detail?recordId=a8M7X0000004V6GUAU&tab=Librarydetail
								this[NavigationMixin.Navigate]({
										// type: 'comm__namedPage',
										type: 'standard__webPage',
										attributes: {
												name: pageapi,
												url: pagename+'?recordId='+appointmentId
										},
										// state: {
										//     recordId: appointmentId
										// }
								});
						})
								.catch((error) => {
								console.log('error-->' + error);
								this.error = error;
						});
						/*  setTimeout(() => {
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    name: pageapi,
                    url: pagename
                },
                state: {
                    recordId: appointmentId
                }
            });
        }, 1200);*/
				}
				else {
						console.log("id is null");
				}

				//alert(this.prodId);
				// let toNavigateUrl = '/library/viewschedule?recordId='+`${appointmentId}`;
				// console.log('entered')
				// this.navigateToNewRecordPage(toNavigateUrl);


		}


		//   navigateToNewRecordPage(url) {
		//     console.log('toNavigateUrl=='+url);
		//     this[NavigationMixin.Navigate]({
		//         type: 'standard__webPage',
		//         attributes: {
		//             url: url
		//         }
		//     });
		// }
		getRequestMappedValue(RequestData) {
				let _requestData = RequestData.map(
						record =>
						Object.assign({ "Status": (record.MSD_CORE_Status__c != null && record.MSD_CORE_Status__c == 'Approved') ? 'Scheduled' : (record.MSD_CORE_Status__c != null && (record.MSD_CORE_Status__c == 'Rejected' || record.MSD_CORE_Status__c == 'Closed')) ? 'Closed' : 'Pending' },
													{ "Day": this.getDay(record.Start_DateTime_vod__c) },
													{ "Month": this.getMonth(record.Start_DateTime_vod__c) },
													{ "Time": this.getTime(record.Start_DateTime_vod__c) },
													{ "SubmittedDate": this.getSubmittedDate(record.CreatedDate) },
													record
												 )

				);
				console.log('_requestData11' + JSON.stringify(_requestData));
				console.log('Day = ' + this.getDay);
				return _requestData;
		}
		getDay(date) {
				let d = new Date(date);
				console.log('Day = ' + this.getDay);
				return d.getDate();
		}
		getMonth(date) {
				let d = new Date(date);
				return monthShortNames[d.getMonth()];
		}
		getYear(date) {
				let d = new Date(date);
				return d.getFullYear();
		}
		getFullMonth(date) {
				let d = new Date(date);
				return monthNames[d.getMonth()];
		}
		getTime(date) {
				let d = new Date(date);
				let time = d.toLocaleTimeString('en-US', { timeZone: 'America/New_York' });
				let AMPM = time.substring(time.length - 2, time.length);
				let tempTime = time.substring(0, 4);
				return tempTime + ' ' + AMPM;

		}
		getSubmittedDate(date) {
				//return 'Submitted ' + this.getFullMonth(date) + ' '+ this.getDay(date)+ ' , ' + this.getYear(date) + ' at ' + this.getTime(date);
				return date;
		}
		get setStatusCSS() {
				if (this.requestType == 'Approved') {
						return 'schedule-appointment__Scheduled-Approved';
				}
				else if (this.requestType == 'Pending') {
						return 'schedule-appointment__Scheduled-Pending';
				}
				else {
						return 'schedule-appointment__Scheduled-Rejected';
				}

		}
		handleRowActions(event) {
				window.console.log(' Row Level Action Handled ', event.detail.actionName);
				window.console.log(' Row Level Action Handled ', JSON.stringify(event.detail.data));
		}

		handlePagination(event) {
				//alert(event.detail.pageNo);
				console.log('handlePagination' + event.detail.pageNo);
				this.pageNumber = event.detail.pageNo;
				//window.console.log('Pagination Action Handled ', JSON.stringify(event.detail.records));
		} handleCustomEvent(event) {
				console.log('handlePagination ---- ' + event.detail);
				this.pageNumber = event.detail;
		}
		get showPagination() {
				return this.totalCount <= 6 ? false : true;
		}



		gesitename() {
				getSiteNameAndAPIName({ pageName: 'ProductList' })
						.then((result) => {
						this.prodlstpage = result.siteAPIName;
						this.prodlstpageapi = result.siteName;
				})
						.catch((error) => {
						console.log({ error });
						this.error = error;
				});
		}

		navigatepage(event) {
				let getnameval = event.currentTarget.dataset.name;
				console.log("Get name" + getnameval);
				if (getnameval == 'ProductList') {
						if (this.prodlstpageapi != undefined || this.prodlstpage != undefined) {
								this[NavigationMixin.Navigate]({
										type: 'standard__webPage',
										attributes: {
												name: this.prodlstpageapi,
												url: this.prodlstpage
										},
								});
						}
				} 
		}

		fireDataLayerEvent(category, action, label,moduleval,linkedtext,linkedurl,resourcename) {
				console.log('event triggered');
				this.dispatchEvent(new CustomEvent('datalayereventbrandcontent', {
						detail: {
								data_design_category: category,
								data_design_action: action,
								data_design_label: label,
								data_design_module:moduleval,
								page_type: 'product',
								page_purpose:'appointment',
								page_audience: 'payor',
								page_marketname: 'united_states',
								page_region: 'us',
								page_contentclassification: 'non-commercial',
								link_text:linkedtext,
								link_url:linkedurl,
								content_count:'',
								content_saved:'',
								content_appointments:'',
								content_requests:'',
								content_name:resourcename,
								page_localproductname:this.productName,        
								sfmc_id:USER_ID,
								sfmc_audience: this.contactrole,
								page_url: location.href,
								page_title: 'appointments',
						},
						bubbles: true,
						composed: true
				}));
		}
}