//
//  ManagedObjectExtension.swift
//  MatchPoint
//
//  Created by Charles Prutting on 10/15/22.
//

import Foundation
import CoreData

extension NSManagedObject {
    //ManagedObject extension used to copy CoreData object from one context to another. Used in MatchBrain to copy match objects to the undoMatchArray.
    
    func copyEntireObjectGraph(context: NSManagedObjectContext) -> NSManagedObject {
        
        var cache = Dictionary<NSManagedObjectID, NSManagedObject>()
        return cloneObject(context: context, cache: &cache)
        
    }
    
    func cloneObject(context: NSManagedObjectContext, cache alreadyCopied: inout Dictionary<NSManagedObjectID, NSManagedObject>) -> NSManagedObject {
        
        guard let entityName = self.entity.name else {
            fatalError("source.entity.name == nil")
        }
        
        if let storedCopy = alreadyCopied[self.objectID] {
            return storedCopy
        }
        
        let cloned = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
        alreadyCopied[self.objectID] = cloned
        
        if let attributes = NSEntityDescription.entity(forEntityName: entityName, in: context)?.attributesByName {
            
            for key in attributes.keys {
                cloned.setValue(self.value(forKey: key), forKey: key)
            }
            
        }
        
        if let relationships = NSEntityDescription.entity(forEntityName: entityName, in: context)?.relationshipsByName {
            
            for (key, value) in relationships {
                
                if value.isToMany {
                    
                    if let sourceSet = self.value(forKey: key) as? NSMutableOrderedSet {
                        
                        guard let clonedSet = cloned.value(forKey: key) as? NSMutableOrderedSet else {
                            fatalError("Could not cast relationship \(key) to an NSMutableOrderedSet")
                        }
                        
                        let enumerator = sourceSet.objectEnumerator()
                        
                        var nextObject = enumerator.nextObject() as? NSManagedObject
                        
                        while let relatedObject = nextObject {
                            
                            let clonedRelatedObject = relatedObject.cloneObject(context: context, cache: &alreadyCopied)
                            clonedSet.add(clonedRelatedObject)
                            nextObject = enumerator.nextObject() as? NSManagedObject
                            
                        }
                        
                    } else if let sourceSet = self.value(forKey: key) as? NSMutableSet {
                        
                        guard let clonedSet = cloned.value(forKey: key) as? NSMutableSet else {
                            fatalError("Could not cast relationship \(key) to an NSMutableSet")
                        }
                        
                        let enumerator = sourceSet.objectEnumerator()
                        
                        var nextObject = enumerator.nextObject() as? NSManagedObject
                        
                        while let relatedObject = nextObject {
                            
                            let clonedRelatedObject = relatedObject.cloneObject(context: context, cache: &alreadyCopied)
                            clonedSet.add(clonedRelatedObject)
                            nextObject = enumerator.nextObject() as? NSManagedObject
                            
                        }
                        
                    }
                    
                } else {
                    
                    if let relatedObject = self.value(forKey: key) as? NSManagedObject {
                        
                        let clonedRelatedObject = relatedObject.cloneObject(context: context, cache: &alreadyCopied)
                        cloned.setValue(clonedRelatedObject, forKey: key)
                        
                    }
                    
                }
                
            }
            
        }
        
        return cloned
        
    }
    
}
