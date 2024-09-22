/* global bryntum */
export default function createModelClass(fields) {
  return class ModelClass extends bryntum.grid.Model {
    static get fields() {
      return fields;
    }
  };
}