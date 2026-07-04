//
//  DuoView.swift
//  DuetFlix
//
//  Created by Batu on 4.07.2026.
//

import SwiftUI

struct DuoView: View {
    let uid: String
    let onChangeMode: () -> Void
    
    @State private var roomService = RoomService()
    @State private var joinCode = ""
    @State private var activeCode: String?      // hangi odaya gidilecek?
    @State private var errorMessage: String?
   
    var body: some View {
        NavigationStack {
            ZStack {
                Color.umbraBackground.ignoresSafeArea()
                
                VStack(spacing: Theme.Spacing.lg) {
                    Text("Duo")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color.textPrimary)
                    
                    // Oda kurma
                    Button {
                        Task { await createRoom() }
                    } label: {
                        Text("Oda Kur")
                            .font(.headline)
                            .foregroundStyle(Color.umbraBackground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.ember, in: Capsule())
                    }
                    
                    // Odaya katılma
                    HStack {
                        TextField("Oda Kodu", text: $joinCode)
                            .keyboardType(.numberPad)
                            .padding()
                            .background(Color.umbraSurface, in: Capsule())
                            .foregroundStyle(Color.textPrimary)
                        
                        Button("Katıl") {
                            Task {await joinRoom() }
                        }
                        .foregroundStyle(Color.ember)
                    }
                    
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    Spacer()
                    
                    Button("Mod Değiştir", action: onChangeMode)
                        .foregroundStyle(Color.textSecondary)
                }
                .padding()
            }
            .navigationDestination(item: $activeCode) { code in // oda kurulunca activeCode dolar, bu dolunca da otomatik lobiye gidilir
                LobbyView(code: code, uid: uid)
            }
        }
        .tint(.ember)
    }
    
    // Oda kur -> kodu al -> lobiye geç
    private func createRoom() async {
        do {
            let code = try await roomService.createRoom(hostID: uid)
            activeCode = code
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // Odaya katıl -> lobiye geç
    private func joinRoom() async {
        let code = joinCode.trimmingCharacters(in: .whitespaces)
        guard !code.isEmpty else { return }
        
        do {
            try await roomService.joinRoom(code: code, uid: uid)
            activeCode = code
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    DuoView(uid: "123", onChangeMode: {})
}
