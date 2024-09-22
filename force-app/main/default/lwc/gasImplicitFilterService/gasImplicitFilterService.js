import { createRecord, deleteRecord } from 'lightning/uiRecordApi';
import getImplicitFilterConditions from '@salesforce/apex/VeevaGlobalAccountSearchController.getImplicitFilterConditions';
import getLocationsWithAppliesToValues from '@salesforce/apex/VeevaGlobalAccountSearchController.getLocationsWithAppliesToValues';

import IMPLICIT_FILTER_OBJ from '@salesforce/schema/Implicit_Filter_vod__c';
import IMPLICIT_FILTER_CONDITION_OBJ from '@salesforce/schema/Implicit_Filter_Condition_vod__c';
import FILTER_LOCATION_FIELD from '@salesforce/schema/Implicit_Filter_vod__c.Location_vod__c';
import FILTER_APPLIES_TO_FIELD from '@salesforce/schema/Implicit_Filter_vod__c.Applies_To_vod__c';
import FILTER_INCLUSION_FIELD from '@salesforce/schema/Implicit_Filter_vod__c.Inclusion_vod__c';
import CONDITION_OBJECT_NAME_FIELD from '@salesforce/schema/Implicit_Filter_Condition_vod__c.Object_Name_vod__c';
import CONDITION_FIELD_NAME_FIELD from '@salesforce/schema/Implicit_Filter_Condition_vod__c.Field_Name_vod__c';
import CONDITION_CRITERIA_FIELD from '@salesforce/schema/Implicit_Filter_Condition_vod__c.Criteria_vod__c';
import CONDITION_IMPLICIT_FILTER_REL from '@salesforce/schema/Implicit_Filter_Condition_vod__c.Implicit_Filter_vod__c';

export default class GasImplicitFilterService {
  #locationsWithAppliesToValuesPromise;
  #locationsWithAppliesToValuesMap;

  constructor() {
    this.#locationsWithAppliesToValuesPromise = getLocationsWithAppliesToValues();
  }

  // eslint-disable-next-line class-methods-use-this
  async retrieveConditions(implicitFilterId) {
    const conditions = await getImplicitFilterConditions({ implicitFilterId });
    const convertedConditions = conditions.map(condition => ({
      Id: condition.Id,
      objectName: condition[CONDITION_OBJECT_NAME_FIELD.fieldApiName],
      fieldName: condition[CONDITION_FIELD_NAME_FIELD.fieldApiName],
      criteria: condition[CONDITION_CRITERIA_FIELD.fieldApiName],
    }));
    return convertedConditions;
  }

  async createFilters(filters) {
    const locationsWithAppliesToValuesMap = await this.getLocationsWithAppliesToValuesMap();
    const implicitFiltersCreationInfo = createImplicitFilterCreationInfo(filters, locationsWithAppliesToValuesMap);
    const implicitFilterCreationResultPromises = createRecords(implicitFiltersCreationInfo);
    return convertCreationRecordResult(implicitFilterCreationResultPromises);
  }

  // eslint-disable-next-line class-methods-use-this
  async createConditions(filterId, conditions) {
    const conditionsCreationInfo = createConditionCreationInfo(filterId, conditions);
    const conditionsCreationResultPromises = createRecords(conditionsCreationInfo);
    return convertCreationRecordResult(conditionsCreationResultPromises);
  }

  // eslint-disable-next-line class-methods-use-this
  async deleteConditions(conditions) {
    const conditionsDeleteResultPromises = deleteRecords(conditions);
    return convertDeletionRecordResult(conditionsDeleteResultPromises);
  }

  /**
   * This method creates and deletes Implicit Filter Conditions for a single Implicit Filter based on the following criteria:
   *   - Creates: Condition in currentConditions and not in existingConditions (checking fields)
   *   - Deletes: Condition in existingConditions and not in currentConditions (checking fields)
   *
   * Note no validation is done to confirm that these conditions are part of the passed in Implicit Filter Id
   *
   * @param currentConditions Currently defined Implicit Filter Conditions (Ids are optional)
   * @param existingConditions Existing Implicit Filter Conditions with Ids
   * @returns an array describing which conditions were created or deleted with a success property and message property on failure
   */
  async updateConditions(filterId, currentConditions, existingConditions) {
    const conditionsToCreate = getConditionsToCreate(currentConditions, existingConditions);
    const conditionsToDelete = getConditionsToDelete(currentConditions, existingConditions);
    const createResults = await this.createConditions(filterId, conditionsToCreate);
    const deleteResults = await this.deleteConditions(conditionsToDelete);

    const convertedCreatedResult = createResults.map(createResult => ({
      success: createResult.success,
      created: createResult.success,
      message: createResult.message,
      id: createResult.id,
    }));
    const convertedDeleteResult = deleteResults.map(deleteResult => ({
      success: deleteResult.success,
      deleted: deleteResult.success,
      message: deleteResult.message,
      id: deleteResult.id,
    }));

    return [...convertedCreatedResult, ...convertedDeleteResult];
  }

