# AnyDoor #
Swift with no pain

![door](http://homepage.ntu.edu.tw/~b01302158/images/01.jpg)

Swift is easy to use, but sometimes get some with with it's strict type checking and optional type. How ever, we can extent origin types with extension, so i wrote some for String, NSData and a little wrapper for dictionary and array, make it easier to access items in dictionary or array

Http access depends on Rinku from <https://github.com/RuiAAPeres/Rinku> a very easy to use http lib.

Because need import cocoon lib to support hmac algorithm, you need to add Objective-C bridge header file in project with next content:

    #import <CommonCrypto/CommonHMAC.h>

Extension for String
-----------------------
a String extension

###Get substring by range:###

    abcde"[1, 3]

it will return "bcd".

and you can use negative index:

    "abcde"[1, -2]
    
will return "bc"


###Check one string contains another string###

    "abcde".adContains("bc")
    
will return true

###Get the index of a string be contained in another string###

    "abcde".adStartAt("bc")
    
will return 1 and if substring not in it, will return -1

###Get JSON object###

    "{\"key\":123}".adJsonObject

will return a wrapper object of the json Dictionary, we will talk about it later

