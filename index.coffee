'use strict';
{EventEmitter} = require 'events'
{SerialPort}   = require 'serialport'
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
    @tentacle = new Tentacle()

    _.extend optionsSchema.properties, OPTIONS_SCHEMA

  onMessage: (message) =>

  onConfig: (device) =>
    @setOptions device.options
    @serial.close() if @serial?

    @serial = new SerialPort options.port, baudrate: 57600

    @tentacle = new Tentacle @serial

    @tentacle.on "message", (message) =>
      @emit 'message', _.extend devices: '*', message

    @tentacle.on "error", (error) =>
      debug "Tentacle errored"
      @serial.close() if @serial?

    @tentacle.start()
    @tentacle.onConfig config


  setOptions: (options={}) =>
    @options = options

module.exports =
  messageSchema: MESSAGE_SCHEMA
  optionsSchema: OPTIONS_SCHEMA
  Plugin: Plugin
