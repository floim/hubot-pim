fs           = require 'fs'
util         = require 'util'
EventEmitter = require('events').EventEmitter

Robot        = require('hubot').robot()
Adapter      = require('hubot').adapter()
PimClient    = require 'pim-client'

class Pim extends Adapter
  autoStatus: "focus"

  run: =>
    try
      conf = fs.readFileSync "config.json"
      @options = JSON.parse conf
    catch e
      console.error """
        config.json not found!
        Please provide config.json, specifying your bot's token.
        """
    @connect()
    @emit 'connected' # Don't emit this more than once, EVER! Hubot gets confused

  connect: =>
    @client = new PimClient @, @options
    @client.on 'destroy', =>
      @client.removeAllListeners()
      @client = null
      setTimeout @connect, 1000
    @client.on 'authenticated', (args) =>
      @subscribed = []
      @id = args.id
    @client.on 'error', (e) =>
      @robot.logger.error "#{e.code}"
    @client.on 'log', (message) =>
      unless message.match /^(<<|>>) /
        @robot.logger.info message

  reply: (user, strings...) =>
    @send user, strings...

  send: (to, strings...) =>
    if strings.length > 0
      while message = strings.shift()
        @robot.logger.info "Sending: #{message}"
        @client?.sendCommand "MSG", {chatId:to.chatId,type:"message",message:message,timestamp:new Date().getTime()}, (args) ->
          if args.errorCode
            @robot.logger.error "Failed to send '#{message}'"
            @robot.logger.info util.inspect(args)
    return true

  YOU: (args, cb) =>
    for chatId in args.invites ? []
      @client?.sendCommand "JOIN", {chatId: chatId}, ->
    for chatId in args.chats ? []
      @client?.sendCommand "SUBSCRIBE", {chatId:chatId}, (args2) ->
        if args2.errorCode?
          @robot.logger.error "Couldn't subscribe to '#{chatId}'"
          @robot.logger.info args

  MSG: (args, cb) =>
    if args.type is 'message'
      if args.authorId isnt @id
        from = @robot.userForId args.authorId
        from.chatId = args.chatId
        body = args.message
        @robot.logger.info "Message[chat: #{args.chatId}]: #{body}"
        @robot.receive new Robot.TextMessage(from, body)

  STATUS: (args, cb) =>
  OTR: (args, cb) =>
  DATA: (args, cb) =>

exports.use = (robot) ->
  new Pim robot
