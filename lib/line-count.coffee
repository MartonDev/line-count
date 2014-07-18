
fs   = require 'fs'
sloc = require 'sloc'
filewalker = require 'filewalker'

suffixes = [
  'coffee'
  'js'
  'c'
  'cc'
  'java'
  'php'
  'php5'
  'go'
  'css'
  'scss'
  'less'
  'py'
  'html'
]

pad = (num, w) ->
  num = '' + num
  while num.length < w then num = ' ' + num
  ' ' + num

addAttrs = (sfx, aIn, b) ->
  a = (aIn[sfx] ?= {})
  for k, v of b
    a[k] ?= 0
    a[k] += v

module.exports =

  activate: ->
    atom.workspaceView.command "line-count:open", => @open()

  open: ->
    text = ''
    add = (txt) -> text += (txt ? '') + '\n'

    printSection = (title, data) ->
      add '\n' + title + '\n-----'
      maxS = maxC = maxT = 0
      for label, c of data
        maxS = Math.max maxS, c.sloc
        maxC = Math.max maxC, c.cloc
        maxT = Math.max maxT, c.loc
        ws = ('' + maxS).length + 1
        wc = ('' + maxC).length + 1
        wt = ('' + maxT).length + 1
      for label, c of data
        add pad(c.sloc, ws) + pad(c.cloc, wc) + pad(c.loc, wt) + '  ' + label

    atom.workspaceView.open('Line Count').then (editor) ->
      rootDirPath = atom.project.getRootDirectory().path

      files    = {}
      typeData = {}
      total    = {}

      filewalker(rootDirPath, maxPending: 4).on("file", (path, stats, absPath) ->

          sfxMatch = /\.([^\.]+)$/.exec path
          if sfxMatch and
              (sfx = sfxMatch[1]) in suffixes and
              path.indexOf('node_modules') is -1
            code = fs.readFileSync absPath, 'utf8'
            try
              counts = sloc code, sfx
            catch e
              add 'Warning: ' + e.message
              return

            files[path] = counts
            addAttrs sfx, typeData, counts
            addAttrs  '', total,    counts

        ).on("error", (err) ->
          add err.message

        ).on("done", ->
          add '\nGenerated by the Atom Editor package Line-Count.'
          add '\nResults for directory ' + rootDirPath + '.'
          add 'Counts are in order of source, comments, and total.'

          printSection 'Files', files
          printSection 'Types', typeData
          printSection 'Total', total

          editor.setText text

        ).walk()
