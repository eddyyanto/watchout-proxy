###Dataton WatchOut Proxy Utility.

By default, Dataton WatchOut system control protocol doesn’t support status query of:
- auxiliary timelines status: whether running or stopped.
- object position, scale, opacity, rotation etc.
- value of input variables.

So when we have a WatchOut system that spans multiple screens and controlled by multiple iPads, a utility is needed to act as proxy between WatchOut system and the iPads.

This utility reads command strings that contain auxiliary timelines, input values and object properties sent from multiple iPads and keep track and relay them to WatchOut system.

Note: **setInput** command has a third parameter - fade rate in milliseconds which result in smoother position tweening. The old method of sending multiple same commands with incremental/decremental position value is deprecated.

![WatchOut Proxy Connection Diagram](https://raw.githubusercontent.com/eddyyanto/WatchOut-Proxy/master/connection.png)