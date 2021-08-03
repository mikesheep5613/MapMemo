//
//  ImagesPageViewController.swift
//  MapMemo
//
//  Created by MIKETSAI on 2021/8/2.
//

import UIKit

protocol ImagesPageViewControllerDelegate : AnyObject{
    func didUpdatePageIndex(currentIndex : Int)
}

class ImagesPageViewController: UIPageViewController {
    
    weak var imagesPageViewControllerDelegate: ImagesPageViewControllerDelegate?
    var currentIndex = 0
    var imagesArray : [UIImage]?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        self.dataSource = self
        
        // 建立第一個畫面
        if let startingViewController = showImageVC(at: 0) {
            setViewControllers([startingViewController], direction: .forward, animated: true, completion: nil)
        }
    }
}

extension ImagesPageViewController : UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        var index = (viewController as! ImagesViewController).index
        index -= 1
        return showImageVC(at: index)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        var index = (viewController as! ImagesViewController).index
        index += 1
        return showImageVC(at: index)

    }
    
    func showImageVC (at index: Int) -> ImagesViewController? {
        guard let images = self.imagesArray else {
            return nil
        }
        if index < 0 || index >= images.count {
            return nil
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let pageContentViewController = storyboard.instantiateViewController(identifier: "showImageVC") as? ImagesViewController, let images = self.imagesArray {
            
            pageContentViewController.image = images[index]
            pageContentViewController.index = index
            
            return pageContentViewController
        }
        
        return nil
    }
    
}

extension ImagesPageViewController : UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        if completed {
            if let showImageVC = pageViewController.viewControllers?.first as? ImagesViewController {
                currentIndex = showImageVC.index
                self.imagesPageViewControllerDelegate?.didUpdatePageIndex(currentIndex: showImageVC.index)
                
            }
        }
    }
    
}
