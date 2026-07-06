//
//  LocalizedStrings.swift
//  DuetFlix
//
//  Tüm uygulama metinleri anahtarı (tr, en).
//  Kullanım: Text(L("mode.question"))  ·  Text(Lf("matches.count", n))  (%d/%@ yer tutucu)
//

import Foundation

typealias LocPair = (tr: String, en: String)

enum LocalizedStrings {

    static let table: [String: LocPair] = common
        .merging(tabs) { a, _ in a }
        .merging(mode) { a, _ in a }
        .merging(home) { a, _ in a }
        .merging(detail) { a, _ in a }
        .merging(discover) { a, _ in a }
        .merging(duo) { a, _ in a }
        .merging(lobby) { a, _ in a }
        .merging(swipe) { a, _ in a }
        .merging(matches) { a, _ in a }
        .merging(profile) { a, _ in a }
        .merging(a11y) { a, _ in a }

    // Common
    private static let common: [String: LocPair] = [
        "common.cancel":      ("İptal", "Cancel"),
        "common.close":       ("Kapat", "Close"),
        "common.retry":       ("Tekrar dene", "Retry"),
        "common.change_mode": ("Mod Değiştir", "Change Mode"),
        "common.remove":      ("Listeden çıkar", "Remove from list"),
        "common.delete":      ("Sil", "Delete"),
        "common.coming_soon": ("Yakında", "Coming soon"),
        "common.loading":     ("Yükleniyor", "Loading"),
        "profile.title":      ("Profil", "Profile"),
        "error.title":        ("Bir şeyler ters gitti", "Something went wrong"),
    ]

    // Tab bar
    private static let tabs: [String: LocPair] = [
        "tab.home":      ("Ana Sayfa", "Home"),
        "tab.discover":  ("Keşfet", "Discover"),
        "tab.watchlist": ("İzleme Listesi", "Watchlist"),
        "tab.profile":   ("Profil", "Profile"),
    ]

    // Mode selection
    private static let mode: [String: LocPair] = [
        "mode.question":      ("Nasıl izleyeceksin?", "How will you watch?"),
        "mode.solo.title":    ("Solo", "Solo"),
        "mode.solo.subtitle": ("Keşfet, filtrele, kaydet", "Discover, filter, save"),
        "mode.duo.title":     ("Duo", "Duo"),
        "mode.duo.subtitle":  ("Birlikte eşleş", "Match together"),
    ]

    // Home
    private static let home: [String: LocPair] = [
        "home.popular": ("Popüler", "Popular"),
        "home.mode":    ("Mod", "Mode"),
    ]

    // Detail
    private static let detail: [String: LocPair] = [
        "detail.min":            ("dk", "min"),
        "detail.where_to_watch": ("Nerede izlenir", "Where to watch"),
        "detail.cast":           ("Oyuncular", "Cast"),
        "detail.added":          ("İzleme Listesi'ne eklendi", "Added to Watchlist"),
        "detail.removed":        ("İzleme Listesi'nden çıkarıldı", "Removed from Watchlist"),
    ]

    // Search & Watchlist
    private static let discover: [String: LocPair] = [
        "search.empty.title":    ("Film ara", "Search films"),
        "search.empty.desc":     ("Bir film adı yaz", "Type a film name"),
        "watchlist.empty.title": ("Listen boş", "Your list is empty"),
        "watchlist.empty.desc":  ("Beğendiğin filmleri ❤️ ile buraya ekle", "Add films you like with ❤️"),
    ]

    // Duo
    private static let duo: [String: LocPair] = [
        "duo.your_name":      ("İsmin", "Your name"),
        "duo.name_hint":      ("İsmini gir", "Enter your name"),
        "duo.create_room":    ("Oda Kur", "Create Room"),
        "duo.room_code_hint": ("Oda Kodu", "Room Code"),
        "duo.join":           ("Katıl", "Join"),
        "duo.history":        ("Geçmiş Eşleşmeler", "Match History"),
        "duo.err.name_first": ("Önce bir isim gir", "Enter a name first"),
        "duo.err.create":     ("Oda kurulamadı", "Couldn't create room"),
        "duo.err.code_first": ("Oda kodu gir", "Enter a room code"),
        "duo.err.no_room":    ("Bu koda ait bir oda yok", "No room with that code"),
        "duo.err.name_taken": ("Bu isim odada kullanılıyor, başka bir isim seç", "That name is taken, choose another"),
        "duo.err.join":       ("Katılırken hata oluştu", "Error joining the room"),
    ]

