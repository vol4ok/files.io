fs   = require 'fs'
_    = require 'underscore'
path = require 'path'

{EventEmitter} = require 'events'
{basename, dirname, extname, join, existsSync, relative} = path

MAX_INT = 9007199254740992

###
* Walk dirs and files and run callbacks
* @class Walker
###

class Walker
  
  ###*
  * @constructor
  * @param {Array|String} dirs
  * @param {Object} options
  * @param {Boolean} options.relative
  * @param {Number} options.depth
  * @param {Function} options.on_file
  * @param {Function} options.on_dir
  ###
  
  constructor: (options = {}) ->
    @eventEmitter = new EventEmitter()
    @eventEmitter.on('dir', options.on_dir)   if _.isFunction(options.on_dir)
    @eventEmitter.on('file', options.on_file) if _.isFunction(options.on_file)
    @relative = options.relative or process.cwd()
    @depth    = options.depth or MAX_INT
    
    
  on: (event, listener) ->
    event = event.toLowerCase()
    if /^(dir|file)$/.test(event)
      @options["on_#{event}"] = listener
      @eventEmitter.on(event, listener)
    else
      throw 'Error: unknown event'
    return this
    
  set: (option, value) ->
    @options[option] = value
    switch 'option'
      when 'depth'
        @depth = value
      when 'relative'
        @relative = value
    return this
  
  ###*
  * @public
  * @param {Array|String} targets — dirs or files to walk
  ###
  
  walk: (targets) ->
    targets = [ targets ] unless _.isArray(targets)
    for target in targets
      target = fs.realpathSync(target)
      @_walk(target, relative(@relative, target))
    return this
      
  ###*
  * @private
  * @param {String} apath — absolute path
  * @param {String} [apath = ''] — relative path
  * @param {Number} [depth = ''] — depth of recursion
  ###
  
  _walk: (apath, rpath = '', depth = 0) ->
    return true if depth > @depth
    stat = fs.lstatSync(apath)
    if stat.isDirectory()
      try
        @eventEmitter.emit('dir', apath, rpath, stat)
      catch err
        return false if err
      for file in fs.readdirSync(apath)
        return false unless @_walk(join(apath, file), join(rpath, file), depth+1)
    else
      rpath = basename(apath) if rpath is ''
      try
        @eventEmitter.emit('file', apath, rpath, stat)
      catch err
        return false if err
    return true

###*
* @api
* @param {Array|String} [targets] - dir or files for scan
* @param {Object} [options] - list of options
* @example
* Syntax 1:
  walkSync(['/dir', '/dir2'], {
    relative: '../',
    on_file: function(apath, rpath, stat) {...},
    on_dir: function(apath, rpath, stat) {...}
  });
* Syntax 2:
  walkSync()
    .set(relative, '../')
    .on('file', function(apath, rpath, stat) {...})
    .on('dir', function(apath, rpath, stat) {...})
    .walk(['/dir', '/dir2']);
###
walkSync = (targets, options = {}) ->
  if arguments.length is 0
    return new Walker()
  else if arguments.length is 1
    return new Walker(arguments[0])
  return new Walker(arguments[1]).walk(arguments[0])
  
  
exports extends {walkSync, Walker}