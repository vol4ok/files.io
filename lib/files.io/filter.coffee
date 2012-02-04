###
filter
  allowed-exts
  denied-exts
  allowed-regexp
  denied-regexp
  case-sensitive
###

class Filter
  constructor: (options) ->
    @allow = []
    @deny = []
  test: (str) ->
    