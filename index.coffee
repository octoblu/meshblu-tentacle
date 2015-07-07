'use strict';
{EventEmitter} = require 'events'
serialport     = require 'serialport'
through        = require 'through'
_              = require 'lodash'

debug          = require('debug')('tentacle')
Tentacle       = require './tentacle'

MESSAGE_SCHEMA        = require 'tentacle-protocol-buffer/message-schema.json'
tentacleOptionsSchema = require 'tentacle-protocol-buffer/options-schema.json'

OPTIONS_SCHEMA =
  port:
    title: "Serial Port"
    type: "string"

class Plugin extends EventEmitter
  constructor: ->
    @options = {}
    @messageSchema = MESSAGE_SCHEMA
    @optionsSchema = _.clone tentacleOptionsSchema

    _.extend @optionsSchema.properties, OPTIONS_SCHEMA

  onMessage: (message) =>
    return unless @tentacle?
    @tentacle.onMessage message

  onConfig: (device) =>
    debug "OPTIONS:", device
    @setOptions device.options
    @startTentacleConnection device.options


  startTentacleConnection: (config) =>
    @serial.close() if @serial?

    @getSerialPort config, (err, @serial) =>
      @serial.on 'open', =>
        @tentacle = new Tentacle @serial

        @tentacle.on "message", (message) =>
          @emit 'message', _.extend devices: '*', message

        @tentacle.on "error", (error) =>
          debug 'tentacle errored.'
          @serial.close()
        @tentacle.on "request-config", => @tentacle.onConfig @options

        @tentacle.start()
        @tentacle.onConfig @options

      @serial.on 'close', =>
        @serial = null
        debug 'serial port closed'
        _.defer => @startTentacleConnection(config)

  getSerialPort: (options={}, callback=->) =>
    return callback(null, new serialport.SerialPort options.port, baudrate: 57600 ) if options.port?

    @findPort (err, port) =>
      callback(null, new serialport.SerialPort port, baudrate: 57600)

  findPort: (callback=->)=>
    serialport.list (err, ports) =>
      portName = null
      ports.forEach (port) =>
        manufacturer = port.manufacturer.toLowerCase()
        portName = port.comName if manufacturer.indexOf('arduino') != -1
        debug 'port:', port.comName
        debug 'id: ', port.pnpId
        debug 'manufacturer:', port.manufacturer

      return _.defer( => @findPort(callback)) unless portName?
      callback null, portName

  setOptions: (options={}) =>
    @options = options

module.exports =
  messageSchema: MESSAGE_SCHEMA
  optionsSchema: OPTIONS_SCHEMA
  Plugin: Plugin
