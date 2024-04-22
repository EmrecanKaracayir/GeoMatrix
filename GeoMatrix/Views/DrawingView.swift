//
//  DrawingView.swift
//  GeoMatrix
//
//  Created by Emrecan Karaçayır on 7/3/24.
//

import SwiftUI

struct DrawingView: View {
  // States
  @StateObject private var drawingDocument = DrawingDocument()
  @StateObject private var selectedColor = UserDefaultColor()
  @StateObject private var selectedLineWidth = UserDefaultLineWidth()
  @StateObject private var selectedSmoothingFactor = UserDefaultSmoothingFactor()
  @State private var cursorLocation: CGPoint = CGPoint(x: UIScreen.main.bounds.width / 2, y: (UIScreen.main.bounds.height / 2) - 150)
  @State private var cursorIndicatorSize: Double = .zero
  @State private var cursorHistory = [CGPoint(x: UIScreen.main.bounds.width / 2, y: (UIScreen.main.bounds.height / 2) - 150)]
  @State private var cursorHistoryIndex: Int = 0
  @State private var lineHistory = [Line]()
  @State private var showConfirmationForDrawingDeletion: Bool = false
  @State private var showConfirmationForCursorDeletion: Bool = false
  
  // View
  var body: some View {
    VStack {
      HStack {
        ColorPicker("line color", selection: $selectedColor.color)
          .labelsHidden()
        Slider(value: $selectedLineWidth.lineWidth, in: 1...20) {
          Text("line width")
        }.frame(maxWidth: 100)
        Text(String(format: "%.0f", selectedLineWidth.lineWidth))
        
        Spacer()
        
        Button {
          let last = drawingDocument.lines.removeLast()
          lineHistory.append(last)
          if cursorHistoryIndex > cursorHistory.startIndex {
            cursorHistoryIndex -= 1
            let lastCursor = cursorHistory[cursorHistoryIndex]
            cursorLocation = lastCursor
          }
        } label: {
          Image(systemName: "arrow.uturn.backward.circle")
            .imageScale(.large)
        }.disabled(drawingDocument.lines.count == 0)
        
        Button {
          let last = lineHistory.removeLast()
          drawingDocument.lines.append(last)
          if cursorHistoryIndex < cursorHistory.endIndex - 1 {
            cursorHistoryIndex += 1
            let lastCursor = cursorHistory[cursorHistoryIndex]
            cursorLocation = lastCursor
          }
        } label: {
          Image(systemName: "arrow.uturn.forward.circle")
            .imageScale(.large)
        }.disabled(lineHistory.count == 0)
        
        Button(action: {
          showConfirmationForDrawingDeletion = true
        }) {
          Text("Delete")
        }.foregroundColor(.red)
          .confirmationDialog(
            Text("Do you want to delete the drawing?"),
            isPresented: $showConfirmationForDrawingDeletion,
            titleVisibility: Visibility.visible
          ) {
            Button("Delete", role: .destructive) {
              drawingDocument.lines = [Line]()
              lineHistory = [Line]()
            }
          }
      }.padding()
      
      DrawingAreaView(
        drawingDocument: drawingDocument,
        selectedColor: $selectedColor.color,
        selectedLineWidth: $selectedLineWidth.lineWidth,
        selectedSmoothingFactor: $selectedSmoothingFactor.smoothingFactor,
        cursorLocation: $cursorLocation,
        cursorIndicatorSize: $cursorIndicatorSize,
        cursorHistory: $cursorHistory,
        cursorHistoryIndex: $cursorHistoryIndex
      )
      
      Divider()
      
      HStack {
        Image(systemName: "lasso.badge.sparkles").imageScale(.large)
        Slider(value: $selectedSmoothingFactor.smoothingFactor, in: 0...10) {
          Text("smoothing factor")
        }.frame(maxWidth: 100)
        Text(String(format: "%.0fx", selectedSmoothingFactor.smoothingFactor))
        
        Spacer()
        
        Button {
          cursorHistoryIndex -= 1
          let last = cursorHistory[cursorHistoryIndex]
          cursorLocation = last
        } label: {
          Image(systemName: "arrow.uturn.backward.circle")
            .imageScale(.large)
        }.disabled(cursorHistoryIndex == 0)
        
        Button {
          cursorHistoryIndex += 1
          let last = cursorHistory[cursorHistoryIndex]
          cursorLocation = last
        } label: {
          Image(systemName: "arrow.uturn.forward.circle")
            .imageScale(.large)
        }.disabled(cursorHistoryIndex == cursorHistory.endIndex - 1)
        
        Button(action: {
          showConfirmationForCursorDeletion = true
        }) {
          Text("Reset")
        }.foregroundColor(.red)
          .confirmationDialog(
            Text("Do you want to reset cursor and its history?"),
            isPresented: $showConfirmationForCursorDeletion,
            titleVisibility: Visibility.visible
          ) {
            Button("Reset", role: .destructive) {
              cursorLocation = CGPoint(x: UIScreen.main.bounds.width / 2, y: (UIScreen.main.bounds.height / 2) - 150)
              cursorHistory = [CGPoint(x: UIScreen.main.bounds.width / 2, y: (UIScreen.main.bounds.height / 2) - 150)]
              cursorHistoryIndex = 0
            }
          }
      }.padding()
      
      TrackpadView(
        selectedLineWidth: $selectedLineWidth.lineWidth,
        selectedSmoothingFactor: $selectedSmoothingFactor.smoothingFactor,
        cursorLocation: $cursorLocation,
        cursorIndicatorSize: $cursorIndicatorSize,
        cursorHistory: $cursorHistory,
        cursorHistoryIndex: $cursorHistoryIndex
      ).frame(height: 100)
    }
  }
}

