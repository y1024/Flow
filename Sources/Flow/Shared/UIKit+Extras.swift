//
//	Flow
//	A declarative approach to UICollectionView & UITableView management
//	--------------------------------------------------------------------
//	Created by:	Daniele Margutti
//				hello@danielemargutti.com
//				http://www.danielemargutti.com
//
//	Twitter:	@danielemargutti
//
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//	THE SOFTWARE.

import Foundation
import UIKit

internal struct SectionChanges {
	
	public private(set) var inserts = IndexSet()
	public private(set) var deletes = IndexSet()
	public private(set) var replaces = IndexSet()
	public private(set) var moves: [(from: Int, to: Int)] = []
	
	internal init() { }
	
	public var hasChanges: Bool {
		return (self.inserts.count > 0 || self.deletes.count > 0 || self.replaces.count > 0 || self.moves.count > 0)
	}
	
	public static func create(oldSections old: [CollectionSection], newSections new: [CollectionSection]) -> SectionChanges {
		let changes = diff(old: old, new: new)
		var data = SectionChanges()
		changes.forEach {
			switch $0 {
			case .delete(let v):
				data.deletes.insert(v.index)
			case .insert(let v):
				data.inserts.insert(v.index)
			case .move(let v):
				data.moves.append( (from: v.fromIndex, to: v.toIndex) )
			case .replace(let v):
				data.replaces.insert(v.index)
			}
		}
		return data
	}

	public func applyChangesIfNeeded(collection: UICollectionView?) {
		guard let c = collection, self.hasChanges else { return }
		c.deleteSections(self.deletes)
		c.insertSections(self.inserts)
		self.moves.forEach {
			c.moveSection($0.from, toSection: $0.to)
		}
		c.reloadSections(self.replaces)
	}
	
}


internal struct SectionItemsChanges {
	
	public let inserts: [IndexPath]
	public let deletes: [IndexPath]
	public let replaces: [IndexPath]
	public let moves: [(from: IndexPath, to: IndexPath)]
	
	public init(
		inserts: [IndexPath],
		deletes: [IndexPath],
		replaces:[IndexPath],
		moves: [(from: IndexPath, to: IndexPath)]) {
		
		self.inserts = inserts
		self.deletes = deletes
		self.replaces = replaces
		self.moves = moves
	}
	
	
	public static func create<T>(fromChanges changes: [Change<T>], section: Int) -> SectionItemsChanges {
		let inserts = changes.compactMap({ $0.insert }).map({ $0.index.toIndexPath(section: section) })
		let deletes = changes.compactMap({ $0.delete }).map({ $0.index.toIndexPath(section: section) })
		let replaces = changes.compactMap({ $0.replace }).map({ $0.index.toIndexPath(section: section) })
		let moves = changes.compactMap({ $0.move }).map({
			(
				from: $0.fromIndex.toIndexPath(section: section),
				to: $0.toIndex.toIndexPath(section: section)
			)
		})
		
		return SectionItemsChanges(
			inserts: inserts,
			deletes: deletes,
			replaces: replaces,
			moves: moves
		)
	}
	
	public func applyChangesToSectionItems(of collection: UICollectionView?) {
		guard let c = collection else { return }
		
		c.deleteItems(at: self.deletes)
		c.insertItems(at: self.inserts)
		self.moves.forEach {
			c.moveItem(at: $0.from, to: $0.to)
		}
		c.reloadItems(at: self.replaces)
	}
}

internal extension Int {
	
	fileprivate func toIndexPath(section: Int) -> IndexPath {
		return IndexPath(item: self, section: section)
	}
	
}