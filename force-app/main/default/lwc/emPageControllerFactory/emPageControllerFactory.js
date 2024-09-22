import { LightningElement } from 'lwc';
import Container from 'c/container';
import { getService } from 'c/veevaServiceFactory';

import EmPageLayoutEngineService from 'c/emPageLayoutEngineService';
import EventActionService from 'c/eventActionService';
import EmDataService from 'c/emDataService';

import EmController from 'c/emController';
import EmEventController from 'c/emEventController';
import EmEventBudgetController from 'c/emEventBudgetController';
import EmEventTeamMemberController from 'c/emEventTeamMemberController';
import EmExpenseEstimateController from 'c/emExpenseEstimateController';
import EmEventMaterialController from 'c/emEventMaterialController';
import EmEventSessionController from 'c/emEventSessionController';
import EmEventSessionAttendeeController from 'c/emEventSessionAttendeeController';
import EmEventSpeakerController from 'c/emEventSpeakerController';
import EmExpenseHeaderController from 'c/emExpenseHeaderController';
import EmExpenseLineController from 'c/emExpenseLineController';
import EmSpeakerNominationController from 'c/emSpeakerNominationController';
import EmSpeakerCapController from 'c/emSpeakerCapController';
import EmSpeakerController from 'c/emSpeakerController';

const services = Container.SERVICES;
services.singleton('emPageLayoutEngineSvc', EmPageLayoutEngineService, ['dataSvc']);
services.singleton('eventActionSvc', EventActionService, ['dataSvc']);
services.singleton('emDataSvc', EmDataService, ['dataSvc']);

const dataSvc = getService('dataSvc');
const userInterfaceSvc = getService('userInterfaceSvc');
const messageSvc = getService('messageSvc');
const metaStore = getService('metaStore');
const emPageLayoutEngineSvc = getService('emPageLayoutEngineSvc');
const eventActionSvc = getService('eventActionSvc');
const emDataSvc = getService('emDataSvc');
const PAGE_CONTROLLER_ARGS = [dataSvc, userInterfaceSvc, messageSvc, metaStore];
const EM_PAGE_CONTROLLER_ARGS = [...PAGE_CONTROLLER_ARGS, emPageLayoutEngineSvc];

// register EM page controllers
const pageControllers = Container.PAGE_CONTROLLERS;
pageControllers.register('EM_Event_vod__c', EmEventController, [...EM_PAGE_CONTROLLER_ARGS, eventActionSvc, emDataSvc]);
pageControllers.register('EM_Attendee_vod__c', EmController, EM_PAGE_CONTROLLER_ARGS);
pageControllers.register('EM_Event_Budget_vod__c', EmEventBudgetController, EM_PAGE_CONTROLLER_ARGS);
pageControllers.register('EM_Event_Session_vod__c', EmEventSessionController, EM_PAGE_CONTROLLER_ARGS);
pageControllers.register('EM_Event_Session_Attendee_vod__c', EmEventSessionAttendeeController, EM_PAGE_CONTROLLER_ARGS);
pageControllers.register('EM_Event_Speaker_vod__c', EmEventSpeakerController, EM_PAGE_CONTROLLER_ARGS);
pageControllers.register('Expense_Header_vod__c', EmExpenseHeaderController, EM_PAGE_CONTROLLER_ARGS);
pageControllers.register('Expense_Line_vod__c', EmExpenseLineController, EM_PAGE_CONTROLLER_ARGS);
pageControllers.register('EM_Expense_Estimate_vod__c', EmExpenseEstimateController, EM_PAGE_CONTROLLER_ARGS);
pageControllers.register('EM_Event_Material_vod__c', EmEventMaterialController, EM_PAGE_CONTROLLER_ARGS);
pageControllers.register('EM_Event_Team_Member_vod__c', EmEventTeamMemberController, EM_PAGE_CONTROLLER_ARGS);
pageControllers.register('EM_Speaker_Nomination_vod__c', EmSpeakerNominationController, [...PAGE_CONTROLLER_ARGS, emDataSvc]);
pageControllers.register('EM_Speaker_Cap_vod__c', EmSpeakerCapController, PAGE_CONTROLLER_ARGS);
pageControllers.register('EM_Speaker_vod__c', EmSpeakerController, PAGE_CONTROLLER_ARGS);

export default class EmPageControllerFactory extends LightningElement {}