struct DrawingAreaView: View {
  // Environments
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.colorScheme) private var colorScheme
  
  // Parameters
  @ObservedObject var drawingDocument: DrawingDocument
  @Binding var selectedColor: Color
  @Binding var selectedLineWidth: Double
  @Binding var selectedSmoothingFactor: Double
  @Binding var cursorLocation: CGPoint
  @Binding var cursorIndicatorSize: Double
  @Binding var cursorHistory: [CGPoint]
  @Binding var cursorHistoryIndex: Int
  
  // Constants
  private let engine = DrawingEngine()
  private let cursorStrokeWidth: CGFloat = 2
  
  // States
  @State private var gestureEnded: Bool = true
  @State private var lastLocation: CGPoint = .zero
  
  // View
  var body: some View {
    Canvas { context, size in
      for line in drawingDocument.lines {
        let path = engine.createPath(for: line.points)
        context.stroke(
          path,
          with: .color(line.color),
          style: StrokeStyle(lineWidth: line.lineWidth, lineCap: .round, lineJoin: .round)
        )
      }
      let cursor = Circle().path(
        in: CGRect(
          x: cursorLocation.x - (selectedLineWidth + cursorStrokeWidth * 2) / 2,
          y: cursorLocation.y - (selectedLineWidth + cursorStrokeWidth * 2) / 2,
          width: selectedLineWidth + cursorStrokeWidth * 2,
          height: selectedLineWidth + cursorStrokeWidth * 2
        )
      )
      context.blendMode = .difference
      if cursorIndicatorSize != selectedLineWidth {
        let cursorIndicator = Circle().path(
          in: CGRect(
            x: cursorLocation.x - cursorIndicatorSize / 2,
            y: cursorLocation.y - cursorIndicatorSize / 2,
            width: cursorIndicatorSize,
            height: cursorIndicatorSize
          )
        )
        context.stroke(
          cursorIndicator,
          with: .color(colorScheme == .dark ? Color.white : Color.black),
          lineWidth: 0.5
        )
      }
      context.stroke(
        cursor,
        with: .color(colorScheme == .dark ? Color.black : Color.white),
        lineWidth: cursorStrokeWidth
      )
      context.fill(
        cursor,
        with: .color(colorScheme == .dark ? Color.white : Color.black)
      )
    }
    .gesture(
      DragGesture(minimumDistance: 0, coordinateSpace: .local)
        .onChanged{ value in
          if gestureEnded {
            lastLocation.x = smoothNumber(
              number: value.startLocation.x,
              multiple: selectedSmoothingFactor
            )
            lastLocation.y = smoothNumber(
              number: value.startLocation.y,
              multiple: selectedSmoothingFactor
            )
            drawingDocument.lines.append(
              Line(
                points: [cursorLocation],
                color: selectedColor,
                lineWidth: selectedLineWidth
              )
            )
            gestureEnded = false
          }
          else {
            drawingDocument.lines[drawingDocument.lines.count - 1].points
              .append(cursorLocation)
          }
          let lastCursorLocation = CGPoint(x: cursorLocation.x, y: cursorLocation.y)
          self.cursorLocation.x += smoothNumber(
            number: value.location.x - lastLocation.x,
            multiple: selectedSmoothingFactor
          )
          self.cursorLocation.y += smoothNumber(
            number: value.location.y - lastLocation.y,
            multiple: selectedSmoothingFactor
          )
          if lastCursorLocation.x != cursorLocation.x || lastCursorLocation.y != cursorLocation.y {
            lastLocation = value.location
          }
        }.onEnded{ _ in
          cursorHistory.removeLast(cursorHistory.count - (cursorHistoryIndex + 1))
          cursorHistory.append(self.cursorLocation)
          cursorHistoryIndex += 1
          gestureEnded = true
        }
    )
    .onChange(of: scenePhase) { oldValue, newValue in
      if newValue == .background {
        drawingDocument.save()
      }
    }
  }
}

