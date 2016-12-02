## Build

Building from source
You can build the server from source on Windows. Please download the source code and libraries needed [Download] . Move them to a folder (e.g. `D:\shiny`) and unzip them.

Please install B4J IDE per the instructions in https://b4x.com/b4j.html. This project is built with Version 4.20(1). Note that you need to install JDK instead of JRE.

jCore library(4.20) in B4J 4.20 contains a bug ( https://www.b4x.com/android/forum/threads/updates-to-internal-libaries.48274/#post-416708 ). It’s been fixed in B4J 4.50.

When using B4J 4.20, you need to update the jCore library.
Copy the files in `D:\shiny\libs\Libraries` to overwrite existing libraries in internal library folder (e.g. `C:\Program Files\Anywhere Software\B4J\Libraries` )

Open B4J, choose Tools > Configure Paths, set the additional lib path (`D:\shiny\libs\additional`). Close the B4J IDE(to refresh the updated libraries).

Double click server.b4j (`D:\shiny\source\server.b4j`) to load the server project.

Select Release mode (drop list Debug/Release/Release(obfuscated)) and press run(F5). You can find compiled file `Objects\server.jar`. Now that the sever is running from B4J IDE, you can choose the Logs tab (right bottom) press Kill Process.

`Objects` folder contains all the files you need to run the sever. You may want to copy the Objects folder to another folder and rename it (e.g., to server) . You can archive this folder (e.g., zip / tar.gz) and distribute it.

`Objects/src`, `Objects/bin` and `Objects/shell` folders contain build information, you should remove them before distribution if you don’t want to share them.

If you want to run server on Windows, you need to install R and shiny first.


[Download]: ../../../releases
