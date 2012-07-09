fs = require 'fs'
path = require 'path'
async = require 'async'
util = require 'util'
jade = require 'jade'

module.exports = (wintersmith, callback) ->

  class JadePlugin extends wintersmith.ContentPlugin

    constructor: (@_filename, @_base, @_text, @_metadata) ->

    getFilename: ->
      @_filename.replace /jade$/, 'html'

    getHtml: (base='/') ->
      options =
        locals: @_metadata
      fn = jade.compile @_text, @_metadata
      fn @

    render: (locals, contents, templates, callback) ->
      # do something with the text!
      callback null, new Buffer @html

    @property 'metadata', ->
      @_metadata

    @property 'template', ->
      @_metadata.template or 'none'

    @property 'html', ->
      @getHtml()

    @property 'title', ->
      @_metadata.tile or 'Untiltled'

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

  wintersmith.registerContentPlugin 'jade', '**/*.jade', JadePlugin
  callback() # tell the plugin manager we are done

extractMetadata = (content) ->
  a = content.split '\n\n'
  metadata:
    parseMetadata a[0]
  text: a[1]

parseMetadata = (content) ->
  lines = content.split '\n'
  obj = {}
  for line in lines
    key = line.replace /^(.+?) ?=(.+)/, '$1'
    value = line.replace /(.+?)'(.+?)'$/, '$2'
    obj[key] = value
  obj