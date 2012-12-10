var AssessmentListView,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = Object.prototype.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

AssessmentListView = (function(_super) {

  __extends(AssessmentListView, _super);

  function AssessmentListView() {
    this.newAssessmentSave = __bind(this.newAssessmentSave, this);
    this.render = __bind(this.render, this);
    this.refresh = __bind(this.refresh, this);
    AssessmentListView.__super__.constructor.apply(this, arguments);
  }

  AssessmentListView.prototype.events = {
    'keypress .new_assessment_name': 'newAssessmentSave',
    'click .new_assessment_save': 'newAssessmentSave',
    'click .new_assessment_cancel': 'newAssessmentToggle',
    'click .new_assessment': 'newAssessmentToggle',
    'click .import': 'import',
    'click .groups': 'gotoGroups'
  };

  AssessmentListView.prototype.gotoGroups = function() {
    return Tangerine.router.navigate("groups", true);
  };

  AssessmentListView.prototype["import"] = function() {
    return Tangerine.router.navigate("import", true);
  };

  AssessmentListView.prototype.initialize = function(options) {
    var group, view, _i, _len, _ref, _results;
    this.assessments = options.assessments;
    this.group = options.group;
    this.curriculaListView = new CurriculaListView({
      "curricula": options.curricula
    });
    this.isAdmin = Tangerine.user.isAdmin();
    this.views = [];
    this.publicViews = [];
    this.sections = [this.group, "public"];
    this.groupViews = [];
    if (Tangerine.settings.context === "server") {
      _ref = this.sections;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        group = _ref[_i];
        view = new AssessmentsView({
          "group": group,
          "allAssessments": this.assessments,
          "parent": this
        });
        _results.push(this.groupViews.push(view));
      }
      return _results;
    } else if (Tangerine.settings.context === "mobile") {
      return this.listView = new AssessmentsView({
        "group": false,
        "allAssessments": this.assessments,
        "parent": this
      });
    }
  };

  AssessmentListView.prototype.refresh = function() {
    var _this = this;
    this.assessments = new Assessments;
    return this.assessments.fetch({
      success: function(assessments) {
        var assessmentCount, groupName, i, view, _len, _ref, _results;
        _ref = _this.groupViews;
        _results = [];
        for (i = 0, _len = _ref.length; i < _len; i++) {
          view = _ref[i];
          assessmentCount = assessments.where({
            "group": _this.sections[i],
            "archived": false
          }).length;
          groupName = _this.sections[i] === "public" ? "Public" : _this.sections[i];
          _this.$el.find(".header_" + view.cid).html("" + groupName + " (" + assessmentCount + ")");
          view.allAssessments = assessments;
          _results.push(view.refresh(true));
        }
        return _results;
      }
    });
  };

  AssessmentListView.prototype.render = function() {
    var assessmentCount, groupName, groupsButton, html, i, importButton, newButton, view, _len, _ref;
    newButton = "<button class='new_assessment command'>New</button>";
    importButton = "<button class='import command'>Import</button>";
    groupsButton = "<button class='navigation groups'>Groups</button>";
    html = "      " + (Tangerine.settings.context === "server" ? groupsButton : "") + "      <h1>Assessments</h1>      ";
    if (this.isAdmin) {
      html += "        " + (Tangerine.settings.context === "server" ? newButton : "") + "        " + (Tangerine.settings.context === "mobile" ? importButton : "") + "        <div class='new_assessment_form confirmation'>          <div class='menu_box_wide'>            <input type='text' class='new_assessment_name' placeholder='Assessment Name'>            <button class='new_assessment_save command'>Save</button> <button class='new_assessment_cancel command'>Cancel</button>          </div>        </div>      ";
    }
    this.$el.html(html);
    if (Tangerine.settings.context === "server") {
      _ref = this.groupViews;
      for (i = 0, _len = _ref.length; i < _len; i++) {
        view = _ref[i];
        assessmentCount = this.assessments.where({
          "group": this.sections[i],
          "archived": false
        }).length;
        groupName = this.sections[i] === "public" ? "Public" : this.sections[i];
        this.$el.append("<h2 class='header_" + view.cid + "'>" + groupName + " (" + assessmentCount + ")</h2><ul id='group_" + view.cid + "' class='assessment_list'></ul>");
        view.setElement(this.$el.find("#group_" + view.cid));
        view.render();
      }
    } else if (Tangerine.settings.context === "mobile") {
      this.$el.append("<ul class='assessment_list'></ul>");
      this.listView.setElement(this.$el.find("ul.assessment_list"));
      this.listView.render();
    }
    this.trigger("rendered");
  };

  AssessmentListView.prototype.newAssessmentToggle = function() {
    this.$el.find('.new_assessment_form, .new_assessment').fadeToggle(250);
    return false;
  };

  AssessmentListView.prototype.newAssessmentSave = function(event) {
    var name, newAssessment, newId,
      _this = this;
    if (event.type !== "click" && event.which !== 13) return true;
    name = this.$el.find('.new_assessment_name').val();
    if (name.length !== 0) {
      newId = Utils.guid();
      newAssessment = new Assessment({
        "name": name,
        "group": this.group,
        "_id": newId,
        "assessmentId": newId,
        "archived": false
      });
      newAssessment.save(null, {
        success: function() {
          _this.refresh();
          return _this.$el.find('.new_assessment_form, .new_assessment').fadeToggle(250, function() {
            return _this.$el.find('.new_assessment_name').val("");
          });
        }
      });
      Utils.midAlert("" + name + " saved");
    } else {
      Utils.midAlert("<span class='error'>Could not save <img src='images/icon_close.png' class='clear_message'></span>");
    }
    return false;
  };

  AssessmentListView.prototype.closeViews = function() {
    var view, _base, _i, _len, _ref, _results;
    if (typeof (_base = this.curriculaListView).close === "function") {
      _base.close();
    }
    _ref = this.groupViews;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      view = _ref[_i];
      _results.push(view.close());
    }
    return _results;
  };

  AssessmentListView.prototype.onClose = function() {
    return this.closeViews();
  };

  return AssessmentListView;

})(Backbone.View);