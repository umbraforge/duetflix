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
    // Bu cihaz ŞU AN oyunda (swipe ekranında) mı? (lobide olanlar false)
    private var isPlaying: Bool { viewModel.room?.playing?.contains(uid) ?? false }

    var body: some View {
        // Hangi ekran? BEN oyundaysam swipe, değilsem lobi.
        // (Her oyuncu bağımsız biri kaydırırken diğeri lobide olabilir)
        Group {
            if isPlaying {
                SwipeView(code: code, uid: uid)
            } else {
                lobbyContent
            }
        }
        // Alt bildirim baloncuğu
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
        .onAppear { viewModel.listen(code: code, uid: uid) }
        .onDisappear { viewModel.stopListening() }
        // Oda silinince (host kapatınca) karşı taraf bilgilendirilip otomatik çıkar
        .onChange(of: viewModel.roomClosed) { _, closed in
            if closed && !isLeaving {
                showToast(Lf("lobby.closed_by", viewModel.closedBy ?? "Host"))
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
                    if isPlaying {
                        // Oyundaysam → sadece lobiye dön (oda silinmez)
                        Task { await viewModel.exitToLobby(code: code, uid: uid) }
                    } else {
                        // Lobideysem → odadan çık. Fire-and-forget → anında dismiss.
                        isLeaving = true
                        viewModel.leave(code: code, uid: uid)
                        dismiss()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                }
                .accessibilityLabel(L("a11y.back"))
            }
        }
    }


    private var lobbyContent: some View {
        ZStack {
            Color.umbraBackground.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.lg) {
                Text(L("lobby.room_code"))
                    .font(.headline)
                    .foregroundStyle(Color.textSecondary)

                HStack(spacing: Theme.Spacing.md) {
                    Text(code)
                        .font(.system(size: 44, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.ember)

                    Button {
                        UIPasteboard.general.string = code
                        showToastAutoHide(L("lobby.copied"))
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.title3)
                            .foregroundStyle(Color.textSecondary)
                    }
                    .accessibilityLabel(L("a11y.copy_code"))

                    if let inviteURL = URL(string: "duetflix://join?code=\(code)") {
                        ShareLink(
                            item: inviteURL,
                            subject: Text("DuetFlix"),
                            message: Text(Lf("lobby.share_message", code))
                        ) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title3)
                                .foregroundStyle(Color.textSecondary)
                        }
                        .accessibilityLabel(L("a11y.share_room"))
                    }
                }

                Divider().overlay(Color.textSecondary.opacity(0.3))

                Text(L("lobby.participants"))
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)

                if let room = viewModel.room {
                    ForEach(room.members.sorted(by: { $0.key < $1.key }), id: \.key) { memberID, name in
                        HStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "person.fill")
                                .foregroundStyle(Color.ember)
                            Text(memberID == uid ? "\(name) \(L("lobby.you"))" : name)
                                .foregroundStyle(Color.textPrimary)
                            if memberID == room.hostID {
                                Text("(Host)")
                                    .font(.caption)
                                    .foregroundStyle(Color.textSecondary)
                            }
                            // swipe ekranında olanlara "Eşleşmede" rozeti
                            if room.playing?.contains(memberID) == true {
                                Text(L("lobby.matching"))
                                    .font(.caption2.bold())
                                    .foregroundStyle(Color.ember)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.ember.opacity(0.15), in: Capsule())
                            }
                        }
                    }
                } else {
                    ProgressView()
                }

                Spacer()

                if viewModel.room?.status == "swiping" {
                    // Oyun devam ediyor ama ben lobideyim → Oyuna Dön
                    Button {
                        Task { await viewModel.rejoin(code: code, uid: uid) }
                    } label: {
                        HStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "arrow.uturn.forward")
                            Text(L("lobby.rejoin"))
                        }
                        .font(.headline)
                        .foregroundStyle(Color.umbraBackground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.ember, in: Capsule())
                        .shadow(color: Color.ember.opacity(0.4), radius: 12, y: 4)
                    }
                    .padding(.bottom, Theme.Spacing.sm)
                } else if isHost {
                    // Oyunu başlat — sadece host, en az 2 kişi olunca aktif
                    let canStart = (viewModel.room?.members.count ?? 0) >= 2
                    Button {
                        Task { await viewModel.startGame(code: code) }
                    } label: {
                        HStack(spacing: Theme.Spacing.sm) {
                            if viewModel.isStarting {
                                ProgressView().tint(Color.umbraBackground)
                            } else {
                                Image(systemName: canStart ? "play.fill" : "hourglass")
                            }
                            Text(canStart ? L("lobby.start") : L("lobby.waiting"))
                        }
                        .font(.headline)
                        .foregroundStyle(canStart ? Color.umbraBackground : Color.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(canStart ? Color.ember : Color.umbraSurface, in: Capsule())
                        .shadow(color: canStart ? Color.ember.opacity(0.4) : .clear, radius: 12, y: 4)
                    }
                    .disabled(!canStart || viewModel.isStarting)
                    .animation(.easeInOut(duration: 0.2), value: canStart)
                    .padding(.bottom, Theme.Spacing.sm)
                }

                VStack(spacing: 4) {
                    Label(isHost ? L("lobby.info_host") : L("lobby.info_guest"),
                          systemImage: "info.circle")
                    // Odaların TTL ile otomatik silindiğini kullanıcıya bildir
                    Label(L("lobby.info_ttl"), systemImage: "clock")
                }
                .font(.caption2)
                .foregroundStyle(Color.textSecondary.opacity(0.6))
                .padding(.bottom, Theme.Spacing.sm)
            }
            .padding()
        }
    }

    private func showToast(_ message: String) {
        withAnimation { toastMessage = message }
    }

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
