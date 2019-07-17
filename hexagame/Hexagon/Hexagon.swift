//
//  Hexagon.swift
//  hexagame
//
//  Created by Nathan on 7/7/19.
//  Copyright © 2019 Nathan. All rights reserved.
//
import SpriteKit


class Hexagon: SKSpriteNode {
    
    static let hexagonSize = CGSize(width: 120, height: 104) // size with border
    static let innerSize = CGSize(width: 90 - sqrt(12), height: 100) // size without the border
    // settable values
    var isMovable = true
    var gridIndex: HexagonIndex
    
    var isDragging = false
    
    var north: HexagonSide = HexagonSide(direction: .north)
    var northEast: HexagonSide = HexagonSide(direction: .northEast)
    var southEast: HexagonSide = HexagonSide(direction: .southEast)
    var south: HexagonSide = HexagonSide(direction: .south)
    var southWest: HexagonSide = HexagonSide(direction: .southWest)
    var northWest: HexagonSide = HexagonSide(direction: .northWest)
    
    func getSide(direction: HexagonDirection) -> HexagonSide {
        switch (direction) {
        case .north:
            return north
        case .northEast:
            return northEast
        case .southEast:
            return southEast
        case .south:
            return south
        case .southWest:
            return southWest
        case .northWest:
            return northWest
        }
    }
    
    // computed values
    var sides: [HexagonSide] {
        get {
            return [north, northEast, southEast, south, southWest, northWest]
        }
    }
    
    var gridPosition: CGPoint {
        get {
            var x = (2 * CGFloat(gridIndex.col) * Hexagon.innerSize.width) + (0.5 * Hexagon.hexagonSize.width)
            if gridIndex.row % 2 == 1 {
                x += Hexagon.innerSize.width
            }

            let y = (0.5 * CGFloat(gridIndex.row) * Hexagon.innerSize.height) + (0.5 * Hexagon.hexagonSize.height)

            return CGPoint(x: x, y:y)
        }
    }
    
    
    var totalColors: Int {
        get {
            return self.sides.reduce(0, {total, side in total + (side.isConnectable ? 1 : 0)} )
        }
    }
    var totalConnectedColors: Int {
        get {
            return self.sides.reduce(0, {total, side in total + (side.isConnected ? 1 : 0)} )
        }
    }
    var isFullyConnected: Bool {
        get {
            return totalColors == totalConnectedColors
        }
    }
    
    init(isMovable: Bool, gridIndex: HexagonIndex) {
        self.isMovable = isMovable
        self.gridIndex = gridIndex
        super.init(texture: SKTexture(imageNamed: "hexagonBase"), color: UIColor.clear, size: Hexagon.hexagonSize)
        self.position = gridPosition
        
        for side in self.sides {
            side.bind(hexagon: self)
        }
        
        self.zPosition = isMovable ? 0 : 1
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func switchColors(hexagon: Hexagon, redraw: Bool = true) {
        if !isMovable || !hexagon.isMovable {
            return
        }
        
        for (sideA, sideB) in zip(sides, hexagon.sides) {
            swap(&sideA.connectionColor, &sideB.connectionColor)
        }
        if redraw {
            self.draw(recurse: true)
            hexagon.draw(recurse: true)
        }
    }
    
    func resetGridPosition() {
        self.position = gridPosition
    }
    
    func isTouching(location: CGPoint) -> Bool {
        return location.x * location.x + location.y * location.y < (Hexagon.innerSize.height/2) * (Hexagon.innerSize.height/2)
    }
    
    func draw(recurse: Bool, lazy: Bool = false) {
        self.texture = SKTexture(cgImage: HexagonDrawer.draw(hexagon: self))
        if recurse {
            for side in self.sides {
                if !lazy || side.isConnected {
                    side.neighbor?.draw(recurse: false)
                }
            }
        }
    }
    
    func startDragging() {
        isDragging = true
        zPosition = 100
        //draw(recurse: true, lazy: true)
    }
    func stopDragging() {
        isDragging = false
        zPosition = 0
       draw(recurse: true, lazy: true)
    }
}
