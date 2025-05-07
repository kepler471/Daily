//
//  TaskStackView.swift
//  Daily
//
//  Created using Claude Code.
//

import SwiftUI
import SwiftData

struct TaskStackView: View {
    // Data source
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [Task]
    
    // Stack configuration
    var verticalOffset: CGFloat
    var offsetByIndex: ((Int) -> CGFloat)?
    var scaleByIndex: ((Int) -> CGFloat)?
    var scaleAmount: CGFloat
    
    /// Initialize with a constant vertical offset and optional scale
    init(verticalOffset: CGFloat = 20, scale: CGFloat = 1.0) {
        self.verticalOffset = verticalOffset
        self.offsetByIndex = nil
        self.scaleByIndex = nil
        self.scaleAmount = scale
        
        _tasks = Query(sort: [
            SortDescriptor(\Task.order, order: .forward),
            SortDescriptor(\Task.createdAt, order: .forward)
        ])
    }
    
    /// Initialize with a function mapping index to offset and optional scale
    init(offsetByIndex: @escaping (Int) -> CGFloat, scale: CGFloat = 1.0) {
        self.verticalOffset = 0 // Not used in this initialization
        self.offsetByIndex = offsetByIndex
        self.scaleByIndex = nil
        self.scaleAmount = scale
        
        _tasks = Query(sort: [
            SortDescriptor(\Task.order, order: .forward),
            SortDescriptor(\Task.createdAt, order: .forward)
        ])
    }
    
    /// Initialize with functions for both offset and scale
    init(offsetByIndex: @escaping (Int) -> CGFloat, scaleByIndex: @escaping (Int) -> CGFloat) {
        self.verticalOffset = 0 // Not used in this initialization
        self.offsetByIndex = offsetByIndex
        self.scaleByIndex = scaleByIndex
        self.scaleAmount = 1.0 // Not used in this initialization
        
        _tasks = Query(sort: [
            SortDescriptor(\Task.order, order: .forward),
            SortDescriptor(\Task.createdAt, order: .forward)
        ])
    }
    
    var body: some View {
        ZStack {
            ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                TaskCardView(task: task) {
                    task.isCompleted.toggle()
                }
                // Handle vertical offset based on initialization method
                .offset(y: calculateYOffset(for: index))
                // Apply scaling effect
                .scaleEffect(calculateScale(for: index))
                // Ensure proper stacking with z-index
                .zIndex(Double(tasks.count - index))
            }
        }
        .padding()
    }
    
    /// Calculate the Y offset for a card at the given index
    private func calculateYOffset(for index: Int) -> CGFloat {
        if let offsetByIndex = offsetByIndex {
            // Use the offset function if provided
            return offsetByIndex(index)
        } else {
            // Use the constant offset multiplied by index
            return verticalOffset * CGFloat(index)
        }
    }
    
    /// Calculate the scale for a card at the given index
    private func calculateScale(for index: Int) -> CGFloat {
        if let scaleByIndex = scaleByIndex {
            // Use the scaling function if provided
            return scaleByIndex(index)
        } else {
            // Apply linear scaling based on index and scale amount
            // The formula ensures that the first card (index 0) has scale 1.0,
            // and each subsequent card is scaled down by a factor proportional to scaleAmount
            let baseScale = 1.0
            let scaleFactor = scaleAmount
            let numberOfCards = CGFloat(tasks.count)
            
            // No scaling if scale amount is 1.0
            if scaleFactor == 1.0 {
                return 1.0
            }
            
            // Otherwise, scale down for deeper cards in the stack
            // Ensure we don't scale below 0.5
            return max(baseScale - (baseScale - scaleFactor) * CGFloat(index) / max(1, numberOfCards - 1), 0.5)
        }
    }
}

// MARK: - Previews

#Preview("Scalar") {
    TaskStackView(verticalOffset: 20)
        .frame(height: 600)
        .padding()
        .modelContainer(TaskMockData.createPreviewContainer())
}

#Preview("Log") {
    TaskStackView(offsetByIndex: { i in
        return CGFloat(60 * pow(0.2 * Double(i), 0.5))
    })
        .frame(height: 600)
        .padding()
        .modelContainer(TaskMockData.createPreviewContainer())
}

#Preview("With Scale") {
    TaskStackView(verticalOffset: 20, scale: 0.85)
        .frame(height: 600)
        .padding()
        .modelContainer(TaskMockData.createPreviewContainer())
}

