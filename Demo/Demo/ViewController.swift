//
//  ViewController.swift
//  AKLocationManager Demo
//
//  Created by Artem Krachulov.
//  Copyright © 2016 Krachulov Artem . All rights reserved.
//  Website: http://www.artemkrachulov.com/
//

import UIKit

class ViewController: UIViewController {
  
   // MARK: - Navigation
   
   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    
    let vc = segue.destinationViewController as! DemoViewController
    vc.google = segue.identifier == "google-segue"
   }
}

