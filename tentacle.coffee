{EventEmitter} = require 'events'
through = require 'through'
debug   = require('debug')('tentacle:client')
_ = require 'lodash'
TentacleTransformer = require 'tentacle-protocol-buffer'

class Tentacle extends EventEmitter
  constructor: (tentacleConn) ->
    @tentacleTransformer = new TentacleTransformer()
    @tentacleConn = tentacleConn

  start: =>
    debug 'start called'
    @tentacleConn.on 'error', @onTentacleConnectionError
    @tentacleConn.on 'end', @onTentacleConnectionClosed
    @tentacleConn.pipe through(@onTentacleData)

  onTentacleData: (data) =>
    debug "adding #{data.length} bytes from tentacle"
    @parseTentacleMessage data
    @tentacleTransformer.addData data
    @parseTentacleMessage()

  onMessage: (message) =>
    debug "received message\n#{JSON.stringify(message, null, 2)}"
    return unless message?.payload?

    @messageTentacle _.extend({}, message.payload, topic: 'action')

  onConfig: (config) =>
    tentacleConfig = topic: 'config'
    _.extend tentacleConfig, _.pick( config.options, 'pins', 'broadcastPins', 'broadcastInterval' )
    @messageTentacle tentacleConfig

  onTentacleConnectionError: (error) =>
    debug 'tentacle connection error'
    @emit 'error', error
    @cleanup error

  onTentacleConnectionClosed: (data) =>
    debug 'client closed the connection'
    @cleanup()

  parseTentacleMessage: =>
    try
      while (message = @tentacleTransformer.toJSON())
        debug "I got the message\n#{JSON.stringify(message, null, 2)}"
        return @emit 'authenticate', message.authentication if message.topic == 'authentication'
        return @emit 'message', message

    catch error
      debug "error parsing tentacle message"
      @emit 'error', error

  messageTentacle: (msg) =>
    debug "Sending message to the tentacle: #{JSON.stringify(msg, null, 2)}"
    @tentacleConn.write @tentacleTransformer.toProtocolBuffer(msg)

module.exports = Tentacle
