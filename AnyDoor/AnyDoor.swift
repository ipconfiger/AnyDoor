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
public enum HMACAlgorithm {
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
        return ADAccessor((value as! NSArray).objectAtIndex(index))
    }

    /// Access range of aray item
    /// sample:  accessor[1...3]
    ///:params: range object
    ///:return: Accessor array wrap the item in array
    subscript(range:NSRange)->Array<ADAccessor>{
        let arr:NSArray = (value as! NSArray).subarrayWithRange(range)
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
        let v:AnyObject = (value as! NSDictionary).objectForKey(index)!
        return ADAccessor(v)
    }

    func val<T>(_:T.Type)->T{
        return (value as! T)
    }

    /// Get wrapped Array value
    public var array:[Any]!{
        get{
            return map((value as! [AnyObject]), {ADAccessor($0)})
        }
    }

    /// Get wrapped dictionary value
    public var dictionary:Dictionary<String, ADAccessor>{
        get{
            let dt:[String:AnyObject] = (value as! [String:AnyObject])
            var result:Dictionary<String, ADAccessor> = Dictionary<String, ADAccessor>(minimumCapacity:dt.count)
            for (k, val) in dt{
                result[k] = ADAccessor(val)
            }
            return result
        }
    }

    /**
    check if a key in dictionary value

    :param: key key of dictionary

    :returns: Accessor object wrap the dictionary value
    */
    func hasKey(key:String)->Bool{
        if (self.value is Dictionary<String, AnyObject>){
            if (self.value as! Dictionary<String, AnyObject>)[key] != nil{
                return true
            }
        }
        return false
    }

}

/// Operator to repeat string "a"*5 return "aaaaa"
func * (pt0: String, pt1: Int) -> String {
    var arr:[String] = [pt0]
    for i in 1..<pt1{
        arr+=[pt0]
    }
    return "".join(arr)
}


public extension String{

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
            let length: Int = count(self)
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

    /// Get String length
    public var length:Int {
        get{
            return count(self)
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
            return self.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!.adJsonObject
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



    //#MARK: - URL extension
    /// self as a YouPai Yun file key, get a Rinku object to fetch resource
    func adYouPaiYunFileData(domain:String)->Rinku{
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
        let strLen = Int(self.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        let digestLen = algorithm.digestLength()
        let result = UnsafeMutablePointer<CUnsignedChar>.alloc(digestLen)
        let objcKey = key as NSString
        let keyStr = objcKey.cStringUsingEncoding(NSUTF8StringEncoding)
        let keyLen = Int(objcKey.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))


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
        let strLen = Int(self.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        let digestLen = algorithm.digestLength()
        let result = UnsafeMutablePointer<CUnsignedChar>.alloc(digestLen)
        let objcKey = key as NSString
        let keyStr = objcKey.cStringUsingEncoding(NSUTF8StringEncoding)
        let keyLen = Int(objcKey.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        CCHmac(algorithm.toCCHmacAlgorithm(), keyStr, keyLen, str!, strLen, result)
        let resultData:NSData = NSData(bytes: UnsafePointer<Void>(result), length: digestLen)
        return resultData
    }


    /// get md5 hash hex
    func adMD5Hex() -> String {
        let data = (self as NSString).dataUsingEncoding(NSUTF8StringEncoding)
        let result = NSMutableData(length: Int(CC_MD5_DIGEST_LENGTH))
        let resultBytes = UnsafeMutablePointer<CUnsignedChar>(result!.bytes)
        CC_MD5(data!.bytes, CC_LONG(data!.length), resultBytes)

        let a = UnsafeBufferPointer<CUnsignedChar>(start: resultBytes, count: result!.length)
        let hash = NSMutableString()

        for i in a {
            hash.appendFormat("%02x", i)
        }
        return hash as String
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

public extension NSData{

    /// get json dictionary wrapped by accessor object
    public var adJsonObject:ADAccessor{
        get{
            return ADAccessor(NSJSONSerialization.JSONObjectWithData(self, options: NSJSONReadingOptions.AllowFragments, error: nil)!)
        }
    }

    /// to utf8 string
    public var adUtf8String:String{
        get{
            return "\(NSString(data: self, encoding: NSUTF8StringEncoding))"
        }
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
        let ts = Int(NSDate().timeIntervalSince1970) + 3600*12
        let policyStr = "{\"scope\":\"\(scope)\",\"deadline\":\(ts)}"
        let encodedPutPolicy = policyStr.adToUrlSafeBase64String()
        let encodedSign = encodedPutPolicy.adHmacEncrptData(HMACAlgorithm.SHA1, key: accessSecret).adToUrlSafeB64String()
        let policyToken = ":".join([accessKey, encodedSign, encodedPutPolicy])
        return Rinku.post("http://upload.qiniu.com").file(self, filefield: "file", filename: filename, extForm: ["token":policyToken, "key": filename])
    }


    /// upload file to YouPai Yun
    ///:params:filename, bucket, securyKey, ext-form
    ///:return:Rinku object
    func adUploadToYouPaiYun(filename:String, bucket:String, securyKey:String, form:Dictionary<String, AnyObject>)->Rinku{
        let ts = Int(NSDate().timeIntervalSince1970) + 3600*12
        let policy = "{\"bucket\":\"\(bucket)\",\"expiration\":\(ts),\"save-key\":\"\(filename)\"}"
        let sign = "\(policy.adToUrlSafeBase64String())&\(securyKey)".adMD5Hex()
        var params = ["bucket":bucket,"save-key":"\(filename)", "expiration":"\(ts)", "policy":policy.adToUrlSafeBase64String(), "signature":sign]
        for (k, val) in form{
            params.updateValue((val as! String), forKey: k)
        }
        return Rinku.post("http://v0.api.upyun.com/\(bucket)").file(self, filefield: "file", filename: filename, extForm: params)
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
