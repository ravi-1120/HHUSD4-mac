/*!
 *
 * Bryntum Calendar 5.6.0
 *
 * Copyright(c) 2023 Bryntum AB
 * https://bryntum.com/contact
 * https://bryntum.com/license
 *
 */
(function(s,l){var i=typeof exports=="object";if(typeof define=="function"&&define.amd)define([],l);else if(typeof module=="object"&&module.exports)module.exports=l();else{var p=l(),m=i?exports:s;for(var u in p)m[u]=p[u]}})(typeof self<"u"?self:void 0,()=>{var s={},l={exports:s},i=Object.defineProperty,p=Object.getOwnPropertyDescriptor,m=Object.getOwnPropertyNames,u=Object.prototype.hasOwnProperty,v=(e,t,o)=>t in e?i(e,t,{enumerable:!0,configurable:!0,writable:!0,value:o}):e[t]=o,b=(e,t)=>{for(var o in t)i(e,o,{get:t[o],enumerable:!0})},h=(e,t,o,r)=>{if(t&&typeof t=="object"||typeof t=="function")for(let a of m(t))!u.call(e,a)&&a!==o&&i(e,a,{get:()=>t[a],enumerable:!(r=p(t,a))||r.enumerable});return e},f=e=>h(i({},"__esModule",{value:!0}),e),E=(e,t,o)=>(v(e,typeof t!="symbol"?t+"":t,o),o),g={};b(g,{default:()=>S}),l.exports=f(g);var y=class d{static mergeLocales(...t){let o={};return t.forEach(r=>{Object.keys(r).forEach(a=>{typeof r[a]=="object"?o[a]={...o[a],...r[a]}:o[a]=r[a]})}),o}static trimLocale(t,o){let r=(a,n)=>{t[a]&&(n?t[a][n]&&delete t[a][n]:delete t[a])};Object.keys(o).forEach(a=>{Object.keys(o[a]).length>0?Object.keys(o[a]).forEach(n=>r(a,n)):r(a)})}static normalizeLocale(t,o){if(!t)throw new Error('"nameOrConfig" parameter can not be empty');if(typeof t=="string"){if(!o)throw new Error('"config" parameter can not be empty');o.locale?o.name=t||o.name:o.localeName=t}else o=t;let r={};if(o.name||o.locale)r=Object.assign({localeName:o.name},o.locale),o.desc&&(r.localeDesc=o.desc),o.code&&(r.localeCode=o.code),o.path&&(r.localePath=o.path);else{if(!o.localeName)throw new Error(`"config" parameter doesn't have "localeName" property`);r=Object.assign({},o)}for(let a of["name","desc","code","path"])r[a]&&delete r[a];if(!r.localeName)throw new Error("Locale name can not be empty");return r}static get locales(){return globalThis.bryntum.locales||{}}static set locales(t){globalThis.bryntum.locales=t}static get localeName(){return globalThis.bryntum.locale||"En"}static set localeName(t){globalThis.bryntum.locale=t||d.localeName}static get locale(){return d.localeName&&this.locales[d.localeName]||this.locales.En||Object.values(this.locales)[0]||{localeName:"",localeDesc:"",localeCoode:""}}static publishLocale(t,o){let{locales:r}=globalThis.bryntum,a=d.normalizeLocale(t,o),{localeName:n}=a;return!r[n]||o===!0?r[n]=a:r[n]=this.mergeLocales(r[n]||{},a||{}),r[n]}};E(y,"skipLocaleIntegrityCheck",!1);var c=y;globalThis.bryntum=globalThis.bryntum||{},globalThis.bryntum.locales=globalThis.bryntum.locales||{},c._$name="LocaleHelper";var C={localeName:"Ru",localeDesc:"Русский",localeCode:"ru",Object:{Yes:"Да",No:"Нет",Cancel:"Отмена",Ok:"OK",Week:"Неделя",None:"Нет"},ColorPicker:{noColor:"Нет цвета"},Combo:{noResults:"Нет результатов",recordNotCommitted:"Запись не может быть добавлена",addNewValue:e=>`добавить ${e}`},FilePicker:{file:"Файл"},Field:{badInput:"Недопустимое значение поля",patternMismatch:"Значение должно соответствовать определенному шаблону",rangeOverflow:e=>`Значение должно быть меньше или равно ${e.max}`,rangeUnderflow:e=>`Значение должно быть больше или равно ${e.min}`,stepMismatch:"Значение должно соответствовать шагу",tooLong:"Значение должно быть короче",tooShort:"Значение должно быть длиннее",typeMismatch:"Значение должно быть в специальном формате",valueMissing:"Поле не может быть пустым",invalidValue:"Недопустимое значение поля",minimumValueViolation:"Нарушение минимального значения",maximumValueViolation:"Нарушение максимального значения",fieldRequired:"Поле не может быть пустым",validateFilter:"Выберите значение из списка"},DateField:{invalidDate:"Неверный формат даты"},DatePicker:{gotoPrevYear:"Перейти к предыдущему году",gotoPrevMonth:"Перейти к предыдущему месяцу",gotoNextMonth:"Перейти в следующий месяц",gotoNextYear:"Перейти в следующий год"},NumberFormat:{locale:"ru",currency:"RUB"},DurationField:{invalidUnit:"Неверные единицы"},TimeField:{invalidTime:"Неверный формат времени"},TimePicker:{hour:"Час",minute:"Минуты",second:"секунда"},List:{loading:"Загрузка...",selectAll:"Выбрать все"},GridBase:{loadMask:"Загрузка...",syncMask:"Сохраняю данные, пожалуйста подождите..."},PagingToolbar:{firstPage:"Перейти на первую страницу",prevPage:"Перейти на предыдущую страницу",page:"страница",nextPage:"Перейти на следующую страницу",lastPage:"Перейти на последнюю страницу",reload:"Перезагрузить текущую страницу",noRecords:"Нет записей для отображения",pageCountTemplate:e=>`из ${e.lastPage}`,summaryTemplate:e=>`Показаны записи ${e.start} - ${e.end} из ${e.allCount}`},PanelCollapser:{Collapse:"Свернуть",Expand:"Развернуть"},Popup:{close:"Закрыть"},UndoRedo:{Undo:"Отменить",Redo:"Повторить",UndoLastAction:"Отменить последнее действие",RedoLastAction:"Повторить последнее отмененное действие",NoActions:"Нет записей в очереди отмены"},FieldFilterPicker:{equals:"равен",doesNotEqual:"не равен",isEmpty:"пустой",isNotEmpty:"не пустой",contains:"содержит",doesNotContain:"не содержит",startsWith:"начинается c",endsWith:"заканчивается с",isOneOf:"входит в",isNotOneOf:"не входит в",isGreaterThan:"больше чем",isLessThan:"меньше чем",isGreaterThanOrEqualTo:"больше или равен",isLessThanOrEqualTo:"меньше или равен",isBetween:"между",isNotBetween:"не между",isBefore:"до",isAfter:"после",isToday:"сегодня",isTomorrow:"завтра",isYesterday:"вчера",isThisWeek:"эта неделя",isNextWeek:"следующая неделя",isLastWeek:"последняя неделя",isThisMonth:"этот месяц",isNextMonth:"следующий месяц",isLastMonth:"последний месяц",isThisYear:"этот год",isNextYear:"следующий год",isLastYear:"последний год",isYearToDate:"год по дате",isTrue:"правда",isFalse:"ложь",selectAProperty:"Выбор свойства",selectAnOperator:"Выбор оператора",caseSensitive:"С учетом регистра",and:"и",dateFormat:"D/M/YYYY",selectValue:"Выберите значение",selectOneOrMoreValues:"Выберите одно или несколько значений",enterAValue:"Введите значение",enterANumber:"Введите число",selectADate:"Выберите дату"},FieldFilterPickerGroup:{addFilter:"Добавить фильтр"},DateHelper:{locale:"ru",weekStartDay:1,nonWorkingDays:{0:!0,6:!0},weekends:{0:!0,6:!0},unitNames:[{single:"миллисек",plural:"миллисек",abbrev:"мс"},{single:"секунда",plural:"секунд",abbrev:"с"},{single:"минута",plural:"минут",abbrev:"мин"},{single:"час",plural:"часов",abbrev:"ч"},{single:"день",plural:"дней",abbrev:"д"},{single:"неделя",plural:"недели",abbrev:"нед"},{single:"месяц",plural:"месяцев",abbrev:"мес"},{single:"квартал",plural:"кварталов",abbrev:"квар"},{single:"год",plural:"лет",abbrev:"г"},{single:"десятилетие",plural:"десятилетия",abbrev:"дес"}],unitAbbreviations:[["мс","мил"],["с","сек"],["м","мин"],["ч"],["д","ден","дне"],["н","нед"],["мес"],["к","квар","квр"],["г"],["дес"]],parsers:{L:"DD.MM.YYYY",LT:"HH:mm",LTS:"HH:mm:ss"},ordinalSuffix:e=>`${e}-й`}},$=c.publishLocale(C),w=new String,T={localeName:"Ru",localeDesc:"Русский",localeCode:"ru",ColumnPicker:{column:"Колонка",columnsMenu:"Колонки",hideColumn:"Спрятать колонку",hideColumnShort:"Спрятать",newColumns:"Новые столбцы"},Filter:{applyFilter:"Применить фильтр",filter:"Фильтр",editFilter:"Изменить фильтр",on:"В этот день",before:"До",after:"После",equals:"Равно",lessThan:"Меньше, чем",moreThan:"Больше, чем",removeFilter:"Убрать фильтр",disableFilter:"Отключить фильтр"},FilterBar:{enableFilterBar:"Показать панель фильтров",disableFilterBar:"Спрятать панель фильтров"},Group:{group:"Группа",groupAscending:"Группа по возрастанию",groupDescending:"Группа по убыванию",groupAscendingShort:"Возрастание",groupDescendingShort:"Убывание",stopGrouping:"Убрать группу",stopGroupingShort:"Убрать"},HeaderMenu:{moveBefore:e=>`Расположить перед "${e}"`,moveAfter:e=>`Расположить после "${e}"`,collapseColumn:"Свернуть колонку",expandColumn:"Развернуть колонку"},ColumnRename:{rename:"Переименовать"},MergeCells:{mergeCells:"Объединить ячейки",menuTooltip:"Объединить ячейки с одинаковыми значениями при сортировке по этому столбцу"},Search:{searchForValue:"Найти значение"},Sort:{sort:"Сортировка",sortAscending:"Сортировать по возрастанию",sortDescending:"Сортировать по убыванию",multiSort:"Сложная сортировка",removeSorter:"Убрать сортировку",addSortAscending:"Добавить сортировку по возрастанию",addSortDescending:"Добавить сортировку по убыванию",toggleSortAscending:"Сортировать по возрастанию",toggleSortDescending:"Сортировать по убыванию",sortAscendingShort:"Возрастание",sortDescendingShort:"Убывание",removeSorterShort:"Убрать",addSortAscendingShort:"+ Возраст...",addSortDescendingShort:"+ Убыв..."},Split:{split:"Разделить",unsplit:"Неразделенный",horizontally:"Горизонтально",vertically:"Вертикально",both:"Оба"},Column:{columnLabel:e=>`${e.text?`${e.text} столбец. `:""}ПРОБЕЛ для контекстного меню${e.sortable?", ENTER для сортировки":""}`,cellLabel:w},Checkbox:{toggleRowSelect:"Переключить выделение строки",toggleSelection:"Переключить выбор всего набора данных"},RatingColumn:{cellLabel:e=>{var t;return`${e.text?e.text:""} ${(t=e.location)!=null&&t.record?`rating : ${e.location.record.get(e.field)||0} || 0`:""}`}},GridBase:{loadFailedMessage:"Не удалось загрузить!",syncFailedMessage:"Не удалось синхронизировать!",unspecifiedFailure:"Неуказанная ошибка",networkFailure:"Ошибка сети",parseFailure:"Не удалось разобрать ответ сервера",serverResponse:"Ответ сервера:",noRows:"Нет записей для отображения",moveColumnLeft:"Передвинуть в левую секцию",moveColumnRight:"Передвинуть в правую секцию",moveColumnTo:e=>`Переместить колонку в секцию ${e}`},CellMenu:{removeRow:"Удалить"},RowCopyPaste:{copyRecord:"Копировать",cutRecord:"Вырезать",pasteRecord:"Вставить",rows:"строки",row:"строка"},CellCopyPaste:{copy:"Копировать",cut:"Вырезать",paste:"Вставить"},PdfExport:{"Waiting for response from server":"Ожидание ответа от сервера...","Export failed":"Не удалось экспортировать","Server error":"На сервере произошла ошибка","Generating pages":"Генерация страниц...","Click to abort":"Отмена"},ExportDialog:{width:"40em",labelWidth:"13em",exportSettings:"Настройки",export:"Экспорт",printSettings:"Настройки печати",print:"Печать",exporterType:"Разбивка на страницы",cancel:"Отмена",fileFormat:"Формат файла",rows:"Строки",alignRows:"Выровнять строки",columns:"Колонки",paperFormat:"Размер листа",orientation:"Ориентация",repeatHeader:"Повторять заголовок"},ExportRowsCombo:{all:"Все строки",visible:"Видимые строки"},ExportOrientationCombo:{portrait:"Портретная",landscape:"Ландшафтная"},SinglePageExporter:{singlepage:"Одна страница"},MultiPageExporter:{multipage:"Многостраничный",exportingPage:({currentPage:e,totalPages:t})=>`Экспорт страницы ${e}/${t}`},MultiPageVerticalExporter:{multipagevertical:"Многостраничный (по вертикали)",exportingPage:({currentPage:e,totalPages:t})=>`Экспорт страницы ${e}/${t}`},RowExpander:{loading:"Загрузка",expand:"Развернуть",collapse:"Свернуть"},TreeGroup:{group:"Группировать по",stopGrouping:"Прекратить группировку",stopGroupingThisColumn:"Прекратить группировку этого столбца"}},k=c.publishLocale(T),D={localeName:"Ru",localeDesc:"Русский",localeCode:"ru",Object:{newEvent:"Новое событие"},ResourceInfoColumn:{eventCountText:e=>e+" "+(e>=2&&e<=4?"события":e!==1?"событий":"событие")},Dependencies:{from:"От",to:"К",valid:"Верная",invalid:"Неверная"},DependencyType:{SS:"НН",SF:"НО",FS:"ОН",FF:"ОО",StartToStart:"Начало-Начало",StartToEnd:"Начало-Окончание",EndToStart:"Окончание-Начало",EndToEnd:"Окончание-Окончание",short:["НН","НО","ОН","ОО"],long:["Начало-Начало","Начало-Окончание","Окончание-Начало","Окончание-Окончание"]},DependencyEdit:{From:"От",To:"К",Type:"Тип",Lag:"Запаздывание","Edit dependency":"Редактировать зависимость",Save:"Сохранить",Delete:"Удалить",Cancel:"Отменить",StartToStart:"Начало к Началу",StartToEnd:"Начало к Окончанию",EndToStart:"Окончание к Началу",EndToEnd:"Окончание к Окончанию"},EventEdit:{Name:"Название",Resource:"Ресурс",Start:"Начало",End:"Конец",Save:"Сохранить",Delete:"Удалить",Cancel:"Отмена","Edit event":"Изменить событие",Repeat:"Повтор"},EventDrag:{eventOverlapsExisting:"Событие перекрывает существующее событие для этого ресурса",noDropOutsideTimeline:"Событие не может быть отброшено полностью за пределами графика"},SchedulerBase:{"Add event":"Добавить событие","Delete event":"Удалить событие","Unassign event":"Убрать назначение с события",color:"Цвет"},TimeAxisHeaderMenu:{pickZoomLevel:"Выберите масштаб",activeDateRange:"Диапазон дат",startText:"Начало",endText:"Конец",todayText:"Сегодня"},EventCopyPaste:{copyEvent:"Копировать событие",cutEvent:"Вырезать событие",pasteEvent:"Вставить событие"},EventFilter:{filterEvents:"Фильтровать задачи",byName:"По имени"},TimeRanges:{showCurrentTimeLine:"Показать линию текущего времени"},PresetManager:{secondAndMinute:{name:"секунды"},minuteAndHour:{topDateFormat:"ddd DD.MM, HH:mm"},hourAndDay:{topDateFormat:"ddd DD.MM",name:"день"},day:{name:"день/часы"},week:{name:"Неделя/часы"},dayAndWeek:{name:"Неделя/дни"},dayAndMonth:{name:"месяц"},weekAndDay:{displayDateFormat:"HH:mm",name:"неделяa"},weekAndMonth:{name:"недели"},weekAndDayLetter:{name:"недели/будние дни"},weekDateAndMonth:{name:"Месяцы/недели"},monthAndYear:{name:"Месяцы"},year:{name:"Годы"},manyYears:{name:"Meerdere jaren"}},RecurrenceConfirmationPopup:{"delete-title":"Вы удаляете повторяющееся событие","delete-all-message":"Хотите удалить все повторения этого события?","delete-further-message":"Хотите удалить это и все последующие повторения этого события или только выбранное?","delete-further-btn-text":"Удалить все будущие повторения","delete-only-this-btn-text":"Удалить только это событие","update-title":"Вы изменяете повторяющееся событие","update-all-message":"Изменить все повторения события?","update-further-message":"Изменить только это повторение или это и все последующие повторения события?","update-further-btn-text":"Все будущие повторения","update-only-this-btn-text":"Только это событие",Yes:"Да",Cancel:"Отменить",width:600},RecurrenceLegend:{" and ":" и ",Daily:"Ежедневно","Weekly on {1}":({days:e})=>`Еженедельно (${e})`,"Monthly on {1}":({days:e})=>`Ежемесячно (день: ${e})`,"Yearly on {1} of {2}":({days:e,months:t})=>`Ежегодно (день: ${e}, месяц: ${t})`,"Every {0} days":({interval:e})=>`Каждый ${e} день`,"Every {0} weeks on {1}":({interval:e,days:t})=>`Каждую ${e} неделю, день: ${t}`,"Every {0} months on {1}":({interval:e,days:t})=>`Каждый ${e} месяц, день: ${t}`,"Every {0} years on {1} of {2}":({interval:e,days:t,months:o})=>`Каждый ${e} год, день: ${t} месяц: ${o}`,position1:"первый",position2:"второй",position3:"третий",position4:"четвертый",position5:"пятый","position-1":"последний",day:"день",weekday:"будний день","weekend day":"выходной день",daysFormat:({position:e,days:t})=>`${e} ${t}`},RecurrenceEditor:{"Repeat event":"Повторять событие",Cancel:"Отменить",Save:"Сохранить",Frequency:"Как часто",Every:"Каждый(ую)",DAILYintervalUnit:"день",WEEKLYintervalUnit:"неделю",MONTHLYintervalUnit:"месяц",YEARLYintervalUnit:"год/лет",Each:"Какого числа","On the":"В следующие дни","End repeat":"Прекратить","time(s)":"раз(а)"},RecurrenceDaysCombo:{day:"день",weekday:"будний день","weekend day":"выходной день"},RecurrencePositionsCombo:{position1:"первый",position2:"второй",position3:"третий",position4:"четвертый",position5:"пятый","position-1":"последний"},RecurrenceStopConditionCombo:{Never:"Никогда",After:"После","On date":"В дату"},RecurrenceFrequencyCombo:{None:"Без повторения",Daily:"Каждый день",Weekly:"Каждую неделю",Monthly:"Каждый месяц",Yearly:"Каждый год"},RecurrenceCombo:{None:"Не выбрано",Custom:"Настроить..."},Summary:{"Summary for":e=>`Сводка на ${e}`},ScheduleRangeCombo:{completeview:"Полное расписание",currentview:"Текущая видимая область",daterange:"Диапазон дат",completedata:"Полное расписание (по всем событиям)"},SchedulerExportDialog:{"Schedule range":"Диапазон расписания","Export from":"С","Export to":"По"},ExcelExporter:{"No resource assigned":"Ресурс не назначен"},CrudManagerView:{serverResponseLabel:"Ответ сервера:"},DurationColumn:{Duration:"Длительность"}},F=c.publishLocale(D),x={localeName:"Ru",localeDesc:"Русский",localeCode:"ru",EventEdit:{Calendar:"Календарь","All day":"На весь день",day:"День",week:"Неделя",month:"Месяц",year:"Год",decade:"Десятилетие"},EventMenu:{duplicateEvent:"копировать событие",copy:"копия"},Calendar:{Today:"Сегодня",next:e=>`${e.includes("неделя")?"следующая":"следующий"} ${e}`,previous:e=>`${e.includes("неделя")?"предыдущая":"предыдущий"} ${e}`,plusMore:e=>`Еще +${e}`,allDay:"На весь день",endsOn:e=>`Заканчивается ${e}`,weekOfYear:([e,t])=>`Неделя ${t}, ${e}`,loadFail:"Не удалось загрузить данные календаря. Пожалуйста, обратитесь к системному администратору"},CalendarDrag:{holdCtrlForRecurrence:"Удерживайте CTRL для повторяющегося события"},CalendarMixin:{eventCount:e=>`${e||"Нет"} ${e===1?"событие":"событий"}`},EventTip:{"Edit event":"Редактировать событие",timeFormat:"LT"},ModeSelector:{includeWeekends:"Включить выходные",weekends:"выходные"},AgendaView:{Agenda:"Повестка дня"},MonthView:{Month:"Месяц",monthUnit:"месяц"},WeekView:{weekUnit:"неделя"},YearView:{Year:"Год",yearUnit:"год",noEvents:"Нет событий"},EventList:{List:"Список",Start:"Начало",Finish:"Конец",days:e=>`${e>1?`${e} `:""}${e===1?"день":"дни"}`},DayView:{Day:"День",dayUnit:"день",daysUnit:"дни",expandAllDayRow:"Развернуть группу событий на весь день",collapseAllDayRow:"Свернуть группу событий на весь день",timeFormat:"LT"},DayResourceView:{dayResourceView:"Дневные ресурсы"},Sidebar:{"Filter events":"Фильтровать события"},WeekExpander:{expandTip:"Нажмите, чтобы развернуть строку",collapseTip:"Нажмите, чтобы свернуть строку"}},S=c.publishLocale(x);if(typeof l.exports=="object"&&typeof s=="object"){var R=(e,t,o,r)=>{if(t&&typeof t=="object"||typeof t=="function")for(let a of Object.getOwnPropertyNames(t))!Object.prototype.hasOwnProperty.call(e,a)&&a!==o&&Object.defineProperty(e,a,{get:()=>t[a],enumerable:!(r=Object.getOwnPropertyDescriptor(t,a))||r.enumerable});return e};l.exports=R(l.exports,s)}return l.exports});
