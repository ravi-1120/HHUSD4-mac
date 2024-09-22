/*!
 *
 * Bryntum Grid 5.5.4
 *
 * Copyright(c) 2023 Bryntum AB
 * https://bryntum.com/contact
 * https://bryntum.com/license
 *
 */
(function(i,n){var a=typeof exports=="object";if(typeof define=="function"&&define.amd)define([],n);else if(typeof module=="object"&&module.exports)module.exports=n();else{var d=n(),c=a?exports:i;for(var g in d)c[g]=d[g]}})(typeof self<"u"?self:void 0,()=>{var i={},n={exports:i},a=Object.defineProperty,d=Object.getOwnPropertyDescriptor,c=Object.getOwnPropertyNames,g=Object.prototype.hasOwnProperty,u=(e,r,t)=>r in e?a(e,r,{enumerable:!0,configurable:!0,writable:!0,value:t}):e[r]=t,f=(e,r)=>{for(var t in r)a(e,t,{get:r[t],enumerable:!0})},k=(e,r,t,l)=>{if(r&&typeof r=="object"||typeof r=="function")for(let o of c(r))!g.call(e,o)&&o!==t&&a(e,o,{get:()=>r[o],enumerable:!(l=d(r,o))||l.enumerable});return e},b=e=>k(a({},"__esModule",{value:!0}),e),v=(e,r,t)=>(u(e,typeof r!="symbol"?r+"":r,t),t),p={};f(p,{default:()=>F}),n.exports=b(p);var s=class{static mergeLocales(...e){let r={};return e.forEach(t=>{Object.keys(t).forEach(l=>{typeof t[l]=="object"?r[l]={...r[l],...t[l]}:r[l]=t[l]})}),r}static trimLocale(e,r){let t=(l,o)=>{e[l]&&(o?e[l][o]&&delete e[l][o]:delete e[l])};Object.keys(r).forEach(l=>{Object.keys(r[l]).length>0?Object.keys(r[l]).forEach(o=>t(l,o)):t(l)})}static normalizeLocale(e,r){if(!e)throw new Error('"nameOrConfig" parameter can not be empty');if(typeof e=="string"){if(!r)throw new Error('"config" parameter can not be empty');r.locale?r.name=e||r.name:r.localeName=e}else r=e;let t={};if(r.name||r.locale)t=Object.assign({localeName:r.name},r.locale),r.desc&&(t.localeDesc=r.desc),r.code&&(t.localeCode=r.code),r.path&&(t.localePath=r.path);else{if(!r.localeName)throw new Error(`"config" parameter doesn't have "localeName" property`);t=Object.assign({},r)}for(let l of["name","desc","code","path"])t[l]&&delete t[l];if(!t.localeName)throw new Error("Locale name can not be empty");return t}static get locales(){return globalThis.bryntum.locales||{}}static set locales(e){globalThis.bryntum.locales=e}static get localeName(){return globalThis.bryntum.locale||"En"}static set localeName(e){globalThis.bryntum.locale=e||s.localeName}static get locale(){return s.localeName&&this.locales[s.localeName]||this.locales.En||Object.values(this.locales)[0]||{localeName:"",localeDesc:"",localeCoode:""}}static publishLocale(e,r){let{locales:t}=globalThis.bryntum,l=s.normalizeLocale(e,r),{localeName:o}=l;return!t[o]||r===!0?t[o]=l:t[o]=this.mergeLocales(t[o]||{},l||{}),t[o]}},m=s;v(m,"skipLocaleIntegrityCheck",!1),globalThis.bryntum=globalThis.bryntum||{},globalThis.bryntum.locales=globalThis.bryntum.locales||{},m._$name="LocaleHelper";var h={localeName:"Da",localeDesc:"Dansk",localeCode:"da",Object:{Yes:"Ja",No:"Nej",Cancel:"Aflyse",Ok:"OK",Week:"Uge"},ColorPicker:{noColor:"Ingen farve"},Combo:{noResults:"Ingen resultater",recordNotCommitted:"Posten kunne ikke tilføjes",addNewValue:e=>`Tilføj ${e}`},FilePicker:{file:"Fil"},Field:{badInput:"Ugyldig feltværdi",patternMismatch:"Værdien skal matche et bestemt mønster",rangeOverflow:e=>`Værdien skal være mindre end eller lig med ${e.max}`,rangeUnderflow:e=>`Værdien skal være større end eller lig med ${e.min}`,stepMismatch:"Værdien skal passe til trinnet",tooLong:"Værdien skal være kortere",tooShort:"Værdien skal være længere",typeMismatch:"Værdien skal være i et særligt format",valueMissing:"dette felt er påkrævet",invalidValue:"Ugyldig feltværdi",minimumValueViolation:"Overtrædelse af minimumsværdien",maximumValueViolation:"Maksimal værdikrænkelse",fieldRequired:"Dette felt er påkrævet",validateFilter:"Værdien skal vælges på listen"},DateField:{invalidDate:"Ugyldig datoinput"},DatePicker:{gotoPrevYear:"Gå til forrige år",gotoPrevMonth:"Gå til forrige måned",gotoNextMonth:"Gå til næste måned",gotoNextYear:"Gå til næste år"},NumberFormat:{locale:"da",currency:"DKK"},DurationField:{invalidUnit:"Ugyldig enhed"},TimeField:{invalidTime:"Ugyldig tidsindtastning"},TimePicker:{hour:"timer",minute:"minutter",second:"Anden"},List:{loading:"Indlæser...",selectAll:"Vælg alle"},GridBase:{loadMask:"Indlæser...",syncMask:"Gemmer ændringer, vent venligst..."},PagingToolbar:{firstPage:"Gå til første side",prevPage:"Gå til forrige side",page:"Side",nextPage:"Gå til næste side",lastPage:"Gå til sidste side",reload:"Genindlæs den aktuelle side",noRecords:"Ingen poster at vise",pageCountTemplate:e=>`af ${e.lastPage}`,summaryTemplate:e=>`Viser poster ${e.start} - ${e.end} af ${e.allCount}`},PanelCollapser:{Collapse:"Samle",Expand:"Udvide"},Popup:{close:"Luk popup"},UndoRedo:{Undo:"Fortryd",Redo:"Gentag",UndoLastAction:"Fortryd sidste handling",RedoLastAction:"Gentag sidst fortrudte handling",NoActions:"Ingen elementer i fortrydelseskøen"},FieldFilterPicker:{equals:"lig med",doesNotEqual:"er ikke lig",isEmpty:"er tom",isNotEmpty:"er ikke tom",contains:"indeholder",doesNotContain:"indeholder ikke",startsWith:"starter med",endsWith:"slutter med",isOneOf:"er en af",isNotOneOf:"er ikke en af",isGreaterThan:"er større end",isLessThan:"er mindre end",isGreaterThanOrEqualTo:"er større end eller lig med",isLessThanOrEqualTo:"er mindre end eller lig med",isBetween:"er mellem",isNotBetween:"er ikke mellem",isBefore:"er før",isAfter:"er efter",isToday:"er i dag",isTomorrow:"er i morgen",isYesterday:"er i går",isThisWeek:"er denne uge",isNextWeek:"er i næste uge",isLastWeek:"er i sidste uge",isThisMonth:"er denne måned",isNextMonth:"er næste måned",isLastMonth:"er sidste måned",isThisYear:"er i år",isNextYear:"er næste år",isLastYear:"er sidste år",isYearToDate:"er år til dato",isTrue:"er sand",isFalse:"er falsk",selectAProperty:"Vælg en ejendom",selectAnOperator:"Vælg en operatør",caseSensitive:"Stillende mellem store og små bogstaver",and:"og",dateFormat:"D/M/YY",selectOneOrMoreValues:"Vælg en eller flere værdier",enterAValue:"Indtast en værdi",enterANumber:"Indtast et tal",selectADate:"Vælg en dato"},FieldFilterPickerGroup:{addFilter:"Tilføj filter"},DateHelper:{locale:"da",weekStartDay:1,nonWorkingDays:{0:!0,6:!0},weekends:{0:!0,6:!0},unitNames:[{single:"millisekund",plural:"ms",abbrev:"ms"},{single:"sekund",plural:"sekunder",abbrev:"s"},{single:"minut",plural:"minutter",abbrev:"min"},{single:"timer",plural:"timer",abbrev:"t"},{single:"dag",plural:"dage",abbrev:"d"},{single:"uge",plural:"uger",abbrev:"u"},{single:"måned",plural:"måneder",abbrev:"mån"},{single:"kvartal",plural:"kvartaler",abbrev:"k"},{single:"år",plural:"år",abbrev:"år"},{single:"årti",plural:"årtier",abbrev:"dek"}],unitAbbreviations:[["mil"],["s","sek"],["m","min"],["t","tr"],["d"],["u","ugr"],["må","mån","måndr"],["k","kvar","kvart"],["å","år"],["dek"]],parsers:{L:"DD.MM.YYYY",LT:"HH.mm",LTS:"HH.mm.ss"},ordinalSuffix:e=>e+"."}},x=m.publishLocale(h),y=new String,S={localeName:"Da",localeDesc:"Dansk",localeCode:"da",ColumnPicker:{column:"Kolonne",columnsMenu:"Kolonner",hideColumn:"Skjul kolonne",hideColumnShort:"Skjul",newColumns:"Nye kolonner"},Filter:{applyFilter:"Anvend filter",filter:"Filter",editFilter:"Rediger filter",on:"On",before:"Før",after:"Efter",equals:"Lige med",lessThan:"Mindre end",moreThan:"Mere end",removeFilter:"Fjern filteret",disableFilter:"Deaktiver filter"},FilterBar:{enableFilterBar:"Vis filterbjælke",disableFilterBar:"skjul filterbjælken"},Group:{group:"Gruppér",groupAscending:"Gruppér stigende",groupDescending:"Gruppér faldende",groupAscendingShort:"stigende",groupDescendingShort:"faldende",stopGrouping:"Stop gruppering",stopGroupingShort:"Stop"},HeaderMenu:{moveBefore:e=>`Flyt før "${e}"`,moveAfter:e=>`Flyt efter "${e}"`,collapseColumn:"Skjul kolonne",expandColumn:"Skjul kolonne"},ColumnRename:{rename:"Omdøb"},MergeCells:{mergeCells:"Flet celler",menuTooltip:"Flet celler med samme værdi, når de sorteres efter denne kolonne"},Search:{searchForValue:"Søg efter værdi"},Sort:{sort:"Sortér",sortAscending:"Sorter stigende",sortDescending:"Sorter faldende",multiSort:"Multi sortering",removeSorter:"Fjern sorteringsenheden",addSortAscending:"Tilføj stigende sortering",addSortDescending:"Tilføj faldende sortering",toggleSortAscending:"Skift til stigende",toggleSortDescending:"Skift til faldende",sortAscendingShort:"Stigende",sortDescendingShort:"Faldende",removeSorterShort:"Fjerne",addSortAscendingShort:"+ Stigende",addSortDescendingShort:"+ Faldende"},Split:{split:"Opdel",unsplit:"Ikke opdelt",horizontally:"Vandret",vertically:"Lodret",both:"Begge"},Column:{columnLabel:e=>`${e.text?`${e.text} kolonne. `:""}MELLEMRUM for kontekstmenu${e.sortable?",ENTER for at sortere":""}`,cellLabel:y},Checkbox:{toggleRowSelect:"Skift rækkevalg",toggleSelection:"Skift valg af hele datasættet"},RatingColumn:{cellLabel:e=>{var r;return`${e.text?e.text:""} ${(r=e.location)!=null&&r.record?` bedømmelse : ${e.location.record.get(e.field)||0}`:""}`}},GridBase:{loadFailedMessage:"Dataindlæsning mislykkedes!",syncFailedMessage:"Datasynkronisering mislykkedes!",unspecifiedFailure:"Uspecificeret fejl",networkFailure:"Netværksfejl",parseFailure:"Kunne ikke parse serversvar",serverResponse:"Serversvar:",noRows:"Ingen poster at vise",moveColumnLeft:"Flyt til venstre sektion",moveColumnRight:"Flyt til højre sektion",moveColumnTo:e=>`Flyt kolonne til ${e}`},CellMenu:{removeRow:"Slet"},RowCopyPaste:{copyRecord:"Kopi",cutRecord:"klip",pasteRecord:"sæt ind",rows:"rækker",row:"række"},CellCopyPaste:{copy:"Kopi",cut:"Skære",paste:"Sæt ind"},PdfExport:{"Waiting for response from server":"Venter på svar fra serveren...","Export failed":"Eksporten mislykkedes","Server error":"Serverfejl","Generating pages":"Generering af sider...","Click to abort":"Afbestille"},ExportDialog:{width:"40em",labelWidth:"12em",exportSettings:"Eksporter indstillinger",export:"Eksport",exporterType:"Styr paginering",cancel:"Afbestille",fileFormat:"Filformat",rows:"Rækker",alignRows:"Juster rækker",columns:"Kolonner",paperFormat:"Papirformat",orientation:"Orientering",repeatHeader:"Gentag overskriften"},ExportRowsCombo:{all:"Alle rækker",visible:"Synlige rækker"},ExportOrientationCombo:{portrait:"Portræt",landscape:"Landskab"},SinglePageExporter:{singlepage:"Enkelt side"},MultiPageExporter:{multipage:"Flere sider",exportingPage:({currentPage:e,totalPages:r})=>`Eksporterer side ${e}/${r}`},MultiPageVerticalExporter:{multipagevertical:"Flere sider (lodret)",exportingPage:({currentPage:e,totalPages:r})=>`Eksporterer side ${e}/${r}`},RowExpander:{loading:"Indlæser",expand:"Udvide",collapse:"Samle"},TreeGroup:{group:"Gruppér efter",stopGrouping:"Stop gruppering",stopGroupingThisColumn:"Fjern gruppe på kolonne"}},F=m.publishLocale(S);if(typeof n.exports=="object"&&typeof i=="object"){var j=(e,r,t,l)=>{if(r&&typeof r=="object"||typeof r=="function")for(let o of Object.getOwnPropertyNames(r))!Object.prototype.hasOwnProperty.call(e,o)&&o!==t&&Object.defineProperty(e,o,{get:()=>r[o],enumerable:!(l=Object.getOwnPropertyDescriptor(r,o))||l.enumerable});return e};n.exports=j(n.exports,i)}return n.exports});
