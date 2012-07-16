fs = require 'fs'
path = require 'path'
async = require 'async'
util = require 'util'
jade = require 'jade'
underscore = require 'underscore'

module.exports = (wintersmith, callback) ->

  class JadePlugin extends wintersmith.ContentPlugin

    constructor: (@_filename, @_base, @_text, @_metadata) ->

    getFilename: ->
      @_filename.replace /jade$/, 'html'

    getHtml: (base='/') ->
      # all we want to do here, is to render the body
      options =
        filename: path.join @_base, @_filename
        pretty: true

      htmlFn = jade.compile @_text, options
      htmlFn @_metadata

    render: (locals, contents, templates, callback) ->

      if @template == 'none'
        return callback null, null

      template = templates[@template]
      if not template?
        callback new Error "page '#{ @filename}' specifies unknown template '#{ @template }'"
      else
        ctx =
          page: @
          contents: contents
          _: underscore

        for name, method of locals
          ctx[name] = method

        template.render ctx, callback

    @property 'metadata', ->
      @_metadata

    @property 'template', ->
      @_metadata.template or 'none'

    @property 'html', ->
      @getHtml()

    @property 'title', ->
      @_metadata.title or 'Untiltled'

    @property 'date', ->
      new Date(@_metadata.date or 0)

    @property 'rfc822date', ->
      rfc822 @date

    @property 'intro', ->
      @_metadata.intro or ''

    @property 'hasMore', ->
      @_hasMore ?= (@html.length > @intro.length)

  JadePlugin.fromFile = (filename, base, callback) ->
    fs.readFile path.join(base, filename), (error, buffer) ->
      if error
        callback error
      else
        result = extractMetadata buffer.toString()
        {text, metadata} = result
        callback null, new JadePlugin filename, base, text, metadata

  wintersmith.registerContentPlugin 'pages', '**/*.jade', JadePlugin
  callback() # tell the plugin manager we are done

extractMetadata = (content) ->
  a = content.split '\n\n'
  metadata:
    parseMetadata a[0]
  text: a[1..a.length].join('\n\n')

parseMetadata = (content) ->
  lines = content.split '\n'
  obj = {}
  for line in lines
    key = line.replace /^(.+?) ?=(.+)/, '$1'
    value = line.replace /(.+?)'(.+?)'$/, '$2'
    obj[key] = value
  obj