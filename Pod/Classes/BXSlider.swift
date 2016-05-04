//
//  BXSlider.swift
//

import UIKit
import PinAuto

private let debug = false

public class BXSlider<T:BXSlide>: UIView, UICollectionViewDataSource,UICollectionViewDelegateFlowLayout{
  public private(set) var slides:[T] = []
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
  }
  
  
  func onPageChanged(){
  }
  
  public func updateSlides(rawSlides:[T]){
    slides.removeAll()
    if !rawSlides.isEmpty{
      self.slides.appendContentsOf(rawSlides)
    }
    pageControl.numberOfPages =  rawSlides.count
    pageControl.currentPage = 0
    collectionView.reloadData()
    if autoSlide{
      if let first = slides.first{
        fireTimerAfterDeplay(first.bx_duration)
      }
    }
  }
  
  func updatePageControl(){
    if let index = currentPageIndexPath{
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
  
  public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return slides.count
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
    if debug { NSLog("\(#function)") }
    removeTimer()
  }
  
  public func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
    if debug { NSLog("\(#function)") }
    // On AutoTurn Page Changed
  }
  
  public func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if debug { NSLog("\(#function) \(decelerate)") }
  }
  
  public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
    if debug { NSLog("\(#function)") }
      addTimerIfNeeded()
      updatePageControl()
  }
  
}


public let bxSlideCellIdentifier = "slideCell"

extension BXSlider{
  
  public func itemAtIndexPath(indexPath:NSIndexPath) -> T{
    return slides[indexPath.item]
  }
  
}

// MARK: Slide Load Support
extension BXSlider{

  
}

//MARK: Auto Turn Page Support

extension BXSlider{
  func addTimerIfNeeded(){
    if let slide = slideAtCurrentPage(){
      addTimer(slide)
    }
  }
  
  func addTimer(nextSlide:T){
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
    let index = (indexPath.item + 1) % slides.count
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