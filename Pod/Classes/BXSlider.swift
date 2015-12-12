//
//  BXSlider.swift
//

import UIKit

public protocol BXSlide{
    var bx_image:UIImage?{ get }
    var bx_imageURL:NSURL?{ get }
    var bx_title:String?{ get }
}

public extension BXSlide{
    public var bx_duration:NSTimeInterval{
        return 3.0
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

public class BXSlider<T:BXSlide>: UIView,UIScrollViewDelegate{
    public var slides:[T] = []
    public let pageControl = UIPageControl()
    public let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 320, height: 120))
    public var imageScaleMode: UIViewContentMode = .ScaleAspectFill
    public var autoSlide = true
    public var onTapBXSlideHandler: ( (T) -> Void)?
    public var loadImageBlock:( (URL:NSURL,imageView:UIImageView) -> Void  )?
    var isFirstStart = true
  
  public convenience init(){
    self.init(frame: CGRect(x: 0, y: 0, width: 320, height: 120))
  }
  
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.frame = frame
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        commonInit()
    }
    
    func commonInit(){
        scrollView.pagingEnabled = true
        scrollView.clipsToBounds = true
        scrollView.alwaysBounceHorizontal = false
        scrollView.alwaysBounceVertical = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bounces = false
        scrollView.bouncesZoom = false
        addSubview(scrollView)
        
        addSubview(pageControl)
        pageControl.currentPageIndicatorTintColor = UIColor.whiteColor()
        pageControl.pageIndicatorTintColor = UIColor(white: 0.6, alpha: 0.8)
        pageControl.clipsToBounds = true
    }
    
    
    func onPageChanged(){
    }
    
    public func updateSlides(slides:[T]){
        self.slides = slides
        // configure scroll view
        for subview in scrollView.subviews{
            subview.removeFromSuperview()
        }
        for slide in slides{
            let imageView = UIImageView(frame: CGRectZero)
            if let image = slide.bx_image{
                imageView.image = image
            }else{
                if let url = slide.bx_imageURL{
                 load(url, toImageView: imageView)
                }
            }
            imageView.contentMode = imageScaleMode
            imageView.clipsToBounds = true
            imageView.userInteractionEnabled = true
            let tapGesturer = UITapGestureRecognizer(target: self, action: "onTapSlide:")
            imageView.addGestureRecognizer(tapGesturer)
            scrollView.addSubview(imageView)
        }
        
        isFirstStart = true
      if slides.count > 1{
        bringSubviewToFront(pageControl)
        pageControl.numberOfPages =  slides.count
        pageControl.currentPage = 0
        scrollView.delegate = self
        autoTurnPage()
        pageControl.hidden = false
      }else{
        pageControl.hidden = true
        
      }
        setNeedsLayout()
    }
    
    func load(imageURL:NSURL,toImageView imageView:UIImageView){
        if let loader = loadImageBlock{
            loader(URL: imageURL,imageView: imageView)
        }else{
            let loadTask =  NSURLSession.sharedSession().dataTaskWithURL(imageURL) { (data, resp, error) -> Void in
                if let data = data{
                    NSLog("completionHandler isMainThread?\(NSThread.isMainThread())")
                    let image = UIImage(data: data)
                    dispatch_async(dispatch_get_main_queue()){
                        imageView.image = image
                    }
                }
            }
            loadTask.resume()
        }
    }
    
    private func updateSlideFrame(){
        let rect = bounds
        var currentX : CGFloat = 0
        for subview in scrollView.subviews{
            let imageView = subview
            let imageFrame = rect.offsetBy(dx: currentX, dy: 0)
            imageView.frame = imageFrame
            currentX += rect.width
        }
        scrollView.contentSize = CGSize(width: currentX, height: rect.height)
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        scrollView.frame = bounds
        updateSlideFrame()
       
        let pageCtrlRect = CGRect(x: bounds.minX + 15, y: bounds.maxY - 20, width: bounds.width - 30, height: 20)
        pageControl.frame = pageCtrlRect
        
    }
    
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        let pageWidth = scrollView.frame.width
        pageControl.currentPage = Int(scrollView.contentOffset.x / pageWidth)
        onPageChanged()
    }
    
    public func slideAtCurrentPage() -> T{
        return slides[pageControl.currentPage]
    }
    
    public func slideOfPage(page:Int) -> T{
        return slides[page]
    }
    
    func onTapSlide(gesture:UITapGestureRecognizer){
       let slide = slideAtCurrentPage()
        NSLog("\(__FUNCTION__) \(slide.bx_title)")
        onTapBXSlideHandler?(slide)
    }
    
    
    func autoTurnPage(){
        let nextPage = (pageControl.currentPage + (isFirstStart ? 0: 1)) % slides.count
        isFirstStart = false
        #if DEBUG
        NSLog("autoTurn to page \(nextPage)")
        #endif
        if autoSlide{
            let nextSlide = slideOfPage(nextPage)
            let duration = max(1,nextSlide.bx_duration)
             NSTimer.scheduledTimerWithTimeInterval(duration, target: self, selector: "autoTurnPage", userInfo: nil, repeats: false)
        }
        let pageWidth = frame.width
        UIView.animateWithDuration(0.25){
            self.scrollView.contentOffset.x = pageWidth * CGFloat(nextPage)
            self.pageControl.currentPage = nextPage
        }
        onPageChanged()
    }
}