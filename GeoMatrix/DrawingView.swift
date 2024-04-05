//
//  DrawingView.swift
//  GeoMatrix
//
//  Created by Emrecan Karaçayır on 7/3/24.
//

import SwiftUI

struct DrawingView: View {
  
  @Environment(\.scenePhase) var scenePhase
  
  @StateObject var drawingDocument = DrawingDocument()
  @State private var deletedLines = [Line]()
  
  @StateObject var selectedColor = UserDefaultColor()
  // @State private var selectedColor: Color = .black
  @SceneStorage("selectedLineWidth") var selectedLineWidth: Double = 1
  
  let engine = DrawingEngine()
  @State private var showConfirmation: Bool = false
  
  @State private var gestureEnded: Bool = true
  @State private var offsetDefPhase: Bool = false
  
  @State private var offsetCircleLocation: CGPoint = CGPoint(x: 0, y: 0)
  
  @State private var offset: CGPoint = CGPoint(x: 0, y: 0)
  
  private let offsetAmount: CGFloat = 100.0
  
  var body: some View {
    
    VStack {
      
      HStack {
        ColorPicker("line color", selection: $selectedColor.color)
          .labelsHidden()
        Slider(value: $selectedLineWidth, in: 1...20) {
          Text("linewidth")
        }.frame(maxWidth: 100)
        Text(String(format: "%.0f", selectedLineWidth))
        
        Spacer()
        
        Button {
          let last = drawingDocument.lines.removeLast()
          deletedLines.append(last)
        } label: {
          Image(systemName: "arrow.uturn.backward.circle")
            .imageScale(.large)
        }.disabled(drawingDocument.lines.count == 0)
        
        Button {
          let last = deletedLines.removeLast()
          drawingDocument.lines.append(last)
        } label: {
          Image(systemName: "arrow.uturn.forward.circle")
            .imageScale(.large)
        }.disabled(deletedLines.count == 0)
        
        Button(action: {
          showConfirmation = true
        }) {
          Text("Delete")
        }.foregroundColor(.red)
          .confirmationDialog(Text("Are you sure you want to delete everything?"), isPresented: $showConfirmation) {
            
            Button("Delete", role: .destructive) {
              drawingDocument.lines = [Line]()
              deletedLines = [Line]()
            }
          }
        
      }.padding()
      
      
      //            ZStack {
      //                Color.white
      //
      //                ForEach(drawingDocument.lines){ line in
      //                    DrawingShape(points: line.points)
      //                        .stroke(line.color, style: StrokeStyle(lineWidth: line.lineWidth, lineCap: .round, lineJoin: .round))
      //                }
      //            }
      Canvas { context, size in
        for line in drawingDocument.lines {
          let path = engine.createPath(for: line.points)
          context.stroke(
            path,
            with: .color(line.color),
            style: StrokeStyle(lineWidth: line.lineWidth, lineCap: .round, lineJoin: .round)
          )
        }
        if offsetDefPhase {
          let offsetCircle = Path(ellipseIn:
                                    CGRect(x: offsetCircleLocation.x,
                                           y: offsetCircleLocation.y,
                                           width: offsetAmount * 2, height: offsetAmount * 2))
          context.stroke(offsetCircle, with: .color(.accentColor))
          
          let offsetCrosshair = Path(ellipseIn:
                                      CGRect(x: offsetCircleLocation.x + offsetAmount,
                                             y: offsetCircleLocation.y + offsetAmount,
                                             width: 2, height: 2))
          context.stroke(offsetCrosshair, with: .color(selectedColor.color), lineWidth: 2)
        }
        
      }
      .gesture(
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
          .onChanged { value in
            if gestureEnded {
              gestureEnded = false
              offsetCircleLocation.x = value.startLocation.x - offsetAmount
              offsetCircleLocation.y = value.startLocation.y - offsetAmount
              offsetDefPhase = true
              return
            }
            if offsetDefPhase {
              let xDistance = offsetCircleLocation.x + offsetAmount - value.location.x
              let yDistance = offsetCircleLocation.y + offsetAmount - value.location.y
              if sqrt((xDistance * xDistance) + (yDistance * yDistance)) >= offsetAmount {
                offsetDefPhase = false
                offset.x = xDistance
                offset.y = yDistance
                
                // Create new line
                drawingDocument.lines.append(
                  Line(points: [CGPoint(x: value.location.x + offset.x, y: value.location.y + offset.y)],
                       color: selectedColor.color, lineWidth: selectedLineWidth))
              }
              return
            }
            
            // Create point for line
            drawingDocument.lines[drawingDocument.lines.count - 1]
              .points.append(CGPoint(x: value.location.x + offset.x, y: value.location.y + offset.y))
          }
          .onEnded { value in
            gestureEnded = true
            offsetDefPhase = false
            if let last = drawingDocument.lines.last?.points, last.isEmpty {
              drawingDocument.lines.removeLast()
            }
          }
      )
    }
    .onChange(of: scenePhase) { oldValue, newValue in
      if newValue == .background {
        drawingDocument.save()
      }
    }
  }
}

struct DrawingView_Previews: PreviewProvider {
  static var previews: some View {
    DrawingView()
  }
}
