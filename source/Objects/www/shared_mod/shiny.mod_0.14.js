//load after b4j_utils.js (functions _g_* _g_shinyver )
//shiny version 0.14
socket_ShinyAppM = (typeof socket_ShinyAppM !== "undefined") ? socket_ShinyAppM : {};

socket_ShinyAppM.createSocket = function () {
    var self = this;
	
    var createSocketFunc = function() {
		var ws_url =  socket_address("");
		var ws = new WebSocket(ws_url );
		
		ws.binaryType = 'arraybuffer';
		return ws;
	};

    var socket = createSocketFunc();      
	window._g_wsshared = socket;
	
	var hasOpened = false; //0.14
	
	var shinyver_jsevents= ["0.12.2","0.13.0","0.13.1","0.13.2","0.14"];
	
    socket.onopen = function() {
	   hasOpened = true; //0.14
	  //(document).trigger shiny events are available shiny.js 0.12.2-0.13.2
	  if ( shinyver_jsevents.indexOf(_g_shinyver) > -1 ){ 
	    $(document).trigger({
		  type: 'shiny:connected',
		  socket: socket
	    });
	  } 
	  
	  self.onConnected(); //0.14
	  
	  socket_send(JSON.stringify({	  
		method: 'init',
		data: self.$initialInput
	  }));
		  
    };


    socket.onmessage = function(e) {

		_g_lastServerMsgDt = socket_getDt(); 
		var ed = JSON.parse(e.data);
        if (ed.etype === "eval" &&  ed.hasOwnProperty("value") && ed.value[0] === "__shinymsgs__" ) {
			self.dispatchMessage(ed.prop);	  
		}else{
			b4j_ws_onmessage(ed);
		}
		
		//after receive the first message( b4j setAutomaticEvents ), the ws connection is made. 
		if (_g_recvfirstmsg === false ){
			_g_recvfirstmsg = true;
			socket_initping();
		}
		//send messages in the queue
		socket_send('');
    };
	
    socket.onclose = function() {
	  //(document).trigger shiny events are available shiny.js 0.12.2-0.13.2
	  if (hasOpened) {  //0.14
        $(document).trigger({
          type: 'shiny:disconnected',
          socket: socket
        });
		
	  }
	  
      $(document.body).addClass('disconnected');
	  if (hasOpened) {  //0.14
        self.$notifyDisconnected();  
	  }
	  socket_disconnectmodal("");

      self.onDisconnected(); //0.14 Must be run before self.$removeSocket()
      self.$removeSocket();  //0.14
		
    };
    return socket;
};


socket_ShinyAppM.$sendMsg = function(msg) {
	socket_send(msg);
};

