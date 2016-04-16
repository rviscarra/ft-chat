ftChat = angular.module 'ft-chat', []

endPoints =
  [
    'localhost:8000',
    # 'localhost:8001',
    # 'localhost:8002'
  ]

chooseRandomEndpoint = (blacklist) ->
  available = (e for e in endPoints when e !in blacklist)
  ix = Math.floor(Math.random() * available.length)
  available[ix]

ftChat.service 'ChatService',
  class ChatService

    constructor: () ->

      @status = WebSocket.CLOSED
      @endPoint = chooseRandomEndpoint []

    connect: () ->
      try
        @ws = new WebSocket('ws://' + @endPoint + '/chat')
        @ws.onopen = () =>
          @status = WebSocket.OPEN
          if @onConnectCb
            @onConnectCb(@endPoint)

        onDisconnect = (evt) =>
          if @onDisconnectCb and @ws.readyState in [WebSocket.CLOSED, WebSocket.CLOSING]
            @onDisconnectCb()
          @status = @ws.readyState

        @ws.onerror = onDisconnect
        @ws.onclose = onDisconnect

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
      @ws.send(JSON.stringify message)

ftChat.service 'RoomService', ['$http',
  class RoomService
    constructor: (@$http) ->

    getRooms: () ->
      @$http.get('/rooms')
]

ftChat.controller 'ChatController', ['$scope', 'RoomService', 'ChatService',
  class ChatController
    constructor: (@$scope, roomService, chatService) ->
      chatService.onConnect (connectedEndPoint) =>
        @$scope.connectedEndPoint = connectedEndPoint
        @$scope.$apply()

      chatService.onDisconnect () =>
        @$scope.connectedEndPoint = undefined
        @$scope.$apply()

      chatService.connect()

      roomService.getRooms().then (response) =>
        @$scope.allRooms = response.data.rooms.sort()

    selectRoom: (room) ->
      @$scope.selectedRoom = room



]
