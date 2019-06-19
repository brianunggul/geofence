//
//  diningViewController.swift
//  MGM app
//
//  Created by Brian Unggul on 6/13/19.
//  Copyright © 2019 Brian Unggul. All rights reserved.
//

import UIKit
import Foundation

class diningViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
	
	var timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) {
		(_) in
		print("I find dining interesting!")
	}

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