  async getLocationsWithAppliesToValuesMap() {
    if (!this.#locationsWithAppliesToValuesMap) {
      const locationsWithAppliesToValues = await this.#locationsWithAppliesToValuesPromise;
      const locationsWithAppliesToValuesMap = {};
      locationsWithAppliesToValues.forEach(locationWithAppliesToValues => {
        locationsWithAppliesToValuesMap[locationWithAppliesToValues.value] = locationWithAppliesToValues;
      });
      this.#locationsWithAppliesToValuesMap = locationsWithAppliesToValuesMap;
    }
    return this.#locationsWithAppliesToValuesMap;
  }
}

function getRecordIds(records) {
  return records.map(record => record.Id);
}

function hasValidAppliesToValue(filter, appliesTo, requiresAppliesToValue) {
  let validAppliesTo = true;
  if (filter.appliesTo) {
    validAppliesTo = appliesTo.findIndex(appliesToValue => appliesToValue.value === filter.appliesTo) >= 0;
  } else if (requiresAppliesToValue && !filter.appliesTo) {
    validAppliesTo = false;
  }
  return validAppliesTo;
}

function createImplicitFilterCreationInfo(filters, locationsWithAppliesToValuesMap) {
  const implicitFiltersCreationInfo = filters.map(filter => {
    const { appliesTo: appliesToOptions, requiresAppliesToValue } = locationsWithAppliesToValuesMap[filter.location];
    const hasValidAppliesTo = hasValidAppliesToValue(filter, appliesToOptions, requiresAppliesToValue);
    if (!hasValidAppliesTo) {
      return { create: false, errorMessage: 'Invalid Applies To' };
    }
    return {
      create: true,
      record: {
        apiName: IMPLICIT_FILTER_OBJ.objectApiName,
        fields: {
          [FILTER_LOCATION_FIELD.fieldApiName]: filter.location,
          [FILTER_APPLIES_TO_FIELD.fieldApiName]: filter.appliesTo,
          [FILTER_INCLUSION_FIELD.fieldApiName]: filter.inclusion,
        },
      },
    };
  });
  return implicitFiltersCreationInfo;
}

function createConditionCreationInfo(filterId, conditions) {
  const conditionCreationInfo = conditions.map(condition => ({
    create: true,
    record: {
      apiName: IMPLICIT_FILTER_CONDITION_OBJ.objectApiName,
      fields: {
        [CONDITION_OBJECT_NAME_FIELD.fieldApiName]: condition.objectName,
        [CONDITION_FIELD_NAME_FIELD.fieldApiName]: condition.fieldName,
        [CONDITION_CRITERIA_FIELD.fieldApiName]: condition.criteria,
        [CONDITION_IMPLICIT_FILTER_REL.fieldApiName]: filterId,
      },
    },
  }));
  return conditionCreationInfo;
}

function createRecords(recordCreationInfos) {
  const recordCreationResultPromises = recordCreationInfos.map(recordCreationInfo => {
    if (!recordCreationInfo.create) {
      return Promise.resolve({
        error: true,
        message: recordCreationInfo.errorMessage,
      });
    }
    return createRecord(recordCreationInfo.record);
  });
  return recordCreationResultPromises;
}

function deleteRecords(records) {
  const recordCreationResultPromises = getRecordIds(records).map(recordId => ({
    id: recordId,
    deletePromise: deleteRecord(recordId),
  }));
  return recordCreationResultPromises;
}

async function convertCreationRecordResult(recordResults) {
  return Promise.all(
    recordResults.map(async resultPromise => {
      try {
        const result = await resultPromise;
        return {
          ...result,
          success: !result.error,
        };
      } catch (error) {
        // If an rejection occurs we will handle it here
        const result = {
          success: false,
          error: true,
          message: getErrorMessage(error),
        };
        getErrorMessage(error, result);
        return result;
      }
    })
  );
}

async function convertDeletionRecordResult(recordResults) {
  return Promise.all(
    recordResults.map(async resultPromise => {
      try {
        await resultPromise.deletePromise;
        return {
          id: resultPromise.id,
          success: true,
        };
      } catch (error) {
        // If an rejection occurs we will handle it here
        const result = {
          success: false,
          id: resultPromise.id,
          error: true,
          message: getErrorMessage(error),
        };
        getErrorMessage(error, result);
        return result;
      }
    })
  );
}

function getErrorMessage(error) {
  let errorMessage = error.body.message;
  if (error?.body?.output?.errors?.length > 0) {
    errorMessage = error?.body?.output?.errors[0]?.message ?? error.body.message;
  }
  return errorMessage;
}

function getConditionsToCreate(currentConditions, existingConditions) {
  return currentConditions.filter(
    currentCondition => !existingConditions.some(existingCondition => conditionsEqual(existingCondition, currentCondition))
  );
}

function getConditionsToDelete(currentConditions, existingConditions) {
  return existingConditions.filter(
    existingCondition => !currentConditions.some(currentCondition => conditionsEqual(existingCondition, currentCondition))
  );
}

function conditionsEqual(existingCondition, currentCondition) {
  return (
    existingCondition.objectName === currentCondition.objectName &&
    existingCondition.fieldName === currentCondition.fieldName &&
    existingCondition.criteria === currentCondition.criteria
  );
}