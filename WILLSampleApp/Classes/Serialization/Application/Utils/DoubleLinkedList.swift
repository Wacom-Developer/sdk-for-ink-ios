//
//  DoubleLinkedList.swift
//  WacomInk
//
//  Created by nikolay.atanasov on 28.02.20.
//  Copyright © 2020 nikolay.atanasov. All rights reserved.
//

open class DoublyLinkedList<T> {
    /// Basic node class for our linked list implementation
    class Node<T>  {
        var value: T
        fileprivate weak var previous: Node<T>?
        fileprivate var next: Node<T>?
        
        
        init(value: T) {
            self.value = value
        }
        
        var previousNode: Node<T>? {
            return previous
        }
        
        var nextNode: Node<T>? {
            return next
        }
        
        deinit {
            //print("^^^^^^^^ DEINIT NODE")
        }
    }
    //========================================================================================================
    // MARK: Private properties
    //========================================================================================================
    
    /// Head of the list
    private var head: Node<T>?
    
    /// Tail of the lsit
    private var tail: Node<T>?
    
    private var size: Int = 0
    
    deinit {
        print("^^^^^^^^ DEINIT DoublyLinkedList")
    }
    
    //========================================================================================================
    // MARK: Public properties
    //========================================================================================================
    
    /// Returns true if there are no entries in the list
    var isEmpty: Bool {
        return head == nil
    }
    
    /// Get the first entry in the list
    var first: Node<T>? {
        return head
    }
    
    /// Get the last entry in the list
    var last: Node<T>? {
        return tail
    }
    
    /// Get the number of entries in the linked list
    var count: Int {
        get {
            return size
        }
    }
    
    // Accesses the node at the specified position.
    ///
    /// - Parameter index: The position of the element to access
    subscript(_ index: Int) -> Node<T>? {
        get {
            return node(at: index)
        }
        
        set {
            if let newNode = newValue,
                let theNode = node(at: index) {
                _ = replace(node: theNode, with: [newNode])
            }
        }
    }
    
    /// Returns an array of all the values of the list of nodes
    ///
    ///
    func allValues() -> [T]? {
        guard head != nil else {
            return nil
        }
        
        var allItems = [T]()
        var curr = head
        
        while curr != nil {
            allItems.append(curr!.value)
            curr = curr?.next
        }
        
        return allItems
    }
    
    /// Returns an array of all the values  of the list of nodes in reverse order
    ///
    ///
    func allValuesReverse() -> [T]? {
        guard head != nil else {
            return nil
        }
        
        var allItems = [T]()
        var curr = tail
        
        while curr != nil {
            allItems.append(curr!.value)
            curr = curr?.previous
        }
        
        return allItems
    }
    
    
    /// Return the node at the given index
    ///
    /// - Parameter index: The index of the node to return
    /// - Returns: The node at the required index, or nil if there is no node at that index
    func node(at index: Int) -> Node<T>? {
        if index >= 0 {
            var node = head
            var i = index
            while node != nil {
                if i == 0 { return node }
                i -= 1
                node = node!.next
            }
        }
        return nil
    }
    
    /// Returns the first index of the specified node
    ///
    /// - Parameter node: A node to search for in the list.
    func firstIndex(of node: Node<T>) -> Int? {
        var count: Int = -1
        var current = head
        
        while let theCurrent = current {
            count += 1
            
            if theCurrent === node {
                break
            }
            current = current?.next
        }
        
        return count == -1 ? nil : count
    }
    
    // MARK: Adding Nodes
    
    /// Adds a new node at the end of the list
    ///
    /// - Parameter newNode: The node to append to the list.
    func append(node newNode: Node<T>) {
        if let tailNode = tail {
            newNode.previous = tailNode
            tailNode.next = newNode
        } else {
            head = newNode
        }
        
        tail = newNode
        
        size += 1
    }
    
    /// Adds a new node at the start of the list
    ///
    /// - Parameter newNode: The node to prepend to the list.
    func prepend(node newNode: Node<T>) {
        if let headNode = head {
            newNode.next = headNode
            headNode.previous = newNode
        } else {
            tail = newNode
        }
        
        head = newNode
        
        size += 1
    }
    
