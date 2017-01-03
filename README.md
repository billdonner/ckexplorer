# cloudkit laboratory
CloudKit Explorer Lab - Move Content From Desktop to Cloud and Then Into TVOS

A small platform for experimenting with Cloudkit, especially with AppleTV.

![http://s350968899.onlinehome.us/ckexplorerpic/ckexplorerpic.001.png](http://s350968899.onlinehome.us/ckexplorerpic/ckexplorerpic.001.png)

Pull images thru iTunes on the desktop, or from iCloud files, or from Photos Albums 

## motivation
For real time music and other performance purposes it is convenient to put media asset on a TV screen without depending on a host computer or even a mobile device acting as a relay.

This laboratory is a start towards measuring the latencies surrounding the use of CloudKit as a means for uploading content to the iCloud and downloading content to the apple TV.



## cloudkit library 
Code common to IOS and TVOS 
TBD: turn into framework

## targets
- viewer for IOS
- viewer for TVOS
- tbd: viewer for OSX, Web

from tvos:

-- choose cloudkit assets by color

![http://s350968899.onlinehome.us/ckexplorerpic/tv01.jpg](http://s350968899.onlinehome.us/ckexplorerpic/tv01.jpg)

-- hit the "more" button for statistics overlay

![http://s350968899.onlinehome.us/ckexplorerpic/tv03.jpg](http://s350968899.onlinehome.us/ckexplorerpic/tv03.jpg)

-- go full screen by selecting item

![http://s350968899.onlinehome.us/ckexplorerpic/tv02.jpg](http://s350968899.onlinehome.us/ckexplorerpic/tv02.jpg)

-- return via Menu button

![http://s350968899.onlinehome.us/ckexplorerpic/tv04.jpg](http://s350968899.onlinehome.us/ckexplorerpic/tv04.jpg)




## utility functions
Measure common operations 
Currently on screen only


![http://s350968899.onlinehome.us/ckexplorerpic/ck01.png](http://s350968899.onlinehome.us/ckexplorerpic/ck01.png)


![http://s350968899.onlinehome.us/ckexplorerpic/ck02.png](http://s350968899.onlinehome.us/ckexplorerpic/ck02.png)


![http://s350968899.onlinehome.us/ckexplorerpic/ck03.png](http://s350968899.onlinehome.us/ckexplorerpic/ck03.png)

### upload
Sends N Images to Cloudkit in Background. IOS only
Happens quickly because everything is done out of process.

### download
Retrieve all Images in Background, IOS and TVOS
Can be obviously slow with large cloudkit dataset.

### delete
Deletes all Images from Cloudkit, IOS only
Tested with thousands of entries

## Requirements

### Build

Xcode 8.0, iOS 10.0 SDK, tvOS 10.0 SDK 

### Runtime

iOS 9.0, tvOS 9.0 

### License

Apache 2.0

Copyright (C) 2016 Bill Donner. All rights reserved.
