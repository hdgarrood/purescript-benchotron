/* global exports */
/* global require */
"use strict";

// module Benchotron.BenchmarkJS

exports.benchmarkJS = require('benchmark');

exports.monkeyPatchBenchmark = function (b) {
  return function () {
    b.support.decompilation = false;
  };
};

exports.runBenchmarkImpl = function (Benchmark) {
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
