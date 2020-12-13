//
//  ViewController.swift
//  Stocks
//
//  Created by Oleg Koptev on 13.12.2020.
//
import Foundation
import Network
import UIKit
import SwiftyJSON

class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    var connected: Bool = false
    let monitor = NWPathMonitor()
    
    @IBOutlet weak var companyNameLabel: UILabel!
    @IBOutlet weak var companySymbolLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var priceChangeLabel: UILabel!
    @IBOutlet weak var companyPickerView: UIPickerView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - private properties
    
    private let companies: [[String]] = [["Apple", "AAPL"],
                                               ["Microsoft", "MSFT"],
                                               ["Google", "GOOG"],
                                               ["Amazon", "AMZN"],
                                               ["Facebook", "FB"]]
    
    // MARK: - Private methods
    
    private func requestQuote(for symbol: String) {
        let headers = [
            "x-rapidapi-key": "cc681d1322msh1c666ac12b77acfp16f811jsn62de3a99ff86",
            "x-rapidapi-host": "apidojo-yahoo-finance-v1.p.rapidapi.com"
        ]

        let request = NSMutableURLRequest(url: NSURL(string: "https://apidojo-yahoo-finance-v1.p.rapidapi.com/stock/v2/get-statistics?symbol=\(symbol)&region=US")! as URL,
                                                cachePolicy: .useProtocolCachePolicy,
                                            timeoutInterval: 10.0)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers

        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            guard
                error == nil,
                (response as? HTTPURLResponse)?.statusCode == 200,
                let data = data
            else {
                print("Network error!")
                return
            }
            self.parseQuote(data: data)
        })

        dataTask.resume()
    }
    
    private func resetLabels() {
        self.companyNameLabel.text = "-"
        self.companySymbolLabel.text = "-"
        self.priceLabel.text = "-"
        self.priceChangeLabel.textColor = .none
        self.priceChangeLabel.text = "-"
    }
    
    private func requestQuoteUpdate() {
        self.activityIndicator.startAnimating()
        self.resetLabels()
        let selectedRow = self.companyPickerView.selectedRow(inComponent: 0)
        let selectedSymbol = self.companies[selectedRow][1]
        self.requestQuote(for: selectedSymbol)
    }
    
    private func parseQuote(data: Data) {
        do {
            let jsonObject = try JSON(data: data)
            let companyName = jsonObject["price"]["shortName"].stringValue
            let companySymbol = jsonObject["price"]["symbol"].stringValue
            let price = jsonObject["price"]["regularMarketPrice"]["fmt"].stringValue
            let priceChange = jsonObject["price"]["regularMarketChange"]["fmt"].stringValue
            let priceSymbol = jsonObject["price"]["currencySymbol"].stringValue
            
            DispatchQueue.main.async {
                self.displayStockInfo(companyName: companyName,
                                      symbol: companySymbol,
                                      price: price,
                                      priceChange: priceChange,
                                      priceSymbol: priceSymbol)
            }
            
        } catch {
            print("Invalid JSON formatting")
        }
    }
    
    private func displayStockInfo(companyName: String, symbol: String, price: String, priceChange: String, priceSymbol: String) {
        self.activityIndicator.stopAnimating()
        self.companyNameLabel.text = companyName
        self.companySymbolLabel.text = symbol
        self.priceLabel.text = "\(price)\(priceSymbol)"
        let parsedChange = Double(priceChange)!
        if (parsedChange > 0) {
            self.priceChangeLabel.textColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
            self.priceChangeLabel.text = "+\(priceChange)\(priceSymbol)"
        } else {
            self.priceChangeLabel.text = "\(priceChange)\(priceSymbol)"
            if (parsedChange < 0) {
                self.priceChangeLabel.textColor = #colorLiteral(red: 0.8549019694, green: 0.250980407, blue: 0.4784313738, alpha: 1)
            } else {
                self.priceChangeLabel.textColor = .none
            }
        }
    }
    
    private func checkConnection() {
        let queue = DispatchQueue(label: "Monitor")
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    self.connected = true
                    self.requestQuoteUpdate()
                } else {
                    self.connected = false
                    self.resetLabels()
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.companyPickerView.dataSource = self
        self.companyPickerView.delegate = self
        
        self.activityIndicator.hidesWhenStopped = true
        checkConnection()
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1;
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.companies.count;
    }
    
    // MARK: - UIPickerViewDelegate
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.companies[row][0]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if (connected) {
            self.requestQuoteUpdate()
        }
    }

}

