function pdtp_log(level, message) {
  console.log("[" + level + "]\t-\t" + message);
}

function checkForApplet() {
  if(document.peerlet && document.peerlet.setString) {
    document.peerlet.setString("Hello, Worlds!");
    document.peerlet.callback({ myfun: function(x) { alert(x); } });
  } else {
    setTimeout(checkForApplet, 200);
  }
}
    
checkForApplet();