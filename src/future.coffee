EventEmitter = require('events').EventEmitter
require 'harmony-reflect'

class Future
  isFuture: yes

  constructor: (@fn) ->
    @event_emitter = new EventEmitter
    @is_done = no
    @fn @finished
    return Proxy Function, @proxy_methods()


  done: (callback) =>
    if @is_done
      process.nextTick =>
        callback.apply {}, @saved_args
    else
      @event_emitter.on 'done', callback


  finished: (err, data) =>
    if @is_done
      throw new Error "Callback fired more than once"
    else
      @is_done = yes
      @saved_args = [err, data]
      @event_emitter.emit 'done', err, data


  setThis: (obj) => @this = obj


  proxy_methods: =>
    apply: (target, thisArg, args) =>
      new Future (callback) =>
        @done (err, data) =>
          callback err, data.apply(@this, args)

    get: (target, name, receiver) =>
      return @[name] if @[name]
      future = new Future (callback) =>
        @done (err, data) =>
          future.setThis data
          callback err, data[name]
      return future

    set: (target, name, val, receiver) =>
      @done (err, data) ->
        data[name] = val


module.exports = Future
