//
//  TrailerPlayerView.swift
//  DuetFlix
//
//  YouTube fragmanını tam ekran oynatan WKWebView sarmalayıcı (IFrame Player API).
//

import SwiftUI
import WebKit

// Tam ekran fragman oynatıcı — üstte kapatma (X) butonu, altta ekranı dolduran YouTube player.
struct TrailerPlayerView: View {
    let youtubeKey: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            YouTubeWebView(key: youtubeKey)
                .ignoresSafeArea()
        }
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .padding()
            .accessibilityLabel(L("a11y.close"))
        }
    }
}

// YouTube IFrame Player API ile gömülü oynatıcı. JS kontrolü sayesinde: video bitince
// BAŞA SARIP DURUR (loop yok, "diğer videolar" ızgarası çıkmaz) — kullanıcı isterse
// play'e basıp tekrar oynatır. Video her yönde ekran genişliğini doldurur.
private struct YouTubeWebView: UIViewRepresentable {
    let key: String

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true               // tam ekrana zorlamadan sayfada oyna
        config.mediaTypesRequiringUserActionForPlayback = []  // autoplay'e izin ver

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.allowsBackForwardNavigationGestures = false

        webView.loadHTMLString(Self.html(key: key),
                               baseURL: URL(string: "https://www.youtube-nocookie.com"))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    private static func html(key: String) -> String {
        """
        <!DOCTYPE html><html><head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          html,body{margin:0;height:100%;overflow:hidden;background:#000;}
          /* Contain (kırpmasız): 16:9 videoyu her yönde ekrana sığdır, ortala.
             Dikeyde tam genişlik (üst/alt letterbox), yatayda tam yükseklik (yanlarda
             ince siyah). Hiçbir yeri kesilmez. */
          #player{position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);
                  width:min(100vw, 177.7778vh);
                  height:min(56.25vw, 100vh);}
        </style>
        </head><body>
        <div id="player"></div>
        <script src="https://www.youtube.com/iframe_api"></script>
        <script>
          var player;
          function onYouTubeIframeAPIReady(){
            player = new YT.Player('player', {
              host: 'https://www.youtube-nocookie.com',
              videoId: '\(key)',
              playerVars: {playsinline:1, autoplay:1, rel:0, modestbranding:1,
                           fs:0, iv_load_policy:3, controls:1},
              events: {
                onReady: function(e){ e.target.playVideo(); },
                onStateChange: function(e){
                  if(e.data === YT.PlayerState.ENDED){
                    // Başa sar + poster'a dön: son ekran ızgarası çıkmaz, kullanıcı isterse oynatır
                    e.target.cueVideoById('\(key)');
                  }
                }
              }
            });
          }
        </script>
        </body></html>
        """
    }

    // Kullanıcının fragmandan dışarı (gerçek YouTube izleme/kanal sayfasına) çıkmasını engelle;
    // embed + iframe_api yüklemelerine izin ver.
    final class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            let url = navigationAction.request.url?.absoluteString ?? ""
            if url.contains("youtube.com/watch")
                || url.contains("youtu.be/")
                || url.contains("youtube.com/channel")
                || url.contains("youtube.com/@") {
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
    }
}
