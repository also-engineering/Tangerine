SampleView = Backbone.View.extend

  events:
    'change #year' : 'updateYear'
    'change #year-2-boys' : 'updateYear2Instructions'
    'change #year-2-girls' : 'updateYear2Instructions'
    'change #year-1-cpba-boys' : 'updateYear1Instructions'
    'change #year-1-cpba-girls' : 'updateYear1Instructions'
    'change #year-1-non-cpba-boys' : 'updateYear1Instructions'
    'change #year-1-non-cpba-girls' : 'updateYear1Instructions'

  updateYear: ->
    @year = parseInt(@$el.find('#year').val())
    if @year is 1
      @renderYear1()
    else if @year is 2
      @renderYear2()

  renderYear1: ->
    @$el.find("#sample-calculator").html "
      <table>
        <tr>
          <td><label for='year-1-cpba-boys'>CPBA Boys</label></td>
          <td><input id='year-1-cpba-boys' type='number'></td>
        </tr>
        <tr>
          <td><label for='year-1-cpba-girls'>CPBA Girls</label></td>
          <td><input id='year-1-cpba-girls' type='number'></td>
        </tr>
        <tr>
          <td><label for='year-1-non-cpba-boys'>Non CPBA Boys</label></td>
          <td><input id='year-1-non-cpba-boys' type='number'></td>
        </tr>
        <tr>
          <td><label for='year-1-non-cpba-girls'>Non CPBA Girls</label></td>
          <td><input id='year-1-non-cpba-girls' type='number'></td>
        </tr>
      </table>
    "
    @$el.find("#sample-instructions").html('')

  renderYear2: ->
    @$el.find("#sample-calculator").html "
      <label for='year-2-boys'>Boys</label>
      <input id='year-2-boys' type='number'>
      <br>
      <label for='year-2-girls'>Girls</label>
      <input id='year-2-girls' type='number'>
    "
    @$el.find("#sample-instructions").html('')

  updateYear1Instructions: ->

    need = 5

    cpbaBoys = parseInt @$el.find("#year-1-cpba-boys").val()
    nonCpbaBoys = parseInt @$el.find("#year-1-non-cpba-boys").val()
    cpbaGirls = parseInt @$el.find("#year-1-cpba-girls").val()
    nonCpbaGirls = parseInt @$el.find("#year-1-non-cpba-girls").val()

    cpbaBoysInstructions = ''
    nonCpbaBoysInstructions = ''
    cpbaGirlsInstructions = ''
    nonCpbaGirlsInstructions = ''

    if cpbaBoys <= need
      cpbaBoysInstructions = "Sample all CPBA boys."

    else if cpbaBoys > need

      samples = @getTwoTeirs
        from: cpbaBoys
        need: need

      firstSelection = samples.first
      replacements = samples.second

      cpbaBoysInstructions = "
        <h3>First selection</h3>#{firstSelection.join(', ')}
        <h3>Replacements</h3>#{replacements.join(', ')}
      "

    if nonCpbaBoys <= need
      nonCpbaBoysInstructions = "Sample all Non-CPBA boys."

    else if nonCpbaBoys > need
      samples = @getTwoTeirs
        from: nonCpbaBoys
        need: need
      firstSelection = samples.first
      replacements = samples.second

      nonCpbaBoysInstructions = "
        <h3>First selection</h3>#{firstSelection.join(', ')}
        <h3>Replacements</h3>#{replacements.join(', ')}
      "

    if cpbaGirls <= need
      cpbaGirlsInstructions = "Sample all CPBA girls."

    else if cpbaGirls > need

      samples = @getTwoTeirs
        from: cpbaGirls
        need: need

      firstSelection = samples.first
      replacements = samples.second

      cpbaGirlsInstructions = "
        <h3>First selection</h3>#{firstSelection.join(', ')}
        <h3>Replacements</h3>#{replacements.join(', ')}
      "

    if nonCpbaGirls <= need
      nonCpbaGirlsInstructions = "Sample all Non-CPBA girls."

    else if nonCpbaGirls > need
      samples = @getTwoTeirs
        from: nonCpbaGirls
        need: need
      firstSelection = samples.first
      replacements = samples.second

      nonCpbaGirlsInstructions = "
        <h3>First selection</h3>#{firstSelection.join(', ')}
        <h3>Replacements</h3>#{replacements.join(', ')}
      "

    @$el.find("#sample-instructions").html "
      <section>
        <h2>CPBA Boys</h2>#{cpbaBoysInstructions}
      </section>
      <section>
        <h2>CPBA Girls</h2>#{cpbaGirlsInstructions}
      </section>
      <section>
        <h2>Non CPBA Boys</h2>#{nonCpbaBoysInstructions}
      </section>
      <section>
        <h2>Non CPBA Girls</h2>#{nonCpbaGirlsInstructions}
      </section>
    "


  updateYear2Instructions: ->

    need = 10

    boys = parseInt(@$el.find('#year-2-boys').val())
    girls = parseInt(@$el.find('#year-2-girls').val())
    boysInstructions = ''
    girlsInstructions = ''

    if boys + girls < 20
      return @$el.find("#sample-instructions").html "Sample all students."

    if boys <= need
      if need - boys > 0
        if need - boys <= girls - need
          additionalGirls = "And sample #{need - boys} replacement girls."

      boysInstructions = "
        Sample all boys. #{additionalGirls || ''}
      "
    else if boys > need
      samples = @getTwoTeirs
        from: boys
        need: need

      firstSelection = samples.first
      replacements = samples.second

      boysInstructions = "
        <h3>First selection</h3>
        #{firstSelection.join(', ')}

        <h3>Replacements</h3>
        #{replacements.join(', ')}
      "

    if girls <= need
      if need - girls > 0
        if need - girls <= boys - need
          additionalBoys = "And sample #{need - girls} replacement boys."

      boysInstructions = "
        Sample all boys. #{additionalBoys || ''}
      "

      girlsInstructions = "
        Sample all girls. #{}
      "
    else if girls > need

      girlSample = @getTwoTeirs
        from: girls
        need: need

      girlFirstSelection = girlSample.first
      girlReplacements = girlSample.second

      girlsInstructions = "
        <h3>First selection</h3><p>#{girlFirstSelection.join(', ')}</p>
        <h3>Replacements</h3><p>#{girlReplacements.join(', ')}</p>
      "


    @$el.find("#sample-instructions").html "
      <section>
        <h2>Boys</h2>
        #{boysInstructions}
      </section>
      <section>
        <h2>Girls</h2>
        #{girlsInstructions}
      </section>
    "
  sampleWithInterval: (opts) ->
    interval = opts.interval
    need = opts.need
    all = opts.all

    if need is "all"
      need = all.length

    sample = []
    index = -1
    while (sample.length < need && all.length != 0)
      index = (index + interval) % all.length
      sample = sample.concat( all.splice(index, 1) )
      index--
    return sample

  getTwoTeirs: (opts) ->
      from = opts.from
      need = opts.need

      interval = Math.max(1, Math.ceil(from / need))

      all = [1..from]

      first  = @sampleWithInterval
        interval: interval
        all: all
        need: need

      second = @sampleWithInterval
        interval: interval
        all: all
        need: "all"

      return {
        first  : first,
        second : second
      }

  initialize: ->
    @digit = new CheckDigit



  render: ->
    @$el.html "
      <h1>Sample helper</h1>
      <h3>1. Have you verified the number of students present TODAY in this classroom?</h3>
      <h3>2. Have you verified their CPBA status of all attending children?</h3>

      <label for='year'>3. Are there CPBA students in the classroom?</label>
      <select id='year'>
        <option selected disabled>Select</option>
        <option value='1'>Yes</option>
        <option value='2'>No</option>
      </select>
      <section id='sample-calculator'></section>
      <div id='sample-instructions'></div>
    "

    @trigger 'rendered'