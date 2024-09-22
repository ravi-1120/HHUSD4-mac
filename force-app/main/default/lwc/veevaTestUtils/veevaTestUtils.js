/* eslint-disable no-promise-executor-return */
import EMPTY from './veevaTestUtilsEmptyTemplate.html';

const clearUp = () => {
  const { body } = document;
  while (body.firstChild) {
    body.removeChild(body.firstChild);
  }
  jest.clearAllMocks();
};

const getElement = (from, path) => {
  let result = from;
  path.split(' ').every(x => {
    const pair = x.split(':');
    const saved = result;
    result = (result.shadowRoot || result).querySelectorAll(pair[0])[pair[1] || 0];
    if (result == null) {
      result = saved.querySelectorAll(pair[0])[pair[1] || 0];
    }
    return !!result; // break out of loop if false
  });
  return result;
};

const flushPromises = () => new Promise(resolve => process.nextTick(resolve));

// eslint-disable-next-line @lwc/lwc/no-async-operation
const delay = ms => new Promise(res => setTimeout(res, ms));

export { EMPTY, clearUp, getElement, flushPromises, delay };