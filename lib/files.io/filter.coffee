require 'colors'
fs   = require 'fs'
_    = require 'underscore'
path = require 'path'

{extname, basename, existsSync} = path

###
* Basic regexp rule
* @class RegexpRule
###

class RegexpRule
  NAME: 'regexp'
  ALIASES: [ 're' ]
  constructor: (@filter, @regexp) ->
  test: (target) -> @regexp.test(target)

###
* Match file ext
* @class ExtRule
###

class ExtRule
  NAME: 'ext'
  constructor: (@filter, exts...) ->
    @exts = {}
    # exts = [exts] unless _.isArray(exts)
    @exts[@_rd(ext)] = yes for ext in exts
  _rd: (e) -> if e[0] and e[0] is '.' then e.slice(1) else e
  test: (target) -> 
    targetExt = @_rd(extname(target))
    return @exts[targetExt]?
    
###
* Basename of file regexp match
* @class BasenameRule
###

class BasenameRule
  NAME: 'basename'
  constructor: (@filter, @regexp) ->
  test: (target) -> @regexp.test(basename(target))

###
* is file or directory check
* @class DirRule
###

class DirRule
  NAME: 'dir'
  constructor: (@filter) ->
  test: (target) -> 
    debugger
    return false unless existsSync(target)
    fs.lstatSync(target).isDirectory()
    
###
* implement logical and
* @class AndRule
###

class AndRule
  NAME: 'and'
  constructor: (@filter, rules...) ->
    @rules = []
    for rule in rules
      @rules.push(@filter.createRule(rule...))
  test: (target) ->
    return false for rule in @rules when not rule.test(target)
    return true
    
###
* implement logical or
* @class OrRule
###

class OrRule
  NAME: 'or'
  constructor: (@filter, rules...) ->
    @rules = []
    for rule in rules
      @rules.push(@filter.createRule(rule...))
  test: (target) ->
  test: (target) ->
    return true for rule in @rules when not rule.test(target)
    return false

###
* implement logical not
* @class NotRule
###

class NotRule
  NAME: 'not'
  constructor: (@filter, rule) ->
    @rule = @filter.createRule(rule...)
  test: (target) ->
    return not @rule.test(target)
    
    
###
* Parse rules and check targets
* @class Filter
###

class Filter
  defaults:
    allow: []
    deny: []
    rulesClasses: [RegexpRule, ExtRule, BasenameRule, DirRule, AndRule, OrRule, NotRule]
    
  ###*
  * @constructor
  * @param {Object} options
  * @param {Array} options.rulesClasses
  * @param {Array} options.allow
  * @param {Array} options.deny
  ###
  
  constructor: (options = {}) ->
    o = _.defaults options, @defaults
    @_allow = []
    @_deny = []
    @rulesClasses = {}
    @regilsterRuleClass(c) for c in o.rulesClasses
    @allow(r) for r in o.allow
    @deny(r) for r in o.deny
      
  ###*
  * @public
  * @param {Object} ruleClass
  ###
  
  regilsterRuleClass: (ruleClass) ->
    @default = ruleClass::NAME.toLowerCase() unless @default?
    @rulesClasses[ruleClass::NAME.toLowerCase()] = ruleClass
    if _.isArray(ruleClass::ALIASES)
      for alias in ruleClass::ALIASES
        @rulesClasses[alias.toLowerCase()] = ruleClass
    return this
    
  ###*
  * @public
  * @param {String} rule — rule class NAME
  * @param {Any} - args... — arguments list
  ###
  
  createRule: (rule, args...) -> new @rulesClasses[rule.toLowerCase()](this, args...)
  
  ###*
  * Add array with allow rules
  * @public
  * @param {String} rule — rule class NAME
  * @param {Any} - args... — arguments list
  ###
    
  allow: ->
    @_allow.push(@createRule(arguments...))
    return this
    
  ###*
  * Add array with deny rules
  * @public
  * @param {String} rule — rule class NAME
  * @param {Any} - args... — arguments list
  ###
  
  deny: ->
    @_deny.push(@createRule(arguments...))
    return this
    
  ###*
  * Add array with allow rules
  * @public
  * @param {Array} list
  ###
    
  allowList: (list) ->
    for rule in list
      @_allow.push(@createRule(rule...))
    return this
    
  ###*
  * Add array with deny rules 
  * @public
  * @param {Array} list
  ###
    
  denyList: (list) ->
    for rule in list
      @_deny.push(@createRule(rule...))
    return this
    
  ###*
  * @public
  * @param {String} target
  ###
    
  test: (target) ->
    return false for rule in @_deny  when rule.test(target)
    return true  for rule in @_allow when rule.test(target)    
    return false
    
exports extends {Filter, RegexpRule, ExtRule, BasenameRule, DirRule, AndRule, OrRule, NotRule}