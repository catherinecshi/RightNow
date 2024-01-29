import UIKit
import CalendarKit
import EventKit
import EventKitUI


class CalendarViewController: DayViewController, EKEventEditViewDelegate {
    // MARK: Lifecycle Methods
    
    private let eventStore = EKEventStore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "RightNow"
        calendar.timeZone = TimeZone.current
        
        requestAccessToCalendar()
        //requestAccessToNotifications()
        
        //now it will notify the function whenever the app loads
        subscribeToNotifications()

    }
    
    private var cachedEvents: [EKEvent] = []
    private var eventModificationDates: [String: Date] = [:]
    
    //if you want to get a notification about which event changed
    @objc func storeChanged(_ notification: Notification) {
        //the moment something changes, this will notify the selector above
        reloadData()
        
        //creates the events to check against
        let startDate = Date()
        var oneDayComponents = DateComponents()
        oneDayComponents.day = 1
        let endDate = Calendar.current.date(byAdding: oneDayComponents, to: startDate)!
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let newEvents = eventStore.events(matching: predicate)
        
        //make notifications for events not in calendar prior
        for event in newEvents {
            //this is just to make sure isModified can handle nil values for lastModifiedDate
            let isModified = true
            if event.lastModifiedDate != nil {
                let isModified = eventModificationDates[event.eventIdentifier] != event.lastModifiedDate
            }
            
            //if isModified = true or if cachedEvents do not contain this event's identifier (meaning this event is new)
            if !cachedEvents.contains(where: { $0.eventIdentifier == event.eventIdentifier }) || isModified {
                scheduleNotification(for: event)
            }
        }
        
        //update cache
        cachedEvents = newEvents
        eventModificationDates = newEvents.reduce(into: [:]) { (result, event) in
            result[event.eventIdentifier] = event.lastModifiedDate
        }
    }
    
    //this is the active/currently being edited event out of the two
    override func dayView(dayView: DayView, didUpdate event: EventDescriptor) {
        guard let editingEvent = event as? EKWrapper else { return }
        //so if there actually is an edited event, you can continue
        if let originalEvent = event.editedEvent {
            editingEvent.commitEditing() //this updates the inactive parent event out of the two clones
            
            if originalEvent === editingEvent {
                // event creation flow
                presentEditingViewForEvent(editingEvent.ekEvent)
            } else {
                //editing flow
                try! eventStore.save(editingEvent.ekEvent, span: .thisEvent)
                scheduleNotification(for: editingEvent.ekEvent)
                //when we're editing something, we want to save it
                //we don't want to save immediately, because what if the user cancels
            }
            
        }
        reloadData()
    }
    
    // MARK: Request Access
    
    //access has been granted on 5/9/2023
    func requestAccessToCalendar() {
        eventStore.requestAccess(to: .event) { success, error in
            
        }
    }
    
    
    
    //allows the controller to be notified every time there is a change in the event store (if someone changes something in the Apple calendar or other things too)
    func subscribeToNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(storeChanged(_:)), name: .EKEventStoreChanged, object: nil)
    }
    
    //adds a notification
    func scheduleNotification(for event: EKEvent) {
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = "Right Now"
        content.body = "Log \(event.title ?? "") now"
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "eventNotification"
        
        //makes sure eventIdentifier isn't nil
        guard let eventIdentifier = event.eventIdentifier else {
            print("Error: eventIdentifier is nil")
            return
        }
        
        //for userInfo for extraction when clicking on notification
        content.userInfo = ["eventIdentifier": event.eventIdentifier!]
        
        let triggerDate = event.startDate.addingTimeInterval(-60)
        
        //just making the console readable
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .medium
        dateFormatter.timeZone = TimeZone.current
        print("Scheduling notification for \(dateFormatter.string(from: triggerDate))")
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate), repeats: false)
        
        let request = UNNotificationRequest(identifier: event.eventIdentifier, content: content, trigger: trigger)
        
        center.add(request) { (error) in
            if let error = error {
                print("Error \(error.localizedDescription)")
            } else {
                print("Notification scheduled!")
            }
        }
    }
    
    // MARK: Event Creation from Apple Calendar
    
    override func eventsForDate(_ date: Date) -> [EventDescriptor] {
        //date is midnight of today by default
        
        let startDate = date
        var oneDayComponents = DateComponents()
        oneDayComponents.day = 1
        
        //calendar is instance variable of DayViewController
        let endDate = calendar.date(byAdding: oneDayComponents, to: startDate)! //currently this just crashes the app if this doesn't work
        
        //create a predicate to get all the events from start to end date
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil) //right now fetching events from all calendars. if i just want to fetch for e.g. red calendar, it will go in the currently nil field
        
        let eventKitEvents = eventStore.events(matching: predicate)
        
        //currently, EKEvents are not compatible with EventDescriptor, so now we are converting it (to EventKitEvents)
        //this creates a eventkitevent for every EKEvent
        //map takes every function from eventKitEvents array (fetched from event kit store) and applies to code to every event it finds in the array
        let calendarKitEvents = eventKitEvents.map(EKWrapper.init)
        return calendarKitEvents
    }
    
    // MARK: User Actions
    
    //when the event is clicked or some other action, CK notifies another object called delegate that something has happened
    override func dayViewDidSelectEventView(_ eventView: EventView) {
        //get data model in order to show data (bc this is just a view)
        //if the descriptor property eventView is an instance of EKWrapper, then cast will succeed and ckEvent will contain that instance (otherwise, nil)
        guard let ckEvent = eventView.descriptor as? EKWrapper else {
            return
        }
        
        //we have our ckEvent but we need the details from the ekEvent as well
        let ekEvent = ckEvent.ekEvent
        presentDetailView(ekEvent: ekEvent)
        
    }
    
    override func dayViewDidLongPressEventView(_ eventView: EventView) {
        endEventEditing() //just in case the user went from one long press to another or something similar
        guard let ckEvent = eventView.descriptor as? EKWrapper else {
            return
        }
        beginEditing(event: ckEvent, animated: true)
    }
    
    override func dayView(dayView: DayView, didTapTimelineAt date: Date) {
        endEventEditing()
    }
    
    //stops the editing mode when the user drags the timeline left or right
    override func dayViewDidBeginDragging(dayView: DayView) {
        endEventEditing()
        
    }
    
    override func dayView(dayView: DayView, didLongPressTimelineAt date: Date) {
        //the event kit event exists without the store so you have to pass that first
        let newEKEvent = EKEvent(eventStore: eventStore)
        newEKEvent.calendar = eventStore.defaultCalendarForNewEvents
        
        var oneHourComponents = DateComponents()
        oneHourComponents.hour = 1
        
        let endDate = calendar.date(byAdding: oneHourComponents, to: date)
        
        newEKEvent.startDate = date
        newEKEvent.endDate = endDate
        newEKEvent.title = "New Event"
        
        let newEKWrapper = EKWrapper(eventKitEvent: newEKEvent)
        newEKWrapper.editedEvent = newEKWrapper //tells the controller to show the event with editing controls
        
        create(event: newEKWrapper, animated: true) //adds animation
        
    }
    
    // MARK: User Action (Supplements)
    
    func presentEditingViewForEvent(_ ekEvent: EKEvent) {
        let editingViewController = EKEventEditViewController()
        editingViewController.editViewDelegate = self
        editingViewController.event = ekEvent
        editingViewController.eventStore = eventStore
        present(editingViewController, animated: true, completion: nil)
    }
    
    private func presentDetailView(ekEvent: EKEvent) {
        let eventViewController = EKEventViewController()
        eventViewController.event = ekEvent
        
        //add flags so we can edit event and show in calendar
        eventViewController.allowsCalendarPreview = true
        eventViewController.allowsEditing = true
        
        navigationController?.pushViewController(eventViewController, animated: true)
    }
    
    //tells the controller whether the user has completed or cancelled the action
    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        endEventEditing()
        reloadData()
        controller.dismiss(animated: true, completion: nil)
        self.tabBarController?.tabBar.isHidden = false
        
        //notification setting for newly created events
        if action == .saved, let editedEvent = controller.event {
            scheduleNotification(for: editedEvent)
        }
    }
}
