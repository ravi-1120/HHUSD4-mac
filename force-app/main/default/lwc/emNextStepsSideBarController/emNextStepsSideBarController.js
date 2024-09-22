import VeevaSideBarController from 'c/veevaSideBarController';
import template from './emNextStepsSideBarController.html';

export default class EmNextStepsSideBarController extends VeevaSideBarController {
  get hasContent() {
    return !!this.content;
  }

  initTemplate() {
    this.template = template;
    this.content = this.pageCtrl.nextStepsContent;
    this.title = this.pageCtrl.nextStepsTitle;
    return super.initTemplate();
  }
}