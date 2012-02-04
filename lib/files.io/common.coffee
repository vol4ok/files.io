###!
 * nBuild
 * Copyright(c) 2011-2012 vol4ok <admin@vol4ok.net>
 * MIT Licensed
###

###* Module dependencies ###

fs   = require 'fs'
path = require 'path'
_    = require 'underscore'

{normalize, basename, dirname, extname, join, existsSync, relative} = path

ALPHABET = 'abcdefghijklmnopqrstuvwxyz0123456789'.split('')

###*
* Generate random number from 0..n
* 
* @exports
* @param {Number} n
###

rand = (n) -> Math.floor(Math.random()*n)

###*
* Generate random string
*
* @exports
* @param {Number} length
* @param {Array} alphabet
###

randStr = (length, alphabet = ALPHABET) ->
  str = ""
  for i in [0...length]
    str += alphabet[rand(alphabet.length)]
  return str

###*
* Create directory with intermediate directories as required
*
* @api
* @param {String} path
* @param {Object} options
###

makeDir = (path, options = {}) -> 
  mode = options.mode or 0755
  parent = dirname(path)
  makeDir(parent, options) unless existsSync(parent)
  unless existsSync(path)
    fs.mkdirSync(path, mode)
    options.createdDirs.push(path) if _.isArray(options.createdDirs)

exports extends {rand, randStr, makeDir}