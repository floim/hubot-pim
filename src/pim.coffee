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
    @loadedUsernames = []
    @client = new PimClient @, @options
    @client.on 'destroy', =>
      @client.removeAllListeners()
      @client = null
      setTimeout @connect, 1000
    @client.on 'authenticated', (args) =>
      @subscribed = []
      @id = args.id
      userIds = []
      for own key, user of @robot.brain.data.users
        userIds.push user.id
      if userIds.length
        @loadUsernames userIds
    @client.on 'error', (e) =>
      @robot.logger.error "#{e.code}"
    @client.on 'log', (message) =>
      unless message.match /^(<<|>>) /
        @robot.logger.info message
      else
        @robot.logger.debug message

  reply: (user, strings...) =>
    @send user, strings...

  send: (to, strings...) =>
    if strings.length > 0
      while message = strings.shift()
        @robot.logger.info "Sending: #{message}"
        # Transform message
        message = message.replace /(^|\s)(https?:\/\/[^\s]+\.(?:jpe?g|png|gif))(\s|$)/g, "$1!!$2$3"
        @client?.sendCommand "MSG", {chatId:to.chatId,type:"message",message:message,timestamp:new Date().getTime()}, (args) ->
          if args.errorCode
            @robot.logger.error "Failed to send '#{message}'"
            @robot.logger.info util.inspect(args)
    return true

  loadUsernames: (ids) =>
    if !Array.isArray ids
      ids = [ids]
    uncheckedIds = []
    for id in ids
      if @loadedUsernames.indexOf(id) is -1
        uncheckedIds.push id
        @loadedUsernames.push id
    if uncheckedIds.length > 0
      @client.sendCommand "USERINFO", {id:[id]}, @processUSERINFO

  processUSERINFO: (args) =>
    if args.errorCode? or !args.id? or !args.username?
      @robot.logger.warning "USERINFO error or invalid args"
      return
    for id, i in args.id ? []
      user = @robot.userForId id
      user['name'] = args.username[i]
      @robot.logger.debug "Set username for user #{id}: #{user['name']}"

  YOU: (args, cb) =>
    for chatId in args.invites ? []
      @client?.sendCommand "JOIN", {chatId: chatId}, ->
    for chatId in args.chats ? []
      @client?.sendCommand "SUBSCRIBE", {chatId:chatId}, (args2) =>
        if args2.errorCode?
          @robot.logger.error "Couldn't subscribe to '#{chatId}'"
          @robot.logger.info args
        else
          @loadUsernames args2.memberId ? []

  MSG: (args, cb) =>
    if args.type is 'message'
      if args.authorId isnt @id
        from = @robot.userForId args.authorId
        if /(^[0-9]| )/.test ""+from['name']
          from['name'] = "User #{from.id}"
          @loadUsernames from.id
        from.chatId = args.chatId
        body = args.message
        @robot.logger.info "Message[chat: #{args.chatId}]: #{body}"
        @robot.receive new Robot.TextMessage(from, body)

  STATUS: (args, cb) =>
  OTR: (args, cb) =>
  DATA: (args, cb) =>

exports.use = (robot) ->
  new Pim robot
