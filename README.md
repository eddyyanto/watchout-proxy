### Dataton WatchOut Proxy Utility.

This proxy utility exposes WatchOut show properties to external TCP client through socket which by default isn't available through WatchOut Control Protocol. Those properties include:
- Auxiliary timelines status, whether it's in running mode or stopped.
- Object position, scale, opacity, rotation and other tween properties etc.
- Value of input defined under Input windows.

This utility reads command strings that contain auxiliary timelines, input values and object properties sent from multiple iPads, keeps track and relay them to WatchOut system.

Note: **setInput** command has a third parameter - fade rate in milliseconds which result in smoother position tweening. The old method of sending multiple same commands with incremental/decremental position value is deprecated.

![WatchOut Proxy Connection Diagram](https://raw.githubusercontent.com/eddyyanto/WatchOut-Proxy/master/connection.png)
