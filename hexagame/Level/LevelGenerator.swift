//
//  LevelGenerator.swift
//  hexagame
//
//  Created by Nathan on 7/7/19.
//  Copyright © 2019 Nathan. All rights reserved.
//
import GameplayKit


/// Creates a level
class LevelGenerator {
    
    /// seeded rng to make deterministic decisions
    static var rng = GKLinearCongruentialRandomSource.init(seed: 0)
    
    
    /// Create a level
    ///
    /// - Parameters:
    ///   - seed: what seed to use for rng
    ///   - dificulty: what dificulty to use
    /// - Returns: Hexagon Level
    static func create(seed: UInt64, dificulty: Int) -> HexagonLevel {
        self.rng = GKLinearCongruentialRandomSource.init(seed: seed)
        
        let meta = LevelConstants.metas[dificulty]
        let description = LevelDescription(rng: self.rng, meta: meta)
        
        // generates the grid
        let level = generateLevelHexagons(description: description)
        
        populateGridWithConnections(level: level, description: description)
        scrambleLevel(level: level)
        
        for hexagon in level.hexagons.values {
            hexagon.draw(recurse: false)
        }
        return level
    }
    
    
    /// Creates a level of hexagons based off parameters with no connections.
    ///
    /// - Parameter description: parameters used to create level
    /// - Returns: simple conection-less hexagon level
    static func generateLevelHexagons(description: LevelDescription) -> HexagonLevel {
        var hexagons = [HexagonIndex: Hexagon]()
        
        var availableHexagonIndecies: [HexagonIndex] = []
        
        // place the starting hexagons at random positions
        for _ in 0..<description.startHexagons {
            availableHexagonIndecies.append(HexagonIndex(row: rng.nextInt(upperBound: description.size.height), col: rng.nextInt(upperBound: description.size.width)))
        }
        
        // iterate until all levels hexagons are created
        while hexagons.count < description.totalHexagons {
            let newHexagonIndex = availableHexagonIndecies.remove(at: self.rng.nextInt(upperBound: availableHexagonIndecies.count))
            
            // invalid index
            if newHexagonIndex.col > description.size.width || newHexagonIndex.row > description.size.height || newHexagonIndex.row < 0 || newHexagonIndex.col < 0 {
                continue
            }
            // already exists
            if (hexagons.keys.contains(newHexagonIndex)) {
                continue
            }
            
            // add element
            let newHexagon = Hexagon(isMovable: self.rng.nextInt(upperBound: 20) < 17, gridIndex: newHexagonIndex)
            hexagons[newHexagonIndex] = newHexagon
            
            // add neighbors to search space if not already added
            for direction in HexagonDirection.allCases {
                let newNeighbor = newHexagon.gridIndex.getNeighborIndex(direction: direction)
                if !availableHexagonIndecies.contains(newNeighbor) {
                    availableHexagonIndecies.append(newNeighbor)
                }
            }
            
        }
        
        // get the extrema positions of the board
        var minTop = Int.max, maxTop = Int.min, minLeft = Int.max, maxLeft = Int.min
        
        for hexagonIndex in hexagons.keys {
            minTop = min(hexagonIndex.row, minTop)
            maxTop = max(hexagonIndex.row, maxTop)
            minLeft = min(hexagonIndex.col, minLeft)
            maxLeft = max(hexagonIndex.col, maxLeft)
        }
        
        // use extrema to zero position the board
        var simplifiedHexagons = [HexagonIndex: Hexagon]()
        for (hexagonIndex, hexagon) in hexagons {
            let newIndex = HexagonIndex(row: hexagonIndex.row - minTop, col: hexagonIndex.col - minLeft)
            hexagon.gridIndex = newIndex
            hexagon.resetGridPosition()
            simplifiedHexagons[newIndex] = hexagon
        }
        
        // bind neighbors together
        for hexagon in simplifiedHexagons.values {
            hexagon.sides.forEach({side in
                side.bindNeighbors(parentHexagon: hexagon, otherHexagon: simplifiedHexagons[hexagon.gridIndex.getNeighborIndex(direction: side.direction)])
            })
        }
        // create the hexagon level
        return HexagonLevel(hexagons: simplifiedHexagons, gridSize: (cols: maxLeft - minLeft + 1, rows: maxTop - minTop + 1))
    }
    
    
    /// Given an empty connection level and description, populate level with connections
    ///
    /// - Parameters:
    ///   - level: level to populate connections
    ///   - description: level description indicating how much to populate
    static func populateGridWithConnections(level: HexagonLevel, description: LevelDescription) {
        var colorConnectionsCreated = 0
        let keys = level.hexagons.keys.sorted()
        while colorConnectionsCreated < description.connections {
            guard let hexagon = level.getHexagon(index: keys[self.rng.nextInt(upperBound: keys.count)]) else {
                continue
            }
            let direction = HexagonDirection(rawValue: self.rng.nextInt(upperBound: 6)) ?? HexagonDirection.north
            if hexagon.getSide(direction: direction).createConnection(connectionColor: HexagonSideColor(rawValue: self.rng.nextInt(upperBound: description.colors) + 1) ?? HexagonSideColor.blue) {
                colorConnectionsCreated += 1
            }
            
        }
    }
    
    /// Scramble the hexagons in the map w/o using the seeded rng
    ///
    /// - Parameter level: level to scramble
    static func scrambleLevel(level: HexagonLevel) {
        // get hexagons in order of index
        for hexagon in level.hexagons.values.sorted(by: {(hexagon1, hexagon2) in hexagon1.gridIndex < hexagon2.gridIndex}) {
            // only if it can be moved
            if !hexagon.isMovable {
                continue
            }
            if let (newHexagonIndex, newHexagon) = level.hexagons.randomElement() {
                // skip if switching the same hexagon index
                if newHexagonIndex == hexagon.gridIndex {
                    continue
                }
                // new hexagon must also be switchable
                if !newHexagon.isMovable {
                    continue
                }
                // switch the colors of the sides
                hexagon.switchColors(hexagon: newHexagon, redraw: false)
            }
        }
    }
}
