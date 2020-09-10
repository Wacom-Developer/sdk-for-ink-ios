//
//  HashableArray.swift
//  WacomInk
//
//  Created by nikolay.atanasov on 28.02.20.
//  Copyright © 2020 nikolay.atanasov. All rights reserved.
//

import Foundation

typealias HashableArrayElement<T, S> = (key: T, value: S) where T: Hashable

class HashableArray<S, T> where S: Hashable {
    
    private var linkedList: DoublyLinkedList = DoublyLinkedList<T>()
    private var dict: [S: DoublyLinkedList<T>.Node<T>] = [:]
    
    /// Returns whether there are no elements in the collection
    ///
    var isEmpty: Bool {
        get {
            linkedList.isEmpty
        }
    }
    
    var doubleLinkedList: DoublyLinkedList<T> {
        return linkedList
    }
    
    var dictionary: [S: DoublyLinkedList<T>.Node<T>] {
        return dict
    }
    
    var values: [T]? {
        return linkedList.allValues()
    }
    
    /// The number of elements
    ///
    public var count: Int {
        get  {
            return linkedList.count
        }
    }
    
    /// Accesses the value associated with the given key for reading and writing.
    ///
    subscript(key: S) -> T? {
        get{
            return value(key: key)
        }
        
        set{
            if let theNewValue = newValue {
                _ = updateValue(theNewValue, key: key)
            }
        }
    }
    
    
    /// Returns the value for the specified key
    ///
    func value(key: S) -> T? {
        return dict[key]?.value
    }
    
    /// Returns the value of the element preceding the element with the specified key
    ///
    func previousValue(key: S) -> T? {
        var result: T?
        
        if let node = dict[key],
            let prevNode = node.previousNode {
            result = prevNode.value
        }
        
        return result
    }
    
    /// Returns the value of the element succeeding the element with the specified key
    ///
    func nextValue(key: S) -> T? {
        var result: T?
        
        if let node = dict[key],
            let nextNode = node.nextNode {
            result = nextNode.value
        }
        
        return result
    }
    
    /// Returns the value of the element at the specified position
    ///
    /// - Parameter index: The index of the value to return
    /// - Returns: The value at the required index, or nil if there is no node at that index
    func value(at index: Int) -> T? {
        return linkedList.node(at: index)?.value
    }
    
    /// Adds a new element at the end of the collection.
    /// Removes the old value for the specified key
    /// Updates the hash table
    ///
    /// - Parameter key: The key of the element to append
    /// - Parameter value: The value of the element to append
    func append(key: S, value: T) {
        
        if let oldNode = dict[key] {
            _ = linkedList.remove(node: oldNode)
        }
        
        let node = DoublyLinkedList<T>.Node<T>(value: value)
        dict[key] = node
        
        linkedList.append(node: node)
    }
    
    /// Adds a new element at the start of the collection.
    /// Removes the old value for the specified key
    /// Updates the hash table
    ///
    /// - Parameter key: The key of the element to prepend
    /// - Parameter value: The value of the element to prepend
    func prepend(key: S, value: T) {
        if let oldNode = dict[key] {
            _ = linkedList.remove(node: oldNode)
        }
        
        let node = DoublyLinkedList<T>.Node<T>(value: value)
        dict[key] = node
        linkedList.prepend(node: node)
    }
    
    /// Inserts a new element at the start of the collection.
    /// Removes the old value for the specified key
    ///
    /// - Parameter key: The key of the element to prepend
    /// - Parameter value: The value of the element to prepend
    /// - Parameter index: The position of the element
    func insert(key: S, value: T, at index: Int) {
        guard index >= 0 && index <= linkedList.count else {
            print("Error, index out of bounds")
            return
        }
        
        if let oldNode = dict[key] {
            _ = linkedList.remove(node: oldNode)
        }
        
        let node = DoublyLinkedList<T>.Node<T>(value: value)
        dict[key] = node
        linkedList.insert(node: node, at: index)
    }
    
    /// Inserts a new element after the element with the given key.
    /// Removes the old value for the inserted element
    ///
    /// - Parameter key: The key of the element to insert
    /// - Parameter value: The value of the element to insert
    /// - Parameter prevKey: The key of the element that precedes the inserted element
    func insert(key: S, value: T, after prevKey: S) {
        if let prevNode = dict[prevKey] {
            _ = insert(key: key, value: value, after: prevNode)
        }
    }
    
    /// Updates the value of the element associated the given key or adds a element if the key does not exist.
    ///
    /// - Parameter element: The element to place at the position of the element with the given key
    /// - Parameter key: The key of the element to update
    func updateValue(_ value: T, key: S) -> T {
        let newNode = DoublyLinkedList<T>.Node<T>(value: value)
        
        if let oldNode = dict[key] {
            _ = linkedList.replace(node: oldNode, with: newNode)
            dict[key] = newNode
        }
        else {
            append(key: key, value: value)
        }
        
        return value
    }
    
    /// Replaces the value associated the given key  with the specified elements
    ///
    /// - Parameter key: The key of the element to replace
    /// - Parameter elements: The elements to place at the position of the element with the given key
    /// - Returns: The value of the replaced element
    func replace(key: S, with elements: [HashableArrayElement<S, T>]) -> T? {
        let elementsToAddCount = elements.count
        
        guard elementsToAddCount > 0 else {
            return remove(key: key)
        }
        
        let nodeToReplace = dict[key]
        
        guard nodeToReplace != nil else {
            return nil
        }
        
        var result: T?
        
        if var currentNode = nodeToReplace {
            var shouldRemove = true
            
            var currentKey = key
            var nextKey: S
            var nextNode: DoublyLinkedList<T>.Node<T>
            
            for anElem in elements {
                nextKey = anElem.key
                
                if key == nextKey {
                    shouldRemove = false
                }
                
                if currentKey != nextKey {
                    nextNode = insert(key: nextKey, value: anElem.value, after: currentNode)
                } else {
                    nextNode = DoublyLinkedList<T>.Node<T>(value: anElem.value)
                    _ = linkedList.replace(node: currentNode, with: nextNode)
                    dict[nextKey] = nextNode
                }
                
                // loop here
                currentKey = nextKey
                currentNode = nextNode
            }
            
            if shouldRemove {
                result = remove(key: key)
            }
        }
        
        return result
    }
    
    /// Removes the given key and its associated value from the collection
    ///
    /// - Returns: The value of the removed element
    func remove(key: S) -> T? {
        var result: T?
        
        if let node = dict[key] {
            result = node.value
            _ = linkedList.remove(node: node)
            dict.removeValue(forKey: key)
        }
        
        return result
    }
    
    /// Removes all elements  from the collection
    ///.
    func removeAll() {
        dict.removeAll()
        linkedList.removeAll()
    }
    
    private func insert(key: S, value: T, after prevNode: DoublyLinkedList<T>.Node<T>) -> DoublyLinkedList<T>.Node<T> {
        _ = remove(key: key)
        
        let node = DoublyLinkedList<T>.Node<T>(value: value)
        dict[key] = node
        linkedList.insert(node: node, after: prevNode)
        
        return node
    }
}
