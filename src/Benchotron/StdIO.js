/* global exports */
/* global process */
"use strict";

export const stdoutWrite = function (str) {
  return function () {
    process.stdout.write(str);
  };
};

export const stderrWrite = function (str) {
  return function () {
    process.stderr.write(str);
  };
};

export const closeInterface = function (i) {
  return function() {
    i.close();
  };
};
