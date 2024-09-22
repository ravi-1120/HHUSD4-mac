import loadSalesforceDateFieldWidget from './widget/salesforceDateField';

/**
 * Loads all custom widgets that we want accessible to Bryntum
 * @param bryntumNamespace The namespace will be bryntum.grid, bryntum.scheduler or anything that has bryntum's widgets.
 *                         We will also load our Custom Widgets in this namespace
 */
export function loadAllCustomWidgets(bryntumNamespace) {
  loadSalesforceDateFieldWidget(bryntumNamespace);
};

export default loadAllCustomWidgets;