//
//  ViewController.swift
//  ScrollViewScreenShootsDemo
//
//  Created by 骚姜的HHBoy on 2018/6/4.
//  Copyright © 2018年 骚姜的HHBoy. All rights reserved.
//

import UIKit
import WebKit
import SnapKit

class ViewController: UIViewController ,UIGestureRecognizerDelegate,WKUIDelegate,WKNavigationDelegate{
    
    lazy var webView =  WKWebView()
    var money:Float = 0.00;
    var password:NSString = ""
    var count:Int = 0;
    var currentCount:Int = 1;
    var currentMoney:Float = 0;
    let shotsBtn:UIButton = UIButton()
    let maxWithdrawMoney:Float = 50000.00
    
    var urlStr:NSString = "" {
        willSet {
            print("will set url")
        }
        didSet {
            print("did set url")
            //load webView
            webView.load(NSURLRequest(url: NSURL(string: self.urlStr as String)! as URL) as URLRequest)
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setWebSubView()
        webView.uiDelegate = self
        webView.navigationDelegate = self;
        self.urlStr = "https://epay.163.com/wap/h5/mainView.htm"
    }
    
    func setWebSubView() {
        webView.backgroundColor = UIColor.white
        self.view.addSubview(webView)
        
        webView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.view)
        }
        
