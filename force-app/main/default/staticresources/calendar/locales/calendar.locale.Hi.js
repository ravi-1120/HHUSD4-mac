/*!
 *
 * Bryntum Calendar 5.6.0
 *
 * Copyright(c) 2023 Bryntum AB
 * https://bryntum.com/contact
 * https://bryntum.com/license
 *
 */
(function(s,n){var i=typeof exports=="object";if(typeof define=="function"&&define.amd)define([],n);else if(typeof module=="object"&&module.exports)module.exports=n();else{var p=n(),u=i?exports:s;for(var m in p)u[m]=p[m]}})(typeof self<"u"?self:void 0,()=>{var s={},n={exports:s},i=Object.defineProperty,p=Object.getOwnPropertyDescriptor,u=Object.getOwnPropertyNames,m=Object.prototype.hasOwnProperty,h=(e,t,a)=>t in e?i(e,t,{enumerable:!0,configurable:!0,writable:!0,value:a}):e[t]=a,v=(e,t)=>{for(var a in t)i(e,a,{get:t[a],enumerable:!0})},b=(e,t,a,r)=>{if(t&&typeof t=="object"||typeof t=="function")for(let o of u(t))!m.call(e,o)&&o!==a&&i(e,o,{get:()=>t[o],enumerable:!(r=p(t,o))||r.enumerable});return e},f=e=>b(i({},"__esModule",{value:!0}),e),E=(e,t,a)=>(h(e,typeof t!="symbol"?t+"":t,a),a),g={};v(g,{default:()=>x}),n.exports=f(g);var y=class d{static mergeLocales(...t){let a={};return t.forEach(r=>{Object.keys(r).forEach(o=>{typeof r[o]=="object"?a[o]={...a[o],...r[o]}:a[o]=r[o]})}),a}static trimLocale(t,a){let r=(o,l)=>{t[o]&&(l?t[o][l]&&delete t[o][l]:delete t[o])};Object.keys(a).forEach(o=>{Object.keys(a[o]).length>0?Object.keys(a[o]).forEach(l=>r(o,l)):r(o)})}static normalizeLocale(t,a){if(!t)throw new Error('"nameOrConfig" parameter can not be empty');if(typeof t=="string"){if(!a)throw new Error('"config" parameter can not be empty');a.locale?a.name=t||a.name:a.localeName=t}else a=t;let r={};if(a.name||a.locale)r=Object.assign({localeName:a.name},a.locale),a.desc&&(r.localeDesc=a.desc),a.code&&(r.localeCode=a.code),a.path&&(r.localePath=a.path);else{if(!a.localeName)throw new Error(`"config" parameter doesn't have "localeName" property`);r=Object.assign({},a)}for(let o of["name","desc","code","path"])r[o]&&delete r[o];if(!r.localeName)throw new Error("Locale name can not be empty");return r}static get locales(){return globalThis.bryntum.locales||{}}static set locales(t){globalThis.bryntum.locales=t}static get localeName(){return globalThis.bryntum.locale||"En"}static set localeName(t){globalThis.bryntum.locale=t||d.localeName}static get locale(){return d.localeName&&this.locales[d.localeName]||this.locales.En||Object.values(this.locales)[0]||{localeName:"",localeDesc:"",localeCoode:""}}static publishLocale(t,a){let{locales:r}=globalThis.bryntum,o=d.normalizeLocale(t,a),{localeName:l}=o;return!r[l]||a===!0?r[l]=o:r[l]=this.mergeLocales(r[l]||{},o||{}),r[l]}};E(y,"skipLocaleIntegrityCheck",!1);var c=y;globalThis.bryntum=globalThis.bryntum||{},globalThis.bryntum.locales=globalThis.bryntum.locales||{},c._$name="LocaleHelper";var T={localeName:"Hi",localeDesc:"हिन्दी",localeCode:"hi",Object:{Yes:"हाँ",No:"नहीं",Cancel:"रद्द करें",Ok:"ओके",Week:"सप्ताह",None:"कोई नहीं"},ColorPicker:{noColor:"कोई रंग नहीं"},Combo:{noResults:"कोई परिणाम नहीं",recordNotCommitted:"रिकॉर्ड जोड़ा नहीं जा सका",addNewValue:e=>`जोड़ें  ${e}`},FilePicker:{file:"फाइल"},Field:{badInput:"अमान्य फील्ड मान",patternMismatch:"मान को विशिष्ट पैटर्न के अनुरूप होना चाहिए",rangeOverflow:e=>`मान को ${e.max} से कम या बराबर होना चाहिए`,rangeUnderflow:e=>`मान को ${e.min} से अधिक या बराबर होना चाहिए `,stepMismatch:"मान इस स्टेप से फिट होना चाहिए",tooLong:"मान छोटा होना चाहिए",tooShort:"मान अधिक लंबा होना चाहिए",typeMismatch:"मान को विशेष फार्मेट में होना चाहिए",valueMissing:"यह फील्ड आवश्यक है",invalidValue:"अमान्य फील्ड मान",minimumValueViolation:"न्यूनतम मान उल्लंघन",maximumValueViolation:"अधिकतम मान उल्लंघन",fieldRequired:"यह फील्ड आवश्यक है",validateFilter:"इस सूची के लिए मान चुना जाना चाहिए"},DateField:{invalidDate:"अमान्य तारीख इनपुट"},DatePicker:{gotoPrevYear:"पिछले साल पर जाएं",gotoPrevMonth:"पिछले महीने पर जाएं",gotoNextMonth:"अगले महीने पर जाएं",gotoNextYear:"अगले साल पर जाएं"},NumberFormat:{locale:"hi",currency:"INR"},DurationField:{invalidUnit:"अमान्य इकाई"},TimeField:{invalidTime:"अमान्य समय इनपुट"},TimePicker:{hour:"साल",minute:"मिनट",second:"सेकंड"},List:{loading:"लोड कर रहा है...",selectAll:"सभी का चयन करें"},GridBase:{loadMask:"लोड कर रहा है...",syncMask:"बदलाव सहेज रहा है, कृपया प्रतीक्षा करें..."},PagingToolbar:{firstPage:"पहले पेज पर जाएं",prevPage:"पिछले पेज पर जाएं",page:"पेज",nextPage:"अगले पेज पर जाएं",lastPage:"पिछले पेज पर जाएं",reload:"वर्तमान पेज रीलोड करें",noRecords:"दर्शाने के लिए कोई रिकॉर्ड नहीं",pageCountTemplate:e=>`${e.lastPage} का`,summaryTemplate:e=>`${e.allCount} का ${e.start} - ${e.end} का रिकॉर्ड दर्शा रहा है`},PanelCollapser:{Collapse:"समेटें",Expand:"फैलाएं"},Popup:{close:"पॉपअप बंद करें"},UndoRedo:{Undo:"अनडू करें",Redo:"रीडू करें",UndoLastAction:"पिछला ऐक्शन अनडू करें",RedoLastAction:"पिछला ऐक्शन रीडू करें",NoActions:"कतार अनडू करें में कोई आइटम नहीं है"},FieldFilterPicker:{equals:"बराबर है",doesNotEqual:"बराबर नहीं है",isEmpty:"खाली है",isNotEmpty:"खाली नहीं है",contains:"शामिल है",doesNotContain:"शामिल नहीं है",startsWith:"के साथ शुरू होता है",endsWith:"के साथ अंत होता है",isOneOf:"इनमें से एक है",isNotOneOf:"इनमें से एक नहीं है",isGreaterThan:"इससे बड़ा है",isLessThan:"इससे छोटा है",isGreaterThanOrEqualTo:"इसके बराबर या बड़ा है",isLessThanOrEqualTo:"इसके बराबर या छोटा है",isBetween:"बीच में है",isNotBetween:"बीच में नहीं है",isBefore:"पहले है",isAfter:"बाद में है",isToday:"आज है",isTomorrow:"आगामी कल है",isYesterday:"बीते कल है",isThisWeek:"इस सप्ताह है",isNextWeek:"अगले सप्ताह है",isLastWeek:"पिछले सप्ताह हैं",isThisMonth:"इस माह है",isNextMonth:"अगले माह है",isLastMonth:"पिछले माह है",isThisYear:"इस साल है",isNextYear:"अगले साल है",isLastYear:"पिछले साल है",isYearToDate:"साल से आज तक है",isTrue:"सच है",isFalse:"असत्य है",selectAProperty:"कोई गुण चुनें",selectAnOperator:"कोई ऑपरेटर चुनें",caseSensitive:"केस-संवेदी",and:"और",dateFormat:"D/M/YY",selectValue:"कोई मान चुनें",selectOneOrMoreValues:"एक या अधिक मान चुनें",enterAValue:"एक मान दर्ज करें",enterANumber:"एक संख्या दर्ज करें",selectADate:"एक तारीख चुनें"},FieldFilterPickerGroup:{addFilter:"फिल्टर जोड़ें"},DateHelper:{locale:"hi",weekStartDay:1,nonWorkingDays:{0:!0,6:!0},weekends:{0:!0,6:!0},unitNames:[{single:"मिलीसेकंड",plural:"मिलीसेकंड",abbrev:"मिसे"},{single:"सेकंड",plural:"सेकंड",abbrev:"से"},{single:"मिनट",plural:"मिनट",abbrev:"मि"},{single:"घंटा",plural:"घंटे",abbrev:"घं"},{single:"दिन",plural:"दिन",abbrev:"दि"},{single:"हफ्ता",plural:"हफ्ते",abbrev:"ह"},{single:"महीना",plural:"महीने",abbrev:"माह"},{single:"तिमाही",plural:"तिमाही",abbrev:"ति"},{single:"साल",plural:"साल",abbrev:"सा"},{single:"दशक",plural:"दशक",abbrev:"द"}],unitAbbreviations:[["मिसे"],["से","से"],["मि","मि"],["घं","घं"],["दि"],["ह","ह"],["माह","माह","माह"],["ति","ति","ति"],["सा","सा"],["द"]],parsers:{L:"MM/DD/YYYY",LT:"HH:mm A",LTS:"HH:mm:ss A"},ordinalSuffix:e=>{let t={1:"",2:"",3:"",4:"",6:"",7:"",8:"",9:""}[e]||"वां";return e+t}}},L=c.publishLocale(T),C=new String,S={localeName:"Hi",localeDesc:"हिन्दी",localeCode:"hi",ColumnPicker:{column:"कॉलम",columnsMenu:"कॉलम",hideColumn:"कॉलम छिपाएं",hideColumnShort:"छिपाएं",newColumns:"नए कॉलम"},Filter:{applyFilter:"फिल्टर लागू करें",filter:"फिल्टर",editFilter:"फिल्टर संपादित करें",on:"पर",before:"पहले",after:"बाद में",equals:"के बराबर",lessThan:"से कम",moreThan:"से अधिक",removeFilter:"फिल्टर हटाएं",disableFilter:"फिल्टर अक्षम करें"},FilterBar:{enableFilterBar:"फिल्टर बार दिखाएं",disableFilterBar:"फिल्टर बार छिपाएं"},Group:{group:"समूहित करें",groupAscending:"आरोही समूहित करें",groupDescending:"अवरोही समूहित करें",groupAscendingShort:"आरोही",groupDescendingShort:"अवरोही",stopGrouping:"समूहित करना बंद करें",stopGroupingShort:"बंद करें"},HeaderMenu:{moveBefore:e=>`"${e}" से पहले ले जाएं`,moveAfter:e=>`"${e}" के बाद ले जाएं`,collapseColumn:"कॉलम कोलैप्स करें",expandColumn:"कॉलम फैलाएं"},ColumnRename:{rename:"नाम बदलें"},MergeCells:{mergeCells:"सेल मर्ज करें",menuTooltip:"इस कॉलम द्वारा छांटते समय समान मान वाले सेल मर्ज करें"},Search:{searchForValue:"मान की खोज करें"},Sort:{sort:"छांटें",sortAscending:"आरोही छांटें",sortDescending:"अवरोही छांटें",multiSort:"एकाधिक छांटें",removeSorter:"छांटने वाला निकालें",addSortAscending:"आरोही छांटने वाला जोड़ें",addSortDescending:"अवरोही छांटने वाला जोड़ें",toggleSortAscending:"आरोही में बदलें",toggleSortDescending:"अवरोही में बदलें",sortAscendingShort:"आरोही",sortDescendingShort:"अवरोही",removeSorterShort:"हटाएं",addSortAscendingShort:"+ आरोही",addSortDescendingShort:"+ अवरोही"},Split:{split:"विभाजित",unsplit:"अविभाजित",horizontally:"क्षैतिजता से",vertically:"लंबवत",both:"दोनों"},Column:{columnLabel:e=>`${e.text?`${e.text} कॉलम. `:""}प्रसंग मेनू के लिए SPACE पर टैप करें${e.sortable?", सॉर्ट करने के लिए ENTER":""}`,cellLabel:C},Checkbox:{toggleRowSelect:"पंक्ति चयन टॉगल करें",toggleSelection:"पूरे डेटासेट का चयन टॉगल करें"},RatingColumn:{cellLabel:e=>{var t;return`${e.text?e.text:""} ${(t=e.location)!=null&&t.record?` रेटिंग : ${e.location.record.get(e.field)||0}`:""}`}},GridBase:{loadFailedMessage:"डेटा लोडिंग विफल रहा!",syncFailedMessage:"डेटा सिक्रोनाइजेशन विफल रहा!",unspecifiedFailure:"अनिर्दिष्ट विफलता",networkFailure:"नेटवर्क त्रुटि",parseFailure:"सर्वर प्रतिक्रिया पार्स करना विफल रहा",serverResponse:"सर्वर प्रतिक्रिया:",noRows:"दर्शाने के लिए कोई रिकॉर्ड नहीं है",moveColumnLeft:"बाएं सेक्शन पर जाएं",moveColumnRight:"दाएं सेक्शन पर जाएं",moveColumnTo:e=>`कॉलम को ${e} पर ले जाएं`},CellMenu:{removeRow:"हटाएं"},RowCopyPaste:{copyRecord:"कॉपी करें",cutRecord:"कट करें",pasteRecord:"पेस्ट करें",rows:"पंक्तियां",row:"पंक्ति"},CellCopyPaste:{copy:"कॉपी करें",cut:"कट करें",paste:"पेस्ट करें"},PdfExport:{"Waiting for response from server":"सर्वर प्रतिक्रिया की प्रतीक्षा कर रहा है...","Export failed":"एक्सपोर्ट विफल रहा","Server error":"सर्वर त्रुटि","Generating pages":"पेजों को जनरेट कर रहा है...","Click to abort":"रद्द करें"},ExportDialog:{width:"40em",labelWidth:"12em",exportSettings:"सेटिंग्स निर्यात करें",export:"एक्सपोर्ट करें",printSettings:"प्रिंट सेटिंग्स",print:"प्रिंट",exporterType:"पेजिनेशन नियंत्रित करें",cancel:"रद्द करें",fileFormat:"फाइल फार्मेट",rows:"पंक्तियां",alignRows:"पंक्तियां संरेखित करें",columns:"कॉलम",paperFormat:"पेपर फार्मेट",orientation:"अभिविन्यास",repeatHeader:"हेडर दोहराएं"},ExportRowsCombo:{all:"सभी पंक्तियां",visible:"दिखने वाली पंक्तियां"},ExportOrientationCombo:{portrait:"पोर्ट्रेट",landscape:"लैंडस्केप"},SinglePageExporter:{singlepage:"एकल पेज"},MultiPageExporter:{multipage:"एकाधिक पेज",exportingPage:({currentPage:e,totalPages:t})=>`निर्यात पृष्ठ ${e}/${t}`},MultiPageVerticalExporter:{multipagevertical:"एकाधिक पेज (लंबवत)",exportingPage:({currentPage:e,totalPages:t})=>`निर्यात पृष्ठ ${e}/${t}`},RowExpander:{loading:"लोडिंग",expand:"फैलाएं",collapse:"समेटें"},TreeGroup:{group:"द्वारा समूह बनाएं",stopGrouping:"समूह बनाना बंद करें",stopGroupingThisColumn:"इस स्तंभ का समूह विस्थापित न करें"}},k=c.publishLocale(S),D={localeName:"Hi",localeDesc:"हिन्दी",localeCode:"hi",Object:{newEvent:"नया ईवेंट"},ResourceInfoColumn:{eventCountText:e=>e+" ईवेंट"},Dependencies:{from:"से",to:"तक",valid:"मान्य",invalid:"अमान्य"},DependencyType:{SS:"भ-भ",SF:"त-भ",FS:"भ-त",FF:"त-त",StartToStart:"आरंभ से आरंभ तक",StartToEnd:"आरंभ से अंत तक",EndToStart:"अंत से आरंभ तक",EndToEnd:"अंत से अंत तक",short:["भ-भ","त-भ","भ-त","त-त"],long:["आरंभ से आरंभ तक","आरंभ से अंत तक","अंत से आरंभ तक","अंत से अंत तक"]},DependencyEdit:{From:"से",To:"तक",Type:"प्रकार",Lag:"पिछड़ाव","Edit dependency":"निर्भरता संपादित करें",Save:"सहेजें",Delete:"हटाएं",Cancel:"रद्द करें",StartToStart:"आरंभ से आरंभ तक",StartToEnd:"आरंभ से अंत तक",EndToStart:"अंत से आरंभ तक",EndToEnd:"अंत से अंत तक"},EventEdit:{Name:"नाम",Resource:"संसाधन",Start:"आरंभ",End:"अंत",Save:"सहेजें",Delete:"हटाएं",Cancel:"रद्द करें","Edit event":"ईवेंट संपादित करें",Repeat:"दोहराएं"},EventDrag:{eventOverlapsExisting:"इवेंट इस संसाधन के लिए मौजूदा ईवेंट को ओवरलैप करता है",noDropOutsideTimeline:"इवेंट को पूरी तरह से टाइमलाइन के बाहर नहीं छोड़ा जा सकता"},SchedulerBase:{"Add event":"ईवेंट जोड़ें","Delete event":"ईवेंट हटाएं","Unassign event":"ईवेंट असाइनमेंट निकालें",color:"रंग"},TimeAxisHeaderMenu:{pickZoomLevel:"ज़ूम करें",activeDateRange:"तारीख की रेंज",startText:"आरंभ तारीख",endText:"समापन तारीख",todayText:"आज"},EventCopyPaste:{copyEvent:"ईवेंट कॉपी करें",cutEvent:"ईवेंट कट करें",pasteEvent:"ईवेंट पेस्ट करें"},EventFilter:{filterEvents:"टास्क फिल्टर करें",byName:"नाम के आधार पर"},TimeRanges:{showCurrentTimeLine:"वर्तमान टाइमलाइन दिखाएं"},PresetManager:{secondAndMinute:{displayDateFormat:"ll LTS",name:"सेकंड"},minuteAndHour:{topDateFormat:"ddd MM/DD, hA",displayDateFormat:"ll LST"},hourAndDay:{topDateFormat:"ddd MM/DD",middleDateFormat:"LST",displayDateFormat:"ll LST",name:"दिन"},day:{name:"दिन/घंटे"},week:{name:"सप्ताह/घंटे"},dayAndWeek:{displayDateFormat:"ll LST",name:"सप्ताह/दिन"},dayAndMonth:{name:"माह"},weekAndDay:{displayDateFormat:"ll LST",name:"सप्ताह"},weekAndMonth:{name:"सप्ताह"},weekAndDayLetter:{name:"सप्ताह/सप्ताहांत"},weekDateAndMonth:{name:"माह/सप्ताह"},monthAndYear:{name:"माह"},year:{name:"साल"},manyYears:{name:"एकाधिक साल"}},RecurrenceConfirmationPopup:{"delete-title":"आप एक ईवेंट हटा रहे हैं","delete-all-message":"क्या आप इस ईवेंट की सभी घटनाएं हटाना चाहते हैं?","delete-further-message":"क्या आप इसे और इस ईवेंट की भविष्य की सभी घटनाओं को हटाना चाहते हैं, या केवल चयनित ईवेंट को हटाना चाहते हैं?","delete-further-btn-text":"भविष्य के सभी ईवेंट हटाएं","delete-only-this-btn-text":"केवल यह ईवेंट हटाएं","update-title":"आप एक दोहराव वाले ईवेंट को बदल रहे हैं","update-all-message":"क्या आप इस ईवेंट की सभी घटनाएं हटाना चाहते हैं?","update-further-message":"क्या आप केवल इस ईवेंट की घटना को बदलना चाहते हैं, या यह और भविष्य के सभी ईवेंट बदलना चाहते हैं?","update-further-btn-text":"भविष्य के सभी ईवेंट","update-only-this-btn-text":"केवल यह ईवेंट",Yes:"हाँ",Cancel:"रद्द करें",width:600},RecurrenceLegend:{" and ":" और ",Daily:"दैनिक","Weekly on {1}":({days:e})=>`${e} पर साप्ताहिक`,"Monthly on {1}":({days:e})=>`${e} पर मासिक`,"Yearly on {1} of {2}":({days:e,months:t})=>` ${t} के ${e} सलाना`,"Every {0} days":({interval:e})=>`प्रत्येक ${e} दिनों के अंतराल पर`,"Every {0} weeks on {1}":({interval:e,days:t})=>`प्रत्येक ${e} सप्ताह के अंतराल पर ${t} को`,"Every {0} months on {1}":({interval:e,days:t})=>`प्रत्येक ${e} महीनो के अंतराल पर  ${t} को`,"Every {0} years on {1} of {2}":({interval:e,days:t,months:a})=>`प्रत्येक ${e} सालों के अंतराल पर ${a} के ${t} को`,position1:"पहला",position2:"दूसरा",position3:"तीसरा",position4:"चौथा",position5:"पांचवां","position-1":"अंतिम",day:"दिन",weekday:"सप्ताह का दिन","weekend day":"सप्ताहांत का दिन",daysFormat:({position:e,days:t})=>`${e} ${t}`},RecurrenceEditor:{"Repeat event":"ईवेंट दोहराएं",Cancel:"रद्द करें",Save:"सहेजें",Frequency:"आवृत्ति",Every:"हर",DAILYintervalUnit:"दिन",WEEKLYintervalUnit:"हफ्ता(ते)",MONTHLYintervalUnit:"महीना(ने)",YEARLYintervalUnit:"साल",Each:"प्रत्येक","On the":"पर","End repeat":"अंत दोहराव","time(s)":"बार"},RecurrenceDaysCombo:{day:"दिन",weekday:"सप्ताह का दिन","weekend day":"सप्ताहांत का दिन"},RecurrencePositionsCombo:{position1:"पहला",position2:"दूसरा",position3:"तीसरा",position4:"चौथा",position5:"पांचवां","position-1":"अंतिम"},RecurrenceStopConditionCombo:{Never:"कभी नहीं",After:"के बाद","On date":"इस तारीख को"},RecurrenceFrequencyCombo:{None:"कोई दोहराव नहीं",Daily:"दैनिक",Weekly:"साप्ताहिक",Monthly:"मासिक",Yearly:"वार्षिक"},RecurrenceCombo:{None:"कोई नहीं",Custom:"कस्टम..."},Summary:{"Summary for":e=>` ${e} का सारांश`},ScheduleRangeCombo:{completeview:"पूरा शेड्यूल",currentview:"दिखने वाला शेड्यूल",daterange:"तारीख की रेंज",completedata:"पूरा शेड्यूल(सभी ईवेंट के लिए)"},SchedulerExportDialog:{"Schedule range":"शेड्यूल रेंज","Export from":"से","Export to":"तक"},ExcelExporter:{"No resource assigned":"कोई संसाधन असाइन नहीं"},CrudManagerView:{serverResponseLabel:"सर्वर प्रतिक्रिया:"},DurationColumn:{Duration:"अवधि"}},M=c.publishLocale(D),w={localeName:"Hi",localeDesc:"हिन्दी",localeCode:"hi",EventEdit:{Calendar:"कैलेन्डर","All day":"सारा दिन",day:"दिन",week:"सप्ताह",month:"महीना",year:"साल",decade:"दशक"},EventMenu:{duplicateEvent:"डुप्लीकेट ईवेंट",copy:"कॉपी करें"},Calendar:{Today:"आज",next:e=>`अगली ${e}`,previous:e=>`पिछली ${e}`,plusMore:e=>`+${e} और`,allDay:"सारा दिन",endsOn:e=>`समाप्ति तिथि ${e}`,weekOfYear:([e,t])=>`सप्ताह ${t}, ${e}`,loadFail:"कैलेंडर डेटा लोड विफल रहा। कृपया अपने सिस्टम प्रशासक से संपर्क करें"},CalendarDrag:{holdCtrlForRecurrence:"बार-बार होने वाले ईवेंट के लिए CTRL दबाएं"},CalendarMixin:{eventCount:e=>`${e||"शून्य"} ईवेंट`},EventTip:{"Edit event":"ईवेंट संपादित करें",timeFormat:"LST"},ModeSelector:{includeWeekends:"सप्ताहांत शामिल करें",weekends:"सप्ताहांत"},AgendaView:{Agenda:"एजेंडा"},MonthView:{Month:"महीना",monthUnit:"महीना"},WeekView:{weekUnit:"सप्ताह"},YearView:{Year:"साल",yearUnit:"साल",noEvents:"कोई घटनाएँ नहीं"},EventList:{List:"सूची",Start:"शुरू करें",Finish:"समाप्त करें",days:e=>`${e>1?`${e} `:""}दिन}`},DayView:{Day:"दिन",dayUnit:"दिन",daysUnit:"दिन",expandAllDayRow:"सारा-दिन सेक्शन फैलाएं",collapseAllDayRow:"सारा-दिन सेक्शन समेटें",timeFormat:"LST"},DayResourceView:{dayResourceView:"दैनिक संसाधन"},Sidebar:{"Filter events":"ईवेंट्स फिल्टर करें"},WeekExpander:{expandTip:"पंक्ति फैलाने के लिए क्लिक करें",collapseTip:"पंक्ति समेटने के लिए क्लिक करें"}},x=c.publishLocale(w);if(typeof n.exports=="object"&&typeof s=="object"){var F=(e,t,a,r)=>{if(t&&typeof t=="object"||typeof t=="function")for(let o of Object.getOwnPropertyNames(t))!Object.prototype.hasOwnProperty.call(e,o)&&o!==a&&Object.defineProperty(e,o,{get:()=>t[o],enumerable:!(r=Object.getOwnPropertyDescriptor(t,o))||r.enumerable});return e};n.exports=F(n.exports,s)}return n.exports});
