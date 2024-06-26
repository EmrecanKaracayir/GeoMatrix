//
//  DrawingDocument.swift
//  GeoMatrix
//
//  Created by Emrecan Karaçayır on 11/3/24.
//

import Foundation
import Combine

class DrawingDocument: ObservableObject {
  @Published var lines = [Line]()
  
  var subscription = Set<AnyCancellable>()
  
  init() {
    //load the data
    if FileManager.default.fileExists(atPath: url.path),
       let data = try? Data(contentsOf: url) {
      
      let decoder = JSONDecoder()
      do {
        let lines = try decoder.decode([Line].self, from: data)
        self.lines = lines
      } catch {
        print("decoding error \(error)")
      }
    }
    
    $lines
      .filter({ !$0.isEmpty })
      .debounce(for: 2, scheduler: RunLoop.main)
      .sink { [unowned self] lines in
        self.save()
      }.store(in: &subscription)
    
  }
  
  func save() {
    DispatchQueue.global(qos: .background).async { [unowned self] in
      let encoder = JSONEncoder()
      let data = try? encoder.encode(self.lines)
      
      do {
        try data?.write(to: self.url)
      }catch {
        print("error saving \(error)")
      }
    }
  }
  
  var url: URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    return documentsDirectory.appendingPathComponent("Document").appendingPathExtension("json")
  }
  
}
