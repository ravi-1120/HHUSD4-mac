/*!
 *
 * Bryntum Grid 5.5.4
 *
 * Copyright(c) 2023 Bryntum AB
 * https://bryntum.com/contact
 * https://bryntum.com/license
 *
 */
(function(i,n){var l=typeof exports=="object";if(typeof define=="function"&&define.amd)define([],n);else if(typeof module=="object"&&module.exports)module.exports=n();else{var c=n(),u=l?exports:i;for(var d in c)u[d]=c[d]}})(typeof self<"u"?self:void 0,()=>{var i={},n={exports:i},l=Object.defineProperty,c=Object.getOwnPropertyDescriptor,u=Object.getOwnPropertyNames,d=Object.prototype.hasOwnProperty,b=(e,a,o)=>a in e?l(e,a,{enumerable:!0,configurable:!0,writable:!0,value:o}):e[a]=o,v=(e,a)=>{for(var o in a)l(e,o,{get:a[o],enumerable:!0})},y=(e,a,o,r)=>{if(a&&typeof a=="object"||typeof a=="function")for(let t of u(a))!d.call(e,t)&&t!==o&&l(e,t,{get:()=>a[t],enumerable:!(r=c(a,t))||r.enumerable});return e},g=e=>y(l({},"__esModule",{value:!0}),e),h=(e,a,o)=>(b(e,typeof a!="symbol"?a+"":a,o),o),m={};v(m,{default:()=>P}),n.exports=g(m);var s=class{static mergeLocales(...e){let a={};return e.forEach(o=>{Object.keys(o).forEach(r=>{typeof o[r]=="object"?a[r]={...a[r],...o[r]}:a[r]=o[r]})}),a}static trimLocale(e,a){let o=(r,t)=>{e[r]&&(t?e[r][t]&&delete e[r][t]:delete e[r])};Object.keys(a).forEach(r=>{Object.keys(a[r]).length>0?Object.keys(a[r]).forEach(t=>o(r,t)):o(r)})}static normalizeLocale(e,a){if(!e)throw new Error('"nameOrConfig" parameter can not be empty');if(typeof e=="string"){if(!a)throw new Error('"config" parameter can not be empty');a.locale?a.name=e||a.name:a.localeName=e}else a=e;let o={};if(a.name||a.locale)o=Object.assign({localeName:a.name},a.locale),a.desc&&(o.localeDesc=a.desc),a.code&&(o.localeCode=a.code),a.path&&(o.localePath=a.path);else{if(!a.localeName)throw new Error(`"config" parameter doesn't have "localeName" property`);o=Object.assign({},a)}for(let r of["name","desc","code","path"])o[r]&&delete o[r];if(!o.localeName)throw new Error("Locale name can not be empty");return o}static get locales(){return globalThis.bryntum.locales||{}}static set locales(e){globalThis.bryntum.locales=e}static get localeName(){return globalThis.bryntum.locale||"En"}static set localeName(e){globalThis.bryntum.locale=e||s.localeName}static get locale(){return s.localeName&&this.locales[s.localeName]||this.locales.En||Object.values(this.locales)[0]||{localeName:"",localeDesc:"",localeCoode:""}}static publishLocale(e,a){let{locales:o}=globalThis.bryntum,r=s.normalizeLocale(e,a),{localeName:t}=r;return!o[t]||a===!0?o[t]=r:o[t]=this.mergeLocales(o[t]||{},r||{}),o[t]}},p=s;h(p,"skipLocaleIntegrityCheck",!1),globalThis.bryntum=globalThis.bryntum||{},globalThis.bryntum.locales=globalThis.bryntum.locales||{},p._$name="LocaleHelper";var k={localeName:"Sk",localeDesc:"Slovenský",localeCode:"sk",Object:{Yes:"Áno",No:"Nie",Cancel:"Zrušiť",Ok:"OK",Week:"Týždeň"},ColorPicker:{noColor:"Žiadna farba"},Combo:{noResults:"Žiadne výsledky",recordNotCommitted:"Záznam sa nepodarilo pridať",addNewValue:e=>`Pridať ${e}`},FilePicker:{file:"Súbor"},Field:{badInput:"Neplatná hodnota poľa",patternMismatch:"Hodnota by sa mala zhodovať so špecifickým vzorom",rangeOverflow:e=>`Hodnota mus byť menšia alebo rovná ${e.max}`,rangeUnderflow:e=>`Hodnota musí byť väčšia alebo rovná ${e.min}`,stepMismatch:"Hodnota by sa mala zhodovať s krokom",tooLong:"Hodnota by mala byť kratšia",tooShort:"Hodnota by mala byť dlhšia",typeMismatch:"Požaduje sa, aby hodnota bola v špeciálnom formáte",valueMissing:"Toto políčko sa požaduje",invalidValue:"Neplatná hodnota políčka",minimumValueViolation:"Narušenie minimálnej hodnoty",maximumValueViolation:"Narušenie maximálnej hodnoty",fieldRequired:"Toto políčko sa požaduje",validateFilter:"Hodnota musí byť zvolená zo zoznamu"},DateField:{invalidDate:"Vloženie neplatného dátumu"},DatePicker:{gotoPrevYear:"Prejsť na predchádzajúci rok",gotoPrevMonth:"Prejsť na predchádzajúci mesiac",gotoNextMonth:"Prejsť na nasledujúci mesiac",gotoNextYear:"Prejsť na nalsedujúci rok"},NumberFormat:{locale:"sk",currency:"EUR"},DurationField:{invalidUnit:"Neplatná jednotka"},TimeField:{invalidTime:"Vloženie neplatného času"},TimePicker:{hour:"Hodina",minute:"Minúta",second:"Sekunda"},List:{loading:"Načítavanie...",selectAll:"Vybrať všetko"},GridBase:{loadMask:"Načítavanie...",syncMask:"ukladajú sa zmeny, čakajte..."},PagingToolbar:{firstPage:"Prejsť na prvú stranu",prevPage:"Prejsť na predchádzajúcu stranu",page:"Strana",nextPage:"Prejsť na nasledujúcu stranu",lastPage:"Prejsť na poslednú stranu",reload:"Znovu načítať súčasnú stranu",noRecords:"Žiadne záznamy na zobrazenie",pageCountTemplate:e=>`z ${e.lastPage}`,summaryTemplate:e=>`Zobrazujú sa záznamy ${e.start} - ${e.end} z ${e.allCount}`},PanelCollapser:{Collapse:"Zbaliť",Expand:"Rozbaliť"},Popup:{close:"Zatvoriť vyskakovacie okno"},UndoRedo:{Undo:"Vrátiť späť",Redo:"Znovu vykonať",UndoLastAction:"Vrátiť späť poslednú akciu",RedoLastAction:"Znovu urobiť poslednú nevykonanú akciu",NoActions:"Žiadne položky v rade na vrátenie späť"},FieldFilterPicker:{equals:"rovná sa",doesNotEqual:"nerovná sa",isEmpty:"je prázdne",isNotEmpty:"nie je prázdne",contains:"obsahuje",doesNotContain:"neobsahuje",startsWith:"začína na",endsWith:"končí na",isOneOf:"je jeden z",isNotOneOf:"nie je jedno z",isGreaterThan:"je väčšie než",isLessThan:"je menšie než",isGreaterThanOrEqualTo:"je väčšie alebo sa rovná",isLessThanOrEqualTo:"je menšie alebo sa rovná",isBetween:"je medzi",isNotBetween:"nie je medzi",isBefore:"je pred",isAfter:"je po",isToday:"je dnes",isTomorrow:"je zajtra",isYesterday:"je včera",isThisWeek:"je tento týždeň",isNextWeek:"je budúci týždeň",isLastWeek:"je minulý týždeň",isThisMonth:"je tento mesiac",isNextMonth:"je budúci mesiac",isLastMonth:"je minulý mesiac",isThisYear:"je tento rok",isNextYear:"je budúci rok",isLastYear:"je minulý rok",isYearToDate:"je rok do dnešného dňa",isTrue:"je správne",isFalse:"je nesprávne",selectAProperty:"Vyberte vlastnosť",selectAnOperator:"Vyberte operátora",caseSensitive:"Rozlišuje malé a veľké písmená",and:"a",dateFormat:"D/M/YY",selectOneOrMoreValues:"Vyberte jednu alebo viac hodnôt",enterAValue:"Zadajte hodnotu",enterANumber:"Zadajte číslo",selectADate:"Vyberte dátum"},FieldFilterPickerGroup:{addFilter:"Pridajte filter"},DateHelper:{locale:"sk",weekStartDay:1,nonWorkingDays:{0:!0,6:!0},weekends:{0:!0,6:!0},unitNames:[{single:"milisekunda",plural:"ms",abbrev:"ms"},{single:"sekunda",plural:"sekundy",abbrev:"s"},{single:"minúta",plural:"minúty",abbrev:"min"},{single:"hodina",plural:"hodiny",abbrev:"h"},{single:"deň",plural:"dni",abbrev:"d"},{single:"týždeň",plural:"týždne",abbrev:"tžd"},{single:"mesiac",plural:"mesiace",abbrev:"msc"},{single:"štvrť",plural:"štvrtiny",abbrev:""},{single:"rok",plural:"roky",abbrev:"rk"},{single:"dekáda",plural:"dekády",abbrev:"dek"}],unitAbbreviations:[["mil"],["s","sec"],["m","min"],["h","h"],["d"],["tžd","tžd"],["msc","msc","msc"],["štvrť","štvrť","štvrť"],["rk","rk"],["dek"]],parsers:{L:"D. M. YYYY.",LT:"HH:mm",LTS:"HH:mm:ss A"},ordinalSuffix:e=>e+"."}},x=p.publishLocale(k),j=new String,f={localeName:"Sk",localeDesc:"Slovenský",localeCode:"sk",ColumnPicker:{column:"Stĺpec",columnsMenu:"Stĺpce",hideColumn:"Skryť stĺpec",hideColumnShort:"Skryť",newColumns:"Nové stĺpce"},Filter:{applyFilter:"Použiť filter",filter:"Filter",editFilter:"Upraviť filter",on:"On",before:"Pred",after:"Po",equals:"Rovná sa",lessThan:"Menej ako",moreThan:"Viac ako",removeFilter:"Odstrániť filter",disableFilter:"Deaktivovať filter"},FilterBar:{enableFilterBar:"Ukázať lištu filtra",disableFilterBar:"Skryť lištu filtra"},Group:{group:"Group",groupAscending:"Vzostup skupiny",groupDescending:"Pokles skupiny",groupAscendingShort:"Vzostu",groupDescendingShort:"Pokles",stopGrouping:"Zastaviť zoskupovanie",stopGroupingShort:"Zastaviť"},HeaderMenu:{moveBefore:e=>`Pohyb pred "${e}"`,moveAfter:e=>`Pohyb po "${e}"`,collapseColumn:"Zbaliť stĺpec",expandColumn:"Rozbaliť stĺpec"},ColumnRename:{rename:"Premenovať"},MergeCells:{mergeCells:"Zlúčiť bunky",menuTooltip:"Zlúčiť bunky s rovnakou hodnotou, keď sú triedené podľa tohto stĺpca"},Search:{searchForValue:"Hľadať hodnotu"},Sort:{sort:"Sort",sortAscending:"Triediť vzrastajúce",sortDescending:"Triediť klesajúce",multiSort:"Viacnásobné triedenie",removeSorter:"Odstrániť filter",addSortAscending:"Pridať stúpajúci filetr",addSortDescending:"Pridať klesajúci filter",toggleSortAscending:"Zmeniť na stúpajúci",toggleSortDescending:"Zmeniť na klesajúci",sortAscendingShort:"Stúpajúci",sortDescendingShort:"Klesajúci",removeSorterShort:"Odstrániť",addSortAscendingShort:"+ Stúpajúci",addSortDescendingShort:"+ Klesajúci"},Split:{split:"Rozdelené",unsplit:"Nerozdelené",horizontally:"Horizontálne",vertically:"Vertikálne",both:"Obe"},Column:{columnLabel:e=>`${e.text?`${e.text} stĺpec. `:""}MEDZERNÍK pre kontextové menu${e.sortable?", ZADAŤ na triedenie":""}`,cellLabel:j},Checkbox:{toggleRowSelect:"Prepnúť výber riadka",toggleSelection:"Prepnúť výber celej sady údajov"},RatingColumn:{cellLabel:e=>{var a;return`${e.text?e.text:""} ${(a=e.location)!=null&&a.record?`hodnotenie : ${e.location.record.get(e.field)||0}`:""}`}},GridBase:{loadFailedMessage:"Načítavanie údajov zlyhalo!",syncFailedMessage:"Synchronizácia údajov zlyhala!",unspecifiedFailure:"Nešpecifikované zlyhanie",networkFailure:"Chyba siete",parseFailure:"Analýza odpovede server zlyhala",serverResponse:"Odpoveď servera:",noRows:"Žiadne záznamy na zobrazenie",moveColumnLeft:"Presunúť do ľavej časti",moveColumnRight:"Presunúť do pravej časti",moveColumnTo:e=>`Presunúť stĺpec do ${e}`},CellMenu:{removeRow:"Vymazať"},RowCopyPaste:{copyRecord:"Kopírovať",cutRecord:"Orezať",pasteRecord:"Vložiť",rows:"riadky",row:"radok"},CellCopyPaste:{copy:"Kopírovať",cut:"Vystrihnúť",paste:"Vložiť"},PdfExport:{"Waiting for response from server":"Čakanie na odpoveď servera...","Export failed":"Export zlyhal","Server error":"Chyba servera","Generating pages":"Generujú sa stránky...","Click to abort":"Zrušiť"},ExportDialog:{width:"40em",labelWidth:"12em",exportSettings:"Exportovať nastavenia",export:"Exportovať",exporterType:"Kontrolovať stránkovanie",cancel:"Zrušiť",fileFormat:"Formát súboru",rows:"Riadky",alignRows:"Zarovnať riaky",columns:"Stĺpce",paperFormat:"Formát papiera",orientation:"Orientácia",repeatHeader:"Zopakovať hlavičku"},ExportRowsCombo:{all:"Všetky riadky",visible:"Viditeľné riadky"},ExportOrientationCombo:{portrait:"Portrét",landscape:"Krajina"},SinglePageExporter:{singlepage:"Jedna strana"},MultiPageExporter:{multipage:"Viaceré strany",exportingPage:({currentPage:e,totalPages:a})=>`Exportuje sa strana ${e}/${a}`},MultiPageVerticalExporter:{multipagevertical:"Viaceré strany (vertikálne)",exportingPage:({currentPage:e,totalPages:a})=>`Exportuje sa strana ${e}/${a}`},RowExpander:{loading:"Načítavanie",expand:"Rozbaliť",collapse:"Zbaliť"},TreeGroup:{group:"Zoskupiť podľa",stopGrouping:"Zastaviť zoskupovanie",stopGroupingThisColumn:"Zrušiť zoskupovanie tejto stĺpca"}},P=p.publishLocale(f);if(typeof n.exports=="object"&&typeof i=="object"){var z=(e,a,o,r)=>{if(a&&typeof a=="object"||typeof a=="function")for(let t of Object.getOwnPropertyNames(a))!Object.prototype.hasOwnProperty.call(e,t)&&t!==o&&Object.defineProperty(e,t,{get:()=>a[t],enumerable:!(r=Object.getOwnPropertyDescriptor(a,t))||r.enumerable});return e};n.exports=z(n.exports,i)}return n.exports});
