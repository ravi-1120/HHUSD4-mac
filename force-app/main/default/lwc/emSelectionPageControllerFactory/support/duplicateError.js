const DUPLICATE_ERROR = 'DuplicateError';

export default class DuplicateError extends Error {
  constructor(records) {
    super(DUPLICATE_ERROR);
    this.name = DUPLICATE_ERROR;
    this.records = records;
  }
}