struct TrackpadView: View {
  // Parameters
  @Binding var selectedLineWidth: Double
  @Binding var selectedSmoothingFactor: Double
  @Binding var cursorLocation: CGPoint
  @Binding var cursorIndicatorSize: Double
  @Binding var cursorHistory: [CGPoint]
  @Binding var cursorHistoryIndex: Int
  
  // States
  @State private var gestureEnded: Bool = true
  @State private var lastLocation: CGPoint = .zero
  @State private var animBusy: Bool = false
  
  // View
  var body: some View {
    GeometryReader { geometry in
      Color.clear
        .contentShape(Rectangle())
        .gesture(
          DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
              if gestureEnded {
                animBusy = false
                Timer.animateNumber(
                  number: $cursorIndicatorSize,
                  busy: $animBusy,
                  start: 100, end: selectedLineWidth,
                  duration: 0.25
                )
                lastLocation.x = smoothNumber(
                  number: value.startLocation.x,
                  multiple: selectedSmoothingFactor
                )
                lastLocation.y = smoothNumber(
                  number: value.startLocation.y,
                  multiple: selectedSmoothingFactor
                )
                gestureEnded = false
              }
              let lastCursorLocation = CGPoint(x: cursorLocation.x, y: cursorLocation.y)
              self.cursorLocation.x += smoothNumber(
                number: value.location.x - lastLocation.x,
                multiple: selectedSmoothingFactor
              )
              self.cursorLocation.y += smoothNumber(
                number: value.location.y - lastLocation.y,
                multiple: selectedSmoothingFactor
              )
              if lastCursorLocation.x != cursorLocation.x || lastCursorLocation.y != cursorLocation.y {
                lastLocation = value.location
              }
            }
            .onEnded{ _ in
              cursorHistory.removeLast(cursorHistory.count - (cursorHistoryIndex + 1))
              cursorHistory.append(self.cursorLocation)
              cursorHistoryIndex += 1
              gestureEnded = true
            }
        )
    }
  }
}

func smoothNumber(number: Double, multiple: Double) -> Double {
  if multiple == 0 {
    return number
  }
  let intNumber = Int(number.rounded())
  let intMultiple = Int(multiple.rounded())
  var result = abs(intNumber) + intMultiple / 2
  result -= result % intMultiple
  result *= intNumber > 0 ? 1 : -1
  return Double(result)
}

struct DrawingView_Previews: PreviewProvider {
  static var previews: some View {
    DrawingView()
  }
}