#Preview("Log with Scale") {
    TaskStackView(
        offsetByIndex: { i in
            return CGFloat(60 * pow(0.2 * Double(i), 0.5))
        },
        scaleByIndex: { i in
            // Scale from 1.0 down to 0.7 based on index
            return 1.0 - CGFloat(i) * 0.05
        }
    )
    .frame(height: 600)
    .padding()
    .modelContainer(TaskMockData.createPreviewContainer())
}

#Preview("Interactive") {
    TaskStackAdjustablePreview()
        .modelContainer(TaskMockData.createPreviewContainer())
}

/// An interactive preview wrapper for TaskStackView that allows real-time adjustment with sliders
struct TaskStackAdjustablePreview: View {
    // Slider parameters
    @State private var baseValue: Double = 40
    @State private var exponent: Double = 0.7
    @State private var offset: Double = 2
    @State private var formula: OffsetFormula = .exponential
    
    // Scale parameters
    @State private var useScale: Bool = false
    @State private var scaleValue: Double = 0.85
    @State private var useCustomScale: Bool = false
    @State private var scaleMin: Double = 0.7
    
    enum OffsetFormula: String, CaseIterable, Identifiable {
        case linear = "Linear"
        case exponential = "Exponential"
        case logarithmic = "Logarithmic"
        case squareRoot = "Square Root"
        case power = "Power Function"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Formula picker - Top section
            VStack {
                Text("Stack Formula")
                    .font(.headline)
                    .padding(.top, 8)
                
                Picker("Formula", selection: $formula) {
                    ForEach(OffsetFormula.allCases) { formula in
                        Text(formula.rawValue).tag(formula)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.bottom, 4)
            }
            .background(Color.secondary.opacity(0.05))
            
            // Parameter sliders - Middle section with fixed height
            VStack {
                // Offset parameters
                VStack(spacing: 12) {
                    // Always visible base value slider
                    HStack {
                        Text("Offset Base:")
                            .frame(width: 100, alignment: .leading)
                        
                        Text("\(baseValue, specifier: "%.1f")")
                            .frame(width: 50)
                        
                        Slider(value: $baseValue, in: 10...100, step: 1)
                    }
                    
                    // Formula-specific parameters
                    if formula != .linear {
                        HStack {
                            Text("\(formulaExponentLabel):")
                                .frame(width: 100, alignment: .leading)
                            
                            Text("\(exponent, specifier: "%.2f")")
                                .frame(width: 50)
                            
                            Slider(value: $exponent, in: getExponentRange().0...getExponentRange().1, step: 0.01)
                        }
                    }
                    
                    if formula == .logarithmic || formula == .squareRoot {
                        HStack {
                            Text("Offset:")
                                .frame(width: 100, alignment: .leading)
                            
                            Text("\(offset, specifier: "%.1f")")
                                .frame(width: 50)
                            
                            Slider(value: $offset, in: 1...20, step: 0.5)
                        }
                    }
                }
                
                Divider()
                    .padding(.vertical, 6)
                
                // Scale parameters
                VStack(spacing: 10) {
                    Toggle("Enable Scaling", isOn: $useScale)
                        .padding(.horizontal)
                    
                    if useScale {
                        Toggle("Custom Scale Function", isOn: $useCustomScale)
                            .padding(.horizontal)
                        
                        if useCustomScale {
                            HStack {
                                Text("Min Scale:")
                                    .frame(width: 100, alignment: .leading)
                                
                                Text("\(scaleMin, specifier: "%.2f")")
                                    .frame(width: 50)
                                
                                Slider(value: $scaleMin, in: 0.5...0.95, step: 0.01)
                            }
                        } else {
                            HStack {
                                Text("Scale Factor:")
                                    .frame(width: 100, alignment: .leading)
                                
                                Text("\(scaleValue, specifier: "%.2f")")
                                    .frame(width: 50)
                                
                                Slider(value: $scaleValue, in: 0.7...0.98, step: 0.01)
                            }
                        }
                    }
                }
            }
            .frame(height: 190) // Fixed height for the controls section
            .padding(.horizontal)
            
            // Code representation - Bottom section
            VStack {
                Text("Generated Code")
                    .font(.subheadline)
                    .padding(.top, 8)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.1))
                    
