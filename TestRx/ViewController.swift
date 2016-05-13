//
//  ViewController.swift
//  TestRx
//
//  Created by Douglas Sjoquist on 5/13/16.
//  Copyright © 2016 Ivy Gulch LLC. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

struct Item {
    let name: String
}

struct Page {
    let name: String
    let items: [Item]

    init(name: String, count: Int) {
        self.name = name
        var items: [Item] = []
        for index in 0..<count {
            items.append(Item(name: "\(name)_item_\(index)"))
        }
        self.items = items
    }

}

class ViewController: UIViewController {

    let pageCache = Variable<[Observable<Page>]>([])
    let disposeBag = DisposeBag()

    func myFrom<E>(sequence: [E]) -> Observable<E> {
//        print("myFrom: \(sequence)")
        return Observable.create { observer in
            for element in sequence {
                observer.on(.Next(element))
            }

            observer.on(.Completed)
            return NopDisposable.instance
        }.shareReplay(1)
    }

    func itemsFromPages(pages: [Page]) -> Observable<Item> {
        return Observable.create { observer in
            for page in pages {
                for item in page.items {
                    observer.on(.Next(item))
                }
            }

            observer.on(.Completed)
            return NopDisposable.instance
        }.shareReplay(1)
    }
    
    func itemsFromPage(page: Observable<Page>) -> Observable<[Item]> {
//        print("itemsFromPage: \(page)")
        return page.map {
            page -> [Item] in
//            print("itemsFromPage.b: \(page), items=\(page.items)")
            return page.items
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let o = pageCache.asObservable()

        o
            .flatMap(myFrom)
            .flatMap(itemsFromPage)
            .flatMap(myFrom)
            .subscribe(
            onNext: {
                value in
                print("value=\(value)")
        })
            .addDisposableTo(disposeBag)

        doStep(1, max:2, delay:1.0)
    }

    func doStep(count: Int, max: Int, delay: NSTimeInterval) {
        let page = Variable<Page>(Page(name: "Page_\(count)", count: 3))
        var pages = pageCache.value
        pages.append(page.asObservable().shareReplay(1))
        print("publish new pages: \(pages.count)")
        pageCache.value = pages

        if count < max {
            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
            dispatch_after(delayTime, dispatch_get_main_queue()) {
                self.doStep(count+1, max: max, delay: delay)
            }
        }
    }



}

