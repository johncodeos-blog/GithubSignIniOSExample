//
//  LoginViewController.swift
//  GithubSignInExample
//
//  Created by John Codeos on 12/14/19.
//  Copyright © 2019 John Codeos. All rights reserved.
//

import UIKit
import WebKit

class LoginViewController: UIViewController {
    @IBOutlet var githubLoginBtn: UIButton!

    var githubId = 0
    var githubDisplayName = ""
    var githubEmail = ""
    var githubAvatarURL = ""
    var githubAccessToken = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        self.githubLoginBtn.layer.cornerRadius = 10.0
    }

    @IBAction func githubLoginBtnAction(_ sender: UIButton) {
        githubAuthVC()
    }

    var webView = WKWebView()
    func githubAuthVC() {
        // Create github Auth ViewController
        let githubVC = UIViewController()
        // Generate random identifier for the authorization
        let uuid = UUID().uuidString
        // Create WebView
        let webView = WKWebView()
        webView.navigationDelegate = self
        githubVC.view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: githubVC.view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: githubVC.view.leadingAnchor),
            webView.bottomAnchor.constraint(equalTo: githubVC.view.bottomAnchor),
            webView.trailingAnchor.constraint(equalTo: githubVC.view.trailingAnchor)
        ])

        let authURLFull = "https://github.com/login/oauth/authorize?client_id=" + GithubConstants.CLIENT_ID + "&scope=" + GithubConstants.SCOPE + "&redirect_uri=" + GithubConstants.REDIRECT_URI + "&state=" + uuid

        let urlRequest = URLRequest(url: URL(string: authURLFull)!)
        webView.load(urlRequest)

        // Create Navigation Controller
        let navController = UINavigationController(rootViewController: githubVC)
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.cancelAction))
        githubVC.navigationItem.leftBarButtonItem = cancelButton
        let refreshButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshAction))
        githubVC.navigationItem.rightBarButtonItem = refreshButton
        let textAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        navController.navigationBar.titleTextAttributes = textAttributes
        githubVC.navigationItem.title = "github.com"
        navController.navigationBar.isTranslucent = false
        navController.navigationBar.tintColor = UIColor.white
        navController.navigationBar.barTintColor = UIColor.colorFromHex("#333333")
        navController.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
        navController.modalTransitionStyle = .coverVertical

        self.present(navController, animated: true, completion: nil)
    }

    @objc func cancelAction() {
        self.dismiss(animated: true, completion: nil)
    }

    @objc func refreshAction() {
        self.webView.reload()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "detailseg" {
            let DestView = segue.destination as! DetailsViewController
            DestView.githubId = self.githubId
            DestView.githubDisplayName = self.githubDisplayName
            DestView.githubEmail = self.githubEmail
            DestView.githubAvatarURL = self.githubAvatarURL
            DestView.githubAccessToken = self.githubAccessToken
        }
    }
}

extension LoginViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        self.RequestForCallbackURL(request: navigationAction.request)
        decisionHandler(.allow)
    }

    func RequestForCallbackURL(request: URLRequest) {
        // Get the authorization code string after the '?code=' and before '&state='
        let requestURLString = (request.url?.absoluteString)! as String
        print(requestURLString)
        if requestURLString.hasPrefix(GithubConstants.REDIRECT_URI) {
            if requestURLString.contains("code=") {
                if let range = requestURLString.range(of: "=") {
                    let githubCode = requestURLString[range.upperBound...]
                    if let range = githubCode.range(of: "&state=") {
                        let githubCodeFinal = githubCode[..<range.lowerBound]
                        githubRequestForAccessToken(authCode: String(githubCodeFinal))

                        // Close GitHub Auth ViewController after getting Authorization Code
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
        }
    }

    func githubRequestForAccessToken(authCode: String) {
        let grantType = "authorization_code"

        // Set the POST parameters.
        let postParams = "grant_type=" + grantType + "&code=" + authCode + "&client_id=" + GithubConstants.CLIENT_ID + "&client_secret=" + GithubConstants.CLIENT_SECRET
        let postData = postParams.data(using: String.Encoding.utf8)
        let request = NSMutableURLRequest(url: URL(string: GithubConstants.TOKENURL)!)
        request.httpMethod = "POST"
        request.httpBody = postData
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let task: URLSessionDataTask = session.dataTask(with: request as URLRequest) { (data, response, _) -> Void in
            let statusCode = (response as! HTTPURLResponse).statusCode
            if statusCode == 200 {
                let results = try! JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [AnyHashable: Any]
                let accessToken = results?["access_token"] as! String
                // Get user's id, display name, email, profile pic url
                self.fetchGitHubUserProfile(accessToken: accessToken)
            }
        }
        task.resume()
    }

    func fetchGitHubUserProfile(accessToken: String) {
        let tokenURLFull = "https://api.github.com/user"
        let verify: NSURL = NSURL(string: tokenURLFull)!
        let request: NSMutableURLRequest = NSMutableURLRequest(url: verify as URL)
        request.addValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
        let task = URLSession.shared.dataTask(with: request as URLRequest) { data, _, error in
            if error == nil {
                let result = try! JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [AnyHashable: Any]
                // AccessToken
                print("GitHub Access Token: \(accessToken)")
                self.githubAccessToken = accessToken
                // GitHub Id
                let githubId: Int! = (result?["id"] as! Int)
                print("GitHub Id: \(githubId ?? 0)")
                self.githubId = githubId
                // GitHub Display Name
                let githubDisplayName: String! = (result?["login"] as! String)
                print("GitHub Display Name: \(githubDisplayName ?? "")")
                self.githubDisplayName = githubDisplayName
                // GitHub Email
                let githubEmail: String! = (result?["email"] as! String)
                print("GitHub Email: \(githubEmail ?? "")")
                self.githubEmail = githubEmail
                // GitHub Profile Avatar URL
                let githubAvatarURL: String! = (result?["avatar_url"] as! String)
                print("github Profile Avatar URL: \(githubAvatarURL ?? "")")
                self.githubAvatarURL = githubAvatarURL
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "detailseg", sender: self)
                }
            }
        }
        task.resume()
    }
}
