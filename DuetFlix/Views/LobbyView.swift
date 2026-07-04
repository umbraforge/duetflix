//
//  LobbyView.swift
//  DuetFlix
//
//  Created by Batu on 4.07.2026.
//

import SwiftUI

struct LobbyView: View {
    let code: String
    let uid: String
    @State private var viewModel = LobbyViewModel()
    
    
    var body: some View {
        ZStack {
            Color.umbraBackground.ignoresSafeArea()
            
            VStack(spacing: Theme.Spacing.lg) {
                Text("Oda Kodu")
                    .font(.headline)
                    .foregroundStyle(Color.textSecondary)
                
                Text(code)
                    .font(.system(size: 44, weight: .bold, design: .monospaced)) // monospaced kodlar için kullanılır genelde
                    .foregroundStyle(Color.ember)
                
                Divider().overlay(Color.textSecondary.opacity(0.3))
                
                Text("Katılımcılar")
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                
                if let room = viewModel.room {
                    ForEach(room.members, id: \.self) { memberID in
                        HStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "person.fill")
                                .foregroundStyle(Color.ember)
                            Text(memberID == uid ? "Sen" : "Oyuncu")
                                .foregroundStyle(Color.textPrimary)
                            if memberID == room.hostID {
                                Text("(Host)")
                                    .font(.caption)
                                    .foregroundStyle(Color.textSecondary)
                            }
                        }
                    }
                } else { // oda yokken veri gelene kadar yükleniyor ekranı
                    ProgressView()
                }
                
                Spacer()
            }
            .padding()
        }
        .onAppear { viewModel.listen(code: code) } // ekran açılınca dinlemeye başla
        .onDisappear { viewModel.stopListening() } // ekrandan çıkınca dinlemeyi bırak
    }
}

#Preview {
    LobbyView(code: "1232", uid: "1233")
}
