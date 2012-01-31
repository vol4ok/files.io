###!
 * Files.io
 * Copyright(c) 2012 vol4ok <admin@vol4ok.net>
 * MIT Licensed
###

###* Module dependencies ###

require "colors"
fs     = require 'fs'
util   = require 'util'
_      = require 'underscore'
path   = require 'path'
events  = require 'events'
common = require './common'

{normalize, basename, dirname, extname, join, existsSync} = path
{EventEmitter} = events
{makeDir} = common

class CopyFiles
  
  # for internal use
  STATUS_SUCCESS = 0
  STATUS_PENDING = 1
  STATUS_FAIL    = -1
  STATUS_GET_STATS_FAILED = -2
  STATUS_CREATE_DIR_FAILED = -3
  
  # for export
  STATUS_SUCCESS: STATUS_SUCCESS
  STATUS_FAIL :   STATUS_FAIL
  
  # for internal use
  REPLACE       = 0
  SKIP          = 1
  REPLACE_OLDER = 2
  
  # for export
  REPLACE:       REPLACE
  SKIP:          SKIP
  REPLACE_OLDER: REPLACE_OLDER
  
  ###*
  * @field {Object} defaults
  * @field   {Boolean}  defaults.copyFileTimestamp = yes
  * @field   {Number}   defaults.replaceStrategy = REPLACE_OLDER|SKIP|REPLACE
  * @field   {Function} defaults.on_complete
  * @field   {Function} defaults.on_copyBegan
  * @field   {Function} defaults.on_copyEnded
  * @field   {Function} defaults.on_error
  * @private
  ###
  defaults: 
    copyFileTimestamp: yes
    replaceStrategy:   REPLACE_OLDER
    on_complete:       null
    on_copyBegan:      null
    on_copyEnded:      null
    on_error:          null
    
  ###*
  * @field {Number} numOfOpenFiles = 0
  * @private
  ###
  numOfOpenFiles: 0
  
  ###*
  * @field maxNumOfOpenFiles = 100
  * @private
  ###
  maxNumOfOpenFiles: 100
  
  ###*
  * @constructor
  * @public
  * @param {String} src
  * @param {String} dst
  * @param {Object} options
  * @param   {Boolean}  options.copyFileTimestamp = yes
  * @param   {Number}   options.replaceStrategy = REPLACE_OLDER|SKIP|REPLACE
  * @param   {Function} options.on_complete
  * @param   {Function} options.on_copyBegan
  * @param   {Function} options.on_copyEnded
  * @param   {Function} options.on_error
  ###
  constructor: (src, dst, options) ->
    throw "Error: #{src} not found!" unless existsSync(src)
    @options = _.extend {}, @defaults, options
    @contextList = []
    @transferQueue = []
    @eventEmitter = new EventEmitter()
    @eventEmitter.on('complete',     @options.on_complete)  if _.isFunction(@options.on_complete)
    @eventEmitter.on('copyBegan', @options.on_copyBegan) if _.isFunction(@options.on_copyBegan)
    @eventEmitter.on('copyEnded', @options.on_copyEnded) if _.isFunction(@options.on_copyEnded)
    @eventEmitter.on('error',     @options.on_error)     if _.isFunction(@options.on_error)
    @statistics = 
      dirsCopied: 0
      filesCopied: 0
      dirsRequested: 0
      filesRequested: 0
      filesSkipped: 0
      errors: 0
      totalSize: 0
      copiedSize: 0
    src = normalize(src)
    dst = normalize(dst)
    @_copy(src, dst, _.bind(@_complete, this))
    
  ###
  * @public
  * @param {String} event
  * @param {Function} listener
  ###
  on: (event, listener) ->
    event = event.toLowerCase()
    if /^(complete|copyBegan|copyEnded|error)$/.test(event)
      @eventEmitter.on(event, listener)
    else
      throw 'Error: unknown event'
      
  ###
  * @public
  * @alias on
  ###
  bind: -> @on
    
  ###
  * @private
  ###
  _complete: (status) -> @eventEmitter.emit('complete', this)
    
  ###
  * @private
  * @param src
  * @param dst
  ###
  _copy: (src, dst, callback) ->
    ctx = 
      id: @contextList.length
      src: src
      dst: dst
      lock: yes
      complete: no
      status: STATUS_SUCCESS
      copied: 0
      copying: 0
      errors: 0
      replace: no
      callback: callback
      child: []
      createdFolders: []
      lastError: null
      
    ctx.status = (=> 
      try ctx.srcAttr = fs.lstatSync(src)
      catch err
        ctx.lastError = err
        return STATUS_FAIL      
        
      ctx.folder = ctx.srcAttr.isDirectory()
      
      if ctx.exists = existsSync(dst)
        try ctx.dstAttr = fs.lstatSync(dst) 
        catch err
          ctx.lastError = err
          return STATUS_FAIL 
        
      @contextList.push(ctx)
        
      if ctx.folder
        
        unless ctx.exists
          try makeDir(dst, createdDirs: ctx.createdFolders)
          catch err
            lastError = err
            return STATUS_FAIL
            
        @statistics.dirsRequested++
        
        try files = fs.readdirSync(src)
        catch err
          ctx.lastError = err
          return STATUS_FAIL
          
        for file in files
          newSrc = join(src,file)
          newDst = join(dst,file)
          ctx.copying++
          ctx.child.push @_copy(newSrc, newDst, (err) => @_copyCompletetion(err, ctx)).id
      else
        dstDir = dirname(dst)
        unless existsSync(dstDir)
          try makeDir(dstDir, createdDirs: ctx.createdFolders)
          catch err
            @eventEmitter.emit('error', err, ctx, this)
            return STATUS_FAIL 
        @statistics.filesRequested++
        @statistics.totalSize += ctx.srcAttr.size
        ctx.copying++
        if ctx.exists
          switch @options.replaceStrategy
            when SKIP
              @_copyCompletetion(STATUS_SUCCESS, ctx)
              return STATUS_SUCCESS
            when REPLACE_OLDER
              if ctx.srcAttr.mtime.getTime() <= ctx.dstAttr.mtime.getTime()
                @_copyCompletetion(STATUS_SUCCESS, ctx)
                return STATUS_SUCCESS 
              else
                ctx.replace = yes
            else
              ctx.replace = yes
        newCallback = (err) => 
          @_copyCompletetion(0, ctx)
        if @numOfOpenFiles < @maxNumOfOpenFiles
        then @_transferFile(ctx, newCallback)
        else @transferQueue.push(=> @_transferFile(ctx, newCallback))
      
      return if ctx.coping > 0 then STATUS_PENDING else STATUS_SUCCESS
    )()
    ctx.lock = no
    if ctx.complete = ctx.copying is 0 and not ctx.lock
      ctx.callback(ctx.status, ctx)
        
    return ctx

  _transferFile: (ctx, callback) ->
    @eventEmitter.emit('copyBegan', ctx, this)
    @numOfOpenFiles++
    srcStream = fs.createReadStream(ctx.src)
    dstStream = fs.createWriteStream(ctx.dst)
    callback(STATUS_FAIL) unless srcStream or dstStream
    util.pump srcStream, dstStream, callback
      
    
  _copyCompletetion: (err, ctx) ->
    ctx.skipped = ctx.exists and not ctx.replace
    unless ctx.folder or ctx.skipped
      @numOfOpenFiles--;
      while @transferQueue.length > 0 and @numOfOpenFiles < @maxNumOfOpenFiles
        @transferQueue.shift()()
    
    if @options.copyFileTimestamp and not err and not ctx.skipped
      try fs.utimesSync(ctx.dst, ctx.srcAttr.atime, ctx.srcAttr.mtime)
      catch err
        @eventEmitter.emit('error', err, ctx, this)
        err = STATUS_FAIL
    
    if err == STATUS_FAIL
      ctx.errors++
      @statistics.errors++
      ctx.status = STATUS_FAIL
      @eventEmitter.emit('error', ctx, this)
    else
      ctx.status = STATUS_SUCCESS
      ctx.copied++
      if ctx.folder
        @statistics.dirsCopied++
      else
        if ctx.skipped
          @statistics.filesSkipped++
        else
          @statistics.filesCopied++
          @statistics.copiedSize += ctx.srcAttr.size
      
    if --ctx.copying is 0 and not ctx.lock
      @eventEmitter.emit('copyEnded', ctx, this) unless ctx.folder
      ctx.callback(ctx.status)

module.exports = CopyFiles
