/* global exports */
/* global require */
"use strict";

import { createRequire } from 'module';
const require = createRequire(import.meta.url);
export const benchmarkJS = require('benchmark');

export const monkeyPatchBenchmark = function (b) {
  return function () {
    b.support.decompilation = false;
  };
};

export const runBenchmarkImpl = function (Benchmark) {
  return function (fn) {
    return function () {
      var b = new Benchmark(fn);
      b.run();
      if (typeof b.error !== 'undefined') {
         throw b.error;
      }
      return b.stats;
    };
  };
};
