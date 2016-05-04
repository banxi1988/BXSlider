//
//  BXSlideCell.swift
//  Pods
//
//  Created by Haizhen Lee on 16/4/19.
//
//

import Foundation
// Build for target uimodel
import UIKit


//-BXSlideCell(m=BXSlide):cc
//_[e0]:i
//title[hor15,b40,h36]:

class BXSlideCell : UICollectionViewCell{
  let imageView = UIImageView(frame:CGRectZero)
  let titleLabel = UILabel(frame:CGRectZero)
  let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }
  
  var item:BXSlide?
  func bind<T:BXSlide>(item:T,to slider:BXSlider<T>){
    self.item = item
    imageView.image = nil // 避免重用时出现老的图片
    //         imageView.kf_setImageWithURL(item._)
    if let image = item.bx_image{
      imageView.image = image
    }else{
      if let url = item.bx_imageURL{
        if let loader = slider.loadImageBlock{
         loader(URL: url,imageView: imageView)
        }else{
         load(url, toImageView: imageView)
        }
      }
    }
  }
  
  
  
  override func awakeFromNib() {
    super.awakeFromNib()
    commonInit()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  var allOutlets :[UIView]{
    return [imageView,titleLabel,activityIndicator]
  }
  var allUIImageViewOutlets :[UIImageView]{
    return [imageView]
  }
  var allUILabelOutlets :[UILabel]{
    return [titleLabel]
  }
  
  func commonInit(){
    for childView in allOutlets{
      contentView.addSubview(childView)
      childView.translatesAutoresizingMaskIntoConstraints = false
    }
    installConstaints()
    setupAttrs()
    
  }
  
  func installConstaints(){
    imageView.pac_edge(0, left: 0, bottom: 0, right: 0)
    
    titleLabel.pa_height.eq(36).install()
    titleLabel.pa_bottom.eq(40).install()
    titleLabel.pac_horizontal(15)
    
    activityIndicator.pac_center()
    
  }
  
  func setupAttrs(){
    titleLabel.hidden = true
    activityIndicator.hidden = true
    activityIndicator.hidesWhenStopped = true
  }
  
  func load(imageURL:NSURL,toImageView imageView:UIImageView){
      activityIndicator.startAnimating()
      let loadTask =  NSURLSession.sharedSession().dataTaskWithURL(imageURL) { (data, resp, error) -> Void in
        if let data = data{
          let image = UIImage(data: data)
          dispatch_async(dispatch_get_main_queue()){
            imageView.image = image
            self.activityIndicator.stopAnimating()
          }
        }
      }
      loadTask.resume()
  }
}
