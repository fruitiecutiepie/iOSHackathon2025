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



// LIST ITEM

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
                    Text("Choose your Cravings")
                        .font(.system(size: 30, weight: .bold)) // Customize font, size
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding(.top, 24)
                        .padding(.bottom, 12)
                    
                    Text("Trust the wheel. It has great taste.")
                        .font(.system(size: 12, weight: .bold)).italic() // Customize font, size
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding(.top, -2)
                        .padding(.bottom, 12)
                    
                    Button(action: addChoice) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Add Choice")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .padding(.bottom, 10)
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
                                        .font(.system(size: 26))
                                        .foregroundColor(.blue)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    TextField("Choice", text: $viewModel.choices[idx].text)
                                        .focused($focusedItemId, equals: viewModel.choices[idx].id)
                                        .onSubmit { viewModel.moveToTop(at: idx) }
                                        .padding(10)
                                        .fontWeight(.semibold)
                                        .background(Color.white.opacity(0.6))
                                        .cornerRadius(6)
                                }
                                .listRowSeparator(.hidden)
                                //.listRowBackground(Color.clear) // clear bg for each row
                                .padding(.vertical, -10)
                                .padding()
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: gradientColor(for: idx)),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(12)
                                // .shadow(color: .gray.opacity(0.3), radius: 3, x: 0, y: 1)
                                .padding(.horizontal,10)
                                .padding(.vertical, -4.8)
                            }
                            .onDelete(perform: viewModel.delete)
                        }
                        .listStyle(.plain)
                        
                        
                    }
                    
                    if !viewModel.canSpin {
                        Text("Enter at least \(viewModel.minChoices) non-empty choices to spin.")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .padding(.bottom, 8)
                    }
                }
                .background(Color.white.opacity(0.85)) // optional, to slightly cover images behind for readability
                
                // .navigationTitle("What to Eat?")
                .background(Color.white)
                .toolbar {
                    ToolbarItem(placement: .bottomBar) {
                        NavigationLink(destination: SpinnerWheelView(choices: viewModel.choices.map { $0.text })) {
                            Text("Spin the Wheel")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 16)
                                .padding(20)
                                .padding(.horizontal,40)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue.opacity(1), Color.blue.opacity(1.5), Color.blue.opacity(1)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(100)
                                .padding(.horizontal)
                        }
                        .disabled(!viewModel.canSpin)
                        .opacity(viewModel.canSpin ? 1 : 0.9)
                        .padding(.top, 25)
                    }
                }
            
        }
    }
    private func gradientColor(for index: Int) -> [Color] {
      let gradients: [[Color]] = [
        [.mint.opacity(0.3), .blue.opacity(0.3)],
        [.orange.opacity(0.3), .pink.opacity(0.3)],
        [.purple.opacity(0.3), .indigo.opacity(0.3)],
        [.teal.opacity(0.3), .yellow.opacity(0.3)],
        [.cyan.opacity(0.3), .green.opacity(0.3)]
      ]
      return gradients[index % gradients.count]
    }

  private func addChoice() {
    if let newId = viewModel.addChoice() {
      focusedItemId = newId
    }
  }

}


// SPIN WHEEL SCREEN

struct SpinnerWheelView: View {
  let choices: [String]
  @State private var spinAngle: Double = 0
  @State private var selection: String? = nil
  @State private var hasSpunOnAppear = false
  private let feedback = UIImpactFeedbackGenerator(style: .light)
  
  var body: some View {
    VStack(spacing: 20) {
      // Result displayed above the wheel
      Group {
        if let result = selection {
          Text(result)
            .font(.title)
            .bold()
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.8))
            .cornerRadius(12)
            .shadow(radius: 4)
        } else {
          Text("Spin the Wheel")
            .font(.headline)
            .foregroundColor(.secondary)
        }
      }
      
      ZStack {
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
        
        // Wheel segments
        Wheel(choices: choices)
          .rotationEffect(.degrees(spinAngle))
          .animation(.easeOut(duration: 3), value: spinAngle)
          .frame(width: 300, height: 300)
        
        // Arrow indicator
        Arrow()
      }
      
      // Spin button
      Button(action: spinWheel) {
        Text("Spin")
          .font(.headline)
          .padding()
          .frame(maxWidth: .infinity)
          .background(choices.isEmpty ? Color.gray.opacity(0.5) : Color.accentColor)
          .foregroundColor(.white)
          .cornerRadius(12)
      }
      .buttonStyle(ScaleButtonStyle())
      .disabled(choices.isEmpty)
    }
    .padding()
    .onAppear {
      feedback.prepare()
      guard !hasSpunOnAppear else { return }
      hasSpunOnAppear = true
      spinWheel()
    }
    .onChange(of: selection) { new in
      if new != nil { feedback.impactOccurred() }
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

// MARK: - Wheel Shape
struct Wheel: View {
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
          .font(.caption)
          .position(
            x: center.x + cos(step * (Double(i) + 0.5) - .pi/2) * (r * 0.7),
            y: center.y + sin(step * (Double(i) + 0.5) - .pi/2) * (r * 0.7)
          )
      }
    }
  }
}

// MARK: - Arrow Indicator
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
    p.move(to: CGPoint(x: rect.midX, y: rect.maxY))          // Bottom center
    p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))       // Top right
    p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))       // Top left
    p.closeSubpath()
    return p
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
