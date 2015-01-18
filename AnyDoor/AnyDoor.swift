//
//  DreamUtility.swift
//  testRecodeVideo
//
//  Created by LiMing on 15/1/17.
//  Copyright (c) 2015年 miaomi. All rights reserved.
//

import Foundation
import UIKit

/// Sign method enum for hmac
enum HMACAlgorithm {
    case MD5, SHA1, SHA224, SHA256, SHA384, SHA512

    func toCCHmacAlgorithm() -> CCHmacAlgorithm {
        var result: Int = 0
        switch self {
        case .MD5:
            result = kCCHmacAlgMD5
        case .SHA1:
            result = kCCHmacAlgSHA1
        case .SHA224:
            result = kCCHmacAlgSHA224
        case .SHA256:
            result = kCCHmacAlgSHA256
        case .SHA384:
            result = kCCHmacAlgSHA384
        case .SHA512:
            result = kCCHmacAlgSHA512
        }
        return CCHmacAlgorithm(result)
    }

    func digestLength() -> Int {
        var result: CInt = 0
        switch self {
        case .MD5:
            result = CC_MD5_DIGEST_LENGTH
        case .SHA1:
            result = CC_SHA1_DIGEST_LENGTH
        case .SHA224:
            result = CC_SHA224_DIGEST_LENGTH
        case .SHA256:
            result = CC_SHA256_DIGEST_LENGTH
        case .SHA384:
            result = CC_SHA384_DIGEST_LENGTH
        case .SHA512:
            result = CC_SHA512_DIGEST_LENGTH
        }
        return Int(result)
    }
}

/// Access Dictionary or array with no pain
public struct ADAccessor {

    private let value:AnyObject!

    ///:init a accessor
    ///:params: AnyObject
    ///:return:Accessor Object
    public init(_ data:AnyObject){
        value = data
    }

    /// Access Array item
    /// sample: accessor[0]
    ///:params: index
    ///:return: Accessor wrap the item in array
    subscript(index:Int)->ADAccessor{
        return ADAccessor((value as NSArray).objectAtIndex(index))
    }

    /// Access range of aray item
    /// sample:  accessor[1...3]
    ///:params: range object
    ///:return: Accessor array wrap the item in array
    subscript(range:NSRange)->Array<ADAccessor>{
        let arr:NSArray = (value as NSArray).subarrayWithRange(range)
        //let result:NSMutableArray = NSMutableArray(capacity: arr.count)
        var result:Array<ADAccessor> = Array<ADAccessor>()
        for item:AnyObject in arr{
            var acc:ADAccessor = ADAccessor(item)
            result += [acc]
        }
        return result
    }

    /// Access Dictionary item
    /// sample: accessor["key"]
    ///:params: any hashable object
    ///:return: Accessor wrap the item in dictionary
    subscript(index:AnyObject)->ADAccessor{
        let v:AnyObject = (value as NSDictionary).objectForKey(index)!
        return ADAccessor(v)
    }

    /// Get wrapped String value
    public var string:String {
        get{
            return self.value as String
        }
    }

    /// Get wrapped Int value
    public var int:Int{
        get{
            return Int(self.value as NSNumber)
        }
    }

    /// Get wrapped Float value
    public var float:Float{
        get{
            return Float(self.value as NSNumber)
        }
    }

    /// Get wrapped Bool value
    public var bool:Bool{
        get{
            return (self.value as Bool)
        }
    }

    /// Get wrapped Array value
    public var array:[Any]!{
        get{
            return map((value as [AnyObject]), {ADAccessor($0)})
        }
    }

    /// Get wrapped dictionary value
    public var dictionary:Dictionary<String, ADAccessor>{
        get{
            let dt:[String:AnyObject] = (value as [String:AnyObject])
            var result:Dictionary<String, ADAccessor> = Dictionary<String, ADAccessor>(minimumCapacity:dt.count)
            for (k, val) in dt{
                result[k] = ADAccessor(val)
            }
            return result
        }
    }
}

extension String{

    //#MARK: - slicing