    // Lobby
    private static let lobby: [String: LocPair] = [
        "lobby.room_code":     ("Oda Kodu", "Room Code"),
        "lobby.participants":  ("Katılımcılar", "Participants"),
        "lobby.you":           ("(Sen)", "(You)"),
        "lobby.matching":      ("Eşleşmede", "Matching"),
        "lobby.rejoin":        ("Oyuna Dön", "Rejoin Game"),
        "lobby.start":         ("Başlat", "Start"),
        "lobby.waiting":       ("Oyuncu bekleniyor…", "Waiting for a player…"),
        "lobby.info_host":     ("Odayı kapatmak için sol üstten çıkabilirsin", "Close the room from the top-left"),
        "lobby.info_guest":    ("Odadan ayrılmak için sol üstten çıkabilirsin", "Leave the room from the top-left"),
        "lobby.deleted":       ("Oda silindi", "Room deleted"),
        "lobby.copied":        ("Oda kodu kopyalandı", "Room code copied"),
        "lobby.closed_by":     ("%@ odayı kapattı", "%@ closed the room"),
        "lobby.joined":        ("%@ katıldı", "%@ joined"),
        "lobby.left":          ("%@ çıktı", "%@ left"),
        "lobby.a_player":      ("Bir oyuncu", "A player"),
        "lobby.share_message": ("DuetFlix'te odama katıl! Oda kodu: %@", "Join my room on DuetFlix! Room code: %@"),
    ]

    // Swipe + match celebration
    private static let swipe: [String: LocPair] = [
        "swipe.hint":            ("Kaydırarak ya da butonlarla beğen veya geç", "Swipe or use the buttons to like or pass"),
        "swipe.stamp_like":      ("BEĞEN", "LIKE"),
        "swipe.stamp_pass":      ("GEÇ", "NOPE"),
        "swipe.finish":          ("Bitir", "Finish"),
        "swipe.see_matches":     ("Eşleşmeleri gör (%d)", "See matches (%d)"),
        "swipe.back_to_lobby":   ("Lobiye dön", "Back to lobby"),
        "swipe.end_title":       ("Oyunu bitir?", "Finish the game?"),
        "swipe.matches_tonight": ("Bu gece için %d eşleşmeniz var.", "You have %d matches for tonight."),
        "swipe.no_matches_yet":  ("Henüz eşleşmeniz yok.", "No matches yet."),
        "swipe.deck_loading":    ("Deste yükleniyor…", "Loading deck…"),
        "swipe.all_rated":       ("Tüm filmleri değerlendirdin!", "You've rated every film!"),
        "swipe.loading_new":     ("Yeni filmler yükleniyor…", "Loading new films…"),
        "swipe.refill_error":    ("Yeni filmler yüklenemedi", "Couldn't load new films"),
        "match.title":           ("EŞLEŞTİNİZ!", "IT'S A MATCH!"),
        "match.subtitle":        ("İkiniz de bu filmi beğendiniz — bu akşamki film bu olabilir 🍿", "You both liked this film — this could be tonight's pick 🍿"),
        "match.see_details":     ("Detayları gör", "See details"),
        "match.keep_swiping":    ("Kaydırmaya devam", "Keep swiping"),
    ]

    // Matches list & history
    private static let matches: [String: LocPair] = [
        "matches.title":       ("Bu gece için", "For tonight"),
        "matches.empty.title": ("Henüz eşleşme yok", "No matches yet"),
        "matches.empty.desc":  ("İkinizin de beğendiği filmler burada toplanır", "Films you both liked collect here"),
        "matches.count":       ("İkinizin de beğendiği %d film", "%d films you both liked"),
        "matches.remove_hint": ("Bir filmi çıkarmak için üzerine basılı tut", "Press and hold a film to remove it"),
        "history.title":       ("Geçmiş Eşleşmeler", "Match History"),
        "history.empty.desc":  ("Bir Duo oyununda eşleştiğiniz filmler burada birikir", "Films you matched on in a Duo game collect here"),
        "history.duo_game":    ("Duo oyunu", "Duo game"),
    ]

    // Profile / About
    private static let profile: [String: LocPair] = [
        "profile.made_by":     ("UmbraForge tarafından", "by UmbraForge"),
        "profile.language":    ("Dil", "Language"),
        "profile.about":       ("Hakkında", "About"),
        "profile.version":     ("Sürüm", "Version"),
        "profile.data_source": ("Film verileri", "Film data"),
        "profile.tmdb_attr":   ("Bu uygulama TMDB API'sini kullanır ancak TMDB tarafından onaylanmış ya da sertifikalandırılmış değildir.",
                                "This product uses the TMDB API but is not endorsed or certified by TMDB."),
    ]

    // Accessibility (VoiceOver) — ikon-only kontroller
    private static let a11y: [String: LocPair] = [
        "a11y.pass":             ("Geç", "Pass"),
        "a11y.like":             ("Beğen", "Like"),
        "a11y.details":          ("Film detayları", "Film details"),
        "a11y.add_watchlist":    ("İzleme listesine ekle", "Add to watchlist"),
        "a11y.remove_watchlist": ("İzleme listesinden çıkar", "Remove from watchlist"),
        "a11y.copy_code":        ("Oda kodunu kopyala", "Copy room code"),
        "a11y.share_room":       ("Odayı paylaş", "Share room"),
        "a11y.back":             ("Geri", "Back"),
    ]
}
