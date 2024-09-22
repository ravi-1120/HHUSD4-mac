import FieldController from 'c/fieldController';

export default class BlankFieldController extends FieldController {
  initTemplate() {
    this.veevaText = true;
    return this;
  }

  get displayValue() {
    return null;
  }

  get rawValue() {
    return null;
  }

  get value() {
    return null;
  }
}