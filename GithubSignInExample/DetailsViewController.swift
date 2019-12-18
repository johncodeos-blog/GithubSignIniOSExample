//
//  DetailViewController.swift
//  GithubSignInExample
//
//  Created by John Codeos on 12/15/19.
//  Copyright © 2019 John Codeos. All rights reserved.
//

import UIKit

class DetailsViewController: UIViewController {

    @IBOutlet weak var githubIdLabel: UILabel!
    @IBOutlet weak var githubDisplayNameLabel: UILabel!
    @IBOutlet weak var githubEmailLabel: UILabel!
    @IBOutlet weak var githubAvatarUrlLabel: UILabel!
    @IBOutlet weak var githubAccessTokenLabel: UILabel!
    
    var githubId = 0
    var githubDisplayName = ""
    var githubEmail = ""
    var githubAvatarURL = ""
    var githubAccessToken = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        githubIdLabel.text = String(githubId)
        githubDisplayNameLabel.text = githubDisplayName
        githubEmailLabel.text = githubEmail
        githubAvatarUrlLabel.text = githubAvatarURL
        githubAccessTokenLabel.text = githubAccessToken
    }
}
