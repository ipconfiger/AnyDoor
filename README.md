# AnyDoor (任意门)#
Swift with no pain （让Swift不再蛋痛）

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

###Check File exists###

if String is a absolute path of a file, you can check if it exists in file system

    "path".adFileExists

###Get file data###

if String is a absolute path of a file, you can get NSData like this:

    "path".adFileData

###Delete file###

if String is a absolute path of a file, you can delete the file like this:

    "path".adFileDelete()

###Get File in QiNiu Yun###

if the string is a key of public resouces in QiNiu Yun, you can get the file like:

    "qi niu key".adQiniuFileData("your qiniu domain").complete({(data, response, error)->Void in
        data.adSaveTo('file path')
    })
    
###Transform to NSURL###

if the string is an url, you can get NSURL object like this:

    "http://#".adToURL()
    
###Transform to File NSURL###

if the string is a file url, you can get NSURL object like this:

    "file://#".adFileURL()
    
###Get absolute path string in system folder of a filename###

if the string is a filename, you can get absolute path by this:

    "voice.wav".adFileInFolderString(NSSearchPathDirectory.DocumentDirectory)
    
###Get NSURL in system folder of a filename###

if the string is a filename, you can get NSURL by this:

    "voice.wav".adFileInFolderURL(NSSearchPathDirectory.DocumentDirectory)
    
###Encrypt to urlsafe base64 string###

    "abcdefg".adToUrlSafeBase64String()
    
will return a string encrypt to urlsafe base64

###Decrypt an urlsafe base64 string to origin string###

    "xafeWFrfrg==".adFromUrlSafeBase64String()
    
will return the origin string of it

###HMAC hash a string with key###

    "abcdefg".adHmacEncrptHex(HMACAlgorithm.sha1)
    
will return the hex string of hash result

    "abcdefg".adHmacEncrptData(HMACAlgorithm.sha1)
    
will return the NSData object for furthor process

###Get UIImage by name###

    "avatar".adImage()
    
###Get resizableUIImage by name###

    "background".adResizableImage(10, 20, 5, 3)

Extension of NSData
---------------------------
a NSData extension

###Get wrapped json object###

if you got this NSData object,maybe from http lib, or file,you can do like:

    data.adJsonObject

###Get UTF8 String###

    data.adUtf8String
    
###Get urlsafe base64 string###

    data.adToUrlSafeB64String()
    
##Transform to a Array###

    data.adAsArray(Byte)
    
will return Array<Byte>

###Upload File data to QiNiu Yun###

    data.adUploadToQiniu("avatar.jpg",'access key', 'access secret', 'scope name').complete({(data, response, error)->Void in
        let returnJson = data.adJsonObject
        let resourceKey:String = returnJson["key"].string
    })

###Safe NSData to a file###

    data.adSaveTo("file path")

###Get a file###

    NSData.adReadFile("file path")
    
Array and Dictionary with no pain
-----------------------

when you access a Dictionary or Array, you mostly thing to do is to fight with optional type not the data it self. Something like :

    let dict = ["aDict": ["aString": "string"], "anArray":[1,2,3,4]]
    let str:String = (dict["aDict"]! as Dictionary<String,String>)["aString"]!
    let intvalue:Int = (dict["anArray"] as Array<Int>)[2]
    
It's hard to write and hard to read.

So i wrapped the Array and Dictionary with class ADAccessor to make it easier.

extension adJsonObject in String and NSData will return the ADAccessor object wrapped the data(Array or Dictionary)

    let dict = ADAccessor(["aDict": ["aString": "string"], "anArray":[1,2,3,4]])
    let str = dict["aDict"]["aString"].string
    let intvalue:Int = dict["anArray"][2].int

than it's friendly to write and read