    /// Inserts a new node at the specified position.
    ///
    /// - Parameter newNode: The new node to insert into the list
    func insert(node newNode: Node<T>, at index: Int) {
        guard index >= 0 && index <= size else {
            print("Error, index out of bounds")
            return
        }
        
        if index == 0 {
            prepend(node: newNode)
        } else if index == size {
            append(node: newNode)
        } else if let prev = node(at: index - 1) {
            insert(node: newNode, after: prev)
        }
    }
    
    /// Inserts a new node after the specified node
    ///
    /// - Parameter node: The new node to insert into the list
    /// - Parameter prevNode: The given node is inserted at the position next to prevNode
    func insert(node: Node<T>, after prevNode: Node<T>) {
        if tail === prevNode {
            tail = node
        }
        
        let prev = prevNode
        let current = node
        let next = prevNode.next
        
        prev.next = current
        current.previous = prev
        current.next = next
        next?.previous = current
        
        if next == nil {
            tail = node
        }
        
        size += 1
    }
    
    /// Replaces the supplied node with the nodes in the specified collection
    ///
    /// - Parameter node: The node to to be replaced
    /// - Parameter nodes: The nodes to insert at the position of the given node
    func replace(node oldNode: Node<T>, with newNode: Node<T>) -> Node<T>? {
        insert(node: newNode, after: oldNode)
        let result = remove(node: oldNode)
        
        return result
    }
    
    
    /// Replaces the supplied node with the nodes in the specified collection
    ///
    /// - Parameter node: The node to to be replaced
    /// - Parameter nodes: The nodes to insert at the position of the given node
    func replace(node: Node<T>, with nodes: [Node<T>]) -> T {
        let result = node.value
        let nodesToAddCount = nodes.count
        
        if node === head {
            _ = removeFirst()
            
            let nodesReverse = nodes.reversed()
            
            for aNode in nodesReverse {
                prepend(node: aNode)
            }
        }
        else if node === tail {
            _ = removeLast()
            
            for aNode in nodes {
                append(node: aNode)
            }
        }
        else if nodesToAddCount == 0 {
            _ = remove(node: node)
        }
        else if var beforeCurrent = node.previous {
            _ = remove(node: node)
            
            var current: Node<T>
            for ii in 0..<nodesToAddCount {
                current = nodes[ii]
                insert(node: current, after: beforeCurrent)
                beforeCurrent = current
            }
        }
        
        return result
    }
    
    // MARK: Removing Nodes
    
    /// Removes and returns the first node of the list.
    ///
    ///
    func removeFirst() -> Node<T>? {
        let nodeToDelete = head
        
        let secondNode = nodeToDelete?.next
        
        secondNode?.previous = nil
        head = secondNode
        
        nodeToDelete?.previous = nil
        nodeToDelete?.next = nil
        
        size -= 1
        
        return nodeToDelete
    }
    
    /// Removes and returns the last node of the list.
    ///
    ///
    func removeLast() -> Node<T>? {
        let nodeToDelete = tail
        
        let beforeLast = nodeToDelete?.previous
        
        beforeLast?.next = nil
        tail = beforeLast
        
        nodeToDelete?.previous = nil
        nodeToDelete?.next = nil
        
        size -= 1
        
        return nodeToDelete
    }
    
    /// Removes all the nodes
    ///
    ///
    func removeAll() {
        head = nil
        tail = nil
        
        size = 0
    }
    
    
    /// Removes the supplied node from the list
    ///
    /// - Parameter node: The node to remove
    /// - Returns: The value for the node that has been removed
    func remove(node: Node<T>) -> Node<T> {
        let prev = node.previous
        let next = node.next
        
        if let prev = prev {
            prev.next = next
        } else {
            head = next
        }
        
        if let next = next {
            next.previous = prev
        }
        else {
            tail = prev
        }
        
        node.previous = nil
        node.next = nil
        
        size -= 1
        
        return node
    }
}

