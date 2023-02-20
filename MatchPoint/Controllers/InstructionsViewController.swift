//
//  InstructionsViewController.swift
//  CenterCourt
//
//  Created by Charles Prutting on 12/15/22.
//

import UIKit

class InstructionsViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var exitButton: UIButton!
    
    var contentWidth: CGFloat = 0.0
    var screenShot: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initiateScrollViewWithInstructionImages()
        setBackgroundImageAndExitButton()
    }
    
    func initiateScrollViewWithInstructionImages() {
        //creates 4 imageViews for the 4 instruction card assets and embeds them in the scroll view, and sets the width of the scroll view to the width of the 4 images
        
        scrollView.delegate = self
        for image in 0...3 {
            let imageToDisplay = UIImage(named: "instructions\(image)")
            let imageView = UIImageView(image: imageToDisplay)
            
            let xCoordinate = view.frame.midX + (view.frame.width * CGFloat(image))
            let width = view.frame.width
            let height = (width/3)*4.5
            let heightAdjustment = ((width/3)*2)+10
            contentWidth += width
            
            scrollView.addSubview(imageView)
            imageView.frame = CGRect(x: xCoordinate - (width/2), y: (view.frame.height/2) - (heightAdjustment), width: width, height: height)
        }
        scrollView.contentSize = CGSize(width: contentWidth, height: view.frame.height)
    }
    
    func setBackgroundImageAndExitButton() {
        //sets screenshot of presentng viewController as the background of this screen. tricky tricky
        backgroundImage.image = screenShot
        
        //turns exit button off unless the instructions have been seen before. On their first visit the exit button will be turned on when the user swipes to the 4th slide
        if !MatchSettings.hasOpenedAppBefore {
            exitButton.isHidden = true
            MatchSettings.hasOpenedAppBefore = true
        } else {
            exitButton.isHidden = false
        }
    }
    
    
    //MARK: - Button Presses and Swipe Gestures
    
    @IBAction func exitButtonPressed(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //updates page control display to show the correct progress
        pageControl.currentPage = Int(scrollView.contentOffset.x / CGFloat(view.frame.width))
        
        //turns exit button on at 4th slide, if not already on
        if pageControl.currentPage == 3 {
            exitButton.isHidden = false
        }
    }
    
}
