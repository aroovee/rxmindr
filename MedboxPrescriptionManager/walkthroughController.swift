//
//  walkthroughController.swift
//  Rxmindr
//
//  Created by Aroovee Nandakumar on 3/28/25.
//


import UIKit

class ViewController: UIViewController {
    
    var num = 1
    @IBOutlet weak var text: UILabel!
    @IBOutlet weak var dots: UIPageControl!
    @IBOutlet weak var start: UIButton!
    @IBAction func startButton(_ sender: Any) {
        
    }
    override func viewDidLoad(){
        super.viewDidLoad()
    }
    
    @IBAction func swipeAction( sender: Any){
        num += 1
        if num == 4{
            text.isHidden = true
            dots.isHidden = true
        }
        else {
            text.text = "Step\(String(num))"
        }
        if num == 3{
            start.isHidden = false
        }
        else{
            start.isHidden = true
        }
    }
}
