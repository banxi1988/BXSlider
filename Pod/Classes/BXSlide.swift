//
//  BXSlide.swift
//  Pods
//
//  Created by Haizhen Lee on 16/4/19.
//
//

import Foundation
import UIKit


public protocol BXSlide{
  var bx_image:UIImage?{ get }
  var bx_imageURL:NSURL?{ get }
  var bx_title:String?{ get }
}

public extension BXSlide{
  public var bx_duration:NSTimeInterval{
    return 5.0
  }
  var bx_image:UIImage?{ return nil }
  var bx_imageURL:NSURL?{ return nil }
  var bx_title:String?{ return nil }
}

extension NSURL:BXSlide{
  public var bx_imageURL:NSURL?{
    return self
  }
}

extension UIImage:BXSlide{
  public var bx_image:UIImage?{
    return self
  }
}

public class BXSimpleSlide:BXSlide{
  public let image:UIImage?
  public let imageURL:NSURL?
  public let title:String?
  
  public var bx_image:UIImage?{ return image }
  public var bx_imageURL:NSURL?{ return imageURL  }
  public var bx_title:String?{ return title }
  public var bx_duration:NSTimeInterval{ return 5.0 }
  
  public  init(image:UIImage,title:String?=nil){
    self.image = image
    self.title = title
    self.imageURL = nil
  }
  
  public init(imageURL:NSURL,title:String?=nil){
    self.image = nil
    self.title = title
    self.imageURL = imageURL
  }
  
  
  
}