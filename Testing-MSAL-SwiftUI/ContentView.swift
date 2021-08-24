//
//  ContentView.swift
//  Testing-MSAL-SwiftUI
//
//  Created by Muhammad Khan on 8/24/21.
//

import SwiftUI

struct ContentView: View {
    
    let viewModel = MainScreenViewModel()
    
    init() {
        viewModel.initializeMSAL()
    }
    
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
                    Text(viewModel.updateLoggingText)
                        .padding()
                        .frame(width: geo.size.width, height: geo.size.width, alignment: .topLeading)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
