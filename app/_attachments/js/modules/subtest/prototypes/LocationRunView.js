var LocationRunView,
  __hasProp = Object.prototype.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

LocationRunView = (function(_super) {

  __extends(LocationRunView, _super);

  function LocationRunView() {
    LocationRunView.__super__.constructor.apply(this, arguments);
  }

  LocationRunView.prototype.events = {
    "click #school_list li": "autofill",
    "keyup input": "showOptions",
    "click clear": "clearInputs"
  };

  LocationRunView.prototype.initialize = function(options) {
    var i, school, _len, _ref, _results;
    this.model = this.options.model;
    this.parent = this.options.parent;
    this.haystack = [];
    this.li = _.template("<li style='display:none;' data-index='{{i}}'>{{province}} - {{name}} - {{district}} - {{id}}</li>");
    _ref = this.model.get("schools");
    _results = [];
    for (i = 0, _len = _ref.length; i < _len; i++) {
      school = _ref[i];
      _results.push(this.haystack[i] = school.join("").toLowerCase());
    }
    return _results;
  };

  LocationRunView.prototype.clearInputs = function() {
    return this.$el.find("#school_id, #district, #province, #name").val("");
  };

  LocationRunView.prototype.autofill = function(event) {
    var district, id, index, name, province, school;
    this.$el.find("#autofill").fadeOut(250);
    index = $(event.target).attr("data-index");
    school = this.model.get("schools")[index];
    name = school[2];
    district = school[1];
    id = school[3];
    province = school[0];
    this.$el.find("#school_id").val(id);
    this.$el.find("#district").val(district);
    this.$el.find("#province").val(province);
    return this.$el.find("#name").val(name);
  };

  LocationRunView.prototype.showOptions = function(event) {
    var atLeastOne, i, isThere, li, needle, _len, _ref;
    needle = $(event.target).val().toLowerCase();
    atLeastOne = false;
    _ref = $("#school_list li");
    for (i = 0, _len = _ref.length; i < _len; i++) {
      li = _ref[i];
      isThere = ~this.haystack[i].indexOf(needle);
      if (isThere) $(li).css("display", "block");
      if (!isThere) $(li).css("display", "none");
      if (isThere) atLeastOne = true;
    }
    if (atLeastOne) this.$el.find("#autofill").fadeIn(250);
    if (!atLeastOne) this.$el.find("#autofill").fadeOut(250);
    return true;
  };

  LocationRunView.prototype.render = function() {
    var districtText, i, nameText, provinceText, school, schoolIdText, schoolListElements, _len, _ref;
    provinceText = this.model.get("provinceText");
    districtText = this.model.get("districtText");
    nameText = this.model.get("nameText");
    schoolIdText = this.model.get("schoolIdText");
    schoolListElements = "";
    _ref = this.model.get("schools");
    for (i = 0, _len = _ref.length; i < _len; i++) {
      school = _ref[i];
      schoolListElements += this.li({
        i: i,
        province: school[0],
        district: school[1],
        name: school[2],
        id: school[3]
      });
    }
    this.$el.html("    <form>      <button class='clear command'>Clear</button>      <div class='label_value'>        <label for='province'>" + provinceText + "</label>        <input id='province' name='province' value=''>      </div>      <div class='label_value'>        <label for='district'>" + districtText + "</label>        <input id='district' name='district' value=''>      </div>      <div class='label_value'>        <label for='name'>" + nameText + "</label>        <input id='name' name='name' value=''>      </div>      <div class='label_value'>        <label for='school_id'>" + schoolIdText + "</label>        <input id='school_id' name='school_id' value=''>      </div>    <form>    <div id='autofill' style='display:none'>      <h2>Select one from autofill list</h2>      <ul id='school_list'>        " + schoolListElements + "      </ul>    </div>    ");
    return this.trigger("rendered");
  };

  LocationRunView.prototype.getResult = function() {
    return {
      "province": this.$el.find("#province").val(),
      "district": this.$el.find("#district").val(),
      "school_name": this.$el.find("#name").val(),
      "school_id": this.$el.find("#school_id").val()
    };
  };

  LocationRunView.prototype.isValid = function() {
    var input, _i, _len, _ref;
    this.$el.find(".message").remove();
    _ref = this.$el.find("input");
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      input = _ref[_i];
      if ($(input).val() === "") return false;
    }
    return true;
  };

  LocationRunView.prototype.showErrors = function() {
    var input, _i, _len, _ref, _results;
    _ref = this.$el.find("input");
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      input = _ref[_i];
      if ($(input).val() === "") {
        _results.push($(input).after(" <span class='message'>" + ($('label[for=' + $(input).attr('id') + ']').text()) + " cannot be empty</span>"));
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  };

  LocationRunView.prototype.getSum = function() {
    var $input, counts, input, _i, _len, _ref;
    counts = {
      correct: 0,
      incorrect: 0,
      missing: 0,
      total: 0
    };
    _ref = this.$el.find("input");
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      input = _ref[_i];
      $input = $(input);
      if (($input.val() || "") !== "") counts['correct'] += 1;
      if (false) counts['incorrect'] += 0;
      if (($input.val() || "") === "") counts['missing'] += 1;
      if (true) counts['total'] += 1;
    }
    return {
      correct: counts['correct'],
      incorrect: counts['incorrect'],
      missing: counts['missing'],
      total: counts['total']
    };
  };

  return LocationRunView;

})(Backbone.View);
