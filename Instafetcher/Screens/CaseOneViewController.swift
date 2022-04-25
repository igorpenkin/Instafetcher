//
//  CaseOneViewController.swift
//  Instafetcher
//
//  Created by Igor Penkin on 25.04.2022.
//

import UIKit


final class CaseOneViewController: UIViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Case One"
        view.backgroundColor = .secondarySystemBackground
        APICaller.shared.getMe()
    }
}
