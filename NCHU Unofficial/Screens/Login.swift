//
//  Login.swift
//  NCHU Unofficial
//
//  Created by 郭家駿 on 2026/6/27.
//

import SwiftUI

enum Field {
    case username, password
}

struct Login: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @FocusState private var focusedField: Field?
    @State var backgroundColor = UIColor(named: "BackgroundColor") ?? UIColor.systemBackground
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var loginManager: LoginService
    @Binding var showAlert: Bool

    var isDarkMode: Bool {
        colorScheme == .dark ? true : false
    }
    
    var body: some View {
        ZStack {
            Color(backgroundColor)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    focusedField = nil
                }
            VStack {
                Image(isDarkMode ? "IconDark" : "Icon")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .clipShape(.rect(cornerRadius: 10))
                    .padding(.bottom, 30)
                
                inputArea
                    .padding(.bottom, 15)
                    
                Button {
                    login()
                } label: {
                    HStack {
                        Spacer()
                        HStack {
                            if loginManager.isLoggingIn {
                                ProgressView()
                                    .tint(.white)
                                Text("Logging in...")
                            } else {
                                Text("Login")
                                Image(systemName: "arrowshape.right.circle.fill")
                            }
                        }
                        .font(.title3)
                        .padding(8)
                        .foregroundStyle(.white)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .buttonStyle(.plain)
                .disabled(username.isEmpty || password.isEmpty || loginManager.isLoggingIn)
                Spacer()
            }
            .padding(.horizontal, 50)
            .padding(.vertical, 40)
            
            if let errorMessage = loginManager.loginErrorMessage {
                VStack(spacing: 15) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.largeTitle)
                    Text("Login Failed")
                        .font(.headline)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        loginManager.loginErrorMessage = nil
                        login()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(40)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
            }
            
            
        }
        .alert("Password Change Required", isPresented: $showAlert) {
            Button("OK", role: .cancel) {
                showAlert = false
            }
        } message: {
            Text("Passwword change notification detected. It is recommended to change your password.")
        }
    }
    
    
    private var inputArea: some View {
        VStack(spacing: 0) {
            FloatingLabelField(title: "Username", text: $username, isSecure: false, focusBinding: $focusedField, field: .username)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            
            Divider()
                .background(Color.gray.opacity(0.5))
                
            FloatingLabelField(title: "Password", text: $password, isSecure: true, focusBinding: $focusedField, field: .password)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .background(Color(isDarkMode ? .elementBackground : .white))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .contentShape(Rectangle())
        .onTapGesture {
            focusedField = nil
        }
    }
    
    private func login() {
        focusedField = nil
        
        let saved = CredentialHelper.shared.saveCredentials(username: username, password: password)
        
        if saved {
            print("Credentials saved successfully")
            loginManager.startCAS()
        } else {
            print("Failed to save credentials")
            loginManager.loginErrorMessage = "Failed to save credentials"
        }
    }
    
    
}

private struct FloatingLabelField: View {
    let title: String
    @Binding var text: String
    var isSecure: Bool
    var focusBinding: FocusState<Field?>.Binding
    let field: Field
    private var isFocused: Bool {
        focusBinding.wrappedValue == field
    }
    private var isFloating: Bool {
        !text.isEmpty || isFocused
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            Text(title)
                .foregroundStyle(.gray)
                .font(isFloating ? .caption : .body)
                .offset(y: isFloating ? -22 : -7)
                .animation(.easeInOut(duration: 0.2), value: isFloating)
            
            Group {
                if isSecure {
                    SecureField("", text: $text)
                } else {
                    TextField("", text: $text)
                }
            }
            .focused(focusBinding, equals: field)
        }
        .padding(.top, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            focusBinding.wrappedValue = field
        }
    }
}

#Preview {
    Login(showAlert: .constant(false))
        .environmentObject(DataManager())
        .environmentObject(LoginService())
}
