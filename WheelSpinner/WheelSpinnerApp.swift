//
//  WheelSpinnerApp.swift
//  WheelSpinner
//
//  Created by Audrey Santoso on 26/6/2025.
//

import SwiftUI

@main
struct WheelSpinnerApp: App {
    var body: some Scene {
        WindowGroup {
            ChoiceListView()
        }
    }
}


#Preview {
  ChoiceListView()
}


struct ChoiceListView: View {
  @State private var choices: [String] = ["Option 1", "Option 2", "Option 3"]
  var body: some View {
    NavigationView {
      VStack {
        List {
          ForEach(choices.indices, id: \.self) { idx in
            TextField("Choice \(idx+1)", text: $choices[idx])
          }
          .onDelete(perform: delete)
        }
        HStack {
          Button(action: add) {
            Text("Add Choice")
          }
          Spacer()
          NavigationLink(destination: SpinnerView(choices: choices)) {
            Text("Spin").bold()
          }
          .disabled(choices.isEmpty)
        }
        .padding()
      }
      .navigationTitle("Choices")
    }
  }
  
  func add() { choices.append("") }
  func delete(at offsets: IndexSet) { choices.remove(atOffsets: offsets) }
}

struct SpinnerView: View {
  let choices: [String]
  @State private var spinAngle: Double = 0
  @State private var selection: String? = nil
  @Environment(\.presentationMode) private var presentation
  
  var body: some View {
    VStack {
      ZStack {
        WheelView(choices: choices)
          .rotationEffect(.degrees(spinAngle))
          .animation(.easeOut(duration: 3), value: spinAngle)
        Arrow()
      }
      .frame(width: 300, height: 300)
      
      Button("Spin") {
        selection = nil
        let extra = Double.random(in: 3...6) * 360
        spinAngle += extra
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
          computeSelection()
        }
      }
      .padding()
      
      if let choice = selection {
        NavigationLink(
          destination: ResultView(choice: choice),
          isActive: .constant(true)
        ) { EmptyView() }
      }
    }
    .navigationBarTitle("Spinner", displayMode: .inline)
  }
  
  private func computeSelection() {
    let normalized = spinAngle.truncatingRemainder(dividingBy: 360)
    let segment = 360.0 / Double(choices.count)
    let idx = Int((360 - normalized) / segment) % choices.count
    selection = choices[idx]
  }
}

struct WheelView: View {
  let choices: [String]
  var body: some View {
    GeometryReader { g in
      let r = min(g.size.width, g.size.height) / 2
      let center = CGPoint(x: g.size.width/2, y: g.size.height/2)
      let step = 2 * .pi / Double(choices.count)
      
      ForEach(0..<choices.count, id: \.self) { i in
        Path { path in
          path.move(to: center)
          path.addArc(
            center: center,
            radius: r,
            startAngle: Angle(radians: step * Double(i) - .pi/2),
            endAngle: Angle(radians: step * Double(i+1) - .pi/2),
            clockwise: false
          )
        }
        .fill(Color(hue: Double(i) / Double(choices.count), saturation: 0.7, brightness: 0.9))
        
        Text(choices[i])
          .position(
            x: center.x + cos(step * (Double(i) + 0.5) - .pi/2) * (r * 0.7),
            y: center.y + sin(step * (Double(i) + 0.5) - .pi/2) * (r * 0.7)
          )
      }
    }
  }
}

struct Arrow: View {
  var body: some View {
    Triangle()
      .fill(Color.red)
      .frame(width: 20, height: 20)
      .offset(y: -160)
  }
}

struct Triangle: Shape {
  func path(in rect: CGRect) -> Path {
    var p = Path()
    p.move(to: CGPoint(x: rect.midX, y: rect.minY))
    p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
    p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
    p.closeSubpath()
    return p
  }
}

struct ResultView: View {
  let choice: String
  @Environment(\.presentationMode) private var presentation
  
  var body: some View {
    VStack(spacing: 20) {
      Text("Result: \(choice)")
        .font(.largeTitle)
      
      HStack {
        Button("Respin") {
          presentation.wrappedValue.dismiss()
        }
        Spacer()
        Button("Home") {
          presentation.wrappedValue.dismiss()
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            presentation.wrappedValue.dismiss()
          }
        }
      }
      .padding()
    }
    .navigationTitle("Result")
  }
}
