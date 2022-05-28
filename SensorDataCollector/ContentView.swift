//
//  ContentView.swift
//  SensorDataCollector
//
//  Created by Roman Mazeev on 28/05/22.
//

import SwiftUI

struct ContentView: View {
    private let motionManager = MotionManager()

    @State var framesCount: Int?
    @State var isCollecting = false

    @State var isShareSheetPresented = false
    @State var isErrorMessagePresented = false
    @State var isSharingSheetPresented = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            
            if !isCollecting {
                TextField(
                    "Frames",
                    text: Binding(
                        get: {
                            guard let framesCount = framesCount else { return "" }
                            return String(framesCount)
                        }, set: {
                            guard let intValue = Int($0) else { return }
                            framesCount = intValue
                        }
                    )
                )
                .font(.system(size: 70))
                .textFieldStyle(.automatic)
                .frame(height: 120)
                Text("Frame rate is 50")
                    .font(.footnote)
            } else {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
            
            Spacer()
            
            Button(action: {
                guard !isCollecting else { return }
    
                guard let framesCount = framesCount, framesCount > 0 else {
                    isErrorMessagePresented = true
                    return
                }

                isCollecting = true
                motionManager.getAndSaveMotions(framesCount: framesCount) { result in
                    isCollecting = false
                    switch result {
                    case .success:
                        isShareSheetPresented = true
                    case .failure(_):
                        isErrorMessagePresented = true
                    }
                }
            }, label: {
                Text("Start")
                    .frame(maxWidth: .infinity, maxHeight: 50)
                    .background(!isCollecting ? Color.teal : .gray)
                    .cornerRadius(8)
                    .foregroundColor(.white)
            })
        }
        .sheet(isPresented: $isShareSheetPresented) {
            ShareSheet(activityItems: [ URL(fileURLWithPath: motionManager.filePath) ])
        }
        .alert("Something going wrong", isPresented: $isErrorMessagePresented) {
            Button("OK", role: .cancel) { }
        }
        .padding()
        

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
