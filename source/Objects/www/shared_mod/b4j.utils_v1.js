"use strict";

//---------------------------------------------------------------------
// global variables declared in other modules 
// window._g_wsshared is shared with shiny ws
// socket_ShinyAppM is the modified shiny modules


//---------------------------------------------------------------------
//global variables (start with _g_ )  
_g_shinyver = (typeof _g_shinyver !== "undefined") ? _g_shinyver : "0.13.0";


var _g_recvfirstmsg=false;
var _g_pendingMessages = [];

var _g_timerpingIntervalMs = 60000;  // should between 30Sec - 180Sec
var _g_maxClientIdleSec = 90*3600;  // very large number : currently not used 
var _g_lastClientMsgDt = -1; 
var _g_lastServerMsgDt = -1; 

var _g_wsPath = "/relay/ws";


//---------------------------------------------------------------------
//global functions  (start with socket_ )

function socket_getDt(){
	return(Date.now());
}

// shiny-server.js line 466
function socket_disconnectmodal(msg1){
  //$('body').removeClass('ss-reconnecting');
  var msg = 'Disconnected from the server.';
  if(msg1){
	 msg = msg1; 
  }

   
  var html = '<button id="ss-reload-button" type="button" class="ss-dialog-button">Reload</button> '+ msg +'<div class="ss-clearfix"></div>';
  if ($('#ss-connect-dialog').length){
	// Update existing dialog
	$('#ss-connect-dialog').html(html);
	$('#ss-overlay').addClass('ss-gray-out');
  } else {
	// Create dialog from scratch.
	$('<div id="ss-connect-dialog">'+html+'</div><div id="ss-overlay" class="ss-gray-out"></div>').appendTo('body');
  }
  $('#ss-reload-button').click(function(){
	location.reload();
  });
}
	

// get websocket url
// path_par is currently not used  
function socket_address(path_par){
	// var wsPath =  absolutePath; 
	var wsPath = _g_wsPath;

	var l = window.location, fullpath;
	fullpath = ((l.protocol === "https:") ? "wss://" : "ws://") + l.hostname + ":" + l.port + wsPath;

	return fullpath + window.location.search;	

}



//replace socket.send
function socket_send(msg){
	_g_lastClientMsgDt = socket_getDt(); 
	if ( _g_recvfirstmsg == false ) {
		if(msg!=""){
			//console.log( "pendingMessages " + msg);
			_g_pendingMessages.push(msg);
		}

	}else{

		while (_g_pendingMessages.length) {
			var msg2 = _g_pendingMessages.shift();
			//console.log( "pendingMessages sending" + msg2);
			socket_data(msg2);
		}
		if (msg!=""){			
			socket_data(msg);
		}
		
	}
}   

//send the data in b4j format
function socket_data(msg){
	if(msg!=""){
		
		_g_wsshared.send(
			JSON.stringify({type: "event", event: "b4jwsclient_event", params: {"para":msg}})  
		) 				
	}
}

// send b4jcustom custom information (b4j format) to b4j , ping / idletime
// _g_wsshared not init; return
function socket_b4jcustom(typestr, MsgObject){
	if ( _g_recvfirstmsg == false || _g_wsshared.readyState !== 1 ) { 
		return 
	}
	
	var customMsgObject = {};
	customMsgObject["type"] = typestr;
	customMsgObject["message"] = MsgObject;	
	_g_wsshared.send(
		JSON.stringify({type: "event", event: "b4jcustom_event", params:customMsgObject})  
	)

}	

	
function socket_initping(){	

	setInterval(
		function() {
			if ( _g_lastClientMsgDt!=-1 && (_g_lastClientMsgDt + _g_maxClientIdleSec*1000) < socket_getDt() ){
				if (_g_wsshared.readyState == 1) {
				
					_g_wsshared.close();
				}	
			}	

			var pingObject = {};
			socket_b4jcustom("ping",pingObject);
		}, 
		_g_timerpingIntervalMs
	);
		
}	
	
//---------------------------------------------------------------------
//global b4j functions   (start with  b4j_ )
// change b4j_ws to _g_wsshared 
// NOTE: _g_wsshared is changed to a global variable (shinyapp.js)
function b4j_sendData(data) {
    _g_wsshared.send(JSON.stringify({type: "data", data: data}));
}
function b4j_raiseEvent(eventName, parameters) {
    try {
        if (_g_wsshared.readyState !== 1) {
            if (b4j_closeMessage === false) {
                window.console.error("connection is closed.");
                window.alert("Connection is closed. Please refresh the page to reconnect.");
                b4j_closeMessage = true;
            }
        } else {
            _g_wsshared.send(JSON.stringify({type: "event", event: eventName, params: parameters}));
        }
    } catch (e) {
        window.console.error(e);
    }
}
function b4j_addEvent(selector, event, eventName, preventDefault) {
    var obj = $(selector);
    if (obj.length > 0) {
        obj.on(event, function (e) {
            if (preventDefault) {
                e.preventDefault();
                e.stopPropagation();
            }
            b4j_raiseEvent(eventName, {which: e.which, target: e.target.id, pageX: e.pageX, pageY: e.pageY, metaKey: e.metaKey});
        });
    }
}
function b4j_addAutomaticEvents(data) {
    $.each(data, function (index, value) {
        b4j_addEvent("#" + value.id, value.event, value.id + "_" + value.event, true);
    });
}
function b4j_runFunction(func, params) {
    return window[func].apply(null, params);
}

function b4j_eval(params, script) {
    var f = new Function(script);
    return f.apply(null, params);
}

function b4j_ws_onmessage(ed) {
	//console.log('--------b4j_ws_onmessage----------');
	//console.log(ed);
	//var ed = JSON.parse(event.data);
	if (ed.etype === "runmethod") {
		$(ed.id)[ed.method].apply($(ed.id), ed.params);
	} else if (ed.etype === "runmethodWithResult") {
		b4j_sendData($(ed.id)[ed.method].apply($(ed.id), ed.params));
	} else if (ed.etype === "setAutomaticEvents") {
		b4j_addAutomaticEvents(ed.data);
	} else if (ed.etype === "runFunction") {
		b4j_runFunction(ed.prop, ed.value);
	} else if (ed.etype === "runFunctionWithResult") {
		b4j_sendData(b4j_runFunction(ed.prop, ed.value));
	} else if (ed.etype === "eval") {
		b4j_eval(ed.value, ed.prop);
	} else if (ed.etype === "evalWithResult") {
		b4j_sendData(b4j_eval(ed.value, ed.prop));
	} else if (ed.etype === "alert") {
		window.alert(ed.prop);
	}
	
};


//---------------------------------------------------------------------
// document ready

$( document ).ready(function() {
	
    if (typeof WebSocket === 'undefined') {
        window.alert("WebSockets are not supported by your browser.");
        return;
    }	
	
	Shiny.addCustomMessageHandler("__shinyrunb4j__",
	  function(message) {
		b4j_ws_onmessage(message);
	  }
	);

});

