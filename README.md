# AnyDoor
Swift with no pain

![door](http://homepage.ntu.edu.tw/~b01302158/images/01.jpg)

Swift is easy to use, but sometimes get some with with it's strict type checking and optional type. How ever, we can extent origin types with extension, so i wrote some for String, NSData and a little wrapper for dictionary and array, make it easier to access items in dictionary or array

Http access depends on Rinku from <https://github.com/RuiAAPeres/Rinku> a very easy to use http lib.

Because need import cocoon lib to support hmac algorithm, you need to add Objective-C bridge header file in project with next content:

    #import <CommonCrypto/CommonHMAC.h>