    /// Substring by range
    /// sample: "abcde"[1, 3] for "bcd" or negative index as "abcde"[1, -2] for "bc"
    ///:params: range object
    ///:return: sub string
    subscript (range: Int...) -> String {
        get{
            if (range.count>2){
                assertionFailure({ () -> String in
                    "Wrong argument, must 2 bug got \(range.count)"
                    }())
            }
            let length: Int = countElements(self)
            let startIdx = (range[0]<0 ? (length + range[0]) : range[0])
            let endIdx = (range[1]<0 ? (length + range[1]) : range[1])
            if (startIdx>endIdx){
                assertionFailure({ () -> String in
                    "Index out of range (\(startIdx):\(endIdx))"
                    }())
            }
            let indexRange:Range<Int> = Range<Int>(start: startIdx,end: endIdx)
            return self.substringWithRange(Range<String.Index>(start: advance(self.startIndex, indexRange.startIndex), end: advance(self.startIndex, indexRange.endIndex)))
        }
    }

    /// Check if some string contains another
    ///:params:sub string
    ///:return: Bool for string in it
    func adContains(searchString:String)->Bool{
        let textRange = self.rangeOfString(searchString)
        return textRange != nil
    }


    /// Get string in another string's start index int value
    ///:params:sub string
    ///:return: int value
    func adStartAt(searchString:String)->Int{
        let textRange = self.rangeOfString(searchString)
        if (textRange != nil){
            return (textRange!.startIndex.getMirror().value as? Int)!
        }
        return -1
    }

    //#MARK: - JSON extension

    /// json dictionary wrapped by Accessor
    public var adJsonObject:ADAccessor{
        get{
            return self.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!.adToJsonObject()
        }
    }

    //#MARK: - file extension
    /// self as a file path, check if it exists
    public var adFileExists:Bool{
        get{
            return NSFileManager.defaultManager().fileExistsAtPath(self)
        }
    }


    /// self as a file path, get file data as NSData
    public var adFileData:NSData{
        get{
            return NSData(contentsOfFile: self)!
        }
    }

    /// self as a file path, delete it
    func adFileDelete()->Bool{
        return NSFileManager.defaultManager().removeItemAtPath(self, error: nil)
    }


    //#MARK: - URL extension
    /// self as a Qiniu Yun file key, get a Rinku object to fetch resource
    func adQiniuFileData(domain:String)->Rinku{
        var url = "http://\(domain)/\(self)"
        return Rinku.get(url)
    }

    /// self as a url, to NSURL object
    func adToURL()->NSURL{
        return NSURL(string: self)!
    }


    /// self as a File url, to NSURL object
    func adFileURL()->NSURL{
        return NSURL(fileURLWithPath: self)!
    }

    /// self as a filename , get path string if it in system directory
    func adFileInFolderString(catalog:NSSearchPathDirectory)->String{
        let path = NSSearchPathForDirectoriesInDomains(catalog, NSSearchPathDomainMask.UserDomainMask, true)
        return "\(path[0])/\(self)"
    }

    /// self as a filename , get NSURL object if it in system directory
    func adFileInFolderURL(catalog:NSSearchPathDirectory)->NSURL{
        let path = self.adFileInFolderString(catalog)
        return NSURL(fileURLWithPath: path)!
    }

