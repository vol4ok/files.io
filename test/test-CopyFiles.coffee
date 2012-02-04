###!
 * Files.io
 * Copyright(c) 2012 vol4ok <admin@vol4ok.net>
 * MIT Licensed
###

###* Module dependencies ###

vows      = require 'vows'
assert    = require 'assert'
async     = require 'async'
fs        = require 'fs'
path      = require 'path'
exec      = require('child_process').exec
CopyFiles = require '../lib/files.io/copy-files'
common    = require '../lib/files.io/common'

{rand, randStr, makeDir} = common
{normalize, basename, dirname, extname, join, existsSync, relative} = path

SRC_DIR  = './test-copy-files/src'
DST_DIR  = './test-copy-files/dst'
NUM_OF_FILES = 20
FILE_SIZE_LIMIT = 1000

g_createdDirs = []

makeDir(SRC_DIR, createdDirs: g_createdDirs)
makeDir(DST_DIR, createdDirs: g_createdDirs)

cleanDir = (path) ->
  return unless existsSync(path)
  for f in fs.readdirSync(path)
    fs.unlinkSync(join(path,f))
  
generateFiles = (dir, count, maxSize, callback) ->
  files = []
  for i in [0...count]
    files.push join(dir, randStr(10))
  async.forEach files, (file, cb) -> 
    exec "dd if=/dev/urandom of=#{file} bs=1 count=#{rand(maxSize)}", cb
  , callback
  return files

vows.describe('CopyFiles class').addBatch({
  'basic copy':
    topic: -> 
      cleanDir(SRC_DIR)
      cleanDir(DST_DIR)
      generateFiles SRC_DIR, NUM_OF_FILES, FILE_SIZE_LIMIT, @callback
      return undefined
    'after generate':
      topic: ->
        cp = new CopyFiles SRC_DIR, DST_DIR,
          replaceStrategy: CopyFiles.REPLACE
          on_complete: @callback
        return undefined
      'check status': (status, cp) ->
        assert.equal status, CopyFiles.STATUS_SUCCESS
      'check files count': (status, cp) -> 
        assert.equal fs.readdirSync(DST_DIR).length, fs.readdirSync(SRC_DIR).length
      'check presence of files': (status, cp) -> 
        for f in fs.readdirSync(SRC_DIR)
          assert.isTrue(existsSync(join(DST_DIR, f)))
      'check files size': (status, cp) -> 
        for f in fs.readdirSync(SRC_DIR)
          srcStat = fs.lstatSync(SRC_DIR)
          dstStat = fs.lstatSync(DST_DIR)
          assert.equal srcStat.size, dstStat.size
}).addBatch({
  'clean': 
    topic: ->
      cleanDir(SRC_DIR)
      cleanDir(DST_DIR)
      while g_createdDirs.length > 0
        fs.rmdirSync(g_createdDirs.pop())
    'cleaned': ->
}).export(module)