        shotsBtn.setTitle("一键提现", for: UIControlState.normal)
        //        shotsBtn.sizeToFit()
        shotsBtn.backgroundColor = UIColor.black
        self.view.addSubview(shotsBtn)
        shotsBtn.addTarget(self, action: #selector(clickInputBtn), for: UIControlEvents.touchUpInside)
        shotsBtn.snp.makeConstraints { (make) in
            make.top.equalTo(self.view.snp.bottom).offset(-85)
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 80, height: 80))
        }
        //        shotsBtn.backgroundColor = UIColor.init(red: 228, green: 57, blue: 48, alpha: 1)
        
        shotsBtn.layer.masksToBounds = true
        shotsBtn.layer.cornerRadius = 40
    }
    
    @objc func cleaData() {
        self.money = 0;
        self.password = ""
        self.count = 0;
        self.currentCount = 1;
        self.currentMoney = 0;
    }
    
    @objc func clickInputBtn() {
        //初始化UITextField
        
        var moneyField:UITextField = UITextField();
        var passwordField:UITextField = UITextField();
        let msgAlertCtr = UIAlertController.init(title: "提示", message: "请输入完整信息，点击确认进行自动提现", preferredStyle: .alert)
        let ok = UIAlertAction.init(title: "确认", style:.default) { (action:UIAlertAction) ->() in
            if((moneyField.text) == "" || (passwordField.text) == ""){
                print("请输入信息")
                return;
            }
            self.money = Float(moneyField.text!)!
            self.password = passwordField.text! as NSString
            self.count = Int(self.money / self.maxWithdrawMoney)
            if Float(self.count) * self.maxWithdrawMoney < self.money {
                self.count += 1
            }
            self.withdrawBtnClick(portMoney: self.getCurrentMoney())
        }
        
        let cancel = UIAlertAction.init(title: "取消", style:.cancel) { (action:UIAlertAction) -> ()in
            print("取消输入")
        }
        
        msgAlertCtr.addAction(ok)
        msgAlertCtr.addAction(cancel)
        //添加textField输入框
        msgAlertCtr.addTextField { (textField) in
            //设置传入的textField为初始化UITextField
            moneyField = textField
            moneyField.placeholder = "输入提现金额"
        }
        msgAlertCtr.addTextField { (textField) in
            //设置传入的textField为初始化UITextField
            passwordField = textField
            passwordField.placeholder = "输入支付密码"
        }
        //设置到当前视
        self.present(msgAlertCtr, animated: true, completion: nil)
    }
    
    @objc func getCurrentMoney() -> (Float){
        if self.count == 1 {
            return self.money
        } else if self.currentCount == self.count {
            return (self.money - Float(self.count - 1) * self.maxWithdrawMoney)
        } else {
            return self.maxWithdrawMoney
        }
    }
    
    @objc func withdrawBtnClick(portMoney:Float) {
        print("portMoney = %d",portMoney)
        if currentCount  > count || portMoney <= 2{
            self.cleaData()
            return;
        }
        self.currentMoney = portMoney;
        webView.evaluateJavaScript(String(format: "document.getElementsByName(\"amount\")[0].value='%.2f';", portMoney)) { (result, error) in
            print("resultMoney = %.2f",portMoney)
            self.webView.evaluateJavaScript("document.getElementsByClassName(\"long-btn next\")[0].click();") { (result, error) in
                self.checkPasswordUrl()
            }
        }
        
    }
    
    func checkPasswordUrl() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 4) {
            if  self.webView.url?.absoluteString == "https://epay.163.com/wap/h5/charge/chargePage.htm?type=withdraw#verify?step=password&item=SHORT_PAY_PASSWORD" || self.webView.url?.absoluteString == "https://epay.163.com/wap/h5/charge/chargePage.htm?type=withdraw#verify?step=password&item=PAY_PASSWORD"{
                self.inPutPassword()
            } else {
                self.urlStr = "https://epay.163.com/wap/h5/charge/chargePage.htm?type=withdraw"
            }
        }
    }
    
    func inPutPassword() {
        if self.webView.url?.absoluteString == "https://epay.163.com/wap/h5/charge/chargePage.htm?type=withdraw#verify?step=password&item=PAY_PASSWORD" {
            self.webView.evaluateJavaScript(String(format: "document.getElementsByClassName('formInput-1')[0].value='%@'", self.password)) { (result, error) in
                self.webView.evaluateJavaScript("document.getElementsByClassName('long-btn next')[0].disabled=false") { (result, error) in
                    self.webView.evaluateJavaScript("document.getElementsByClassName(\"long-btn next\")[0].click();") { (result, error) in
                        self.currentCount += 1
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 10) {
                            if self.currentCount > self.count
                            {
                                self.cleaData()
                                self.urlStr = "https://epay.163.com/wap/h5/mainView.htm"
                            } else {
                                self.urlStr = "https://epay.163.com/wap/h5/charge/chargePage.htm?type=withdraw"
                            }
                        }
                    }
                } ;
            } ;
        } else if self.webView.url?.absoluteString == "https://epay.163.com/wap/h5/charge/chargePage.htm?type=withdraw#verify?step=password&item=SHORT_PAY_PASSWORD" {
            self.webView.evaluateJavaScript(String(format: "document.getElementsByClassName('password')[0].value='%@'", self.password)) { (result, error) in
                self.webView.evaluateJavaScript("document.getElementsByClassName('long-btn next')[0].disabled=false") { (result, error) in
                    self.webView.evaluateJavaScript("document.getElementsByClassName(\"long-btn next\")[0].click();") { (result, error) in
                        self.currentCount += 1
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 10) {
                            if self.currentCount > self.count
                            {
                                self.cleaData()
                                self.urlStr = "https://epay.163.com/wap/h5/mainView.htm"
                            } else {
                                self.urlStr = "https://epay.163.com/wap/h5/charge/chargePage.htm?type=withdraw"
                            }
                        }
                    }
                } ;
            } ;
        }
    }
    
    /// 页面开始加载
    @objc func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        
        NSLog("loading start")
    }
    
    /// 页面加载完成
    @objc func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        NSLog("loading finish")
        if  self.webView.url?.absoluteString == "https://epay.163.com/wap/h5/charge/chargePage.htm?type=withdraw"{
            shotsBtn.isHidden = false
            if self.currentCount > 1 {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5) {
                    self.withdrawBtnClick(portMoney: self.getCurrentMoney())
                }
            }
        } else {
            shotsBtn.isHidden = true
        }
    }
    
    /// 跳转失败的时候调用
    @objc func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        NSLog("jump error")
    }
    
    /// 内容加载失败
    @objc func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        NSLog("loading eerror")
    }
    
    @objc func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        
    }
}