                    Text(generateCodeText())
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                }
                .frame(height: 80)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .background(Color.secondary.opacity(0.05))
            
            Divider()
            
            // TaskStackView with dynamic parameters
            if useScale {
                if useCustomScale {
                    TaskStackView(
                        offsetByIndex: offsetFunction,
                        scaleByIndex: customScaleFunction
                    )
                    .frame(minHeight: 380)
                } else {
                    TaskStackView(
                        offsetByIndex: offsetFunction,
                        scale: CGFloat(scaleValue)
                    )
                    .frame(minHeight: 380)
                }
            } else {
                TaskStackView(offsetByIndex: offsetFunction)
                    .frame(minHeight: 380)
            }
        }
        .padding(.vertical)
    }
    
    // Generate the offset function based on selected formula and parameters
    private var offsetFunction: (Int) -> CGFloat {
        return { index in
            switch self.formula {
            case .linear:
                return -self.baseValue * CGFloat(index)
                
            case .exponential:
                return -self.baseValue * pow(CGFloat(self.exponent), CGFloat(index))
                
            case .logarithmic:
                return -self.baseValue * (log2(CGFloat(index) + CGFloat(self.offset)) - log2(CGFloat(index) + 1))
                
            case .squareRoot:
                return -self.baseValue * (sqrt(CGFloat(index) + CGFloat(self.offset)) - sqrt(CGFloat(index)))
                
            case .power:
                return -self.baseValue / pow(CGFloat(index) + CGFloat(self.exponent), CGFloat(self.exponent))
            }
        }
    }
    
    // Generate a custom scale function that scales cards from 1.0 to min scale
    private var customScaleFunction: (Int) -> CGFloat {
        return { index in
            // Linear scaling from 1.0 down to minimum scale
            return max(1.0 - CGFloat(index) * 0.05, CGFloat(self.scaleMin))
        }
    }
    
    // Get the appropriate exponent range based on formula
    private func getExponentRange() -> (Double, Double) {
        switch formula {
        case .exponential: return (0.5, 0.99)
        case .power: return (0.5, 2.0)
        case .logarithmic: return (1.1, 3.0)
        case .squareRoot: return (0.1, 1.0)
        default: return (0.5, 1.0)
        }
    }
    
    // Get the exponent label based on the formula
    private var formulaExponentLabel: String {
        switch formula {
        case .exponential: return "Base"
        case .power: return "Power"
        case .logarithmic: return "Log Factor"
        case .squareRoot: return "Root Factor"
        default: return "Factor"
        }
    }
    
    // Generate the full code representation based on current settings
    private func generateCodeText() -> String {
        var code = "TaskStackView(\n"
        
        // Add offset function
        code += "    offsetByIndex: \(getOffsetFunctionText())"
        
        // Add scale if enabled
        if useScale {
            if useCustomScale {
                code += ",\n    scaleByIndex: \(getScaleFunctionText())"
            } else {
                code += ",\n    scale: \(String(format: "%.2f", scaleValue))"
            }
        }
        
        code += "\n)"
        return code
    }
    
    // Get the offset function code representation
    private func getOffsetFunctionText() -> String {
        switch formula {
        case .linear:
            return "{ index in -\(String(format: "%.1f", baseValue)) * CGFloat(index) }"
            
        case .exponential:
            return "{ index in -\(String(format: "%.1f", baseValue)) * pow(\(String(format: "%.2f", exponent)), CGFloat(index)) }"
            
        case .logarithmic:
            return "{ index in -\(String(format: "%.1f", baseValue)) * (log2(CGFloat(index) + \(String(format: "%.1f", offset))) - log2(CGFloat(index) + 1)) }"
            
        case .squareRoot:
            return "{ index in -\(String(format: "%.1f", baseValue)) * (sqrt(CGFloat(index) + \(String(format: "%.1f", offset))) - sqrt(CGFloat(index))) }"
            
        case .power:
            return "{ index in -\(String(format: "%.1f", baseValue)) / pow(CGFloat(index) + \(String(format: "%.2f", exponent)), \(String(format: "%.2f", exponent))) }"
        }
    }
    
    // Get the scale function code representation
    private func getScaleFunctionText() -> String {
        return "{ index in max(1.0 - CGFloat(index) * 0.05, \(String(format: "%.2f", scaleMin))) }"
    }
}
