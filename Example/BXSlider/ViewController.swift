//
//  ViewController.swift
//  BXSlider
//
//  Created by banxi1988 on 11/12/2015.
//  Copyright (c) 2015 banxi1988. All rights reserved.
//

import UIKit
import BXSlider

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let urls = [
            "http://ww2.sinaimg.cn/large/72973f93gw1exwtjow3juj216n16n151.jpg",
            "http://ww4.sinaimg.cn/large/72973f93gw1exmgz9wywcj216o1kwnfs.jpg",
            "http://ww1.sinaimg.cn/large/72973f93gw1extl2fs0zjj22ak1pxqv6.jpg",
            "http://ww2.sinaimg.cn/large/72973f93gw1ex8qcz2m6zj20dc0hsgnh.jpg",
            "http://ww3.sinaimg.cn/large/72973f93gw1ex461bmtocj20dc0hsq57.jpg",
            "http://ww2.sinaimg.cn/large/72973f93gw1ewqbfxchf6j218g0xc4es.jpg",
        ]
        
        let slides = urls.flatMap{ NSURL(string: $0)}.map{ BXSimpleSlide(imageURL: $0) }
        let slider = BXSlider<BXSimpleSlide>()
      slider.onTapBXSlideHandler = { slide in
        NSLog("onTapSlide \(slide.imageURL)")
      }
        slider.autoSlide = false
        self.view.addSubview(slider)
        slider.updateSlides(slides)
        let width = view.frame.width
        let height = width * 0.618
        slider.frame = CGRect(x: 0, y: 0, width: width, height: height)
    }


}

