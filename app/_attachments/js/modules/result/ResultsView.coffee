class ResultsView extends Backbone.View

  className : "ResultsView"

  events:
    'click .cloud'    : 'cloud'
    'click .tablets'  : 'tablets'
    'click .detect'   : 'detectOptions'
    'click .details'  : 'showResultSumView'
    'click .refresh'  : 'refresh'
    'click .report' : 'report'

    'change .dates' : 'updateDates'
    'change #enumerator-selector' : 'updateEnumerators'
    'click .show-instances' : 'showInstances'

    'change #limit' : "setLimit"
    'change #page' : "setOffset"

  makeBlank: () ->
    flags         : { count: 0, instances: [] }
    total         : { count: 0, instances: [] }
    AUTO_FAST     : { count: 0, instances: [] }
    AUTO_SLOW     : { count: 0, instances: [] }
    NOT_STOPPED   : { count: 0, instances: [] }
    STOPPED_WRONG : { count: 0, instances: [] }
    NUDGE         : { count: 0, instances: [] }
    MODULATION    : { count: 0, instances: [] }

  updateDates: ->
    start = @$el.find("#start-date").val()
    end   = @$el.find("#end-date").val()
    @startDate = new Date(parseInt(start.substr(0,4)), parseInt(start.substr(5,2))-1, parseInt(start.substr(8,2)))
    @endDate   = new Date(parseInt(end.substr(0,4)), parseInt(end.substr(5,2))-1, parseInt(end.substr(8,2)))
    @report()

  getReports: (callback) ->
    self = @
    Tangerine.$db.view 'ojai/reporting',
      start_key: @startKey()
      end_key: @endKey()
      group_level: 4
      success: (res) ->
        self.schoolsByKey = res.rows.reduce (result, rows) ->
          rows.value.forEach (value) ->
            return result if _(value.location).isEmpty()
            key = value.location.location.slice(0,3).join(", ")
            if not result[key]?
              result[key] = {}

            result[key].complete = value.length if value.complete is true

            result[key][value.length] = 0 unless result[key][value.length]?
            result[key][value.length]++
          return result
        , {}

        self.byEnumerator = res.rows.reduce (result, row) ->

          row.value.forEach (value) ->

            unless result[value.enumerator]?
              result[value.enumerator] = self.makeBlank()

            enumerator = result[value.enumerator]
            if value.modulation is true
              enumerator.flags.count++
              enumerator.MODULATION.count++
              enumerator.MODULATION.instances.push({grid:grid,'id':value.id,'name':grid.name})

            value.grids.forEach (grid) ->
              enumerator.total.count++
              if grid.auto is true
                if grid.left > 55
                  enumerator.flags.count++
                  enumerator.AUTO_FAST.count++
                  enumerator.AUTO_FAST.instances.push({grid:grid,'id':value.id,'name':grid.name})
                else if grid.left < 30
                  enumerator.flags.count++
                  enumerator.AUTO_SLOW.count++
                  enumerator.AUTO_SLOW.instances.push({grid:grid,'id':value.id,'name':grid.name})
              if grid.left is 0 and grid.last is grid.itemCount
                enumerator.flags.count++
                enumerator.NOT_STOPPED.count++
                enumerator.NOT_STOPPED.instances.push({grid:grid,'id':value.id,'name':grid.name})
              if grid.auto is false and grid.left > 0 and grid.last isnt grid.itemCount
                console.log(grid)
                enumerator.flags.count++
                enumerator.STOPPED_WRONG.count++
                enumerator.STOPPED_WRONG.instances.push({grid:grid,'id':value.id,'name':grid.name})
              if grid.last / ( grid.total - grid.left ) > 3
                enumerator.flags.count++
                enumerator.NUDGE.count++
                enumerator.NUDGE.instances.push({grid:grid,'id':value.id,'name':grid.name})
          return result
        , {}
        callback()

  report: ->
    @$el.find("#report-container").html "Loading..."
    @getReports =>
      dateRangeSelector = "
        <div>
          <label>Date range</label>
          <table>
            <tr>
              <td>
              From <input type='date' class='dates' id='start-date'></td>
              <td>To <input type='date' class='dates' id='end-date'></td></tr>
          </table>
        </div>
      "

      allSelected = @selectedEnumerator is "all"
      enumeratorSelector = "
        <label for='enumerator-selector'>Enumerator</label>
        <select id='enumerator-selector'>
          <option #{if allSelected then 'selected' else ''} value='all'>all</option>
          #{Object.keys(@byEnumerator).map( (el) => "<option value='#{el}' #{if el is @selectedEnumerator then 'selected' else ''}>#{el}</option>").join('')}
        </select>
      "

      html = "
        <style>
          .shaded {background-color:#eee}
          .enumerator-name-spacer {
            height: 20px;
            border-bottom: 1px solid #aaa;
          }
        </style>
        <h2>Reports</h2>
        #{dateRangeSelector}
        <div id='school-list'></div>
        #{enumeratorSelector}
        <div id='enumerator-container'></div>
      "

      @$el.find("#report-container").html html
      @$el.find("#start-date").val(@inputDate(@startDate))
      @$el.find("#end-date").val(@inputDate(@endDate))

      @updateSchoolList()
      @updateEnumerators()

  updateSchoolList: ->
    @$el.find("#school-list").html "
      <h3>School List</h3>
      <table>
        #{Object.keys(@schoolsByKey).map( (schoolName, i) =>
          shadeClass = if i % 2 then "class='shaded'" else ''
          "<tr #{shadeClass}><th style='text-align:left;vertical-align:top;' colspan='3'>#{schoolName}</th></tr>
          <tr #{shadeClass}><th></th><th>Screens complete</th><th>Qty</th></tr>
              #{
                complete = @schoolsByKey[schoolName].complete
                Object.keys(@schoolsByKey[schoolName]).map((subtestCount) =>
                  return '' if subtestCount is "complete"
                  star = if parseInt(subtestCount) is complete and complete? then "***" else ''
                  "<tr><td #{shadeClass}></td><td #{shadeClass} style='text-align:right;'>#{subtestCount}</td>
                    <td #{shadeClass} style='text-align:center;'>#{@schoolsByKey[schoolName][subtestCount]}#{star}</td></tr>"
              ).join('')}
            "
        ).join('')}

      </table>
    "

  inputDate: (date) ->
    day = "0#{date.getDate()}".slice(-2)
    month = "0#{date.getMonth() + 1}".slice(-2)
    return "#{date.getFullYear()}-#{month}-#{day}"

  showInstances: (e) ->
    $(e.target).parent("td").siblings().show()

  updateEnumerators: ->
    @selectedEnumerator = @$el.find("#enumerator-selector").val()
    html = "<table id='report-table'><tr><th>Enumerator</th><th>Flags</th></tr>"

    Object.keys(@byEnumerator).forEach (name, j) =>
      rowCount = -1
      return unless @selectedEnumerator is "all" or name is @selectedEnumerator
      currentEnumerator = @byEnumerator[name]
      height = 0
      Object.keys(currentEnumerator).forEach (flag, i) => height++ if currentEnumerator[flag].count isnt 0
      html += "<tr class='enumerator-name-spacer'><td colspan='3'></td></tr><tr><td rowspan='#{height+1}'>#{name}</td></tr>"
      first = true
      Object.keys(currentEnumerator).forEach (flag, i) =>
        return if currentEnumerator[flag].count is 0
        rowCount++
        showButton = "<button class='command show-instances'>...</button>" unless currentEnumerator[flag].instances.length is 0
        html += "
          <tr class='#{('shaded' unless rowCount % 2) || ''}'>
            <td>#{ResultsView.FLAGS[flag]}</td>
            <td>#{currentEnumerator[flag].count} #{showButton||''}</td>
            <td style='display:none'>#{currentEnumerator[flag].instances.map((el, k) ->
              "<a href='/db/#{Tangerine.db_name}/#{el.id}'>Raw</a><div>#{JSON.stringify(el.grid, null, 2)}</div>"
            ).join('')}</td>
          </tr>"
        first = false
    html += "</table>"

    @$el.find("#enumerator-container").html html



    ###
    * Autostop Too Fast:  if  *_autostop = TRUE AND  *_time_remain > 55.
    * Autostop Too Slow:  if  *_autostop = TRUE AND  *_time_remain < 30.
    * Time Not Stopped:  if *_attempted =  (last grid item value)   AND  *_time_remain = 0
    * Time Stopped Inappropriately:   if  *_time_remain > 0  AND  *_attempted ≠  (last grid item value)
    * Nudge Rule:  if  ( *_attempted) / (total time - *_time_remain) > 3 seconds
    * Mode Modulation Rule:  if  *_attempted = correct  for ALL subtasks in an assessment;
    ###



  refresh: ->
    Utils.restartTangerine("Please wait...")

  showResultSumView: (event) ->
    targetId = $(event.target).attr("data-result-id")
    $details = @$el.find("#details_#{targetId}")
    if not _.isEmpty($details.html())
      $details.empty()
      return

    result = new Result "_id" : targetId
    result.fetch
      success: ->
        view = new ResultSumView
          model       : result
          finishCheck : true
        view.render()
        $details.html "<div class='info_box'>" + $(view.el).html() + "</div>"
        view.close()



  cloud: ->
    if @available.cloud.ok
      $.couch.replicate(
        Tangerine.settings.urlDB("local"),
        Tangerine.settings.urlDB("group"),
          success:      =>
            @$el.find(".status").find(".info_box").html "Results synced to cloud successfully"
          error: (a, b) =>
            @$el.find(".status").find(".info_box").html "<div>Sync error</div><div>#{a} #{b}</div>"
        ,
          doc_ids: @docList
      )
    else
      Utils.midAlert "Cannot detect cloud"
    return false


  tablets: ->
    if @available.tablets.okCount > 0
      for ip in @available.tablets.ips
        do (ip) =>
          $.couch.replicate(
            Tangerine.settings.urlDB("local"),
            Tangerine.settings.urlSubnet(ip),
              success:      =>
                @$el.find(".status").find(".info_box").html "Results synced to #{@available.tablets.okCount} successfully"
              error: (a, b) =>
                @$el.find(".status").find(".info_box").html "<div>Sync error</div><div>#{a} #{b}</div>"
            ,
              doc_ids: @docList
          )
    else
      Utils.midAlert "Cannot detect tablets"
    return false

  initDetectOptions: ->
    @available =
      cloud :
        ok : false
        checked : false
      tablets :
        ips : []
        okCount  : 0
        checked  : 0
        total : 256

  detectOptions: ->
    $("button.cloud, button.tablets").attr("disabled", "disabled")
    @detectCloud()
    @detectTablets()

  detectCloud: ->
    # Detect Cloud
    $.ajax
      dataType: "jsonp"
      url: Tangerine.settings.urlHost("group")
      success: (a, b) =>
        @available.cloud.ok = true
      error: (a, b) =>
        @available.cloud.ok = false
      complete: =>
        @available.cloud.checked = true
        @updateOptions()

  detectTablets: =>
    for local in [0..255]
      do (local) =>
        ip = Tangerine.settings.subnetIP(local)
        $.ajax
          url: Tangerine.settings.urlSubnet(ip)
          dataType: "jsonp"
          contentType: "application/json;charset=utf-8",
          timeout: 30000
          complete:  (xhr, error) =>
            @available.tablets.checked++
            if xhr.status == 200
              @available.tablets.okCount++
              @available.tablets.ips.push ip
            @updateOptions()

  updateOptions: =>
    percentage = Math.decimals((@available.tablets.checked / @available.tablets.total) * 100, 2)
    if percentage == 100
      message = "finished"
    else
      message = "#{percentage}%"
    tabletMessage = "Searching for tablets: #{message}"

    @$el.find(".checking_status").html "#{tabletMessage}" if @available.tablets.checked > 0

    if @available.cloud.checked && @available.tablets.checked == @available.tablets.total
      @$el.find(".status .info_box").html "Done detecting options"
      @$el.find(".checking_status").hide()

    if @available.cloud.ok
      @$el.find('button.cloud').removeAttr('disabled')
    if @available.tablets.okCount > 0 && percentage == 100
      @$el.find('button.tablets').removeAttr('disabled')


  i18n: ->
    @text =
      saveOptions : t("ResultsView.label.save_options")
      cloud       : t("ResultsView.label.cloud")
      tablets     : t("ResultsView.label.tablets")
      csv         : t("ResultsView.label.csv")
      started     : t("ResultsView.label.started")
      results     : t("ResultsView.label.results")
      details     : t("ResultsView.label.details")
      page        : t("ResultsView.label.page")
      perPage     : t("ResultsView.label.per_page")
      advanced    : t("ResultsView.label.advanced")

      noResults   : t("ResultsView.message.no_results")

      refresh     : t("ResultsView.button.refresh")
      detect      : t("ResultsView.button.detect")

  calcKey: (date) ->
    JSON.stringify([@assessment.id].concat [date.getFullYear(), date.getMonth()+1, date.getDate()])

  startKey: ->
    @calcKey @startDate

  endKey: ->
    @calcKey @endDate

  initialize: ( options ) ->

    @i18n()

    @resultLimit  = 100
    @resultOffset = 0

    @subViews = []
    @results = options.results
    @assessment = options.assessment


    @startDate = moment().subtract("weeks", 1)._d
    @endDate = new Date()

    @docList = []
    for result in @results
      @docList.push result.get "id"
    @initDetectOptions()
    @detectCloud()

  render: ->

    @clearSubViews()

    html = "
      <h1>#{@assessment.getEscapedString('name')} #{@text.results}</h1>
      <h2>#{@text.saveOptions}</h2>
      <div class='menu_box'>
        <a href='/brockman/assessment/#{Tangerine.db_name}/#{@assessment.id}'><button class='csv command'>#{@text.csv}</button></a>
      </div>
    "

    html += "
      <section id='report-container'>
        <button class='command report'>Report</button>
      </section>
      <h2 id='results_header'>#{@text.results} (<span id='result_position'>loading...</span>)</h2>
      <div class='confirmation' id='controls'>
        <label for='page' class='small_grey'>#{@text.page}</label><input id='page' type='number' value='0'>
        <label for='limit' class='small_grey'>#{@text.perPage}</label><input id='limit' type='number' value='0'>
      </div>

      <section id='results_container'></section>
      <br>
      <button class='command refresh'>#{@text.refresh}</button>
    "

    @$el.html html

    @updateResults()

    @trigger "rendered"

  setLimit: (event) ->
    # @resultOffset
    # @resultLimit

    @resultLimit = parseInt($("#limit").val()) || 100 # default 100
    @updateResults()

  setOffset: (event) ->
    # @resultOffset
    # @resultLimit

    val           = parseInt($("#page").val()) || 1
    calculated    = (val - 1) * @resultLimit
    maxPage       = Math.floor(@results.length / @resultLimit )
    @resultOffset = Math.limit(0, calculated, maxPage * @resultLimit) # default page 1 == 0_offset

    @updateResults()

  updateResults: (focus) =>
    if @results?.length == 0
      @$el.find('#results_header').html @text.noResults
      return

    $.ajax
      url: Tangerine.settings.urlView('group', "resultSummaryByAssessmentId")+"?descending=true&limit=#{@resultLimit}&skip=#{@resultOffset}"
      type: "POST"
      dataType: "json"
      contentType: "application/json"
      data: JSON.stringify(
        keys : [@assessment.id]
      )
      success: ( data ) =>

        rows  = data.rows
        count = rows.length

        maxResults  = 100
        currentPage = Math.floor( @resultOffset / @resultLimit ) + 1

        if @results.length > maxResults
          @$el.find("#controls").removeClass("confirmation")
          @$el.find("#page").val(currentPage)
          @$el.find("#limit").val(@resultLimit)

        start = @resultOffset + 1
        end   = Math.min(@resultOffset+@resultLimit,@results.length)
        total = @results.length

        @$el.find('#result_position').html t("ResultsView.label.pagination", {start:start, end:end, total:total} )

        htmlRows = ""
        for row in rows

          id      = row.value?.participant_id || "No ID"
          endTime = row.value.end_time
          if endTime?
            long    = moment(endTime).format('YYYY-MMM-DD HH:mm')
            fromNow = moment(endTime).fromNow()
          else
            startTime = row.value.start_time
            long    = "<b>#{@text.started}</b> " + moment(startTime).format('YYYY-MMM-DD HH:mm')
            fromNow = moment(startTime).fromNow()

          time    = "#{long} (#{fromNow})"
          htmlRows += "
            <div>
              #{ id } -
              #{ time }
              <button data-result-id='#{row.id}' class='details command'>#{@text.details}</button>
              <div id='details_#{row.id}'></div>
            </div>
          "

        @$el.find("#results_container").html htmlRows

        @$el.find(focus).focus()

  afterRender: =>
    for view in @subViews
      view.afterRender?()

  clearSubViews:->
    for view in @subViews
      view.close()
    @subViews = []

Object.defineProperty ResultsView, "FLAGS",
  configurable : false
  enumerable   : false
  value:
    flags : "Total flags"
    total : "Total timed tests"
    AUTO_FAST : "Autostop too fast"
    AUTO_SLOW : "Autostop too slow"
    NOT_STOPPED : "Time not stopped"
    STOPPED_WRONG : "Time stopped inappropriately"
    NUDGE : "Nudge rule"
    MODULATION: "Mode modulation rule"



