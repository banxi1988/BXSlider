//
//  BXSlider.swift
//

import UIKit
import PinAuto

#if DEBUG
private let debug = false
#else
private let debug = false
#endif

public class BXSlider<T:BXSlide>: UIView, UICollectionViewDataSource,UICollectionViewDelegateFlowLayout{
  public private(set) var slides:[T] = []
  private var loopSlides: [T] = []
  public let pageControl = UIPageControl()
  private let collectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: UICollectionViewFlowLayout())
  public var scrollView:UICollectionView{
    return collectionView
  }
  public var imageScaleMode: UIViewContentMode = .ScaleAspectFill
  public var autoSlide = true
  public var onTapBXSlideHandler: ( (T) -> Void)?
  public var loadImageBlock:( (URL:NSURL,imageView:UIImageView) -> Void  )?
  
  // 重新注册 bxSlideCellIdentifier 的 Cell 之后便可以使用 此 Block 来 configure 自定义的 各 Cell
  public var configureCellBlock: ( (cell:UICollectionViewCell,indexPath:NSIndexPath) -> Void )?
  
  private let flowlayout = UICollectionViewFlowLayout()
  var isFirstStart = true
  public var loopEnabled = true
  
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
    addSubview(scrollView)
    addSubview(pageControl)
    
    installConstraints()
    setupAttrs()
   
    collectionView.registerClass(BXSlideCell.self, forCellWithReuseIdentifier: bxSlideCellIdentifier)
    
    flowlayout.minimumLineSpacing = 0
    flowlayout.minimumInteritemSpacing = 0
    flowlayout.sectionInset = UIEdgeInsetsZero
    flowlayout.scrollDirection = .Horizontal
    
    collectionView.collectionViewLayout = flowlayout
    collectionView.dataSource = self
    collectionView.delegate = self
    
  }
  
  func installConstraints(){
    scrollView.pac_edge()
    
    pageControl.pac_horizontal(15)
    pageControl.pa_bottom.eq(15).install()
    pageControl.pa_height.eq(20).install()
  }
  
  func setupAttrs(){
    scrollView.clipsToBounds = true
    scrollView.alwaysBounceHorizontal = false
    scrollView.alwaysBounceVertical = false
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.showsVerticalScrollIndicator = false
    scrollView.bounces = false
    scrollView.bouncesZoom = false
    scrollView.pagingEnabled = true
    pageControl.currentPageIndicatorTintColor = UIColor.whiteColor()
    pageControl.pageIndicatorTintColor = UIColor(white: 0.5, alpha: 0.8)
    pageControl.clipsToBounds = true
  }
  
  public override func layoutSubviews() {
    super.layoutSubviews()
    // 需要在 Layout 中确定 itemSize
    let itemSize = bounds.size
    flowlayout.itemSize = itemSize
    if loopEnabled && !loopSlides.isEmpty {
      let indexPath = NSIndexPath(forRow: 1, inSection: 0)
      collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .CenteredHorizontally, animated: false)
    }
  }
  
  
  func onPageChanged(){
  }
  
  public func updateSlides(rawSlides:[T]){
    slides.removeAll()
    if !rawSlides.isEmpty{
      self.slides.appendContentsOf(rawSlides)
    }
    loopSlides.removeAll()
    loopSlides.appendContentsOf(rawSlides)
    
    if let first = rawSlides.first{
      loopSlides.insert(first, atIndex: 0)
    }
    if let last = rawSlides.last{
      loopSlides.append(last)
    }
    
    pageControl.numberOfPages =  rawSlides.count
    pageControl.currentPage = 0
    collectionView.reloadData()
    if loopEnabled && !loopSlides.isEmpty{
      let indexPath = NSIndexPath(forRow: 1, inSection: 0)
      collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .CenteredHorizontally, animated: false)
    }
    if autoSlide{
      if let first = slides.first{
        fireTimerAfterDeplay(first.bx_duration)
      }
    }

  }
  
  func updatePageControl(){
    guard  let index = currentPageIndexPath else {
      return
    }
    if debug { NSLog("currentIndexPath: \(index.to_s)") }
    if loopEnabled{
      if index.item == 0 {
        pageControl.currentPage = slides.count - 1
      }else if index.item == loopSlides.count - 1 {
        pageControl.currentPage = 0
      }else{
        pageControl.currentPage = index.item - 1
      }
    }else{
      pageControl.currentPage = index.item
    }
  }
  
  
  public func slideAtCurrentPage() -> T?{
    if let index = currentPageIndexPath {
      return itemAtIndexPath(index)
    }
    return nil
  }
  
  var currentPageIndexPath:NSIndexPath?{
    let bounds = collectionView.bounds
    return collectionView.indexPathForItemAtPoint(CGPoint(x: bounds.midX, y: bounds.midY))
  }
  
  
  // MARK: Auto Turn Page
  
  var timer:NSTimer?
  
  public override func willMoveToWindow(newWindow: UIWindow?) {
    super.willMoveToWindow(newWindow)
    if newWindow == nil{
      // remove from window
      removeTimer()
    }else{
      addTimerIfNeeded()
    }
  }
  
  func onAutoTurnPageTimerFired(){
    autoTurnPage()
  }
  
  //  BXSlider:UICollectionViewDataSource{
  public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
    return 1
  }
  
  private var numberOfItems:Int {
    if loopEnabled{
       return loopSlides.count
    }else{
      return slides.count
    }
  }
  
  public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return numberOfItems
  }
  
  public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(bxSlideCellIdentifier, forIndexPath: indexPath)
    let item = itemAtIndexPath(indexPath)
    if let slideCell = cell as? BXSlideCell{
      slideCell.bind(item, to: self)
      slideCell.imageView.contentMode = imageScaleMode
    }
    configureCellBlock?(cell: cell,indexPath: indexPath)
    return cell
  }
  
  // UICollectionViewDelegateFlowLayout
  
  public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    let item = itemAtIndexPath(indexPath)
    onTapBXSlideHandler?(item)
  }
 
  // UIScrollViewDelegate
  public func scrollViewWillBeginDragging(scrollView: UIScrollView) {
//    if debug { NSLog("\(#function)") }
    removeTimer()
  }

  
  public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
    if debug { NSLog("\(#function)") }
      addTimerIfNeeded()
    handleSlideToFirstAndLastSlide()
      updatePageControl()
  }
  
  public func scrollViewDidScroll(scrollView: UIScrollView) {
//    if debug { NSLog("\(#function)") }
  }
  
  func handleSlideToFirstAndLastSlide(){
    if !loopEnabled{
      return
    }
    guard let currentIndexPath = currentPageIndexPath else{
      return
    }
    if debug { NSLog("[\(self.loopSlides.count)] currentIndexPath: \(currentIndexPath.to_s)") }
    let index = currentIndexPath.item
    if index == self.loopSlides.count - 1 {
      if debug { NSLog("loopToFirst") }
      let indexPath = NSIndexPath(forItem: 1, inSection: 0)
      collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .CenteredHorizontally, animated: false)
      pageControl.currentPage = 0
    }else if index == 0{
      if debug { NSLog("loopToLast") }
      let indexPath = NSIndexPath(forItem: self.loopSlides.count - 1, inSection: 0)
      collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .CenteredHorizontally, animated: false)
      pageControl.currentPage = pageControl.numberOfPages - 1
    }
  }
  
}

