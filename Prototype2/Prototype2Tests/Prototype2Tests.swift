//
//  Prototype2Tests.swift
//  Prototype2Tests
//
//  Created by Richmond Yeboah on 28/01/2020.
//  Copyright © 2020 Richmond Yeboah. All rights reserved.
//

import XCTest
@testable import Prototype2

class Prototype2Tests: XCTestCase {
    var obj: ObjectDetectionViewController!

    override func setUp() {
        super.setUp()
        obj = ObjectDetectionViewController()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        obj = nil
        super.tearDown()
        
    }
    func testObjectLocation(){
        //Left 0...270
        //midle 270.01...540.01
        //right 540.02...812
        let y = 500.6328125
        let getLocation = obj.getObjectLocation(objectY: CGFloat(y))
        XCTAssertEqual(getLocation, "in front of you", "Score computed from guess is wrong")
    }
    func testObjectLocation2(){
        //Left 0...270
        //midle 270.01...540.01
        //right 540.02...812
        let y = 470.6328125
        let getLocation = obj.getObjectLocation(objectY: CGFloat(y))
        XCTAssertEqual(getLocation, "in front of you", "Wrong location")
    }
    func testObjectLocation3(){
           //Left 0...270
           //midle 270.01...540.01
           //right 540.02...812
           let y = 274.6328125
           let getLocation = obj.getObjectLocation(objectY: CGFloat(y))
           XCTAssertEqual(getLocation, "in front of you", "Wrong location")
       }
    func testObjectLocation4(){
        //Left 0...270
        //midle 270.01...540.01
        //right 540.02...812
        let y = 570.6328125
        let getLocation = obj.getObjectLocation(objectY: CGFloat(y))
        XCTAssertEqual(getLocation, "on your right side", "Wrong location")
    }
    func testObjectLocation5(){
           //Left 0...270
           //midle 270.01...540.01
           //right 540.02...812
           let y = 674.6328125
           let getLocation = obj.getObjectLocation(objectY: CGFloat(y))
           XCTAssertEqual(getLocation, "on your right side", "Wrong location")
       }
    func testObjectLocation6(){
        //Left 0...270
        //midle 270.01...540.01
        //right 540.02...812
        let y = 170.6328125
        let getLocation = obj.getObjectLocation(objectY: CGFloat(y))
        XCTAssertEqual(getLocation, "on your left side", "Wrong location")
    }
    func testObjectLocation7(){
           //Left 0...270
           //midle 270.01...540.01
           //right 540.02...812
           let y = 94.6328125
           let getLocation = obj.getObjectLocation(objectY: CGFloat(y))
           XCTAssertEqual(getLocation, "on your left side", "Wrong location")
       }
    func testObjectLocation8(){
           //Left 0...270
           //midle 270.01...540.01
           //right 540.02...812
           let y = -94.6328125
           let getLocation = obj.getObjectLocation(objectY: CGFloat(y))
           XCTAssertEqual(getLocation, "nil", "Wrong location")
       }
    func testObjectLocation9(){
              //Left 0...270
              //midle 270.01...540.01
              //right 540.02...812
              let y = 43265.6328125
              let getLocation = obj.getObjectLocation(objectY: CGFloat(y))
              XCTAssertEqual(getLocation, "nil", "Wrong location")
          }
    func testGetObj(){
        //Left 0...270
        //midle 270.01...540.01
        //right 540.02...812
        var objects:[[String:Int]]!
        objects  = [
            ["car":70],
            [ "dog" :(80)],
            [ "Traffic Light":(96)],
        ]
        let result = obj.getObjectTest(objects:objects)
        XCTAssertEqual(result, "Traffic Light", "wrong object")
    }
    func testGetObj2(){
        //Left 0...270
        //midle 270.01...540.01
        //right 540.02...812
        var objects:[[String:Int]]!
        objects  = [
            ["car":70],
            [ "dog" :(80)],
            [ "car":(96)],
        ]
        let result = obj.getObjectTest(objects:objects)
        XCTAssertEqual(result, "car", "wrong object")
    }
    func testGetObj3(){
        //Left 0...270
        //midle 270.01...540.01
        //right 540.02...812
        var objects:[[String:Int]]!
        objects  = [["car":70],
                    [ "dog" :(80)],
                    [ "person":(96)],]
        let result = obj.getObjectTest(objects:objects)
        XCTAssertEqual(result, "person", "wrong object")
    }
    func testGetObj4(){
        //Left 0...270
        //midle 270.01...540.01
        //right 540.02...812
        var objects:[[String:Int]]!
        objects  = [
            ["car":70],
            [ "dog" :(80)],
            [ "car":(23)],
        ]
        let result = obj.getObjectTest(objects:objects)
        XCTAssertEqual(result, "nil", "wrong object")
    }
    
    func testGetObj5(){
        //Left 0...270
        //midle 270.01...540.01
        //right 540.02...812
        var objects:[[String:Int]]!
        objects  = [
            ["tree":70],
            [ "dog" :(80)],
            [ "tree":(96)],
        ]
        let result = obj.getObjectTest(objects:objects)
        XCTAssertEqual(result, "tree", "wrong object")
    }
    func testGetObj6(){
           //Left 0...270
           //midle 270.01...540.01 Test name     Test reference    Test input     Test expected output    Test verdict
           //right 540.02...812
           var objects:[[String:Int]]!
           objects  = [
               ["car":70],
               [ "bike" :(80)],
               [ "bike":(80)],
           ]
           let result = obj.getObjectTest(objects:objects)
           XCTAssertEqual(result, "bike", "wrong object")
       }
    func testGetObj7(){
        //Left 0...270
        //midle 270.01...540.01
        //right 540.02...812
        var objects:[[String:Int]]!
        objects  = [
            ["car":40],
            [ "bike" :(0)],
            [ "bike":(80)],
        ]
        let result = obj.getObjectTest(objects:objects)
        XCTAssertEqual(result, "nil", "wrong object")
    }
    func testGetObj8(){
        //Left 0...270
        //midle 270.01...540.01
        //right 540.02...812
        var objects:[[String:Int]]!
        objects  = [
            ["car":70],
            [ "person" :(20)],
            [ "car":(70)],
        ]
        let result = obj.getObjectTest(objects:objects)
        XCTAssertEqual(result, "nil", "wrong object")
    }
    
    
}
