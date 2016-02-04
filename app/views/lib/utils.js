var cell, gridValueMap, surveyValueMap, translatedGridValue, translatedSurveyValue;

gridValueMap = {
  C: "1",
  I: "0",
  M: ".",
  S: "999"
};

surveyValueMap = {
  C: "1",
  U: "0",
  N: ".",
  S: "999"
};

translatedGridValue = function(databaseValue) {
  if (databaseValue == null) {
    databaseValue = "no_record";
  }
  return gridValueMap[databaseValue] || String(databaseValue);
};

translatedSurveyValue = function(databaseValue) {
  if (databaseValue == null) {
    databaseValue = "no_record";
  }
  return surveyValueMap[databaseValue] || String(databaseValue);
};

cell = function(subtest, key, value) {
  var idValue, machineName;
  idValue = (subtest.subtestId || String(subtest)).substr(-3);
  machineName = idValue + "-" + key;
  return {
    k: key,
    v: value,
    m: machineName
  };
};

exports.cell = cell;

exports.translatedSurveyValue = translatedSurveyValue;

exports.translatedGridValue = translatedGridValue;
