import VeevaSectionController from 'c/veevaSectionController';
import template from './emInlineFileSectionController.html';

export default class EmInlineFileSectionController extends VeevaSectionController {
  initTemplate() {
    this.template = template;
    return this;
  }
}