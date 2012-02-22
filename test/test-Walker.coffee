require 'colors'
vows        = require 'vows'
assert      = require 'assert'
fs          = require 'fs'
path        = require 'path'
{inspect}   = require 'util'

{basename} = path
{Filter} = require '../lib/files.io/filter'
{walkSync, Walker}  = require '../lib/files.io/walker'

filter = new Filter().allowList [
  [ 'and',
    ['ext', 'coffee', 'js'],
    [ 'not', 
      ['basename', /ololololo/] ] ] ]
count1 = 0
count2 = 0
walkSync '../',
  relative: '../'
  on_file: (apath, rpath, stat) ->
    console.log 'on_file'.green, rpath.cyan if filter.test(apath)
    count1++
  on_dir: (apath, rpath, stat) ->
    count2++
    #console.log 'on_dir '.green, rpath.magenta
console.log count1, count2