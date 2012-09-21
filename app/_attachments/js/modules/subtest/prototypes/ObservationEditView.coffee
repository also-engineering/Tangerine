# This prototype runs a survey at specified intervals.
class ObservationEditView extends Backbone.View

  initialize: ( options ) ->
    @model = options.model
    surveyAttributes = $.extend(@model.get('surveyAttributes'), {"_id":@model.id})
    @surveyModel = new Backbone.Model(surveyAttributes)
    @surveyView = new SurveyEditView
      "model" : @surveyModel

  save: ->
    
    errors = []
    
    totalSeconds   = parseInt( @$el.find("#total_seconds").val() )
    intervalLength = parseInt( @$el.find("#interval_length").val() )

    if totalSeconds == 0 then errors.push "Total seconds needs to be non-zero value."
    if intervalLength == 0 then errors.push "Interval length needs to be a non-zero value."
    
    if errors.length != 0 then alert ("Warning\n\n#{errors.join('\n')}")

    @model.set
      totalSeconds     : totalSeconds
      intervalLength   : intervalLength
      variableName     : @$el.find("#variable_name").val().safetyDance()
      displayName      : @$el.find("#display_name").val().safetyDance()
      surveyAttributes : @surveyModel.attributes

  render: ->
    totalSeconds   = @model.get("totalSeconds")   || 0
    intervalLength = @model.get("intervalLength") || 0
    variableName   = @model.get("variableName")   || ""
    displayName    = @model.get("displayName")    || ""

    @$el.html "
      <div class='label_value'>
        <label for='variable_name'>Variable name</label>
        <input id='variable_name' value='#{variableName}'><br>

        <label for='display_name'>Display name</label>
        <input id='display_name' value='#{displayName}'><br>

        <label for='total_seconds'>Total seconds</label>
        <input id='total_seconds' value='#{totalSeconds}' type='number'>

        <label for='interval_length' title='In seconds'>Interval length</label>
        <input id='interval_length' value='#{intervalLength}' type='number'>
      </div>
      <div id='survey_editor'></div>
    "

    @surveyView.setElement(@$el.find("#survey_editor"))
    @surveyView.render()

    # remove the option for the grid link
    @$el.find("#grid_link").remove()