/*!
 *
 * Bryntum Calendar 5.6.0
 *
 * Copyright(c) 2023 Bryntum AB
 * https://bryntum.com/contact
 * https://bryntum.com/license
 *
 */
(function(s,i){var l=typeof exports=="object";if(typeof define=="function"&&define.amd)define([],i);else if(typeof module=="object"&&module.exports)module.exports=i();else{var u=i(),m=l?exports:s;for(var p in u)m[p]=u[p]}})(typeof self<"u"?self:void 0,()=>{var s={},i={exports:s},l=Object.defineProperty,u=Object.getOwnPropertyDescriptor,m=Object.getOwnPropertyNames,p=Object.prototype.hasOwnProperty,k=(e,a,o)=>a in e?l(e,a,{enumerable:!0,configurable:!0,writable:!0,value:o}):e[a]=o,h=(e,a)=>{for(var o in a)l(e,o,{get:a[o],enumerable:!0})},b=(e,a,o,n)=>{if(a&&typeof a=="object"||typeof a=="function")for(let t of m(a))!p.call(e,t)&&t!==o&&l(e,t,{get:()=>a[t],enumerable:!(n=u(a,t))||n.enumerable});return e},g=e=>b(l({},"__esModule",{value:!0}),e),j=(e,a,o)=>(k(e,typeof a!="symbol"?a+"":a,o),o),v={};h(v,{default:()=>E}),i.exports=g(v);var y=class c{static mergeLocales(...a){let o={};return a.forEach(n=>{Object.keys(n).forEach(t=>{typeof n[t]=="object"?o[t]={...o[t],...n[t]}:o[t]=n[t]})}),o}static trimLocale(a,o){let n=(t,r)=>{a[t]&&(r?a[t][r]&&delete a[t][r]:delete a[t])};Object.keys(o).forEach(t=>{Object.keys(o[t]).length>0?Object.keys(o[t]).forEach(r=>n(t,r)):n(t)})}static normalizeLocale(a,o){if(!a)throw new Error('"nameOrConfig" parameter can not be empty');if(typeof a=="string"){if(!o)throw new Error('"config" parameter can not be empty');o.locale?o.name=a||o.name:o.localeName=a}else o=a;let n={};if(o.name||o.locale)n=Object.assign({localeName:o.name},o.locale),o.desc&&(n.localeDesc=o.desc),o.code&&(n.localeCode=o.code),o.path&&(n.localePath=o.path);else{if(!o.localeName)throw new Error(`"config" parameter doesn't have "localeName" property`);n=Object.assign({},o)}for(let t of["name","desc","code","path"])n[t]&&delete n[t];if(!n.localeName)throw new Error("Locale name can not be empty");return n}static get locales(){return globalThis.bryntum.locales||{}}static set locales(a){globalThis.bryntum.locales=a}static get localeName(){return globalThis.bryntum.locale||"En"}static set localeName(a){globalThis.bryntum.locale=a||c.localeName}static get locale(){return c.localeName&&this.locales[c.localeName]||this.locales.En||Object.values(this.locales)[0]||{localeName:"",localeDesc:"",localeCoode:""}}static publishLocale(a,o){let{locales:n}=globalThis.bryntum,t=c.normalizeLocale(a,o),{localeName:r}=t;return!n[r]||o===!0?n[r]=t:n[r]=this.mergeLocales(n[r]||{},t||{}),n[r]}};j(y,"skipLocaleIntegrityCheck",!1);var d=y;globalThis.bryntum=globalThis.bryntum||{},globalThis.bryntum.locales=globalThis.bryntum.locales||{},d._$name="LocaleHelper";var z={localeName:"Sk",localeDesc:"Slovenský",localeCode:"sk",Object:{Yes:"Áno",No:"Nie",Cancel:"Zrušiť",Ok:"OK",Week:"Týždeň",None:"Žiadny"},ColorPicker:{noColor:"Žiadna farba"},Combo:{noResults:"Žiadne výsledky",recordNotCommitted:"Záznam sa nepodarilo pridať",addNewValue:e=>`Pridať ${e}`},FilePicker:{file:"Súbor"},Field:{badInput:"Neplatná hodnota poľa",patternMismatch:"Hodnota by sa mala zhodovať so špecifickým vzorom",rangeOverflow:e=>`Hodnota mus byť menšia alebo rovná ${e.max}`,rangeUnderflow:e=>`Hodnota musí byť väčšia alebo rovná ${e.min}`,stepMismatch:"Hodnota by sa mala zhodovať s krokom",tooLong:"Hodnota by mala byť kratšia",tooShort:"Hodnota by mala byť dlhšia",typeMismatch:"Požaduje sa, aby hodnota bola v špeciálnom formáte",valueMissing:"Toto políčko sa požaduje",invalidValue:"Neplatná hodnota políčka",minimumValueViolation:"Narušenie minimálnej hodnoty",maximumValueViolation:"Narušenie maximálnej hodnoty",fieldRequired:"Toto políčko sa požaduje",validateFilter:"Hodnota musí byť zvolená zo zoznamu"},DateField:{invalidDate:"Vloženie neplatného dátumu"},DatePicker:{gotoPrevYear:"Prejsť na predchádzajúci rok",gotoPrevMonth:"Prejsť na predchádzajúci mesiac",gotoNextMonth:"Prejsť na nasledujúci mesiac",gotoNextYear:"Prejsť na nalsedujúci rok"},NumberFormat:{locale:"sk",currency:"EUR"},DurationField:{invalidUnit:"Neplatná jednotka"},TimeField:{invalidTime:"Vloženie neplatného času"},TimePicker:{hour:"Hodina",minute:"Minúta",second:"Sekunda"},List:{loading:"Načítavanie...",selectAll:"Vybrať všetko"},GridBase:{loadMask:"Načítavanie...",syncMask:"ukladajú sa zmeny, čakajte..."},PagingToolbar:{firstPage:"Prejsť na prvú stranu",prevPage:"Prejsť na predchádzajúcu stranu",page:"Strana",nextPage:"Prejsť na nasledujúcu stranu",lastPage:"Prejsť na poslednú stranu",reload:"Znovu načítať súčasnú stranu",noRecords:"Žiadne záznamy na zobrazenie",pageCountTemplate:e=>`z ${e.lastPage}`,summaryTemplate:e=>`Zobrazujú sa záznamy ${e.start} - ${e.end} z ${e.allCount}`},PanelCollapser:{Collapse:"Zbaliť",Expand:"Rozbaliť"},Popup:{close:"Zatvoriť vyskakovacie okno"},UndoRedo:{Undo:"Vrátiť späť",Redo:"Znovu vykonať",UndoLastAction:"Vrátiť späť poslednú akciu",RedoLastAction:"Znovu urobiť poslednú nevykonanú akciu",NoActions:"Žiadne položky v rade na vrátenie späť"},FieldFilterPicker:{equals:"rovná sa",doesNotEqual:"nerovná sa",isEmpty:"je prázdne",isNotEmpty:"nie je prázdne",contains:"obsahuje",doesNotContain:"neobsahuje",startsWith:"začína na",endsWith:"končí na",isOneOf:"je jeden z",isNotOneOf:"nie je jedno z",isGreaterThan:"je väčšie než",isLessThan:"je menšie než",isGreaterThanOrEqualTo:"je väčšie alebo sa rovná",isLessThanOrEqualTo:"je menšie alebo sa rovná",isBetween:"je medzi",isNotBetween:"nie je medzi",isBefore:"je pred",isAfter:"je po",isToday:"je dnes",isTomorrow:"je zajtra",isYesterday:"je včera",isThisWeek:"je tento týždeň",isNextWeek:"je budúci týždeň",isLastWeek:"je minulý týždeň",isThisMonth:"je tento mesiac",isNextMonth:"je budúci mesiac",isLastMonth:"je minulý mesiac",isThisYear:"je tento rok",isNextYear:"je budúci rok",isLastYear:"je minulý rok",isYearToDate:"je rok do dnešného dňa",isTrue:"je správne",isFalse:"je nesprávne",selectAProperty:"Vyberte vlastnosť",selectAnOperator:"Vyberte operátora",caseSensitive:"Rozlišuje malé a veľké písmená",and:"a",dateFormat:"D/M/YY",selectValue:"Vyberte hodnotu",selectOneOrMoreValues:"Vyberte jednu alebo viac hodnôt",enterAValue:"Zadajte hodnotu",enterANumber:"Zadajte číslo",selectADate:"Vyberte dátum"},FieldFilterPickerGroup:{addFilter:"Pridajte filter"},DateHelper:{locale:"sk",weekStartDay:1,nonWorkingDays:{0:!0,6:!0},weekends:{0:!0,6:!0},unitNames:[{single:"milisekunda",plural:"ms",abbrev:"ms"},{single:"sekunda",plural:"sekundy",abbrev:"s"},{single:"minúta",plural:"minúty",abbrev:"min"},{single:"hodina",plural:"hodiny",abbrev:"h"},{single:"deň",plural:"dni",abbrev:"d"},{single:"týždeň",plural:"týždne",abbrev:"tžd"},{single:"mesiac",plural:"mesiace",abbrev:"msc"},{single:"štvrť",plural:"štvrtiny",abbrev:""},{single:"rok",plural:"roky",abbrev:"rk"},{single:"dekáda",plural:"dekády",abbrev:"dek"}],unitAbbreviations:[["mil"],["s","sec"],["m","min"],["h","h"],["d"],["tžd","tžd"],["msc","msc","msc"],["štvrť","štvrť","štvrť"],["rk","rk"],["dek"]],parsers:{L:"D. M. YYYY.",LT:"HH:mm",LTS:"HH:mm:ss A"},ordinalSuffix:e=>e+"."}},C=d.publishLocale(z),f=new String,S={localeName:"Sk",localeDesc:"Slovenský",localeCode:"sk",ColumnPicker:{column:"Stĺpec",columnsMenu:"Stĺpce",hideColumn:"Skryť stĺpec",hideColumnShort:"Skryť",newColumns:"Nové stĺpce"},Filter:{applyFilter:"Použiť filter",filter:"Filter",editFilter:"Upraviť filter",on:"On",before:"Pred",after:"Po",equals:"Rovná sa",lessThan:"Menej ako",moreThan:"Viac ako",removeFilter:"Odstrániť filter",disableFilter:"Deaktivovať filter"},FilterBar:{enableFilterBar:"Ukázať lištu filtra",disableFilterBar:"Skryť lištu filtra"},Group:{group:"Group",groupAscending:"Vzostup skupiny",groupDescending:"Pokles skupiny",groupAscendingShort:"Vzostu",groupDescendingShort:"Pokles",stopGrouping:"Zastaviť zoskupovanie",stopGroupingShort:"Zastaviť"},HeaderMenu:{moveBefore:e=>`Pohyb pred "${e}"`,moveAfter:e=>`Pohyb po "${e}"`,collapseColumn:"Zbaliť stĺpec",expandColumn:"Rozbaliť stĺpec"},ColumnRename:{rename:"Premenovať"},MergeCells:{mergeCells:"Zlúčiť bunky",menuTooltip:"Zlúčiť bunky s rovnakou hodnotou, keď sú triedené podľa tohto stĺpca"},Search:{searchForValue:"Hľadať hodnotu"},Sort:{sort:"Sort",sortAscending:"Triediť vzrastajúce",sortDescending:"Triediť klesajúce",multiSort:"Viacnásobné triedenie",removeSorter:"Odstrániť filter",addSortAscending:"Pridať stúpajúci filetr",addSortDescending:"Pridať klesajúci filter",toggleSortAscending:"Zmeniť na stúpajúci",toggleSortDescending:"Zmeniť na klesajúci",sortAscendingShort:"Stúpajúci",sortDescendingShort:"Klesajúci",removeSorterShort:"Odstrániť",addSortAscendingShort:"+ Stúpajúci",addSortDescendingShort:"+ Klesajúci"},Split:{split:"Rozdelené",unsplit:"Nerozdelené",horizontally:"Horizontálne",vertically:"Vertikálne",both:"Obe"},Column:{columnLabel:e=>`${e.text?`${e.text} stĺpec. `:""}MEDZERNÍK pre kontextové menu${e.sortable?", ZADAŤ na triedenie":""}`,cellLabel:f},Checkbox:{toggleRowSelect:"Prepnúť výber riadka",toggleSelection:"Prepnúť výber celej sady údajov"},RatingColumn:{cellLabel:e=>{var a;return`${e.text?e.text:""} ${(a=e.location)!=null&&a.record?`hodnotenie : ${e.location.record.get(e.field)||0}`:""}`}},GridBase:{loadFailedMessage:"Načítavanie údajov zlyhalo!",syncFailedMessage:"Synchronizácia údajov zlyhala!",unspecifiedFailure:"Nešpecifikované zlyhanie",networkFailure:"Chyba siete",parseFailure:"Analýza odpovede server zlyhala",serverResponse:"Odpoveď servera:",noRows:"Žiadne záznamy na zobrazenie",moveColumnLeft:"Presunúť do ľavej časti",moveColumnRight:"Presunúť do pravej časti",moveColumnTo:e=>`Presunúť stĺpec do ${e}`},CellMenu:{removeRow:"Vymazať"},RowCopyPaste:{copyRecord:"Kopírovať",cutRecord:"Orezať",pasteRecord:"Vložiť",rows:"riadky",row:"radok"},CellCopyPaste:{copy:"Kopírovať",cut:"Vystrihnúť",paste:"Vložiť"},PdfExport:{"Waiting for response from server":"Čakanie na odpoveď servera...","Export failed":"Export zlyhal","Server error":"Chyba servera","Generating pages":"Generujú sa stránky...","Click to abort":"Zrušiť"},ExportDialog:{width:"40em",labelWidth:"12em",exportSettings:"Exportovať nastavenia",export:"Exportovať",printSettings:"Nastavenia tlače",print:"Tlačiť",exporterType:"Kontrolovať stránkovanie",cancel:"Zrušiť",fileFormat:"Formát súboru",rows:"Riadky",alignRows:"Zarovnať riaky",columns:"Stĺpce",paperFormat:"Formát papiera",orientation:"Orientácia",repeatHeader:"Zopakovať hlavičku"},ExportRowsCombo:{all:"Všetky riadky",visible:"Viditeľné riadky"},ExportOrientationCombo:{portrait:"Portrét",landscape:"Krajina"},SinglePageExporter:{singlepage:"Jedna strana"},MultiPageExporter:{multipage:"Viaceré strany",exportingPage:({currentPage:e,totalPages:a})=>`Exportuje sa strana ${e}/${a}`},MultiPageVerticalExporter:{multipagevertical:"Viaceré strany (vertikálne)",exportingPage:({currentPage:e,totalPages:a})=>`Exportuje sa strana ${e}/${a}`},RowExpander:{loading:"Načítavanie",expand:"Rozbaliť",collapse:"Zbaliť"},TreeGroup:{group:"Zoskupiť podľa",stopGrouping:"Zastaviť zoskupovanie",stopGroupingThisColumn:"Zrušiť zoskupovanie tejto stĺpca"}},O=d.publishLocale(S),T={localeName:"Sk",localeDesc:"Slovenský",localeCode:"sk",Object:{newEvent:"Nová udalosť"},ResourceInfoColumn:{eventCountText:e=>e+" udalos"+(e!==1?"ti":"ť")},Dependencies:{from:"From",to:"To",valid:"Platný",invalid:"Neplatný"},DependencyType:{SS:"ZZ",SF:"ZK",FS:"KZ",FF:"KK",StartToStart:"Od začiatku po začiatok",StartToEnd:"Od začiatku po koniec",EndToStart:"Od konca po začiatok",EndToEnd:"Od konca po koniec",short:["ZZ","ZK","KZ","KK"],long:["Od začiatku po začiatok","Od začiatku po koniec","Od konca po začiatok","Od konca po koniec"]},DependencyEdit:{From:"Od",To:"Do",Type:"Typ",Lag:"Lag","Edit dependency":"Upraviť súvislosť",Save:"Uložiť",Delete:"Vymazať",Cancel:"Zrušiť",StartToStart:"Od začiatku po začiatok",StartToEnd:"Od začiatku po koniec",EndToStart:"Od konca po začiatok",EndToEnd:"Od konca po koniec"},EventEdit:{Name:"Názov",Resource:"Zdroj",Start:"Start",End:"End",Save:"Uložiť",Delete:"Vymazať",Cancel:"Zrušiť","Edit event":"Upraviť udalosť",Repeat:"Opakovať"},EventDrag:{eventOverlapsExisting:"Udalosť presahuje existujúcu udalosť pre tento zdroj",noDropOutsideTimeline:"Udalosť nemusí byť úplne klesnutá mimo časového rámca"},SchedulerBase:{"Add event":"Pridať udalosť","Delete event":"Vymazať udalosť","Unassign event":"Zrušiť pridelenie udalosti",color:"Farba"},TimeAxisHeaderMenu:{pickZoomLevel:"Priblížiť",activeDateRange:"Rozsah dátumu",startText:"Dátum začiatku",endText:"Dátum ukončenia",todayText:"Dnes"},EventCopyPaste:{copyEvent:"Kopírovať udalosť",cutEvent:"Odstrániť udalosť",pasteEvent:"Vložiť udalosť"},EventFilter:{filterEvents:"Filtrovať úlohy",byName:"Podľa názvu"},TimeRanges:{showCurrentTimeLine:"Ukázať súčasnú časovú líniu"},PresetManager:{secondAndMinute:{displayDateFormat:"ll LTS",name:"Sekundy"},minuteAndHour:{topDateFormat:"ddd DD. MM., H",displayDateFormat:"ll LST"},hourAndDay:{topDateFormat:"ddd DD. MM.",middleDateFormat:"LST",displayDateFormat:"ll LST",name:"Deň"},day:{name:"Deň/hodiny"},week:{name:"Týždeň/hodiny"},dayAndWeek:{displayDateFormat:"ll LST",name:"Týždeň/dni"},dayAndMonth:{name:"Month"},weekAndDay:{displayDateFormat:"ll LST",name:"Týždeň"},weekAndMonth:{name:"Týždne"},weekAndDayLetter:{name:"Týždne/dni v týždni"},weekDateAndMonth:{name:"Mesiace/týždne"},monthAndYear:{name:"Mesiace"},year:{name:"Roky"},manyYears:{name:"Viac rokov"}},RecurrenceConfirmationPopup:{"delete-title":"Vymazávate udalosť","delete-all-message":"Chcete vymazať všetky výskyty tejto udalosti?","delete-further-message":"Chcete vymazať tento a všetky budúce výskyty tejto udalosti alebo len zvolený výskyt?","delete-further-btn-text":"Vymazať všetky budúce udalosti","delete-only-this-btn-text":"Odstrániť iba túto udalosť","update-title":"Meníte opakujúcu sa udalosť","update-all-message":"Chcete zmeniť všetky výskyty tejto udalosti?","update-further-message":"Chcete zmeniť len tento výskyt udalosti alebo tento a všetky budúce výskyty?","update-further-btn-text":"Všetky budúce udalosti","update-only-this-btn-text":"Len túto udalosť",Yes:"Áno",Cancel:"Zrušiť",width:600},RecurrenceLegend:{" and ":" a ",Daily:"Denne","Weekly on {1}":({days:e})=>`Týždenne v ${e}`,"Monthly on {1}":({days:e})=>`Mesačne v ${e}`,"Yearly on {1} of {2}":({days:e,months:a})=>`Ročne v${e} of ${a}`,"Every {0} days":({interval:e})=>`Každých ${e} days`,"Every {0} weeks on {1}":({interval:e,days:a})=>`Každých ${e} týždňov v ${a}`,"Every {0} months on {1}":({interval:e,days:a})=>`Každých ${e} mesiacov v ${a}`,"Every {0} years on {1} of {2}":({interval:e,days:a,months:o})=>`Každých ${e} rokov v ${a} z ${o}`,position1:"the prvý",position2:"druhý",position3:"tretí",position4:"štvrtý",position5:"piaty","position-1":"ten last",day:"deň",weekday:"pracovný deň","weekend day":"deň víkendu",daysFormat:({position:e,days:a})=>`${e} ${a}`},RecurrenceEditor:{"Repeat event":"Opakovať udalosť",Cancel:"Zrušiť",Save:"Uložiť",Frequency:"Frekvencia",Every:"Každý",DAILYintervalUnit:"day(ni)",WEEKLYintervalUnit:"týždeň(ne)",MONTHLYintervalUnit:"mesiac(e)",YEARLYintervalUnit:"rok(y)",Each:"Každý","On the":"V the","End repeat":"Ukončiť opakovanie","time(s)":"čas(s)"},RecurrenceDaysCombo:{day:"deň",weekday:"pracovný deň","weekend day":"deň víkendu"},RecurrencePositionsCombo:{position1:"prvý",position2:"druhý",position3:"tretí",position4:"štvrtý",position5:"piaty","position-1":"posledný"},RecurrenceStopConditionCombo:{Never:"Nikdy",After:"Po","On date":"V dátum"},RecurrenceFrequencyCombo:{None:"Bez opakovania",Daily:"Denne",Weekly:"Týždenne",Monthly:"Mesačne",Yearly:"Ročne"},RecurrenceCombo:{None:"Žiadny",Custom:"Vlastný..."},Summary:{"Summary for":e=>`Súhrn pre ${e}`},ScheduleRangeCombo:{completeview:"Complete rozvrh",currentview:"Viditeľný rozvrh",daterange:"Rozsah dátumov",completedata:"Dokončiť rozvrh (pre všetky udalosti)"},SchedulerExportDialog:{"Schedule range":"Rozsah rozvrhu","Export from":"Od","Export to":"Do"},ExcelExporter:{"No resource assigned":"Nepridelený žiadny zdroj"},CrudManagerView:{serverResponseLabel:"Odpoveď servera:"},DurationColumn:{Duration:"Trvanie"}},x=d.publishLocale(T),D={localeName:"Sk",localeDesc:"Slovenský",localeCode:"sk",EventEdit:{Calendar:"Kalendár","All day":"Celý deň",day:"Deň",week:"Týždeň",month:"Mesiac",year:"Rok",decade:"Dekáda"},EventMenu:{duplicateEvent:"Duplicitná udalosť",copy:"kopírovať"},Calendar:{Today:"Dnes",next:e=>`Ďalší ${e}`,previous:e=>`Predchádzajúci ${e}`,plusMore:e=>`+${e} viac`,allDay:"Celý deň",endsOn:e=>`Končí ${e}`,weekOfYear:([e,a])=>`Týždeň ${a}, ${e}`,loadFail:"Načítanie údajov z kalendára zlyhalo. Kontaktujte správcu systému"},CalendarDrag:{holdCtrlForRecurrence:"Podržte CTRL pre opakujúcu sa udalosť"},CalendarMixin:{eventCount:e=>`${e||"Žiadne"} udalos${e&&e>1?"ti":"ť"}`},EventTip:{"Edit event":"Upraviť udalosť",timeFormat:"LST"},ModeSelector:{includeWeekends:"Zahrnúť víkendy",weekends:"Víkendy"},AgendaView:{Agenda:"Agenda"},MonthView:{Month:"Mesiac",monthUnit:"mesiac"},WeekView:{weekUnit:"týždeň"},YearView:{Year:"Rok",yearUnit:"rok",noEvents:"Žiadne udalosti"},EventList:{List:"Zoznam",Start:"Začať",Finish:"Skončiť",days:e=>`${e===1?"den":e===0?"0 dní":`${e} dni`}`},DayView:{Day:"Deň",dayUnit:"deň",daysUnit:"dni",expandAllDayRow:"Rozšíriť časť celého dňa",collapseAllDayRow:"Zložiť časť celého dňa",timeFormat:"LST"},DayResourceView:{dayResourceView:"Denné zdroje"},Sidebar:{"Filter events":"Filtrovať udalosti"},WeekExpander:{expandTip:"Kliknúť pre rozšírenie riadka",collapseTip:"Kliknúť pre zloženie riadka"}},E=d.publishLocale(D);if(typeof i.exports=="object"&&typeof s=="object"){var P=(e,a,o,n)=>{if(a&&typeof a=="object"||typeof a=="function")for(let t of Object.getOwnPropertyNames(a))!Object.prototype.hasOwnProperty.call(e,t)&&t!==o&&Object.defineProperty(e,t,{get:()=>a[t],enumerable:!(n=Object.getOwnPropertyDescriptor(a,t))||n.enumerable});return e};i.exports=P(i.exports,s)}return i.exports});
