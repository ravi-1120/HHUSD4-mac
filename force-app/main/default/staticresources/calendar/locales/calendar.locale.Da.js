/*!
 *
 * Bryntum Calendar 5.6.0
 *
 * Copyright(c) 2023 Bryntum AB
 * https://bryntum.com/contact
 * https://bryntum.com/license
 *
 */
(function(s,i){var o=typeof exports=="object";if(typeof define=="function"&&define.amd)define([],i);else if(typeof module=="object"&&module.exports)module.exports=i();else{var m=i(),u=o?exports:s;for(var p in m)u[p]=m[p]}})(typeof self<"u"?self:void 0,()=>{var s={},i={exports:s},o=Object.defineProperty,m=Object.getOwnPropertyDescriptor,u=Object.getOwnPropertyNames,p=Object.prototype.hasOwnProperty,f=(e,t,r)=>t in e?o(e,t,{enumerable:!0,configurable:!0,writable:!0,value:r}):e[t]=r,k=(e,t)=>{for(var r in t)o(e,r,{get:t[r],enumerable:!0})},y=(e,t,r,l)=>{if(t&&typeof t=="object"||typeof t=="function")for(let n of u(t))!p.call(e,n)&&n!==r&&o(e,n,{get:()=>t[n],enumerable:!(l=m(t,n))||l.enumerable});return e},h=e=>y(o({},"__esModule",{value:!0}),e),b=(e,t,r)=>(f(e,typeof t!="symbol"?t+"":t,r),r),c={};k(c,{default:()=>A}),i.exports=h(c);var v=class g{static mergeLocales(...t){let r={};return t.forEach(l=>{Object.keys(l).forEach(n=>{typeof l[n]=="object"?r[n]={...r[n],...l[n]}:r[n]=l[n]})}),r}static trimLocale(t,r){let l=(n,a)=>{t[n]&&(a?t[n][a]&&delete t[n][a]:delete t[n])};Object.keys(r).forEach(n=>{Object.keys(r[n]).length>0?Object.keys(r[n]).forEach(a=>l(n,a)):l(n)})}static normalizeLocale(t,r){if(!t)throw new Error('"nameOrConfig" parameter can not be empty');if(typeof t=="string"){if(!r)throw new Error('"config" parameter can not be empty');r.locale?r.name=t||r.name:r.localeName=t}else r=t;let l={};if(r.name||r.locale)l=Object.assign({localeName:r.name},r.locale),r.desc&&(l.localeDesc=r.desc),r.code&&(l.localeCode=r.code),r.path&&(l.localePath=r.path);else{if(!r.localeName)throw new Error(`"config" parameter doesn't have "localeName" property`);l=Object.assign({},r)}for(let n of["name","desc","code","path"])l[n]&&delete l[n];if(!l.localeName)throw new Error("Locale name can not be empty");return l}static get locales(){return globalThis.bryntum.locales||{}}static set locales(t){globalThis.bryntum.locales=t}static get localeName(){return globalThis.bryntum.locale||"En"}static set localeName(t){globalThis.bryntum.locale=t||g.localeName}static get locale(){return g.localeName&&this.locales[g.localeName]||this.locales.En||Object.values(this.locales)[0]||{localeName:"",localeDesc:"",localeCoode:""}}static publishLocale(t,r){let{locales:l}=globalThis.bryntum,n=g.normalizeLocale(t,r),{localeName:a}=n;return!l[a]||r===!0?l[a]=n:l[a]=this.mergeLocales(l[a]||{},n||{}),l[a]}};b(v,"skipLocaleIntegrityCheck",!1);var d=v;globalThis.bryntum=globalThis.bryntum||{},globalThis.bryntum.locales=globalThis.bryntum.locales||{},d._$name="LocaleHelper";var S={localeName:"Da",localeDesc:"Dansk",localeCode:"da",Object:{Yes:"Ja",No:"Nej",Cancel:"Annullér",Ok:"OK",Week:"Uge",None:"Ingen"},ColorPicker:{noColor:"Ingen farve"},Combo:{noResults:"Ingen resultater",recordNotCommitted:"Række kunne ikke tilføjes",addNewValue:e=>`Tilføj ${e}`},FilePicker:{file:"Fil"},Field:{badInput:"Ugyldig feltværdi",patternMismatch:"Værdien skal matche et bestemt mønster",rangeOverflow:e=>`Værdien skal være mindre end eller lig med ${e.max}`,rangeUnderflow:e=>`Værdien skal være større end eller lig med ${e.min}`,stepMismatch:"Værdien skal passe til trinnet",tooLong:"Værdien skal være kortere",tooShort:"Værdien skal være længere",typeMismatch:"Værdien skal være i et særligt format",valueMissing:"dette felt er påkrævet",invalidValue:"Ugyldig feltværdi",minimumValueViolation:"Overtrædelse af minimumsværdien",maximumValueViolation:"Maksimal værdikrænkelse",fieldRequired:"Dette felt er påkrævet",validateFilter:"Værdien skal vælges på listen"},DateField:{invalidDate:"Ugyldig datoinput"},DatePicker:{gotoPrevYear:"Gå til forrige år",gotoPrevMonth:"Gå til forrige måned",gotoNextMonth:"Gå til næste måned",gotoNextYear:"Gå til næste år"},NumberFormat:{locale:"da",currency:"DKK"},DurationField:{invalidUnit:"Ugyldig enhed"},TimeField:{invalidTime:"Ugyldig tidsangivelse"},TimePicker:{hour:"Time",minute:"Minut",second:"Sekund"},List:{loading:"Indlæser...",selectAll:"Vælg alle"},GridBase:{loadMask:"Indlæser...",syncMask:"Gemmer ændringer, vent venligst..."},PagingToolbar:{firstPage:"Gå til første side",prevPage:"Gå til forrige side",page:"Side",nextPage:"Gå til næste side",lastPage:"Gå til sidste side",reload:"Genindlæs den aktuelle side",noRecords:"Ingen poster at vise",pageCountTemplate:e=>`af ${e.lastPage}`,summaryTemplate:e=>`Viser poster ${e.start} - ${e.end} af ${e.allCount}`},PanelCollapser:{Collapse:"Kollaps",Expand:"Udvide"},Popup:{close:"Luk dialog"},UndoRedo:{Undo:"Fortryd",Redo:"Gentag",UndoLastAction:"Fortryd foregående handling",RedoLastAction:"Gentag den foregående fortrudte handling",NoActions:"Ingen handlinger registreret"},FieldFilterPicker:{equals:"lig med",doesNotEqual:"er ikke lig",isEmpty:"er tom",isNotEmpty:"er ikke tom",contains:"indeholder",doesNotContain:"indeholder ikke",startsWith:"starter med",endsWith:"slutter med",isOneOf:"er en af",isNotOneOf:"er ikke en af",isGreaterThan:"er større end",isLessThan:"er mindre end",isGreaterThanOrEqualTo:"er større end eller lig med",isLessThanOrEqualTo:"er mindre end eller lig med",isBetween:"er mellem",isNotBetween:"er ikke mellem",isBefore:"er før",isAfter:"er efter",isToday:"er i dag",isTomorrow:"er i morgen",isYesterday:"er i går",isThisWeek:"er denne uge",isNextWeek:"er i næste uge",isLastWeek:"er i sidste uge",isThisMonth:"er denne måned",isNextMonth:"er næste måned",isLastMonth:"er sidste måned",isThisYear:"er i år",isNextYear:"er næste år",isLastYear:"er sidste år",isYearToDate:"er år til dato",isTrue:"er sand",isFalse:"er falsk",selectAProperty:"Vælg en ejendom",selectAnOperator:"Vælg en operatør",caseSensitive:"Stillende mellem store og små bogstaver",and:"og",dateFormat:"D/M/YY",selectValue:"Vælg værdi",selectOneOrMoreValues:"Vælg en eller flere værdier",enterAValue:"Indtast en værdi",enterANumber:"Indtast et tal",selectADate:"Vælg en dato"},FieldFilterPickerGroup:{addFilter:"Tilføj filter"},DateHelper:{locale:"da",weekStartDay:1,nonWorkingDays:{0:!0,6:!0},weekends:{0:!0,6:!0},unitNames:[{single:"Millisekund",plural:"Millisekunder",abbrev:"ms"},{single:"Sekund",plural:"Sekunder",abbrev:"s"},{single:"Minut",plural:"Minutter",abbrev:"min"},{single:"Time",plural:"Timer",abbrev:"t"},{single:"Dag",plural:"Dage",abbrev:"d"},{single:"Uge",plural:"Uger",abbrev:"u"},{single:"Måned",plural:"Måneder",abbrev:"mdr"},{single:"Kvartal",plural:"Kvartaler",abbrev:"kv"},{single:"År",plural:"År",abbrev:"år"},{single:"Årti",plural:"Årtier",abbrev:"årti(er)"}],unitAbbreviations:[["mil","ms"],["s","sek"],["m","min"],["t"],["d"],["u"],["m","mdr"],["k","kv"],["å","år"],["årti","årtier"]],parsers:{L:"DD.MM.YYYY",LT:"HH:mm",LTS:"HH:mm:ss"},ordinalSuffix:e=>e}},C=d.publishLocale(S),D=new String,F={localeName:"Da",localeDesc:"Dansk",localeCode:"da",ColumnPicker:{column:"Kolonne",columnsMenu:"Kolonner",hideColumn:"Skjul kolonne",hideColumnShort:"Skjul",newColumns:"Nye kolonner"},Filter:{applyFilter:"Anvend filter",filter:"Filter",editFilter:"Redigér filter",on:"Aktiv",before:"Før",after:"Efter",equals:"Ligmed",lessThan:"Mindre end",moreThan:"Større end",removeFilter:"Fjern filter",disableFilter:"Deaktiver filter"},FilterBar:{enableFilterBar:"Vis filtreringspanel",disableFilterBar:"Skjul filtreringspanel"},Group:{group:"Gruppér",groupAscending:"Gruppér stigende",groupDescending:"Gruppér faldende",groupAscendingShort:"Stigende",groupDescendingShort:"Faldende",stopGrouping:"Stop gruppering",stopGroupingShort:"Stop"},HeaderMenu:{moveBefore:e=>`Flyt før '${e}'`,moveAfter:e=>`Flyt efter '${e}'`,collapseColumn:"Kollaps kolonne",expandColumn:"Udvid kolonne"},ColumnRename:{rename:"Omdøb"},MergeCells:{mergeCells:"Flet celler",menuTooltip:"Flet celler med samme værdi, når de sorteres efter denne kolonne"},Search:{searchForValue:"Søg efter værdi"},Sort:{sort:"Sortér",sortAscending:"Sorter stigende",sortDescending:"Sorter faldende",multiSort:"Multi sortering",removeSorter:"Fjern sorteringsenheden",addSortAscending:"Tilføj stigende sortering",addSortDescending:"Tilføj faldende sortering",toggleSortAscending:"Skift til stigende",toggleSortDescending:"Skift til faldende",sortAscendingShort:"Stigende",sortDescendingShort:"Faldende",removeSorterShort:"Fjerne",addSortAscendingShort:"+ Stigende",addSortDescendingShort:"+ Faldende"},Split:{split:"Opdel",unsplit:"Ikke opdelt",horizontally:"Vandret",vertically:"Lodret",both:"Begge"},Column:{columnLabel:e=>`${e.text?`${e.text} kolonne. `:""}MELLEMRUM for kontekstmenu${e.sortable?",ENTER for at sortere":""}`,cellLabel:D},Checkbox:{toggleRowSelect:"Skift rækkevalg",toggleSelection:"Skift valg af hele datasættet"},RatingColumn:{cellLabel:e=>{var t;return`${e.text?e.text:""} ${(t=e.location)!=null&&t.record?` bedømmelse : ${e.location.record.get(e.field)||0}`:""}`}},GridBase:{loadFailedMessage:"Dataindlæsning mislykkedes!",syncFailedMessage:"Datasynkronisering mislykkedes!",unspecifiedFailure:"Uspecificeret fejl",networkFailure:"Netværksfejl",parseFailure:"Kunne ikke parse serversvar",serverResponse:"Serversvar:",noRows:"Ingen poster at vise",moveColumnLeft:"Flyt til venstre sektion",moveColumnRight:"Flyt til højre sektion",moveColumnTo:e=>`Flyt kolonne til ${e}`},CellMenu:{removeRow:"Slet"},RowCopyPaste:{copyRecord:"Kopi",cutRecord:"klip",pasteRecord:"sæt ind",rows:"rækker",row:"række"},CellCopyPaste:{copy:"Kopi",cut:"Skære",paste:"Sæt ind"},PdfExport:{"Waiting for response from server":"Venter på svar fra serveren...","Export failed":"Eksporten mislykkedes","Server error":"Serverfejl","Generating pages":"Generering af sider...","Click to abort":"Afbestille"},ExportDialog:{width:"40em",labelWidth:"12em",exportSettings:"Eksporter indstillinger",export:"Eksport",printSettings:"Udskriftsindstillinger",print:"Udskriv",exporterType:"Styr paginering",cancel:"Afbestille",fileFormat:"Filformat",rows:"Rækker",alignRows:"Juster rækker",columns:"Kolonner",paperFormat:"Papirformat",orientation:"Orientering",repeatHeader:"Gentag overskriften"},ExportRowsCombo:{all:"Alle rækker",visible:"Synlige rækker"},ExportOrientationCombo:{portrait:"Portræt",landscape:"Landskab"},SinglePageExporter:{singlepage:"Enkelt side"},MultiPageExporter:{multipage:"Flere sider",exportingPage:({currentPage:e,totalPages:t})=>`Eksporterer side ${e}/${t}`},MultiPageVerticalExporter:{multipagevertical:"Flere sider (lodret)",exportingPage:({currentPage:e,totalPages:t})=>`Eksporterer side ${e}/${t}`},RowExpander:{loading:"Indlæser",expand:"Udvide",collapse:"Kollaps"},TreeGroup:{group:"Gruppér efter",stopGrouping:"Stop gruppering",stopGroupingThisColumn:"Fjern gruppe på kolonne"}},M=d.publishLocale(F),E={localeName:"Da",localeDesc:"Dansk",localeCode:"da",Object:{newEvent:"ny begivenhed"},ResourceInfoColumn:{eventCountText:e=>e+" begivenhed"+(e!==1?"er":"")},Dependencies:{from:"Fra",to:"Til",valid:"Gyldig",invalid:"Ugyldig"},DependencyType:{SS:"SS",SF:"SA",FS:"AS",FF:"AA",StartToStart:"Start-til-Start",StartToEnd:"Start-til-Afslutning",EndToStart:"Afslutning-til-Start",EndToEnd:"Afslutning-til-Afslutning",short:["SS","SA","AS","AA"],long:["Start-til-Start","Start-til-Afslutning","Afslutning-til-Start","Afslutning-til-Afslutning"]},DependencyEdit:{From:"Fra",To:"Til",Type:"Type",Lag:"Forsinkelse","Edit dependency":"Redigér afhængighed",Save:"Gem",Delete:"Slet",Cancel:"Annullér",StartToStart:"Start-Start",StartToEnd:"Start-Afslutning",EndToStart:"Afslutning-Start",EndToEnd:"Afslutning-Afslutning"},EventEdit:{Name:"Navn",Resource:"Ressource",Start:"Start",End:"Afslutning",Save:"Gem",Delete:"Slet",Cancel:"Annullér","Edit event":"Redigér begivenhed",Repeat:"Gentag"},EventDrag:{eventOverlapsExisting:"Begivenhed overlapper med eksisterende begivenhed for denne ressource",noDropOutsideTimeline:"Begivenhed må ikke slippes helt uden for tidslinjen"},SchedulerBase:{"Add event":"Tilføj begivenhed","Delete event":"Slet begivenhed","Unassign event":"Fjern tilknytning til begivenhed",color:"Farve"},TimeAxisHeaderMenu:{pickZoomLevel:"Zoom",activeDateRange:"Datointerval",startText:"Startdato",endText:"Slutdato",todayText:"Idag"},EventCopyPaste:{copyEvent:"Kopiér begivenhed",cutEvent:"Klip begivenhed",pasteEvent:"Indsæt begivenhed"},EventFilter:{filterEvents:"Filtrér opgaver",byName:"Efter navn"},TimeRanges:{showCurrentTimeLine:"Vis aktuel tidslinje"},PresetManager:{secondAndMinute:{displayDateFormat:"ll LTS",name:"Sekunder"},minuteAndHour:{topDateFormat:"ddd DD.MM, HH:mm",displayDateFormat:"ll LST"},hourAndDay:{topDateFormat:"ddd DD.MM",middleDateFormat:"LST",displayDateFormat:"ll LST",name:"Dag"},day:{name:"Dag/timer"},week:{name:"Uge/timer"},dayAndWeek:{displayDateFormat:"ll LST",name:"Uge/dage"},dayAndMonth:{name:"Måned"},weekAndDay:{displayDateFormat:"ll LST",name:"Uge"},weekAndMonth:{name:"Uger"},weekAndDayLetter:{name:"Uger/hverdage"},weekDateAndMonth:{name:"Måneder/uger"},monthAndYear:{name:"Måneder"},year:{name:"Flere år"},manyYears:{name:"Flere år"}},RecurrenceConfirmationPopup:{"delete-title":"Du er ved at slette en begivenhed","delete-all-message":"Vil du slette alle forekomster af denne begivenhed?","delete-further-message":"Vil du slette denne og alle fremtidige forekomster af denne begivenhed, eller kun den valgte forekomst?","delete-further-btn-text":"Slet alle fremtidige begivenheder","delete-only-this-btn-text":"Slet kun denne begivenhed","update-title":"Du er ved at ændre en gentagende begivenhed","update-all-message":"Vil du ændre alle forekomster af denne begivenhed?","update-further-message":"Vil du ændre netop denne forekomst af begivenheden, eller denne og alle fremtidige forekomster?","update-further-btn-text":"Alle fremtidige begivenheder","update-only-this-btn-text":"Kun denne begivenhed",Yes:"Ja",Cancel:"Annullér",width:600},RecurrenceLegend:{" and ":" og ",Daily:"Daglig","Weekly on {1}":({days:e})=>`Ugentligt ${e}`,"Monthly on {1}":({days:e})=>`Månedligt ${e}`,"Yearly on {1} of {2}":({days:e,months:t})=>`Årligt ${e} af ${t}`,"Every {0} days":({interval:e})=>`For hver ${e} dage`,"Every {0} weeks on {1}":({interval:e,days:t})=>`For hver ${e} uger ${t}`,"Every {0} months on {1}":({interval:e,days:t})=>`For hver ${e} måneder ${t}`,"Every {0} years on {1} of {2}":({interval:e,days:t,months:r})=>`For hver ${e} år ${t} i ${r}`,position1:"den første",position2:"den anden",position3:"den tredje",position4:"den fjerde",position5:"den femte","position-1":"den sidste",day:"dag",weekday:"ugedag","weekend day":"dag i weekenden",daysFormat:({position:e,days:t})=>`${e} ${t}`},RecurrenceEditor:{"Repeat event":"Gentag begivenhed",Cancel:"Annullér",Save:"Gem",Frequency:"Frekvens",Every:"Alle",DAILYintervalUnit:"dag(e)",WEEKLYintervalUnit:"uge(r)",MONTHLYintervalUnit:"Måned(er)",YEARLYintervalUnit:"År",Each:"For hver","On the":"på","End repeat":"Stop gentagelse","time(s)":"tid(er)"},RecurrenceDaysCombo:{day:"dag",weekday:"ugedag","weekend day":"dag i weekenden"},RecurrencePositionsCombo:{position1:"første",position2:"anden",position3:"tredje",position4:"fjerde",position5:"femte","position-1":"sidste"},RecurrenceStopConditionCombo:{Never:"Aldrig",After:"Efter","On date":"På dato"},RecurrenceFrequencyCombo:{None:"Ingen gentagelse",Daily:"Dagligt",Weekly:"Ugentligt",Monthly:"Månedligt",Yearly:"Årligt"},RecurrenceCombo:{None:"Ingen",Custom:"Tilpasset..."},Summary:{"Summary for":e=>`Resumé for ${e}`},ScheduleRangeCombo:{completeview:"Komplet tidsplan",currentview:"Synlig tidsplan",daterange:"Datointerval",completedata:"Komplet tidsplan (for alle arrangementer)"},SchedulerExportDialog:{"Schedule range":"Tidsplan rækkevidde","Export from":"Fra","Export to":"Til"},ExcelExporter:{"No resource assigned":"Ingen ressourcer tilknyttet"},CrudManagerView:{serverResponseLabel:"Svar fra server:"},DurationColumn:{Duration:"Varighed"}},x=d.publishLocale(E),T={localeName:"Da",localeDesc:"Dansk",localeCode:"da",EventEdit:{Calendar:"Kalender","All day":"Hele dag",day:"dagen",week:"Uge",month:"Måned",year:"År",decade:"Årti"},EventMenu:{duplicateEvent:"Dubleret begivenhed",copy:"kopi"},Calendar:{Today:"I dag",next:e=>`Næste ${e}`,previous:e=>`Tidligere ${e}`,plusMore:e=>`+${e} mere`,allDay:"Hele dagen",endsOn:e=>`Slutter ${e}`,weekOfYear:([e,t])=>`Uge ${t}, ${e}`,loadFail:"Indlæsning af kalenderdata mislykkedes. Kontakt venligst din systemadministrator"},CalendarDrag:{holdCtrlForRecurrence:"Hold CTRL nede for en tilbagevendende begivenhed"},CalendarMixin:{eventCount:e=>`${e||"Ingen"} begivenhed${e&&e>1?"er":""}`},EventTip:{"Edit event":"Rediger begivenhed",timeFormat:"LST"},ModeSelector:{includeWeekends:"Inkluder weekender",weekends:"Weekender"},AgendaView:{Agenda:"Dagsorden"},MonthView:{Month:"måned",monthUnit:"måned"},WeekView:{weekUnit:"uge"},YearView:{Year:"år",yearUnit:"år",noEvents:"Ingen begivenheder"},EventList:{List:"Liste",Start:"Start",Finish:"Afslut",days:e=>`${e>1?`${e} `:""}dag${e===1?"":"e"}`},DayView:{Day:"dag",dayUnit:"dag",daysUnit:"dage",expandAllDayRow:"Udvid heldagsafsnittet",collapseAllDayRow:"Skjul heldagsafsnittet",timeFormat:"LST"},DayResourceView:{dayResourceView:"Dagsressourcer"},Sidebar:{"Filter events":"Filtrer begivenheder"},WeekExpander:{expandTip:"Klik for at udvide rækken",collapseTip:"Klik for at skjule rækken"}},A=d.publishLocale(T);if(typeof i.exports=="object"&&typeof s=="object"){var w=(e,t,r,l)=>{if(t&&typeof t=="object"||typeof t=="function")for(let n of Object.getOwnPropertyNames(t))!Object.prototype.hasOwnProperty.call(e,n)&&n!==r&&Object.defineProperty(e,n,{get:()=>t[n],enumerable:!(l=Object.getOwnPropertyDescriptor(t,n))||l.enumerable});return e};i.exports=w(i.exports,s)}return i.exports});
