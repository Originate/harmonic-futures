Future = require '../src/future'


# Helper function to call a function asynchronously
Function.prototype.callAsync = (obj, args...) -> process.nextTick => @apply(obj, args)



describe 'Future class', ->
  beforeEach -> @spy = sinon.spy()


  it 'instance.isFuture returns true', ->
    future = new Future ->
    expect(future.isFuture).to.be.true


  it 'calls the passed function', ->
    new Future @spy
    expect(@spy).to.have.been.calledOnce


  it 'passes a callback to the called function', ->
    new Future @spy
    expect(@spy.args[0][0]).to.be.a 'function'


  it 'throws an error if callback is called more than once', ->
    expect( ->
      new Future (callback) ->
        callback()
        callback()
    ).to.throw Error



  describe 'done method', ->
    describe 'bound before callback called', ->
      it 'fires when the callback is called', (done) ->
        future = new Future (callback) -> callback.callAsync()
        future.done done

      it 'passes arguments', (done) ->
        future = new Future (callback) -> callback.callAsync(this, 'error', 'data')
        future.done ->
          expect(arguments).to.eql ['error', 'data']
          done()


    describe 'bound after callback called', ->
      it 'fires asynchronously when the callback is called', (done) ->
        future = new Future (callback) -> callback()
        called_asynchronously = no
        future.done ->
          expect(called_asynchronously).to.be.true
          done()
        called_asynchronously = yes

      it 'passes arguments', (done) ->
        future = new Future (callback) -> callback('error', 'data')
        future.done ->
          expect(arguments).to.eql ['error', 'data']
          done()



  describe 'proxy', ->
    describe 'getting properties of futures', ->
      it 'return new futures', (done) ->
        future = new Future (callback) -> callback null, foo: 'bar'
        fooFuture = future.foo
        fooFuture.done (err, data) ->
          expect(data).to.equal 'bar'
          done()

      it 'supports chaining', (done) ->
        future = new Future (callback) -> callback null, foo: bar: 'baz'
        barFuture = future.foo.bar
        barFuture.done (err, data) ->
          expect(data).to.equal 'baz'
          done()


    describe 'setting properties of futures', ->
      it 'sets properties', (done) ->
        future = new Future (callback) -> callback null, foo: 'bar'
        future.foo = 'baz'
        future.foo.done (err, data) ->
          expect(data).to.equal 'baz'
          done()


    describe 'calling methods on futures', ->
      it 'return new futures', (done) ->
        future = new Future (callback) -> callback null, foo: -> 'bar'
        fooFuture = future.foo()
        fooFuture.done (err, data) ->
          expect(data).to.equal 'bar'
          done()

      it 'supports chaining', (done) ->
        future = new Future (callback) -> callback null, foo: -> bar: -> 'baz'
        barFuture = future.foo().bar()
        barFuture.done (err, data) ->
          expect(data).to.equal 'baz'
          done()

      it 'passes arguments', (done) ->
        future = new Future (callback) => callback null, foo: @spy
        future.foo('bar')
        future.done =>
          expect(@spy).to.have.been.calledWith 'bar'
          done()

      it 'sets this properly', (done) ->
        data = foo: @spy
        future = new Future (callback) => callback null, data
        future.foo()
        future.done =>
          expect(@spy).to.have.been.calledOn data
          done()
