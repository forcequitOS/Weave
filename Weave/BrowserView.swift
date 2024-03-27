// Designed with ❤️ and 🤖 by Ctrl.
// Made specifically for your Mac. Try Weave Touch for the iPad!

import SwiftUI
import WebKit

// Fetches Accent Color values to use within CSS code
extension NSColor {
    var hexString: String {
        guard let rgbColor = usingColorSpace(NSColorSpace.sRGB) else { return "#000000" }
        let red = Int(rgbColor.redComponent * 255.0)
        let green = Int(rgbColor.greenComponent * 255.0)
        let blue = Int(rgbColor.blueComponent * 255.0)
        return String(format: "#%02X%02X%02X", red, green, blue)
    }

    static var systemAccentColor: NSColor {
        return NSColor.controlAccentColor
    }
}

// Sets up BrowserView and does basic customizations
struct BrowserView: View {
    @State private var webView = WKWebView()
    @State private var urlString = ""
    @State private var pageTitle = "Weave"
    @State private var faviconImage: NSImage?
    @State private var userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.3.1 Safari/605.1.15"

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            WebView(webView: webView, pageTitle: $pageTitle, urlString: $urlString, faviconImage: $faviconImage, userAgent: $userAgent)
                .onAppear {
                    // CSS Style Injection
                    let sysAccent = NSColor.systemAccentColor.hexString
                    let userScript = """
                        var style = document.createElement('style');
                        style.innerHTML = `
                            body, p, h1, h2, h3, h4, h5, h6, ul, ol, li, a {
                                font-family: -apple-system !important;
                            }
                        `;
                        document.head.appendChild(style);
                    """

                    // Simplistic Adblocking Injection
                    let adBlockerScript = """
                        var adBlockStyle = document.createElement('style');
                        adBlockStyle.innerHTML = `
                            /* Hide common ad classes */
                            .ad-banner, .ad-wrapper, .ad-container, .ad, .ads, .adsense, .adslot, .ad-badge {
                                display: none !important;
                            }

                            /* Hide ads from specific URLs */
                            [href*="doubleclick.net"], [href*="googleadservices.com"], [href*="advertising.com"], [src*="adserver.com"] {
                                display: none !important;
                            }
                        `;
                        document.head.appendChild(adBlockStyle);
                    """
                    let adBlockScript = WKUserScript(source: adBlockerScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
                    webView.configuration.userContentController.addUserScript(adBlockScript)

                    let userScriptInjection = WKUserScript(source: userScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
                    webView.configuration.userContentController.addUserScript(userScriptInjection)
                }
        }
        // Toolbar and navigation stuff
        .frame(minWidth: 1000, minHeight: 600)
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: goBack) {
                    Image(systemName: "chevron.left")
                }
                .help("Go back")
            }
            
            ToolbarItem(placement: .navigation) {
                Button(action: goForward) {
                    Image(systemName: "chevron.right")
                }
                .help("Go forward")
            }
            
            ToolbarItem(placement: .primaryAction) {
                TextField("Search or enter URL", text: $urlString, onCommit: loadUrl)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 400, height: nil) // Set a fixed width
                    .multilineTextAlignment(.center)
                    .lineLimit(1) // Limit to 1 line
                    .truncationMode(.tail) // Truncates at the end
                    .onAppear {
                        self.urlString = webView.url?.absoluteString ?? ""
                    }
                    .help("Enter a URL or search term")
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: loadUrl) {
                    Image(systemName: "arrow.up.circle.fill")
                }
                .help("Begin loading page")
            }
            
            ToolbarItem(placement: .status) {
                if let faviconImage = faviconImage {
                    Image(nsImage: faviconImage)
                        .resizable()
                        .frame(width: 18, height: 18) // Size set to 18x18 for favicon
                } else {
                    Image(systemName: "link")
                        .resizable()
                        .frame(width: 18, height: 18) // Placeholder icon
                }
            }
            
            ToolbarItem(placement: .status) {
                Text(pageTitle)
                    .font(.headline)
                    .lineLimit(1)
            }
            
            ToolbarItem(placement: .status) {
                Spacer()
            }
            
            ToolbarItem(placement: .navigation) {
                Button(action: refresh) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Reload this page")
            }
        }
        .onAppear {
            if let userAgent = webView.value(forKey: "userAgent") as? String {
                self.userAgent = userAgent.replacingOccurrences(of: "Mobile", with: "Safari")
            }
            loadUrl()
        }
    }

    // Basic functions
    private func goBack() {
        if webView.canGoBack {
            webView.goBack()
        }
    }

    private func goForward() {
        if webView.canGoForward {
            webView.goForward()
        }
    }

    private func refresh() {
        webView.reload()
    }

    private func loadUrl() {
        let trimmedUrlString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedUrlString.contains(".") {
            // Contains a dot, likely a URL
            if let url = URL(string: addHttpIfNeeded(trimmedUrlString)) {
                let request = URLRequest(url: url)
                webView.load(request)
            }
        } else {
            // No dot, treat as search query
            search()
        }
    }

    private func search() {
        guard let searchQuery = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        if let searchURL = URL(string: "https://google.com/search?q=\(searchQuery)") {
            let request = URLRequest(url: searchURL)
            webView.load(request)
        }
    }

    private func addHttpIfNeeded(_ urlString: String) -> String {
        if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
            return urlString
        } else {
            return "https://\(urlString)"
        }
    }
}