extension NSIndexPath{
  var to_s:String{
    return "[\(section),\(item)]"
  }
}

public let bxSlideCellIdentifier = "slideCell"

extension BXSlider{
  
  public func itemAtIndexPath(indexPath:NSIndexPath) -> T{
    if loopEnabled{
      return loopSlides[indexPath.item]
    }else{
      return slides[indexPath.item]
    }
  }
  
}

// MARK: Slide Load Support
extension BXSlider{

  
}

//MARK: Auto Turn Page Support

extension BXSlider{
  func addTimerIfNeeded(){
    if !autoSlide{
      return
    }
    if let slide = slideAtCurrentPage(){
      addTimer(slide)
    }
  }
  
  func addTimer(nextSlide:T){
    if !autoSlide{
      return
    }
    let duration = max(1,nextSlide.bx_duration)
    fireTimerAfterDeplay(duration)
  }
  
  func fireTimerAfterDeplay(deplay:NSTimeInterval){
    timer?.invalidate()
    timer = NSTimer.scheduledTimerWithTimeInterval(deplay, target: self, selector: #selector(onAutoTurnPageTimerFired), userInfo: nil, repeats: false)
  }
  
  func removeTimer(){
    timer?.invalidate()
    timer = nil
  }
  
  func nextCycleIndexPathOf(indexPath:NSIndexPath) -> NSIndexPath{
    let index = (indexPath.item + 1) % numberOfItems
    return NSIndexPath(forItem: index, inSection: 0)
  }
  
  func nextCycleItemOfIndexPath(indexPath:NSIndexPath) -> T?{
    guard let indexPath = currentPageIndexPath else{
      return nil
    }
    let nextIndexPath =  nextCycleIndexPathOf(indexPath)
    return itemAtIndexPath(nextIndexPath)
  }
  
  func autoTurnPage(){
    guard let indexPath =  currentPageIndexPath else{
      if autoSlide{ // 当前可能界面还没显示出来 .
        fireTimerAfterDeplay(2)
      }
      return
    }
    if slides.count < 2{
      return
    }
    let nextIndexPath = nextCycleIndexPathOf(indexPath)
    if debug { NSLog("nextIndexPath: \(nextIndexPath)") }
    if autoSlide{
     let nextSlide = itemAtIndexPath(nextIndexPath)
      addTimer(nextSlide)
    }
    self.collectionView.scrollToItemAtIndexPath(nextIndexPath, atScrollPosition: .CenteredHorizontally, animated: true)
    self.pageControl.currentPage = nextIndexPath.item
    onPageChanged()
  }
  
}