//
//  LobbyView.swift
//  DuetFlix
//
//  Created by Batu on 4.07.2026.
//

import SwiftUI
import UIKit   // UIPasteboard (kopyalama) için

struct LobbyView: View {
    let code: String
    let uid: String
    @State private var viewModel = LobbyViewModel()
    @State private var toastMessage: String?
    @State private var isLeaving = false   // ayrılan/kapatan ben miyim (kendi roomClosed toast'ımı gösterme)
    @Environment(\.dismiss) private var dismiss

    // Bu cihaz host mu?
    private var isHost: Bool { viewModel.room?.hostID == uid }

    var body: some View {
        ZStack {
            Color.umbraBackground.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.lg) {
                Text("Oda Kodu")
                    .font(.headline)
                    .foregroundStyle(Color.textSecondary)

                HStack(spacing: Theme.Spacing.md) {
                    Text(code)
                        .font(.system(size: 44, weight: .bold, design: .monospaced)) // monospaced kodlar için kullanılır genelde
                        .foregroundStyle(Color.ember)

                    Button {
                        UIPasteboard.general.string = code   // panoya kopyala
                        showToastAutoHide("Oda kodu kopyalandı")
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.title3)
                            .foregroundStyle(Color.textSecondary)
                    }

                    // Sistem paylaş sayfasıyla oda linkini gönder (tıklanınca uygulama açılıp katılır)
                    if let inviteURL = URL(string: "duetflix://join?code=\(code)") {
                        ShareLink(
                            item: inviteURL,
                            subject: Text("DuetFlix"),
                            message: Text("DuetFlix'te odama katıl! Oda kodu: \(code)")
                        ) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title3)
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                }

                Divider().overlay(Color.textSecondary.opacity(0.3))

                Text("Katılımcılar")
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)

                if let room = viewModel.room {
                    // map'i uid'ye göre sıralı göster
                    ForEach(room.members.sorted(by: { $0.key < $1.key }), id: \.key) { memberID, name in
                        HStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "person.fill")
                                .foregroundStyle(Color.ember)
                            Text(memberID == uid ? "\(name) (Sen)" : name)
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

                // kullanıcı ve host için küçük bilgilendirme
                Label(isHost ? "Odayı kapatmak için sol üstten çıkabilirsin"
                             : "Odadan ayrılmak için sol üstten çıkabilirsin",
                      systemImage: "info.circle")
                    .font(.caption2)
                    .foregroundStyle(Color.textSecondary.opacity(0.6))
                    .padding(.bottom, Theme.Spacing.sm)
            }
            .padding()
        }
        // oda silinince toast
        .overlay(alignment: .bottom) {
            if let toastMessage {
                Text(toastMessage)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.umbraBackground)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.ember, in: Capsule())
                    .padding(.bottom, 60)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sensoryFeedback(.impact, trigger: toastMessage)
        .onAppear { viewModel.listen(code: code, uid: uid) } // ekran açılınca dinlemeye başla
        .onDisappear { viewModel.stopListening() } // ekrandan çıkınca dinlemeyi bırak
        // Host odayı silince misafir bilgilendirilip otomatik çıkar
        .onChange(of: viewModel.roomClosed) { _, closed in
            // Sadece karşı taraf (kapatmayan) bu bildirimi görsün
            if closed && !isLeaving {
                showToast("\(viewModel.closedBy ?? "Host") odayı kapattı")
                Task {
                    try? await Task.sleep(for: .seconds(1.3))
                    dismiss()
                }
            }
        }
        // Katılan/çıkan olunca kısa bildirim
        .onChange(of: viewModel.eventMessage) { _, message in
            if let message { showToastAutoHide(message) }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    Task {
                        let wasHost = isHost                            // ayrılmadan önce host muyum?
                        isLeaving = true                                // ben ayrılıyorum → kendi roomClosed toastım çıkmasın
                        await viewModel.leave(code: code, uid: uid)     // önce odadan çık
                        if wasHost {
                            showToast("Oda silindi")                    // host'a bildir
                            try? await Task.sleep(for: .seconds(1.3))
                        }
                        dismiss()                                       // sonra ekranı kapat
                    }
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
        }
    }

    private func showToast(_ message: String) {
        withAnimation { toastMessage = message }
    }

    // Katıl/çık bildirimi göster, 2 sn sonra kendiliğinden gizle
    private func showToastAutoHide(_ message: String) {
        withAnimation { toastMessage = message }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation { toastMessage = nil }
        }
    }
}

#Preview {
    LobbyView(code: "1232", uid: "1233")
}
