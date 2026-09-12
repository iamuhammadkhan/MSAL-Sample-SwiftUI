//
//  ContentView.swift
//  Testing-MSAL-SwiftUI
//
//  Created by Muhammad Khan on 8/24/21.
//

import SwiftUI

struct ContentView: View {

    // @StateObject, not `let`: SwiftUI has to own the object and subscribe to
    // its publisher, or changes to `loggingText` never reach the view. A plain
    // `let` compiles and silently gives you a log panel that never updates.
    @StateObject private var viewModel = MainScreenViewModel()
    
    var body: some View {
        VStack {
            VStack {
                Text("Microsoft Authentication Library").padding(.top, 25)
                Text("B2C Sample").padding()
                
                Button(action: {
                    viewModel.startAuthorization()
                }, label: {
                    Text("Authorize")
                })
                .padding(.bottom, 12)
                
                Button(action: {
                    viewModel.editProfile()
                }, label: {
                    Text("Edit Profile")
                })
                .padding(.bottom, 12)
                
                Button(action: {
                    viewModel.refreshToken()
                }, label: {
                    Text("Refresh Token")
                })
                .padding(.bottom, 12)
                
                Button(action: {
                    viewModel.callApi()
                }, label: {
                    Text("Call API")
                })
                .padding(.bottom, 12)
                
                Button(action: {
                    viewModel.performLogout()
                }, label: {
                    Text("Logout")
                })
            }
            
            VStack(alignment: .leading) {
                Text("Logging").padding()
                GeometryReader { geo in
                    Text(viewModel.loggingText)
                        .padding()
                        .frame(width: geo.size.width, height: geo.size.width, alignment: .topLeading)
                }
            }
        }
        .onAppear {
            viewModel.initializeMSAL()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
