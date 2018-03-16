//
//  ViewController.swift
//  ApplePayDemo
//
//  Created by shenzhenshihua on 2018/3/15.
//  Copyright © 2018年 shenzhenshihua. All rights reserved.
//

import UIKit
import PassKit

class ViewController: UIViewController, PKPaymentAuthorizationViewControllerDelegate {

    var mySummaryItems = Array<PKPaymentSummaryItem>.init()
    var myShippingMethods = Array<PKShippingMethod>.init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    /*配置支付环境
     
     1.使用XCode创建一个工程, 并设置好对应的BundleID

     2.注册并配置一个商业标示符（Merchant ID）
     
     3.添加一个App ID
     
     4.配置Merchant ID
     
     5.为Merchant ID 配置证书, 并下载证书安装到钥匙串（这一步容易忘记）
     
     6.检查安装到钥匙串中的证书是否有效
     
     7.绑定Merchant ID 到 APP ID
     
     
     8.完成这一切然后 就开始写代码了
    
     */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //点击支付
        //1.检查是否支持apple pay
        if #available(iOS 10.0, *) {
            if PKPaymentAuthorizationController.canMakePayments() {
                //设备支持
                let payRequest = PKPaymentRequest.init()
                //商店的标识码
                payRequest.merchantIdentifier = "merchant.SHMP.ApplePayDemo"
                //支持的支付网络（PKPaymentNetworkChinaUnionPay iOS9.2开始支持）
                payRequest.supportedNetworks = [PKPaymentNetwork.visa,PKPaymentNetwork.chinaUnionPay]
                
                //通过指定merchantCapabilities属性来指定你支持的支付处理标准，3DS支付方式是必须支持的，EMV方式是可选的，
                payRequest.merchantCapabilities = [.capability3DS,.capabilityCredit, .capabilityDebit, .capabilityEMV]
                //国家代码
                payRequest.countryCode = "CN"
                //货币代码
                payRequest.currencyCode = "CNY"
                //默认为shipping
                payRequest.shippingType = .shipping
                
                //购物地址设置 
                payRequest.requiredShippingAddressFields = .all
                //需要的配送信息和账单信息
                payRequest.requiredBillingAddressFields = .all
                
                
                var shipping_methods = Array<PKShippingMethod>.init()
                
                let moneys = ["15:00", "20:00", "10:00"]
                let titles = ["顺丰", "EMS", "四通一达"]
                let descrps = ["隔日达", "五日达", "三日达"]
                
                for (index, value) in titles.enumerated() {
                    let method = PKShippingMethod.init()
                    method.label = value
                    method.amount = NSDecimalNumber.init(string: moneys[index])
                    method.identifier = value
                    method.detail = descrps[index]
                    shipping_methods.append(method)
                }
                myShippingMethods = shipping_methods
                //快递方式 ，用户可选
                payRequest.shippingMethods = shipping_methods
                
                var summaryItems = Array<PKPaymentSummaryItem>.init()
                //产品 item
                let item_product = PKPaymentSummaryItem.init(label: "iPhone X", amount: NSDecimalNumber.init(string: "8000.0"))
                summaryItems.append(item_product)
                //邮递 item
                if !shipping_methods.isEmpty {
                    summaryItems.append(PKPaymentSummaryItem.init(label: shipping_methods[0].label, amount: shipping_methods[0].amount))
                }
                
                //商家 item
                let item_merchent = PKPaymentSummaryItem.init(label: "Helloween", amount: NSDecimalNumber.zero)
                summaryItems.append(item_merchent)
                
                mySummaryItems = summaryItems
                item_merchent.amount = calculateMoney()
                
                payRequest.paymentSummaryItems = summaryItems
                
                //授权 控制器
                let paymentVC = PKPaymentAuthorizationViewController.init(paymentRequest: payRequest)
                paymentVC?.delegate = self
                self.present(paymentVC!, animated: true, completion: nil)
                
                
                
            } else {
                //设备不支持
                let alert = UIAlertController.init(title: "提醒", message: "当前设备不支持Apple pay", preferredStyle: .alert)
                let alert_action = UIAlertAction.init(title: "确定", style: .default, handler: nil)
                alert.addAction(alert_action)
                self.present(alert, animated: true, completion: nil)
            }
        } else {
            // Fallback on earlier versions
        }
        
    }
    //计算总价
    func calculateMoney() -> NSDecimalNumber {
        var total = NSDecimalNumber.zero
        //先把总价设置为0
        mySummaryItems.last?.amount = NSDecimalNumber.zero
        for (_,value) in mySummaryItems.enumerated() {
            total = total.adding(value.amount)
            print(value.amount)
        }
        return total
    }
    
    
    
    
    
    // MARK:  -----PKPaymentAuthorizationViewControllerDelegate 代理方法--必须要-
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        print("用户点击了取消授权按钮 AuthorizationViewController")
        controller.dismiss(animated: true, completion: nil)
    }

    //MARK: --授权成功后的操作---必须要-
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, completion: @escaping (PKPaymentAuthorizationStatus) -> Void) {

        
        completion(.success)
        //此处需要进行后续处理
        //需要集成银联SDK或其它官方支持的第三方SDK以及调用后台接口，并配合后台进行购物信息保留
        print(payment.token.paymentData,payment.shippingContact,payment.shippingMethod)

        let json = try? JSONSerialization.jsonObject(with: payment.token.paymentData, options: .allowFragments)
        
        print(payment.token.paymentData,"json=\(json)")
        
        
    }
    
    //MARK:   ------这些代理并不是一定需要处理---start--
    //将要授权的时候调用
    func paymentAuthorizationViewControllerWillAuthorizePayment(_ controller: PKPaymentAuthorizationViewController) {
        print("将要授权时调用")
    }

    
    /// 选择支付方式代理
    ///
    /// - Parameters:
    ///   - controller:
    ///   - paymentMethod: 支付方式信息
    ///   - completion: 完成回调
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didSelect paymentMethod: PKPaymentMethod, completion: @escaping ([PKPaymentSummaryItem]) -> Void) {
        var payType = String()
        switch paymentMethod.type {
        case .unknown:
            payType = "未知方式"
        case .credit:
            payType = "信用卡"
        case .debit:
            payType = "借记卡"
        case .prepaid:
            payType = "预付卡"
        case .store:
            payType = "Store方式"
        }
        
        print("当前网络:\(String(describing: paymentMethod.network)),支付方式:\(payType),支付卡号:\(String(describing: paymentMethod.displayName))")
        print(paymentMethod.paymentPass as Any)
        
        completion(mySummaryItems)
    }
    
    /// 配送方式
    ///
    /// - Parameters:
    ///   - controller:
    ///   - shippingMethod:
    ///   - completion: 完成
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didSelect shippingMethod: PKShippingMethod, completion: @escaping (PKPaymentAuthorizationStatus, [PKPaymentSummaryItem]) -> Void) {
        // 选择快递方式后需回调处理新的paymentSummaryItems数组
        mySummaryItems[1] = shippingMethod
        //重新计算总价
        mySummaryItems.last?.amount = calculateMoney()
        completion(.success, mySummaryItems)
    }
    
    /// 选择联系人信息，即送货地址
    ///
    /// - Parameters:
    ///   - controller:
    ///   - contact: 联系人
    ///   - completion: 完成回调
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didSelectShippingContact contact: PKContact, completion: @escaping (PKPaymentAuthorizationStatus, [PKShippingMethod], [PKPaymentSummaryItem]) -> Void) {
        print(contact.name?.namePrefix ?? "sd",contact.name?.givenName ?? "s",contact.name?.familyName ?? "sd","sss")
        completion(.success, myShippingMethods, mySummaryItems)
    }
    //MARK:   ------这些代理并不是一定需要处理---end--
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        // Dispose of any resources that can be recreated.
    }


}

