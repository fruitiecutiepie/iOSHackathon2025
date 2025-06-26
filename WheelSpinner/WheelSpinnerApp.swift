import SwiftUI
import UIKit

@main
struct WheelSpinnerApp: App {
  @State private var showSplash = true
  var body: some Scene {
    WindowGroup {
      if showSplash {
        SplashScreenView()
          .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
              withAnimation {
                showSplash = false
              }
            }
          }
      } else {
        ChoiceListView()
      }
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
  
  // Configuration for how many checked items are required/allowed when spinning
  @Published var minSelectable = 2
  @Published var maxSelectable = 10

  var canAdd: Bool { true }

  // Number of checked items (selected for spinning)
  var checkedCount: Int { choices.filter { $0.isChecked }.count }
  
  // The wheel can spin when the checked count is within the configured bounds
  var canSpin: Bool {
    let checkedItems = choices.filter { $0.isChecked }
    let count = checkedItems.count
    guard count >= minSelectable && count <= maxSelectable else { return false }
    return checkedItems.allSatisfy {
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

  enum FocusedField: Hashable {
    case search
    case choice(id: UUID)
  }
  @FocusState private var focusedField: FocusedField?

  private var filteredIndices: [Int] {
    viewModel.choices.indices.filter { idx in
      let text = viewModel.choices[idx].text.lowercased()
      return searchText.isEmpty || text.contains(searchText.lowercased())
    }
  }

  private func addChoice() {
    if let id = viewModel.addChoice() {
      focusedField = .choice(id: id)
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
          .focused($focusedField, equals: .search)
        
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
                  .focused($focusedField, equals: .choice(id: viewModel.choices[idx].id))
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
      .onTapGesture {
        focusedField = nil
      }
      .background(Color.white.opacity(0.85))
      .background(Color.white)
      .toolbar {
        ToolbarItem(placement: .bottomBar) {
          NavigationLink(destination: SpinnerWheelView(choices: viewModel.choices.filter { $0.isChecked }.map { $0.text })) {
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
      .navigationTitle("What to Eat?")
      .toolbar {
        ToolbarItem(placement: .bottomBar) {
          NavigationLink(destination: SpinnerWheelView(
            choices: viewModel.choices.filter { $0.isChecked }.map { $0.text }
          )) {
            Text("Spin").bold()
          }
          .disabled(!viewModel.canSpin)
          .opacity(viewModel.canSpin ? 1 : 0.5)
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
        Text("What to Eat Tonight?")
          .padding(.top, 8)
          .font(.system(size: 30, weight: .bold))
        
        Text("🎯Give it a spin and let fate decide")
          .padding(.top, 0)
        Text("")
          .padding(.top, 20)
        
        Group {
          
          if let result = selection {
            Text(result)
              .font(.system(size: 40, weight: .bold))
              .padding(.horizontal, 32)
              .padding(.vertical, 20)
              .background(Color.white.opacity(0.95))
              .cornerRadius(16)
              .shadow(color: .gray.opacity(0.5), radius: 6, x: 0, y: 4)
              .transition(.scale) // optional: animate appearance
          } else {
            Text("Spin the Wheel")
              .font(.headline)
              .foregroundColor(.secondary)
          }
        }
        
        ZStack {
          // White circular board background
          Circle()
            .fill(Color.white)
            .frame(width: 320, height: 320) // Slightly larger than the wheel
            .shadow(radius: 4)
          
          Wheel(choices: choices)
            .frame(width: 300, height: 300)
            .fixedSize() // Ensures layout stays consistent
            .rotationEffect(.degrees(spinAngle), anchor: .center)
            .animation(.easeOut(duration: 3), value: spinAngle)
            .drawingGroup()
          
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
          .fill(
            AngularGradient(
              gradient: Gradient(colors: [
                [.mint.opacity(0.3), .blue.opacity(0.3)],
                [.orange.opacity(0.3), .pink.opacity(0.3)],
                [.purple.opacity(0.3), .indigo.opacity(0.3)],
                [.teal.opacity(0.3), .yellow.opacity(0.3)],
                [.cyan.opacity(0.3), .green.opacity(0.3)]
              ][i % 5]), // repeat every 5 segments
              center: .center,
              startAngle: .radians(step * Double(i) - .pi/2),
              endAngle: .radians(step * Double(i + 1) - .pi/2)
            )
          )
          
          
          Text(choices[i])
            .font(.system(size: 18, weight: .bold))
          
            .rotationEffect(.radians(step * (Double(i) + 0.5) - .pi / 2)) // Match wheel arc
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
}
