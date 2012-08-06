##The utility acts as a proxy between multiple iPads and WatchOut Production machine.

By default, WatchOut Production doesn't store it's auxiliary timelines' status: on-off status, position status etc. When a WatchOut Show that spans multiple screeens is being controlled by mobile devices (in our case, they're iPads), a third party utility is needed to act as proxy between them. This is where this utility comes in.

![WatchOut Proxy Connection Diagram](eddyyanto.github.com/WatchOut-Proxy/connection.png)

This utility will read the commands from mobile devices and relay them to WatchOut Production. The WatchOut Production will then play videos and images base on the command it received.