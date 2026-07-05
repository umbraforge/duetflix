//
//  DuoView.swift
//  DuetFlix
//
//  Created by Batu on 4.07.2026.
//

import SwiftUI
import SwiftData   // .modelContainer(AppDatabase.shared) için

struct DuoView: View {
    let uid: String
    var initialCode: String? = nil    // deep link'ten gelen oda kodu (varsa)
    let onChangeMode: () -> Void

    @State private var roomService = RoomService()
    @State private var joinCode = ""
    @State private var activeCode: String?      // hangi odaya gidilecek?
    @State private var toastMessage: String?
    @State private var myName = ""              // kullanıcı kendi ismini girer
    @State private var isBusy = false           // kur/katıl sürerken çift tıkı önle
    @State private var showHistory = false      // geçmiş eşleşmeler sheet'i

    private enum Field { case name, code }
    @FocusState private var focusedField: Field?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.umbraBackground.ignoresSafeArea()
                    .onTapGesture { focusedField = nil }   // boşluğa dokununca klavye kapansın

                VStack(spacing: Theme.Spacing.lg) {
                    Text("Duo")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color.textPrimary)

                    // İsim girişi
                    VStack(alignment: .leading, spacing: 6) {
                        Text("İsmin")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                        TextField("İsmini gir", text: $myName)
                            .focused($focusedField, equals: .name)
                            .submitLabel(.done)
                            .padding()
                            .background(Color.umbraSurface, in: Capsule())
                            .foregroundStyle(Color.textPrimary)
                    }

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
                    .disabled(isBusy)                       // çift tık koruması

                    // Odaya katılma
                    HStack {
                        TextField("Oda Kodu", text: $joinCode)
                            .keyboardType(.numberPad)
                            .focused($focusedField, equals: .code)
                            .padding()
                            .background(Color.umbraSurface, in: Capsule())
                            .foregroundStyle(Color.textPrimary)

                        Button("Katıl") {
                            Task { await joinRoom() }
                        }
                        .foregroundStyle(Color.ember)
                        .disabled(isBusy)                   // çift tık koruması
                    }

                    Spacer()

                    // Geçmiş eşleşmeler (kalıcı, oturumlara gruplu)
                    Button { showHistory = true } label: {
                        Label("Geçmiş Eşleşmeler", systemImage: "clock.arrow.circlepath")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.ember)
                    }

                    Button("Mod Değiştir", action: onChangeMode)
                        .foregroundStyle(Color.textSecondary)
                }
                .padding()
            }
            // Alttan çıkan bildirim
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
            // Deep linkten gelen kodu oda kutusuna doldur
            .onAppear { if let initialCode { joinCode = initialCode } }
            .onChange(of: initialCode) { _, new in if let new { joinCode = new } }
            .navigationDestination(item: $activeCode) { code in // activeCode dolunca otomatik lobiye gidilir
                LobbyView(code: code, uid: uid)
            }
            .sheet(isPresented: $showHistory) {
                MatchHistoryView()
                    .modelContainer(AppDatabase.shared)   // sheete SwiftData deposunu ver
            }
        }
        .tint(.ember)
    }

    // Oda kur -> kodu al -> lobiye geç
    private func createRoom() async {
        guard !isBusy else { return }               // zaten işlemdeyse tekrar başlatma
        focusedField = nil                          // klavyeyi kapat
        let name = myName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { showToast("Önce bir isim gir"); return }
        isBusy = true
        defer { isBusy = false }                    // fonksiyon biterken kilidi aç
        do {
            let code = try await roomService.createRoom(hostID: uid, hostName: name)
            activeCode = code
        } catch {
            showToast("Oda kurulamadı")
        }
    }

    // Odaya katıl -> lobiye geç
    private func joinRoom() async {
        guard !isBusy else { return }
        focusedField = nil                          // klavyeyi kapat
        let name = myName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { showToast("Önce bir isim gir"); return }
        let code = joinCode.trimmingCharacters(in: .whitespaces)
        guard !code.isEmpty else { showToast("Oda kodu gir"); return }
        isBusy = true
        defer { isBusy = false }
        do {
            // Oda var mı?
            guard let room = try await roomService.fetchRoom(code: code) else {
                showToast("Bu koda ait bir oda yok"); return
            }
            // Bu isim odada kullanılıyor mu? (büyük/küçük harf duyarsız)
            let taken = room.members.values.contains { $0.lowercased() == name.lowercased() }
            guard !taken else {
                showToast("Bu isim odada kullanılıyor, başka bir isim seç"); return
            }
            try await roomService.joinRoom(code: code, uid: uid, name: name)
            activeCode = code
        } catch {
            showToast("Katılırken hata oluştu")
        }
    }

    // Alttan çıkan bildirim göster, 2 sn sonra gizle
    private func showToast(_ message: String) {
        withAnimation { toastMessage = message }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation { toastMessage = nil }
        }
    }
}

#Preview {
    DuoView(uid: "123", onChangeMode: {})
}
