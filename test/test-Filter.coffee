require 'colors'
vows        = require 'vows'
assert      = require 'assert'
fs          = require 'fs'
path        = require 'path'
{inspect}   = require 'util'

{basename} = path

{Filter} = require '../lib/files.io/filter'

vows.describe('Filter class').addBatch({
  'regexp':
    topic: -> 
      return new Filter()
        .allow('re', /asd/i)
        .allow('re', /zxc/i)
        . deny('re', /qWe/)
        . deny('re', /123$/)
    'allow': (filter) ->
      assert.isTrue(filter.test('fghfgasdfgh'))
      assert.isTrue(filter.test('fghfzxcfgh'))
      assert.isFalse(filter.test('qwerqwerqwerqwerqwerqwer'))
      assert.isTrue(filter.test('asasdqwezxc23'))
      assert.isTrue(filter.test('asdasdasdzxczxczxc'))
    'deny': (filter) ->
      assert.isFalse(filter.test('weasdzxc123'))
      assert.isFalse(filter.test('qWeweqWeasdzxc123'))
      assert.isTrue(filter.test('weasdzxc123w'))
      assert.isFalse(filter.test('qWeasdzxc12'))
      assert.isTrue(filter.test('qwerqqweasdzxc12'))
  'ext':
    topic: -> 
      return new Filter()
        .allow('ext', 'coffee', '.js')
        .allow('ext', '.mu')
        .allow('ext', '.css', 'styl')
        . deny('ext', 'css', '.less')
        . deny('ext', '.styl')
    'allow': (filter) ->
      assert.isTrue(filter.test('/path/to/script.js'))
      assert.isTrue(filter.test('script.coffee'))
      assert.isTrue(filter.test('/script.mu'))
      assert.isFalse(filter.test('script.less'))
      assert.isFalse(filter.test('script.mustache'))
      assert.isFalse(filter.test('/path/to/scriptmu'))
    'deny': (filter) ->
      assert.isFalse(filter.test('/path/to/style.css'))
      assert.isFalse(filter.test('style.less'))
      assert.isFalse(filter.test('/style.styl'))
      assert.isTrue(filter.test('style.css.js'))
      
  'basename':
    topic: -> 
      return new Filter()
        .allow('basename', /\.[^.\/]+$/)
        .deny('basename', /^__/)
        .deny('basename', /^\./)
        .deny('basename', /.tmp$/)
    'allow': (filter) ->
      assert.isTrue(filter.test('test.coffee'))
      assert.isTrue(filter.test('/test.js'))
      assert.isTrue(filter.test('/path/to/test.a'))
      assert.isTrue(filter.test('path//to/rel/test.a'))
      assert.isFalse(filter.test('path//to/rel/test'))
    'deny': (filter) ->
      assert.isFalse(filter.test('test.tmp'))
      assert.isFalse(filter.test('/path/to/__test.js'))
      assert.isFalse(filter.test('path//to/.test.js'))
      assert.isFalse(filter.test('.__test'))
      
  'and':
    topic: ->
      return new Filter()
        .allow('and', ['basename', /^__/], ['ext', '.coffee'])
    'allow': (filter) ->
      assert.isTrue(filter.test('path/to/__test.coffee'))
      assert.isFalse(filter.test('__test.js'))
      assert.isFalse(filter.test('test.coffee'))
      
  'dir':
    topic: ->
      return new Filter()
        .allow('dir')
    'dirs': (filter) ->
      assert.isTrue(filter.test( '../' + basename(process.cwd()) ))
      assert.isTrue(filter.test('.'))
    'file': (filter) ->
      assert.isFalse(filter.test( basename(__filename) ))
      
  'not':
    topic: ->
      return new Filter()
        .allow('and', [ 'not', ['dir'] ], [ 'not', ['basename', /test/] ])
    'test': (filter) ->
      assert.isFalse(filter.test('./' + basename(__filename) ))
      assert.isFalse(filter.test( '../' + basename(process.cwd()) ))
      assert.isTrue(filter.test( 'ololo.coffee' ))
}).export(module)

# filter:
#   allow: [
#     ['and'
#       ['regexp', /erwe/, /test/]
#       ['ext', 'coffee', 'test'] ]
#     ['and', 
#       ['not', 
#         [ 'ext', 'coffee' ] ] ]
#     
#   ]
#