# ckexplorer laboratory
CloudKit Explorer Lab - Move Content From Desktop to Cloud and Then Into TVOS

A platform for experimenting with Cloudkit, especially with AppleTV.

![http://s350968899.onlinehome.us/ckexplorerpic/ckexplorerpic.001.png](http://s350968899.onlinehome.us/ckexplorerpic/ckexplorerpic.001.png)

Pull images thru iTunes on the desktop, or from iCloud files, or from Photos Albumns 

## cloudkit library 
Code common to IOS and TVOS 
TBD: turn into framework
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
TBD: not currently working 
## Requirements

### Build

Xcode 8.0, iOS 10.0 SDK, tvOS 10.0 SDK 

### Runtime

iOS 9.0, tvOS 9.0 

### License

Apache 2.0

Copyright (C) 2016 Bill Donner. All rights reserved.
