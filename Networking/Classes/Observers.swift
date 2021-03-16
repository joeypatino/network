/// A helper object for Observerable instances. Stores weak references to observing objects.
public class Observers<ObserverType> {
    public enum Priority {
        case low
        case medium
        case high
    }
    private var allObserversLow = NSHashTable<AnyObject>.weakObjects()
    private var allObserversMed = NSHashTable<AnyObject>.weakObjects()
    private var allObserversHigh = NSHashTable<AnyObject>.weakObjects()
    private var observers:[ObserverType] {
        let high = allObserversHigh.allObjects.compactMap { $0 as? ObserverType }
        let med = allObserversMed.allObjects.compactMap { $0 as? ObserverType }
        let low = allObserversLow.allObjects.compactMap { $0 as? ObserverType }
        return Array<ObserverType>(high + med + low)
    }
    public func forEach(_ each: (ObserverType) -> Void) {
        observers.forEach(each)
    }
    public func add(_ observer: ObserverType, priority: Priority = .medium) {
        switch priority {
        case .low:
            if allObserversLow.contains(observer as AnyObject) { return }
            allObserversLow.add(observer as AnyObject)
        case .medium:
            if allObserversMed.contains(observer as AnyObject) { return }
            allObserversMed.add(observer as AnyObject)
        case .high:
            if allObserversHigh.contains(observer as AnyObject) { return }
            allObserversHigh.add(observer as AnyObject)
        }
    }
    public func remove(_ observer: ObserverType) {
        allObserversLow.remove(observer as AnyObject)
        allObserversMed.remove(observer as AnyObject)
        allObserversHigh.remove(observer as AnyObject)
    }
    
    public init() {}
}
