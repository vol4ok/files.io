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
io        = require '../lib/files.io'
common    = require '../lib/files.io/common'


{rand, randStr} = common
{copy, remove, makeDir} = io
{normalize, basename, dirname, extname, join, existsSync, relative} = path

SRC_DIR  = './test-copy-files/src'
DST_DIR  = './test-copy-files/dst'
NUM_OF_FILES = 10
FILE_SIZE_LIMIT = 1000

g_createdDirs = []

makeDir(SRC_DIR, createdDirs: g_createdDirs)
makeDir(DST_DIR, createdDirs: g_createdDirs)

cleanDir = (path) ->
  return unless existsSync(path)
  for f in fs.readdirSync(path)
    remove join(path,f)
  
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
        copy SRC_DIR, DST_DIR, @callback
        return undefined
      'check files count': (status, results) -> 
        assert.equal fs.readdirSync(DST_DIR).length, fs.readdirSync(SRC_DIR).length
      'check presence of files': (status, results) -> 
        for f in fs.readdirSync(SRC_DIR)
          assert.isTrue(existsSync(join(DST_DIR, f)))
      'check files size': (status, results) -> 
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
}).addBatch({
  'multiple copy':
    topic: -> 
      cleanDir(SRC_DIR)
      cleanDir(DST_DIR)
      makeDir(join(SRC_DIR, 'dir-1'))
      makeDir(join(SRC_DIR, 'dir-2'))
      async.forEach [join(SRC_DIR, 'dir-1'), join(SRC_DIR, 'dir-2')]
      , (src, cb) ->
        generateFiles src, NUM_OF_FILES, FILE_SIZE_LIMIT, cb
      , @callback
      return undefined
    'after generate':
      topic: ->
        copy [join(SRC_DIR, 'dir-1'), join(SRC_DIR, 'dir-2')], DST_DIR, @callback
        return undefined
      'check files count': (status, results) -> 
        assert.equal fs.readdirSync(DST_DIR).length, 
          fs.readdirSync(join(SRC_DIR, 'dir-1')).length + fs.readdirSync(join(SRC_DIR, 'dir-2')).length
      'check presence of files': (status, results) -> 
        for f in fs.readdirSync(join(SRC_DIR, 'dir-1'))
          assert.isTrue(existsSync(join(DST_DIR, f)))
        for f in fs.readdirSync(join(SRC_DIR, 'dir-2'))
          assert.isTrue(existsSync(join(DST_DIR, f)))
}).addBatch({
  'clean': 
    topic: ->
      cleanDir(SRC_DIR)
      cleanDir(DST_DIR)
      while g_createdDirs.length > 0
        fs.rmdirSync(g_createdDirs.pop())
    'cleaned': ->
}).export(module)