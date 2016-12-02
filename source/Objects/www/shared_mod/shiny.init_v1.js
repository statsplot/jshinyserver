"use strict";
//two global variables written in index html
//var _g_shinyver="0.14";
//var _g_shinyvermap = {"init":"v1","utils":"v1","mod":"0.14","base":"0.14","sharedpath":"0.14"}


document.write('<script src="/shared_mod/b4j.utils_'+ _g_shinyvermap["utils"] +'.js"></script>');
document.write('<script src="/shared_mod/shiny.mod_'+ _g_shinyvermap["mod"] +'.js"></script>');
document.write('<script src="/shared_mod/shiny.base_'+ _g_shinyvermap["base"] +'.js"></script>');   
  
document.write('<link rel="stylesheet" type="text/css" href="/shared_mod/shiny-server.css">');
  

  