###!
 * Files.io
 * Copyright(c) 2012 vol4ok <admin@vol4ok.net>
 * MIT Licensed
###

common      = require './common'
CopyFiles   = require './copy-files'
RemoveFiles = require './remove-files'

{rand, randStr, makeDir} = common

###*
* Copy Files and Directories
*
* @api
* @param {Array|String} src - path to file or array of files
* @param {String} dst — destination directory or file
* @param {Object} options
###
copy = (src, dst, callback) -> 
  new CopyFiles src, dst, 
    replaceStrategy: CopyFiles.REPLACE
    on_complete: (status, obj) ->
      callback(status, obj.statistics)

###*
* Move file or directory
###
move = (src, dst, options) -> #TODO
rename = (src, dst, options) -> #TODO

###
* Remove files or diectories
* 
* @api
* @param {Array|String} file — file or dir or array of files and dirs
* @param {Object} options
###
remove = (file, options) -> new RemoveFiles(file, options)

exports extends {copy, remove, makeDir}