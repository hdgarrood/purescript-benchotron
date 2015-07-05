/* global exports */
"use strict";

// module Benchotron.Core

exports.handleBenchmarkException = function (name) {
  return function (size) {
    return function (innerAction) {
      return function () {
        try {
          return innerAction();
        } catch(innerError) {
          throw new Error(
            'While running Benchotron benchmark function: ' + name + ' ' +
              'at n=' + String(size) + ':\n' +
              innerError.name + ': ' + innerError.message);
        }
      };
    };
  };
};
