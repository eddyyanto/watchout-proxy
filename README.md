##This utility acts as a proxy between iPads and WatchOut Production.

By default, WatchOut Production doesn't store it's auxiliary timelines' status: running or inactive, object position, scale, opacity, rotation etc. So when a WatchOut Show that spans multiple screeens with  is being controlled by mobile devices (in our case, they're iPads), a third party utility is needed to act as proxy between them. This is where this WatchOut proxy utility comes in.

This utility will read the commands from mobile devices (iPads) and relay them to WatchOut Production. The WatchOut Production will then play videos and images base on the command it received.

![WatchOut Proxy Connection Diagram](http://github.com/eddyyanto/WatchOut-Proxy/raw/master/connection.png)