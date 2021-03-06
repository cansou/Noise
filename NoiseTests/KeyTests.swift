//
//  KeyTests.swift
//  Noise
//
// Created by Paulo Andrade on 12/09/2018.
// Copyright © 2018 Outer Corner. All rights reserved.
//

import XCTest
import Noise

class KeyTests: XCTestCase {

    func testPublicKeyGenerator() {
        func testGeneratingKeys(for keyAlgo: NoiseKeyAlgo, length: Int) {
            guard let key = NoiseKeyGenerator.shared.generateKeyPair(keyAlgo) else {
                XCTFail("Failed to generate \(keyAlgo) key pair")
                return
            }
            
            XCTAssertEqual(key.publicKey.keyRole, NoiseKeyRole.public)
            XCTAssertEqual(key.publicKey.keyAlgo, keyAlgo)
            XCTAssertEqual(key.privateKey.keyRole, NoiseKeyRole.private)
            XCTAssertEqual(key.privateKey.keyAlgo, keyAlgo)
            
            XCTAssertEqual(key.privateKey.keyMaterial.count, length)
            XCTAssertEqual(key.publicKey.keyMaterial.count, length)
        }
        
        testGeneratingKeys(for: .curve25519, length: 32)
        testGeneratingKeys(for: .curve448, length: 56)
    }
    
    func testSymmetricKeyGenerator() {
        
        let key = NoiseKeyGenerator.shared.generateSymmetricKey(32)
        
        XCTAssertNotNil(key)
        XCTAssertEqual(key.keyMaterial.count, 32)
        XCTAssertEqual(key.keyRole, .symmetric)
        XCTAssertNil(key.keyAlgo)
    }

    func testKeySerialization() throws {
        guard let key = NoiseKeyGenerator.shared.generateKeyPair(.curve448) else {
            XCTFail("Failed to generate \(NoiseKeyAlgo.curve448) key pair")
            return
        }
        
        let data = try NSKeyedArchiver.archivedData(withRootObject: key, requiringSecureCoding: true)
        
        let rKey = try NSKeyedUnarchiver.unarchivedObject(ofClass: NoiseKeyPair.self, from: data)
        XCTAssertNotNil(rKey)
        
        XCTAssertEqual(key.publicKey.keyRole, rKey?.publicKey.keyRole)
        XCTAssertEqual(key.publicKey.keyAlgo, rKey?.publicKey.keyAlgo)
        XCTAssertEqual(key.privateKey.keyRole, rKey?.privateKey.keyRole)
        XCTAssertEqual(key.privateKey.keyAlgo, rKey?.privateKey.keyAlgo)
        
    }
}
