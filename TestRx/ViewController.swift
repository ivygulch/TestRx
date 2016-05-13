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

    func fromArray<E>(sequence: [E]) -> Observable<E> {
        return Observable.create { observer in
            for element in sequence {
                observer.on(.Next(element))
            }

            observer.on(.Completed)
            return NopDisposable.instance
        }.shareReplay(1)
    }

    func itemsFromPage(page: Observable<Page>) -> Observable<[Item]> {
        return page.map {
            page -> [Item] in
            return page.items
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let o = pageCache.asObservable()

        o
            .flatMap(fromArray)
            .flatMap(itemsFromPage)
            .flatMap(fromArray)

// this produces output I want, but is too wonky to use
//            .scan([]) {
//                lastSlice, newValue in
//                return Array(lastSlice + [newValue])
//            }
//            .debounce(0.5, scheduler: ConcurrentMainScheduler.instance)

// the internal print shows it doing what I want, but no result comes out the end
            .reduce([Item]()) {
                lastSlice, newValue in

                var result = lastSlice as [Item]
                result.append(newValue)

                print("reducing: lastSlice=\(lastSlice.count), newValue=\(newValue)")
                return result
            }

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
        pages.append(page.asObservable())
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

