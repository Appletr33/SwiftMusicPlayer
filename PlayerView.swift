
import SwiftUI
import Foundation
import AVFoundation


var audioHandler = AudioHandler()
let songsPlays = UserDefaults.standard

struct PlayerView: View {
    @State private var playerPaused = true
    
    var body: some View {
        VStack() {
            Text("Swift Music Player")
                .font(.title)
                .bold()
                .frame(alignment: .top)
                .padding(20)
            Image(systemName: "plus")
                          .resizable()
                          .padding(6)
                          .frame(width: 24, height: 24)
                          .background(Color.blue)
                          .clipShape(Circle())
                          .foregroundColor(.white)
            
            let songs = getSongs()
            List {
                ForEach(0..<songs.count) { index in
                    SongView(plays: songsPlays.integer(forKey: songs[index][0]), isPaused: $playerPaused, title: songs[index][0], path: songs[index][1])
                }
            }

            
            Button(action: {
                playerPaused.toggle()
                if playerPaused {
                    audioHandler.player.pause()
                }
                else {
                    audioHandler.player.play()
                }
            }) {
                Image(playerPaused ? "play" : "pause")
                .resizable()
                .frame(width: 32.0, height: 32.0)
                .padding(10.0)
        }

        }
        .background(Color("Orange-Red"))
        .ignoresSafeArea()
    }
}

struct SongView: View {
    @State var plays: Int = 0
    @Binding var isPaused: Bool
    
    var title: String
    var path: String
    var body: some View {
        Button(action: { plays+=1 ; buttonPlaySong(name: title); if self.isPaused {self.isPaused.toggle()}}) {
            HStack {
                Image("song")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.black)
                VStack(alignment: .leading){
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.black)
                    Text("Played \(plays) times")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView()
    }
}

func getSongs() -> Array<Array<String>> {
    let paths = Bundle.main.paths(forResourcesOfType: "m4a", inDirectory: "songs")
    var songs: [Array<String>] = []
    
    for song in paths {
        if let range = song.range(of: "/songs/") {
            let name = (song[range.upperBound...]).replacingOccurrences(of: ".m4a", with: "")
            songs.append([String(name), song])
        }
    }
    
    for song in songs {
        if songsPlays.integer(forKey: song[0]) == nil {
            songsPlays.set(0, forKey: song[0])
        }
    }
    
    return songs
}

func buttonPlaySong(name: String) {
    var i = 0
    let songs = getSongs()
    for song in songs {
        if song[0] == name {
            break;
        }
        i+=1
    }
    audioHandler.playSong(index: i)
}


class AudioHandler: NSObject, ObservableObject, AVAudioPlayerDelegate {
    var player = AVAudioPlayer()
    var index = 0
    var songs = getSongs()
    
    override init() {
        super.init()
        player.delegate = self
    }
    
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if self.index < self.songs.count - 1 {
            self.index+=1
        }
        else {
            self.index = 0
        }
        playSong(index: self.index)
    }
    
    func playSong(index: Int) {
        //defaults.set(songs[self.index][0], forKey: DefaultsKeys.keyOne)
        
        self.index = index
        let songs = getSongs()
        songsPlays.set(songsPlays.integer(forKey: songs[self.index][0]) + 1, forKey: songs[self.index][0])
        let path = Bundle.main.path(forResource: songs[self.index][0], ofType:"m4a", inDirectory: "songs")!
        
        do {
        try AVAudioSession.sharedInstance().setCategory(.playback, options: AVAudioSession.CategoryOptions.mixWithOthers)
        try AVAudioSession.sharedInstance().setActive(true)
        /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
        player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path), fileTypeHint: AVFileType.m4a.rawValue)
        /* iOS 10 and earlier require the following line:
        player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */
        player.delegate = audioHandler
        player.volume = 1
        player.numberOfLoops = 0
        player.prepareToPlay()
        player.play()
        } catch let error {print(error)}
    }
}
