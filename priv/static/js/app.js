(function() {
  'use strict';

  var ChatClient = function(url, onmessage) {

    var ws = new WebSocket(url);
    var self = this;

    var login = function(username) {
      self.username = username;
      ws.send(JSON.stringify({action: 'login', user: username}));
    }

    var join = function(room_name) {
      ws.send(JSON.stringify({action: 'join', room: room_name}));
    }

    var post = function(room, message) {
      ws.send(JSON.stringify({action: 'post', room: room, message: message}));
    }

    var external = {
      login: login,
      join: join,
      post: post,
      onmessage: undefined,
      onopen: undefined
    };

    ws.onopen = function() {
      var x = Math.round(Math.random() * 10000);
      var user = 'user-' + x;
      login(user);
      join('Alpha');
    };

    ws.onmessage = function(evt) {
      var cmd = JSON.parse(evt.data);
      external.onmessage && external.onmessage(cmd);
    }

    return external;
  };

  var text = document.get

  var client = new ChatClient('ws://'+ document.location.host +'/chat');

  document.addEventListener('DOMContentLoaded', function(evt) {
    var message = document.getElementById('message');

    var chat_text = document.getElementById('chat');

    client.onmessage = function(cmd) {
      if(cmd.action) {
        if(cmd.action === 'message') {
          chat_text.innerHTML += '<div class="chat-message">['+ cmd.user +']: '+ cmd.message + '</div>';
        } else if(cmd.action === 'history') {
          for (var i = 0; i < cmd.history.length; i++) {
              var hi = cmd.history[i];
              chat_text.innerHTML += '<div class="chat-message">['+ hi.user +']: '+ hi.message + '</div>';
          }
        } else {
          console.log(cmd);
        }
      }
    };

    document.getElementById('send').addEventListener('click', function(evt) {
      if(message.value != '') {
        client.post('Alpha', message.value);
        message.value = '';
      }
    });
  });
})();