    //#MARK: - base64 extension
    /// get urlsafe base64 string
    func adToUrlSafeBase64String()->String{
        let utf8str: NSData = self.dataUsingEncoding(NSUTF8StringEncoding)!
        let base64Encoded:NSString = utf8str.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))

        return String(base64Encoded).stringByReplacingOccurrencesOfString("+", withString: "-", options: NSStringCompareOptions.LiteralSearch, range: nil).stringByReplacingOccurrencesOfString("/", withString: "_", options: NSStringCompareOptions.LiteralSearch, range: nil)
    }

    /// get string from a base64 string
    func adFromUrlSafeBase64String()->String{
        let b64Str:String = self.stringByReplacingOccurrencesOfString("-", withString: "+", options: NSStringCompareOptions.LiteralSearch, range: nil).stringByReplacingOccurrencesOfString("_", withString: "/", options: NSStringCompareOptions.LiteralSearch, range: nil)

        let data = NSData(base64EncodedString: b64Str, options:NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
        let base64Decoded = NSString(data: data!, encoding: NSUTF8StringEncoding)
        return "\(base64Decoded)"
    }

    //#MARK: - hash extension
    /// get hmac hash hex string
    func adHmacEncrptHex(algorithm: HMACAlgorithm, key:String)->String{
        let str = self.cStringUsingEncoding(NSUTF8StringEncoding)
        let strLen = UInt(self.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        let digestLen = algorithm.digestLength()
        let result = UnsafeMutablePointer<CUnsignedChar>.alloc(digestLen)
        let objcKey = key as NSString
        let keyStr = objcKey.cStringUsingEncoding(NSUTF8StringEncoding)
        let keyLen = UInt(objcKey.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))

        CCHmac(algorithm.toCCHmacAlgorithm(), keyStr, keyLen, str!, strLen, result)
        var hash = NSMutableString()
        for i in 0..<digestLen {
            hash.appendFormat("%02x", result[i])
        }
        result.destroy()
        return String(hash)
    }

    /// get hmac hash NSData
    func adHmacEncrptData(algorithm: HMACAlgorithm, key:String)->NSData{
        let str = self.cStringUsingEncoding(NSUTF8StringEncoding)
        let strLen = UInt(self.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        let digestLen = algorithm.digestLength()
        let result = UnsafeMutablePointer<CUnsignedChar>.alloc(digestLen)
        let objcKey = key as NSString
        let keyStr = objcKey.cStringUsingEncoding(NSUTF8StringEncoding)
        let keyLen = UInt(objcKey.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        CCHmac(algorithm.toCCHmacAlgorithm(), keyStr, keyLen, str!, strLen, result)
        let resultData:NSData = NSData(bytes: UnsafePointer<Void>(result), length: digestLen)
        return resultData
    }

    //#MARK: - Image extension
    /// self as a image name, return UIImage object
    func adImage()->UIImage{
        return UIImage(named: self)!
    }

    /// self as a image name, return resizeable UIImage
    func adResizableImage(corner:Float...)->UIImage{
        if (corner.count != 4){
            assertionFailure({ () -> String in
                "Wrong argument, must be 4 but \(corner.count) input"
            }())
        }
        let img = UIImage(named: self)!
        return img.resizableImageWithCapInsets(UIEdgeInsetsMake(CGFloat(corner[0]), CGFloat(corner[1]), CGFloat(corner[2]), CGFloat(corner[3])))
    }

}

extension NSData{

    /// get json dictionary wrapped by accessor object
    func adToJsonObject()->ADAccessor{
        return ADAccessor(NSJSONSerialization.JSONObjectWithData(self, options: NSJSONReadingOptions.AllowFragments, error: nil)!)
    }

    /// to utf8 string
    func adToUtf8String()->String{
        return "\(NSString(data: self, encoding: NSUTF8StringEncoding))"
    }

    /// to url safe base64 string
    func adToUrlSafeB64String()->String{
        let base64Encoded:NSString = self.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
        return String(base64Encoded).stringByReplacingOccurrencesOfString("+", withString: "-", options: NSStringCompareOptions.LiteralSearch, range: nil).stringByReplacingOccurrencesOfString("/", withString: "_", options: NSStringCompareOptions.LiteralSearch, range: nil)
    }

    /// get Byte Array
    func adAsArray<T>(_:T.Type)->Array<T>{
        let pointer = UnsafePointer<T>(self.bytes)
        let buffer = UnsafeBufferPointer<T>(start:pointer, count:self.length/sizeof(T))
        return [T](buffer)
    }

    /// upload data to Qiniu Yun
    ///:params: filename, accessKey, accessSecret, scope
    ///:return: Rinku object
    func adUploadToQiniu(filename:String, accessKey:String, accessSecret:String, scope:String)->Rinku{
        let policyStr = "{\"scope\":\"\(scope)\",\"deadline\":1421522367}"
        NSLog("op:\(policyStr)")
        let encodedPutPolicy = policyStr.adToUrlSafeBase64String()
        NSLog("ps:\(encodedPutPolicy)")
        let encodedSign = encodedPutPolicy.adHmacEncrptData(HMACAlgorithm.SHA1, key: accessSecret).adToUrlSafeB64String()
        NSLog("sign:\(encodedSign)")
        let policyToken = ":".join([accessKey, encodedSign, encodedPutPolicy])
        NSLog("tk:\(policyToken)")
        return Rinku.post("http://upload.qiniu.com").file(self, filefield: "file", filename: filename, extForm: ["token":policyToken, "key": filename])
    }


    /// save to system directory
    func adSaveTo(catalog:NSSearchPathDirectory, filename:String)->Void{
        let path = filename.adFileInFolderString(catalog)
        self.writeToFile(path, atomically: true)
    }

    /// read file from system directory
    class func adReadFile(catalog:NSSearchPathDirectory, filename:String)->NSData{
        let path = filename.adFileInFolderString(catalog)
        return NSData(contentsOfFile: path, options: NSDataReadingOptions.UncachedRead, error: nil)!
    }

}
