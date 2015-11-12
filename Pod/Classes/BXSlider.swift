//
//  BXSlider.swift
//

import UIKit

public protocol BXSlide{
    var bx_image:UIImage?{ get }
    var bx_imageURL:NSURL?{ get }
    var bx_title:String?{ get }
}

public class BXSimpleSlide:BXSlide{
    public let image:UIImage?
    public let imageURL:NSURL?
    public let title:String?
    
    public var bx_image:UIImage?{ return image }
    public var bx_imageURL:NSURL?{ return imageURL  }
    public var bx_title:String?{ return title }
    
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
    
    public var onTapBXSlideHandler: ( (T) -> Void)?
    public var loadImageBlock:( (URL:NSURL,imageView:UIImageView) -> Void  )?
   
    override init(frame: CGRect = CGRect(x: 0, y: 0, width: 320, height: 120)) {
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
        
        bringSubviewToFront(pageControl)
        pageControl.numberOfPages =  slides.count
        pageControl.currentPage = 0
        scrollView.delegate = self
        setNeedsLayout()
        scheduleTimer()
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
    
    public func slideAtCurrentPage() -> T?{
        return slides[pageControl.currentPage]
    }
    
    func onTapSlide(gesture:UITapGestureRecognizer){
        if let slide = slideAtCurrentPage(){
            NSLog("\(__FUNCTION__) \(slide.bx_title)")
            onTapBXSlideHandler?(slide)
        }
    }
    
    var autoTurnPageTimer: NSTimer?
    func scheduleTimer(){
        autoTurnPageTimer?.invalidate()
        autoTurnPageTimer =  NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: "autoTurnPage", userInfo: nil, repeats: true)
    }
    
    func autoTurnPage(){
        let nextPage = (pageControl.currentPage + 1) % slides.count
        let pageWidth = frame.width
        UIView.animateWithDuration(0.25){
            self.scrollView.contentOffset.x = pageWidth * CGFloat(nextPage)
            self.pageControl.currentPage = nextPage
        }
        onPageChanged()
    }
    
//    public override func intrinsicContentSize() -> CGSize {
//        let size = frame.size
//        NSLog("size \(size)")
//        return size
//    }
}