struct WebView: NSViewRepresentable {
    let webView: WKWebView
    @Binding var pageTitle: String // Binding for the pageTitle
    @Binding var urlString: String // Binding for the urlString
    @Binding var faviconImage: NSImage? // Binding for the favicon image
    @Binding var userAgent: String // Binding for the user agent

    func makeNSView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        webView.customUserAgent = userAgent // Set the custom user agent
        webView.configuration.defaultWebpagePreferences.allowsContentJavaScript = true // Enable JavaScript
        webView.configuration.defaultWebpagePreferences.preferredContentMode = .desktop // Set content mode to desktop
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // Nothing to do here
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(webView: webView, pageTitle: $pageTitle, urlString: $urlString, faviconImage: $faviconImage)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        let webView: WKWebView
        @Binding var pageTitle: String // Binding for the pageTitle
        @Binding var urlString: String // Binding for the urlString
        @Binding var faviconImage: NSImage? // Binding for the favicon image

        init(webView: WKWebView, pageTitle: Binding<String>, urlString: Binding<String>, faviconImage: Binding<NSImage?>) {
            self.webView = webView
            self._pageTitle = pageTitle
            self._urlString = urlString
            self._faviconImage = faviconImage
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("document.title") { (result, error) in
                if let title = result as? String {
                    self.pageTitle = title
                    self.urlString = webView.url?.absoluteString ?? ""
                    self.loadFavicon()
                }
            }
        }

        private func loadFavicon() {
            let script = """
                var favicon = document.querySelector('link[rel="shortcut icon"]') || document.querySelector('link[rel="icon"]');
                favicon ? favicon.href : null;
            """

            // Fetches site favicon
            webView.evaluateJavaScript(script) { (result, error) in
                if let faviconURLString = result as? String, let faviconURL = URL(string: faviconURLString) {
                    URLSession.shared.dataTask(with: faviconURL) { data, _, _ in
                        if let data = data {
                            DispatchQueue.main.async {
                                self.faviconImage = NSImage(data: data)
                            }
                        }
                    }.resume()
                } else {
                    DispatchQueue.main.async {
                        self.faviconImage = nil // Set to nil if no favicon found
                    }
                }
            }
        }
    }
}

struct ContentView: View {
    var body: some View {
        BrowserView()
    }
}

struct WeaveAppCustom: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

@main
struct Weave: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
