class CaseSelectEditView extends Backbone.View

  className: "CaseSelectEditView"

  events:
    'keyup #fields'              : 'updateFields'
    'click #fields-format input' : 'updateFields'

  updateCommaTabDisplay: (event, selector) ->
    value     = @$el.find(selector).val()
    hasTabs   = value.match(/\t/g)?

    if event?.type == "click"
      if $(event.target).val() == "Tabs"
        @commaToTab selector
        hasTabs   = true
      else
        @tabToComma selector
        hasTabs   = false

    if hasTabs
      @$el.find("#{selector}-format :radio[value='Tabs']").attr("checked", "checked").button("refresh")
    else
      @$el.find("#{selector}-format :radio[value='Commas']").attr("checked", "checked").button("refresh")

  updateVisibleFields: (event) ->
    @updateCommaTabDisplay event, "#visible-fields"


  tabToComma: (selector) -> @$el.find(selector).val(String(@$el.find(selector).val()).replace(/\t/g,", "))
  commaToTab: (selector) -> @$el.find(selector).val(@$el.find(selector).val().replace(/, */g, "\t"))

  save: ->

    if @$el.find("#visible-fields").val().match(/\t/g)?
      @visibleFieldsTabToComma()
      @$el.find("#visible-fields-format :radio[value='Tabs']").attr("checked", "checked").button("refresh")

    visibleFields = @$el.find("#visible-fields").val().split(/, */g)
    for visibleField, i in visibleFields
      visibleFields[i] = $.trim(visibleField).replace(/[^a-zA-Z0-9']/g,"")

    caseName = @$el.find("#case-name").val()

    @model.set
      "visibleFields" : visibleFields
      "caseName"      : caseName

  isValid: -> return true

  showErrors: ->
    alertText = "Please correct the following errors:\n\n"
    for error in @errors
      alertText += @errorMessages[error]
    alert alertText
    @errors = []

  errorMessages :
      "column_match"          : "Some columns in the caseDatum data do not match the number of columns in the geographic levels."
      'unknown_visible_field' : "Visible field not found in fields."

  initialize: ( options ) ->
    @errors = []
    @model = options.model

  render: ->
    visibleFields  = _.escape(@model.getArray("visibleFields").join(", "))
    caseName      = @model.getEscapedString("caseName")


    @$el.html  "
      <section>
        <div class='label_value'>
          <label for='case-name'>Case name</label>
          <input id='case-name' value='#{caseName}''>
        </div>

        <div class='label_value'>
          <div class='menu_box'>
            <label for='visible-fields'>Visible Fields</label>
            <input id='visible-fields' value='#{visibleFields}'>
            <label>Format</label><br>
            <div id='visible-fields-format' class='buttonset'>
              <label for='visible-fields-tabs'>Tabs</label>
              <input id='visible-fields-tabs' name='visible-fields-format' type='radio' value='Tabs'>
              <label for='visible-fields-commas'>Commas</label>
              <input id='visible-fields-commas' name='visible-fields-format' type='radio' value='Commas'>
            </div>
          </div>
        </div>
      </section>
    "

  afterRender: ->
    @updateVisibleFields()

