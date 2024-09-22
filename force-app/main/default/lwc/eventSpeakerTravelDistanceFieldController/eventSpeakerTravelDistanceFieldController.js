import FieldController from 'c/fieldController';
import travelDistanceFieldTemplate from './eventSpeakerTravelDistanceField.html';

export default class EventSpeakerTravelDistanceFieldController extends FieldController {

  initTemplate() {
    this.template = travelDistanceFieldTemplate;
    return super.initTemplate();
  }

  get inputAddon() {
    return true;
  }
}