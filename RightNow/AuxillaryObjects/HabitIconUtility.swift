import Foundation
import UIKit

public struct HabitIconUtility {
    private struct HabitIcon {
        let keywords: [String]
        let image: String
        
        var length: Int {
            keywords.map { $0.count }.max() ?? 0
        }
        
        enum MatchType {
            case exact // perfect match
            case partial // partial match
            case none // no match
        }
        
        func matchType(_ input: String) -> MatchType {
            let lowercasedInput = input.lowercased()
            
            // check for exact matches first
            if keywords.contains(where: { $0.lowercased() == lowercasedInput }) {
                return .exact
            }
            
            // for partial matches
            if keywords.contains(where: { $0.lowercased().contains(lowercasedInput) ||
                lowercasedInput.contains($0.lowercased())}) {
                    return .partial
                }
            
            return .none
        }
    }
    
    private static let habitIcons: [HabitIcon] = [
        // Exercise/active
        HabitIcon(keywords: ["run", "move", "activity"],
                 image: "figure.run"),
        HabitIcon(keywords: ["walk"],
                 image: "figure.walk"),
        HabitIcon(keywords: ["rugby", "american football"],
                 image: "figure.american.football"),
        HabitIcon(keywords: ["archery"],
                 image: "figure.archery"),
        HabitIcon(keywords: ["badminton"],
                 image: "figure.badminton"),
        HabitIcon(keywords: ["baseball", "softball"],
                 image: "figure.baseball"),
        HabitIcon(keywords: ["basketball"],
                 image: "figure.basketball"),
        HabitIcon(keywords: ["bowling"],
                 image: "figure.bowling"),
        HabitIcon(keywords: ["boxing"],
                 image: "figure.boxing"),
        HabitIcon(keywords: ["climbing", "bouldering", "scaling", "free soloing", "rope", "roping"],
                 image: "figure.climbing"),
        HabitIcon(keywords: ["stretch", "stretching"],
                 image: "figure.cooldown"),
        HabitIcon(keywords: ["cricket"],
                 image: "figure.cricket"),
        HabitIcon(keywords: ["curling"],
                 image: "figure.curling"),
        HabitIcon(keywords: ["dance", "dancing", "hip hop", "hip-hop", "ballet"],
                 image: "figure.dancing"),
        HabitIcon(keywords: ["skiing"],
                 image: "figure.skiing.downhill"),
        HabitIcon(keywords: ["elliptical"],
                 image: "figure.elliptical"),
        HabitIcon(keywords: ["horse", "equestrian"],
                 image: "figure.equestrian.sports"),
        HabitIcon(keywords: ["fencing", "fence"],
                 image: "figure.fencing"),
        HabitIcon(keywords: ["golf"],
                 image: "figure.golf"),
        HabitIcon(keywords: ["HIIT", "training"],
                 image: "figure.highintensity.intervaltraining"),
        HabitIcon(keywords: ["hiking", "hike", "mountain"],
                 image: "figure.hiking"),
        HabitIcon(keywords: ["hockey"],
                 image: "figure.hockey"),
        HabitIcon(keywords: ["lacrosse"],
                 image: "figure.lacrosse"),
        HabitIcon(keywords: ["martial", "kung fu", "tai chi", "taekwondo"],
                 image: "figure.martial.arts"),
        HabitIcon(keywords: ["kickboxing", "muay thai"],
                 image: "figure.kickboxing"),
        HabitIcon(keywords: ["cardio", "bike", "biking", "cycle", "cycling", "spin"],
                 image: "figure.outdoor.cycle"),
        HabitIcon(keywords: ["swim"],
                 image: "figure.pool.swim"),
        HabitIcon(keywords: ["pilates"],
                 image: "figure.pilates"),
        HabitIcon(keywords: ["row"],
                 image: "figure.rower"),
        HabitIcon(keywords: ["sail"],
                 image: "figure.sailing"),
        HabitIcon(keywords: ["skate", "skating"],
                 image: "figure.skating"),
        HabitIcon(keywords: ["football", "soccer"],
                 image: "figure.soccer"),
        HabitIcon(keywords: ["stair"],
                 image: "figure.stairs"),
        HabitIcon(keywords: ["surf"],
                 image: "figure.surfing"),
        HabitIcon(keywords: ["tennis", "racquetball"],
                 image: "figure.tennis"),
        HabitIcon(keywords: ["strength"],
                 image: "figure.strengthtraining"),
        HabitIcon(keywords: ["volley"],
                 image: "figure.volleyball"),
        HabitIcon(keywords: ["water polo"],
                 image: "figure.waterpolo"),
        HabitIcon(keywords: ["wrestle", "wrestling"],
                 image: "figure.wrestling"),
        HabitIcon(keywords: ["gym", "exercise"],
                 image: "dumbbell.fill"),
        HabitIcon(keywords: ["sport"],
                 image: "sportscourt.fill"),
        
        // Mindfulness
        HabitIcon(keywords: ["read", "book"],
                 image: "books.vertical.fill"),
        HabitIcon(keywords: ["rumination", "ruminate", "journal"],
                 image: "book.pages.fill"),
        HabitIcon(keywords: ["yoga"],
                 image: "figure.yoga"),
        HabitIcon(keywords: ["meditation", "meditate", "breath", "mindful"],
                 image: "figure.mind.and.body"),
        HabitIcon(keywords: ["nature", "grass"],
                 image: "leaf.fill"),
        HabitIcon(keywords: ["outside", "tree", "plant"],
                 image: "tree.fill"),
        HabitIcon(keywords: ["grateful", "gratitude", "happy", "happiness"],
                 image: "party.popper.fill"),
        HabitIcon(keywords: ["pray", "god"],
                 image: "hands.and.sparkles"),
        HabitIcon(keywords: ["monitor"],
                 image: "waveform.path.ecg"),
        HabitIcon(keywords: ["lumosity", "brain", "neural", "neuro"],
                 image: "brain.fill"),
        HabitIcon(keywords: ["save money"],
                 image: "dollarsign.arrow.circlepath"),
        HabitIcon(keywords: ["money"],
                 image: "banknote.fill"),
        HabitIcon(keywords: ["gift"],
                 image: "giftcard.fill"),
        HabitIcon(keywords: ["health", "heart", "love", "kind"],
                 image: "heart.fill"),
        
        // Life essentials
        HabitIcon(keywords: ["wake", "morning"],
                 image: "sun.horizon.fill"),
        HabitIcon(keywords: ["night"],
                 image: "moon.fill"),
        HabitIcon(keywords: ["clean", "tidy", "teeth", "tooth", "floss", "shave"],
                 image: "bubbles.and.sparkles"),
        HabitIcon(keywords: ["cook"],
                 image: "frying.pan.fill"),
        HabitIcon(keywords: ["shower"],
                 image: "shower.fill"),
        HabitIcon(keywords: ["bath"],
                 image: "bathtub.fill"),
        HabitIcon(keywords: ["sleep", "bed"],
                 image: "bed.double.fill"),
        HabitIcon(keywords: ["laundry"],
                 image: "washer.fill"),
        HabitIcon(keywords: ["wash"],
                 image: "sink.fill"),
        HabitIcon(keywords: ["trash", "garbage", "rubbish", "throw away"],
                 image: "trash.fill"),
        HabitIcon(keywords: ["medication", "pill", "birth control", "vitamin", "supplement"],
                 image: "pills.fill"),
        HabitIcon(keywords: ["pet", "maow"],
                 image: "pawprint.fill"),
        HabitIcon(keywords: ["dog"],
                 image: "dog.fill"),
        HabitIcon(keywords: ["cat"],
                 image: "cat.fill"),
        HabitIcon(keywords: ["bird"],
                 image: "bird.fill"),
        HabitIcon(keywords: ["fish"],
                 image: "fish.fill"),
        HabitIcon(keywords: ["eat", "feed", "diet"],
                 image: "carrot.fill"),
        HabitIcon(keywords: ["water", "drink"],
                 image: "drop.fill"),
        HabitIcon(keywords: ["break"],
                 image: "powersleep"),
        HabitIcon(keywords: ["quality time"],
                  image: "figure.2.arms.open"),
        HabitIcon(keywords: ["makeup", "skincare"],
                  image: "wand.and.stars.inverse"),
        HabitIcon(keywords: ["mail"],
                  image: "envelope.fill"),
        HabitIcon(keywords: ["pack"],
                  image: "backpack.fill"),
        
        
        // Hobbies
        HabitIcon(keywords: ["paint", "draw"],
                 image: "paintbrush.pointed.fill"),
        HabitIcon(keywords: ["write", "writing"],
                 image: "pencil.line"),
        HabitIcon(keywords: ["edit"],
                 image: "scissors"),
        HabitIcon(keywords: ["news"],
                 image: "newspaper.fill"),
        HabitIcon(keywords: ["school", "learn"],
                 image: "graduationcap.fill"),
        HabitIcon(keywords: ["photo", "picture"],
                 image: "photo.artframe"),
        HabitIcon(keywords: ["sing", "song"],
                 image: "music.mic"),
        HabitIcon(keywords: ["music"],
                  image: "headphones.circle.fill"),
        HabitIcon(keywords: ["play", "guitar", "piano", "flute", "oboe", "piccolo", "trombone", 
                             "trumpet", "tuba", "french horn", "bassoon", "clarinet", "saxophone",
                             "violin", "viola", "cello", "bass", "drum", "harp"],
                  image: "music.quarternote.3")
    ]
    
    public static func icon(for habitName: String) -> UIImage? {
        // only allow icon matching if 3 letters or more
        guard habitName.count > 2 else {
            return UIImage(systemName: "checkmark.circle.fill")
        }
        
        // group matches by match type
        var exactMatches: [HabitIcon] = []
        var partialMatches: [HabitIcon] = []
        
        for icon in habitIcons {
            switch icon.matchType(habitName) {
            case .exact:
                exactMatches.append(icon)
            case .partial:
                partialMatches.append(icon)
            case .none:
                continue
            }
        }
        
        // prioritise exact matches
        if let exactMatch = exactMatches.first {
            return UIImage(systemName: exactMatch.image)
        }
        
        // use longest partial match if no exact matches
        if let bestMatch = partialMatches.max(by: { $0.length < $1.length }) {
            return UIImage(systemName: bestMatch.image)
        }
        
        // default icon if no matches
        return UIImage(systemName: "checkmark.circle.fill")
    }
}
