export default function addClassSpecifierToHtml(html, className) {
  const lowercaseHtml = html.toLowerCase();
  const htmlArray = html.split('');
  const styleTagRegex = /<style[^>]*>/g;
  // Count keeps track of how many insertions there have been in the array
  let count = 0;
  let startIndex = 0;
  // Loop through every occurence of opening style tag
  while (styleTagRegex.exec(lowercaseHtml) !== null) {
    startIndex = styleTagRegex.lastIndex - 1;
    const endIndex = lowercaseHtml.indexOf('</style>', startIndex);

    if(styleTagFound(startIndex, endIndex)) {
      let nextStartIndex = lowercaseHtml.indexOf('}', startIndex + 1);
      let nextOpenBracketIndex = lowercaseHtml.indexOf('{', startIndex);
      // If it's not the last closing brace before the end of the style tag then put another occurence of the class name
      while(isNotLastBracketInStyleTags(nextStartIndex, endIndex)) {
        // @Media tags are nested in vanilla CSS so need to account for these by putting specifier after first opening bracket
        if(isMediaBeginning(nextOpenBracketIndex, startIndex, lowercaseHtml)) {
          startIndex = nextOpenBracketIndex;
        }
        if(isNotNestedClosingBracket(nextStartIndex, nextOpenBracketIndex)) {
          htmlArray.splice(startIndex + 1 + count, 0, className);
          count++;
          let nextCommaIndex = lowercaseHtml.indexOf(',', startIndex);
          while(isValidNextComma(nextCommaIndex, nextOpenBracketIndex, endIndex)) {
            startIndex = nextCommaIndex;
            htmlArray.splice(startIndex + 1 + count, 0, className);
            count++;
            nextCommaIndex = lowercaseHtml.indexOf(',', startIndex + 1);
          }
        }
        startIndex = nextStartIndex;
        nextStartIndex = lowercaseHtml.indexOf('}', startIndex + 1);
        nextOpenBracketIndex = lowercaseHtml.indexOf('{', startIndex);
      } 
    }
  }
  return htmlArray.join('');
}

function styleTagFound(startIndex, endIndex) {
  return startIndex !== -1 && endIndex !== -1;
}

function isNotLastBracketInStyleTags(nextStartIndex, endIndex) {
  return !(nextStartIndex >= endIndex || nextStartIndex === -1);
}

function isValidNextComma(nextCommaIndex, nextOpenBracketIndex, endIndex) {
  return nextCommaIndex !== -1 && nextOpenBracketIndex < endIndex && nextCommaIndex < nextOpenBracketIndex;
}

function isNotNestedClosingBracket(nextStartIndex, nextOpenBracketIndex) {
  return nextStartIndex >= nextOpenBracketIndex;
}

function isMediaBeginning(nextOpenBracketIndex, startIndex, html) {
  const nextAtSignIndex = html.indexOf('@', startIndex);
  return nextAtSignIndex !== -1 && nextAtSignIndex < nextOpenBracketIndex;
}