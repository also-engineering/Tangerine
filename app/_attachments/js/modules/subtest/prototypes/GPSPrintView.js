// Generated by CoffeeScript 1.6.1
var GPSPrintView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

GPSPrintView = (function(_super) {

  __extends(GPSPrintView, _super);

  function GPSPrintView() {
    return GPSPrintView.__super__.constructor.apply(this, arguments);
  }

  GPSPrintView.prototype.className = "gps";

  GPSPrintView.prototype.initialize = function(options) {
    this.model = this.options.model;
    return this.parent = this.options.parent;
  };

  GPSPrintView.prototype.render = function() {
    if (this.format === "stimuli" || this.format === "backup") {
      return;
    }
    if (this.format === "content") {
      this.$el.html("Capture GPS location");
    }
    return this.trigger("rendered");
  };

  return GPSPrintView;

})(Backbone.View);
