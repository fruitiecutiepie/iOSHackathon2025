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

class ChoiceListViewModel: ObservableObject {
  @Published var choices: [ChoiceItem] = [
    ChoiceItem(text: "Pizza", isChecked: false),
    ChoiceItem(text: "Burger", isChecked: false),
    ChoiceItem(text: "Rice", isChecked: false),
    ChoiceItem(text: "Pasta", isChecked: false),
    ChoiceItem(text: "Tacos", isChecked: false),
    ChoiceItem(text: "Sushi", isChecked: false),
    ChoiceItem(text: "Fried Chicken", isChecked: false),
    ChoiceItem(text: "Salad", isChecked: false),
    ChoiceItem(text: "Sandwich", isChecked: false),
    ChoiceItem(text: "Noodles", isChecked: false),
  ]
  let minChoices = 2
  let maxChoices = 10
  
  var canAdd: Bool { choices.count < maxChoices }
  var canSpin: Bool {
    choices.count >= minChoices && choices.allSatisfy {
      !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
  }
  
  func addChoice() -> UUID? {
    guard canAdd else { return nil }
    let new = ChoiceItem(text: "", isChecked: true)
    choices.insert(new, at: 0)
    return new.id
  }
  
  func toggleAndMove(at idx: Int) {
    var item = choices[idx]
    item.isChecked.toggle()
    choices.remove(at: idx)
    if item.isChecked {
      choices.insert(item, at: 0)
    } else {
      let pos = choices.firstIndex(where: { !$0.isChecked }) ?? choices.count
      choices.insert(item, at: pos)
    }
  }
  
  func moveToTop(at idx: Int) {
    let item = choices[idx]
    choices.remove(at: idx)
    choices.insert(item, at: 0)
  }
  
  func delete(at offsets: IndexSet) {
    choices.remove(atOffsets: offsets)
  }
}

struct ChoiceListView: View {
  @StateObject private var viewModel = ChoiceListViewModel()
  @State private var searchText: String = ""
  @FocusState private var focusedItemId: UUID?
  
  private var filteredIndices: [Int] {
    viewModel.choices.indices.filter { idx in
      let text = viewModel.choices[idx].text.lowercased()
      return searchText.isEmpty || text.contains(searchText.lowercased())
    }
  }
  
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
        .disabled(!viewModel.canAdd)
        .opacity(viewModel.canAdd ? 1 : 0.5)
        
        if viewModel.choices.isEmpty {
          Spacer()
          Text("No choices available. Please add some.")
            .foregroundColor(.gray)
            .padding()
        } else {
          List {
            // 2) Always returns a HStack → no buildExpression error
            ForEach(filteredIndices, id: \.self) { idx in
              HStack {
                Button {
                  viewModel.toggleAndMove(at: idx)
                } label: {
                  Image(systemName: viewModel.choices[idx].isChecked
                        ? "checkmark.square.fill"
                        : "square")
                }
                .buttonStyle(PlainButtonStyle())
                
                TextField("Choice", text: $viewModel.choices[idx].text)
                  .focused($focusedItemId, equals: viewModel.choices[idx].id)
                  .onSubmit { viewModel.moveToTop(at: idx) }
                  .overlay(
                    RoundedRectangle(cornerRadius: 4)
                      .stroke(
                        viewModel.choices[idx].text
                          .trimmingCharacters(in: .whitespacesAndNewlines)
                          .isEmpty
                        ? Color.red
                        : Color.clear,
                        lineWidth: 1
                      )
                  )
              }
            }
            .onDelete(perform: viewModel.delete)
          }
        }
        
        if !viewModel.canSpin {
          Text("Enter at least \(viewModel.minChoices) non-empty choices to spin.")
            .font(.footnote)
            .foregroundColor(.gray)
            .padding(.bottom, 8)
        }
      }
      .navigationTitle("What to Eat?")
      .toolbar {
        ToolbarItem(placement: .bottomBar) {
          NavigationLink(destination: SpinnerView(choices: viewModel.choices.map { $0.text })) {
            Text("Spin").bold()
          }
          .disabled(!viewModel.canSpin)
          .opacity(viewModel.canSpin ? 1 : 0.5)
        }
      }
    }
  }
  
  private func addChoice() {
    if let newId = viewModel.addChoice() {
      focusedItemId = newId
    }
  }
}

struct SpinnerView: View {
  let choices: [String]
  @State private var spinAngle: Double = 0
  @State private var selection: String? = nil
  @State private var hasSpunOnAppear = false
  @Environment(\.presentationMode) private var presentation
  private let feedback = UIImpactFeedbackGenerator(style: .light)
  
  var body: some View {
    VStack {
      // Gradient card background
      RoundedRectangle(cornerRadius: 20)
        .fill(
          LinearGradient(
            gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .frame(width: 340, height: 340)
        .shadow(radius: 5)
      
      // Wheel + arrow
      ZStack {
        WheelView(choices: choices)
          .rotationEffect(.degrees(spinAngle))
          .animation(.easeOut(duration: 3), value: spinAngle)
        Arrow()
      }
      .frame(width: 300, height: 300)
      .onAppear {
        feedback.prepare()
        guard !hasSpunOnAppear else { return }
        hasSpunOnAppear = true
        spinWheel()
      }
      
      Button("Spin") {
        spinWheel()
      }
      .buttonStyle(ScaleButtonStyle())
      .padding()
      .disabled(choices.isEmpty)
      
      if let choice = selection {
        NavigationLink(
          destination: ResultView(choice: choice),
          isActive: .constant(true)
        ) { EmptyView() }
      }
    }
    .navigationBarTitle("Spinner", displayMode: .inline)
    .onChange(of: selection) { newValue in
      guard newValue != nil else { return }
      feedback.impactOccurred()
    }
  }
  
  private func spinWheel() {
    guard !choices.isEmpty else { return }
    selection = nil
    let extra = Double.random(in: 3...6) * 360
    spinAngle += extra
    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
      computeSelection()
    }
  }
  
  private func computeSelection() {
    guard !choices.isEmpty else { return }
    let normalized = spinAngle.truncatingRemainder(dividingBy: 360)
    let segment = 360.0 / Double(choices.count)
    let idx = Int((360 - normalized) / segment) % choices.count
    selection = choices[idx]
  }
}

// MARK: - Custom Button Style
struct ScaleButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.95 : 1)
      .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
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

