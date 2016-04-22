ftChat = angular.module 'ft-chat', []

endPoints =
  [
    'localhost:8000',
    'localhost:8001',
    'localhost:8002'
  ]

chooseRandomEndpoint = (blacklist) ->
  available = (e for e in endPoints when e !in blacklist)
  ix = Math.floor(Math.random() * available.length)
  available[ix]

generateUsername = () ->
  ix = Math.round(Math.random() * 10000000)
  ix = ix.toString()
  pad = '0'.repeat(8 - ix.length)
  "user-#{pad}#{ix}"

ftChat.service 'ChatService',
  class ChatService

    constructor: () ->

      @status = WebSocket.CLOSED
      @blacklist = []
      @endPoint = chooseRandomEndpoint []
      @user = undefined

    connect: () ->
      try

        @ws = new WebSocket('ws://' + @endPoint + '/chat')
        @ws.onopen = () =>
          console.log "Connected to #{@endPoint}"
          @status = WebSocket.OPEN
          if @onConnectCb
            @onConnectCb(@endPoint)

        checkDisconnect = (evt) =>
          if @onDisconnectCb and @ws.readyState in [WebSocket.CLOSED, WebSocket.CLOSING]
            @onDisconnectCb()
            @blacklist.push @endPoint
            if @blacklist.length == endPoints.length
              @blacklist = []
            @endPoint = chooseRandomEndpoint @blacklist
            setTimeout () =>
              @connect()
            , 500

          @status = @ws.readyState

        @ws.onerror = checkDisconnect
        @ws.onclose = checkDisconnect

      catch error
        @ws = undefined
        console.log(error)

    onConnect: (callback) ->
      @onConnectCb = callback

    onMessage: (callback) ->
      @ws.onmessage = (evt) ->
        callback(JSON.parse evt.data)

    onDisconnect: (callback) ->
      @onDisconnectCb = callback

    send: (message) ->
      console.log(message)
      @ws.send(JSON.stringify message)

    login: (user) ->
      # if not @user
      @user = user
      @send
        action: 'login'
        user: user

    join: (room) ->
      @send
        action: 'join'
        room: room

    leave: (room) ->
      @send
        action: 'leave'
        room: room

    post: (room, message) ->
      @send
        action: 'post'
        room: room
        message: message

ftChat.service 'RoomService', ['$http',
  class RoomService
    constructor: (@$http) ->

    getRooms: () ->
      @$http.get '/rooms'
]

ftChat.controller 'ChatController', ['$scope', 'RoomService', 'ChatService',
  class ChatController
    constructor: (@$scope, roomService, @chatService) ->
      @$scope.rooms = {}
      @$scope.text = ''
      @username = generateUsername()
      # @$scope.username = @username

      @chatService.onConnect (connectedEndPoint) =>

        @$scope.connectedEndPoint = connectedEndPoint
        @chatService.login @username
        @$scope.$apply()

        @chatService.onMessage (cmd) =>
          console.log "Received from #{connectedEndPoint}: #{JSON.stringify cmd}"
          if cmd.action == 'message'
            @$scope.rooms[cmd.room].push
              user: cmd.user
              text: cmd.message
          else if cmd.action == 'history'
            @$scope.rooms[cmd.room] =
              {user: hi.user, text: hi.message} for hi in cmd.history
          else
            console.log 'Wrong action: ' + cmd.action
          @$scope.$apply()

      @chatService.onDisconnect () =>
        @$scope.connectedEndPoint = undefined
        @$scope.$apply()

      @chatService.connect()

      roomService.getRooms().then (response) =>
        rooms = response.data.rooms.sort()
        @$scope.allRooms = rooms
        for room in rooms
          @$scope.rooms[room] = []

    selectRoom: (room) ->
      @chatService.join room
      @$scope.selectedRoom = room
      @selectedRoom = room

    post: () ->
      @chatService.post(@selectedRoom, @$scope.text)
      @$scope.text = ''


]
