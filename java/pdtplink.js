function addVideo(localHttpPort, sharePort) {
    console.log("addVideo(", localHttpPort, ", ", sharePort, ")" );
    $A(document.getElementsByTagName("video")).each(function(e) {
        var title = e.getAttribute("title");
        var src = e.getAttribute("src");
        var width = e.getAttribute("width");
        var height = e.getAttribute("height");
        var description = e.getAttribute("title");
        
        if(localHttpPort > 0 && e.getAttribute("usepeers") != "false") {
            src = "http://127.0.0.1:" + localHttpPort + "/" + escape(src);        
        }
        
        var flashSrc = "http://clickcaster.com/plugin_assets/clickcaster_engine/players/videoplayer.swf?"
                + "base_url=http://clickcaster.com&"
                + "slug=spiritualsproject&"
                + "bgcolor=000000&endbox=true&file="
                + src
                + "&text=" + escape(description);

        var flash = document.createElement("embed");            
        flash.setAttribute("src", flashSrc);
        flash.setAttribute("pluginspage", "http://www.macromedia.com/go/getflashplayer");
        flash.setAttribute("wmode", "transparent");
        flash.setAttribute("quality", "high");
        flash.setAttribute("width", width);
        flash.setAttribute("height", height);
        flash.setAttribute("type", "application/x-shockwave-flash");                        
        e.appendChild(flash);        
    });
}

var CHECK_ATTEMPT_NUMBER = 0;
var CHECK_ATTEMPT_MAX = 25;
function checkForApplet() {
  try {
    if(document.peerlet &&
       document.peerlet.isRunning &&
       document.peerlet.isRunning()) {
      var localHttpPort = document.peerlet.getLocalHttpPort();
      var sharePort = document.peerlet.getSharePort();
      console.log("Local HTTP port=" + localHttpPort);
      console.log("Sharing port=" + sharePort);

      addVideo(localHttpPort, sharePort);
    } else {
      ++CHECK_ATTEMPT_NUMBER;
      if(CHECK_ATTEMPT_NUMBER > CHECK_ATTEMPT_MAX) {
        console.log("Applet apparently failed to initialize.");
        addVideo(-1, -1);
      } else {
        setTimeout(checkForApplet, 200);
      }
    }
  } catch(ex) {
    console.log("Exception: " + ex);
    ++CHECK_ATTEMPT_NUMBER;
    if(CHECK_ATTEMPT_NUMBER > CHECK_ATTEMPT_MAX) {
        console.log("Applet apparently failed to initialize.");    
        addVideo(-1, -1);      
    } else {
        setTimeout(checkForApplet, 200);
    }
  }
}
    
checkForApplet();