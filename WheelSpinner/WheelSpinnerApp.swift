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

struct ChoiceItem: Identifiable, Equatable {
  let id = UUID()
  var text: String
  var isChecked: Bool
}

struct ChoiceListView: View {
  @State private var choices: [ChoiceItem] = [
    ChoiceItem(text: "Preset A", isChecked: false),
    ChoiceItem(text: "Preset B", isChecked: false),
    ChoiceItem(text: "Preset C", isChecked: false)
  ]
  @State private var searchText: String = ""
  
  var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        TextField("Search...", text: $searchText)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .padding([.horizontal, .top])
        
        Button(action: addChoice) {
          HStack {
            Image(systemName: "plus.circle")
            Text("Add Choice")
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal)
          .padding(.vertical, 10)
        }
        
        List {
          ForEach(Array(choices.enumerated()), id: \ .element.id) { idx, choice in
            if searchText.isEmpty || choice.text.lowercased().contains(searchText.lowercased()) {
              HStack {
                Button {
                  toggleAndMove(at: idx)
                } label: {
                  Image(systemName: choice.isChecked ? "checkmark.square.fill" : "square")
                }
                .buttonStyle(PlainButtonStyle())
                
                TextField("Choice", text: $choices[idx].text)
                  .onSubmit {
                    moveToTop(at: idx)
                  }
              }
            }
          }
        }
      }
      .navigationTitle("Choices")
      .toolbar {
        ToolbarItem(placement: .bottomBar) {
          NavigationLink(destination: SpinnerView(choices: choices.map { $0.text })) {
            Text("Spin").bold()
          }
          .disabled(choices.isEmpty)
        }
      }
    }
  }
  
  private func addChoice() {
    let new = ChoiceItem(text: "", isChecked: false)
    choices.insert(new, at: 0)
  }
  
  private func toggleAndMove(at idx: Int) {
    var item = choices[idx]
    item.isChecked.toggle()
    choices.remove(at: idx)
    choices.insert(item, at: 0)
  }
  
  private func moveToTop(at idx: Int) {
    let item = choices[idx]
    choices.remove(at: idx)
    choices.insert(item, at: 0)
  }
}

struct SpinnerView: View {
  let choices: [String]
  @State private var spinAngle: Double = 0
  @State private var selection: String? = nil
  @State private var hasSpunOnAppear = false
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
      .onAppear {
        guard !hasSpunOnAppear else { return }
        hasSpunOnAppear = true
        spinWheel()
      }
      
      Button("Spin") {
        spinWheel()
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
  
  private func spinWheel() {
    selection = nil
    let extra = Double.random(in: 3...6) * 360
    spinAngle += extra
    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
      computeSelection()
    }
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
      
      ForEach(0..<choices.count, id: \ .self) { i in
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
