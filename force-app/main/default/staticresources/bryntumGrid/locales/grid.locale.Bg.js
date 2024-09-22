/*!
 *
 * Bryntum Grid 5.5.4
 *
 * Copyright(c) 2023 Bryntum AB
 * https://bryntum.com/contact
 * https://bryntum.com/license
 *
 */
(function(n,l){var i=typeof exports=="object";if(typeof define=="function"&&define.amd)define([],l);else if(typeof module=="object"&&module.exports)module.exports=l();else{var c=l(),g=i?exports:n;for(var p in c)g[p]=c[p]}})(typeof self<"u"?self:void 0,()=>{var n={},l={exports:n},i=Object.defineProperty,c=Object.getOwnPropertyDescriptor,g=Object.getOwnPropertyNames,p=Object.prototype.hasOwnProperty,d=(e,o,a)=>o in e?i(e,o,{enumerable:!0,configurable:!0,writable:!0,value:a}):e[o]=a,b=(e,o)=>{for(var a in o)i(e,a,{get:o[a],enumerable:!0})},h=(e,o,a,t)=>{if(o&&typeof o=="object"||typeof o=="function")for(let r of g(o))!p.call(e,r)&&r!==a&&i(e,r,{get:()=>o[r],enumerable:!(t=c(o,r))||t.enumerable});return e},f=e=>h(i({},"__esModule",{value:!0}),e),y=(e,o,a)=>(d(e,typeof o!="symbol"?o+"":o,a),a),m={};b(m,{default:()=>P}),l.exports=f(m);var s=class{static mergeLocales(...e){let o={};return e.forEach(a=>{Object.keys(a).forEach(t=>{typeof a[t]=="object"?o[t]={...o[t],...a[t]}:o[t]=a[t]})}),o}static trimLocale(e,o){let a=(t,r)=>{e[t]&&(r?e[t][r]&&delete e[t][r]:delete e[t])};Object.keys(o).forEach(t=>{Object.keys(o[t]).length>0?Object.keys(o[t]).forEach(r=>a(t,r)):a(t)})}static normalizeLocale(e,o){if(!e)throw new Error('"nameOrConfig" parameter can not be empty');if(typeof e=="string"){if(!o)throw new Error('"config" parameter can not be empty');o.locale?o.name=e||o.name:o.localeName=e}else o=e;let a={};if(o.name||o.locale)a=Object.assign({localeName:o.name},o.locale),o.desc&&(a.localeDesc=o.desc),o.code&&(a.localeCode=o.code),o.path&&(a.localePath=o.path);else{if(!o.localeName)throw new Error(`"config" parameter doesn't have "localeName" property`);a=Object.assign({},o)}for(let t of["name","desc","code","path"])a[t]&&delete a[t];if(!a.localeName)throw new Error("Locale name can not be empty");return a}static get locales(){return globalThis.bryntum.locales||{}}static set locales(e){globalThis.bryntum.locales=e}static get localeName(){return globalThis.bryntum.locale||"En"}static set localeName(e){globalThis.bryntum.locale=e||s.localeName}static get locale(){return s.localeName&&this.locales[s.localeName]||this.locales.En||Object.values(this.locales)[0]||{localeName:"",localeDesc:"",localeCoode:""}}static publishLocale(e,o){let{locales:a}=globalThis.bryntum,t=s.normalizeLocale(e,o),{localeName:r}=t;return!a[r]||o===!0?a[r]=t:a[r]=this.mergeLocales(a[r]||{},t||{}),a[r]}},u=s;y(u,"skipLocaleIntegrityCheck",!1),globalThis.bryntum=globalThis.bryntum||{},globalThis.bryntum.locales=globalThis.bryntum.locales||{},u._$name="LocaleHelper";var v={localeName:"Bg",localeDesc:"Български",localeCode:"bg",Object:{Yes:"Да",No:"Не",Cancel:"Отказ",Ok:"ОК",Week:"Седмица"},ColorPicker:{noColor:"Няма цвят"},Combo:{noResults:"Няма резултати",recordNotCommitted:"Записът не може да бъде добавен",addNewValue:e=>`Добавете ${e}`},FilePicker:{file:"Файл"},Field:{badInput:"Невалидна стойност на полето",patternMismatch:"Стойността трябва да съответства на определен шаблон",rangeOverflow:e=>`Стойността трябва да е по-малка или равна на ${e.max}`,rangeUnderflow:e=>`Стойността трябва да е по-голяма или равна на ${e.min}`,stepMismatch:"Стойността трябва да съответства на стъпката",tooLong:"Стойността трябва да е по-къса",tooShort:"Стойността трябва да е по-дълга",typeMismatch:"Стойността трябва да бъде в специален формат",valueMissing:"Това поле е задължително",invalidValue:"Невалидна стойност на полето",minimumValueViolation:"Нарушение на минималната стойност",maximumValueViolation:"Нарушение на максималната стойност",fieldRequired:"Това поле е задължително",validateFilter:"Стойността трябва да бъде избрана от списъка"},DateField:{invalidDate:"Невалидно въвеждане на дата"},DatePicker:{gotoPrevYear:"Преминаване към предишната година",gotoPrevMonth:"Преминаване към предишния месец",gotoNextMonth:"Преминаване към следващия месец",gotoNextYear:"Преминаване към следващата година"},NumberFormat:{locale:"bg",currency:"BGN"},DurationField:{invalidUnit:"Невалидна единица"},TimeField:{invalidTime:"Невалидно въведено време"},TimePicker:{hour:"Час",minute:"Минута",second:"Секунда"},List:{loading:"Зареждане...",selectAll:"Избери всички"},GridBase:{loadMask:"Зареждане...",syncMask:"Запазване на промените, моля, изчакайте..."},PagingToolbar:{firstPage:"Преминаване на първа страница",prevPage:"Преминаване на предишната страница",page:"Стр.",nextPage:"Преминаване на следващата страница",lastPage:"Преминаване на последната страница",reload:"Презареждане на текущата страница",noRecords:"Няма записи за показване",pageCountTemplate:e=>`от ${e.lastPage}`,summaryTemplate:e=>`Показване на записи ${e.start} - ${e.end} от ${e.allCount}`},PanelCollapser:{Collapse:"Свиване",Expand:"Разгръщане"},Popup:{close:"Затваряне на изскачащ прозорец"},UndoRedo:{Undo:"Отмяна",Redo:"Повтаряне",UndoLastAction:"Отмяна на последното действие",RedoLastAction:"Повторно извършване на последното отменено действие",NoActions:"Няма елементи в опашката за отмяна"},FieldFilterPicker:{equals:"е равно на",doesNotEqual:"не е равно на",isEmpty:"е празно",isNotEmpty:"не е празно",contains:"съдържа",doesNotContain:"не съдържа",startsWith:"започва с",endsWith:"свършва с",isOneOf:"е част от",isNotOneOf:"не е част от",isGreaterThan:"е по-голямо от",isLessThan:"е по-малко от",isGreaterThanOrEqualTo:"е по-голямо от или равно на",isLessThanOrEqualTo:"е по-малко от или равно на",isBetween:"е между",isNotBetween:"не е между",isBefore:"е преди",isAfter:"е след",isToday:"е днес",isTomorrow:"е утре",isYesterday:"е вчера",isThisWeek:"е тази седмица",isNextWeek:"е следващата седмица",isLastWeek:"е миналата седмица",isThisMonth:"е този месец",isNextMonth:"е следващият месец",isLastMonth:"е миналият месец",isThisYear:"е тази година",isNextYear:"е следващата година",isLastYear:"е миналата година",isYearToDate:"е от началото на годината до днес",isTrue:"е вярно",isFalse:"е грешно",selectAProperty:"Избор на свойство",selectAnOperator:"Избор на оператор",caseSensitive:"Чувствителност към малки и големи букви",and:"и",dateFormat:"D/M/YY",selectOneOrMoreValues:"Избор на една или повече стойности",enterAValue:"Въвеждане на стойност",enterANumber:"Въвеждане на число",selectADate:"Избор на дата"},FieldFilterPickerGroup:{addFilter:"Добавяне на филтър"},DateHelper:{locale:"bg",weekStartDay:1,nonWorkingDays:{0:!0,6:!0},weekends:{0:!0,6:!0},unitNames:[{single:"милисекунда",plural:"милисекунди",abbrev:"мсек"},{single:"секунда",plural:"секунди",abbrev:"сек"},{single:"минута",plural:"минути",abbrev:"мин"},{single:"час",plural:"часа",abbrev:"ч"},{single:"ден",plural:"дни",abbrev:"д"},{single:"седмица",plural:"седмици",abbrev:"сед"},{single:"месец",plural:"месеци",abbrev:"мес"},{single:"тримесечие",plural:"тримесечия",abbrev:"трим"},{single:"година",plural:"години",abbrev:"год"},{single:"десетилетие",plural:"десетилетия",abbrev:"десетил"}],unitAbbreviations:[["милисек"],["с","сек"],["м","мин"],["ч","часа"],["д"],["с","сед"],["ме","мес","мсц"],["тр","трим","тримес"],["г","год"],["дес"]],parsers:{L:"DD.MM.YYYY",LT:"HH:mm",LTS:"HH:mm:ss A"},ordinalSuffix:e=>{let o=e[e.length-1],a={1:"-во",2:"-ро",3:"-то"}[o]||"-ти";return e+a}}},w=u.publishLocale(v),x=new String,C={localeName:"Bg",localeDesc:"Български",localeCode:"bg",ColumnPicker:{column:"Колона",columnsMenu:"Колони",hideColumn:"Скриване на колона",hideColumnShort:"Скриване",newColumns:"Нова колона"},Filter:{applyFilter:"Прилагане на филтър",filter:"Филтри",editFilter:"Редактиране на филтър",on:"Вкл.",before:"Преди",after:"След",equals:"Равно",lessThan:"По-малко от",moreThan:"Повече от",removeFilter:"Премахване на филтър",disableFilter:"Деактивиране на филтъра"},FilterBar:{enableFilterBar:"Показване на лентата с филтри",disableFilterBar:"Скриване на лентата с филтри"},Group:{group:"Група",groupAscending:"Възходяща група",groupDescending:"Низходящ група",groupAscendingShort:"Възходящ",groupDescendingShort:"Низходящ",stopGrouping:"Стоп на групиране",stopGroupingShort:"Стоп"},HeaderMenu:{moveBefore:e=>`Преместване преди "${e}"`,moveAfter:e=>`Преместване след "${e}"`,collapseColumn:"Свиване на колона",expandColumn:"Разширяване на колона"},ColumnRename:{rename:"Преименуване"},MergeCells:{mergeCells:"Сливане на клетки",menuTooltip:"Сливане на клетки с една и съща стойност при сортиране по тази колона"},Search:{searchForValue:"Търсене на стойност"},Sort:{sort:"Сортиране",sortAscending:"Сортиране във възходящ ред",sortDescending:"Сортиране в низходящ ред",multiSort:"Мулти сортиране",removeSorter:"Премахване на сортировач",addSortAscending:"Добавяне на възходящ сортировач",addSortDescending:"Добавяне на низходящ сортировач",toggleSortAscending:"Промяна към възходящ",toggleSortDescending:"Промяна към низходящ",sortAscendingShort:"Възходящ",sortDescendingShort:"Низходящ",removeSorterShort:"Отстраняване",addSortAscendingShort:"+ Възходящ",addSortDescendingShort:"+ Низходящ"},Split:{split:"Разделено",unsplit:"Неразделено",horizontally:"Хоризонтално",vertically:"Вертикално",both:"И двете"},Column:{columnLabel:e=>`${e.text?`${e.text} колона. `:""}SPACE за контекстно меню${e.sortable?", ENTER за сортиране":""}`,cellLabel:x},Checkbox:{toggleRowSelect:"Превключване на избора на ред",toggleSelection:"Превключване на избора на целия набор от данни"},RatingColumn:{cellLabel:e=>{var o;return`${e.text?e.text:""} ${(o=e.location)!=null&&o.record?`рейтинг : ${e.location.record.get(e.field)||0}`:""}`}},GridBase:{loadFailedMessage:"Неуспешно зареждане на данни!",syncFailedMessage:"Неуспешна синхронизация за данни!",unspecifiedFailure:"Неуточнена неизправност",networkFailure:"Грешка в мрежата",parseFailure:"Неуспешен анализ на отговора на сървъра",serverResponse:"Отговор на сървъра:",noRows:"Няма записи за показване",moveColumnLeft:"Преместване в лявата част",moveColumnRight:"Преместване в дясната част",moveColumnTo:e=>`Преместване на колоната в ${e}`},CellMenu:{removeRow:"Изтриване"},RowCopyPaste:{copyRecord:"Копирай",cutRecord:"Изрежи",pasteRecord:"Постави",rows:"редове",row:"ред"},CellCopyPaste:{copy:"Копиране",cut:"Изрязване",paste:"Вмъкване"},PdfExport:{"Waiting for response from server":"В очакване на отговор от сървъра...","Export failed":"Неуспешен експорт","Server error":"Грешка в сървъра","Generating pages":"Генериране на страници...","Click to abort":"Отказ"},ExportDialog:{width:"40em",labelWidth:"12em",exportSettings:"Настройки на експорта",export:"Експорт",exporterType:"Контрол на странирането",cancel:"Отказ",fileFormat:"Файлов формат",rows:"Редове",alignRows:"Подравняване на редовете",columns:"Колони",paperFormat:"Формат на документа",orientation:"Ориентация",repeatHeader:"Повтаряне на заглавката"},ExportRowsCombo:{all:"Всички редове",visible:"Видими редове"},ExportOrientationCombo:{portrait:"Портрет",landscape:"Пейзаж"},SinglePageExporter:{singlepage:"Единична страница"},MultiPageExporter:{multipage:"Няколко страници",exportingPage:({currentPage:e,totalPages:o})=>`Експортиране на страница ${e}/${o}`},MultiPageVerticalExporter:{multipagevertical:"Няколко страници (вертикално)",exportingPage:({currentPage:e,totalPages:o})=>`Експортиране на страница ${e}/${o}`},RowExpander:{loading:"Зареждане",expand:"Разгръщане",collapse:"Свиване"},TreeGroup:{group:"Групиране по",stopGrouping:"Спиране на групирането",stopGroupingThisColumn:"Разгрупиране на колона"}},P=u.publishLocale(C);if(typeof l.exports=="object"&&typeof n=="object"){var T=(e,o,a,t)=>{if(o&&typeof o=="object"||typeof o=="function")for(let r of Object.getOwnPropertyNames(o))!Object.prototype.hasOwnProperty.call(e,r)&&r!==a&&Object.defineProperty(e,r,{get:()=>o[r],enumerable:!(t=Object.getOwnPropertyDescriptor(o,r))||t.enumerable});return e};l.exports=T(l.exports,n)}return l.exports});
