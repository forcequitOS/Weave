// Designed with ❤️ and 🤖 by Ctrl.
// Made specifically for your Mac. Try Weave Touch for the iPad!

import SwiftUI
import WebKit

// Fetches Accent Color values to use within CSS code, future usage I swear.
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
    @State private var URLString = ""
    @State private var pageTitle = "Weave"
    @State private var faviconImage: NSImage?
    @State private var userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.3.1 Safari/605.1.15"

    var body: some View {
        WebView(webView: webView, pageTitle: $pageTitle, URLString: $URLString, faviconImage: $faviconImage, userAgent: $userAgent)
            .onAppear {
                // CSS Style Injection
                var sysAccent = NSColor.systemAccentColor.hexString
                let styleSheet = """
                    var style = document.createElement('style');
                    style.innerHTML = `
                        * {
                            font-family: -apple-system !important;
                        }
                    `;
                    document.head.appendChild(style);
                """

                // Extremely basic CSS Adblock Injection
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
                let adBlockInject = WKUserScript(source: adBlockerScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
                webView.configuration.userContentController.addUserScript(adBlockInject)

                let CSSInject = WKUserScript(source: styleSheet, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
                webView.configuration.userContentController.addUserScript(CSSInject)
                
                // Loads URL when app opens
                loadURL()
            }
        
            // Sets minimum sizing for window and defines toolbar title's content
            .frame(minWidth: 1000, minHeight: 600)
            .navigationTitle(pageTitle)
        
            // Toolbar with keyboard shortcuts and tooltips
            .toolbar {
                // Back button
                ToolbarItem(placement: .navigation) {
                    Button(action: goBack) {
                        Image(systemName: "chevron.left")
                    }
                    .help("Go back")
                    .keyboardShortcut(KeyEquivalent.leftArrow, modifiers: [.command])
                    .disabled(!webView.canGoBack)
                }
                
                // Forward button
                ToolbarItem(placement: .navigation) {
                    Button(action: goForward) {
                        Image(systemName: "chevron.right")
                    }
                    .help("Go forward")
                    .keyboardShortcut(KeyEquivalent.rightArrow, modifiers: [.command])
                    .disabled(!webView.canGoForward)
                }
                
                // Address Bar
                ToolbarItem(placement: .status) {
                    TextField("Search or enter URL", text: $URLString, onCommit: loadURL)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 500, height: nil) // Set a fixed width
                        .multilineTextAlignment(.center)
                        .lineLimit(1) // Limit to 1 line
                        .truncationMode(.tail) // Truncates at the end
                        .onAppear {
                            self.URLString = webView.url?.absoluteString ?? ""
                        }
                        .help("Enter a URL or search term")
                }
                
                // Refresh button
                ToolbarItem(placement: .navigation) {
                    Button(action: refresh) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help("Refresh this page")
                    .keyboardShortcut("r", modifiers: [.command])
                }
                
                // Favicon display
                ToolbarItem(placement: .navigation) {
                    if let faviconImage = faviconImage {
                        Image(nsImage: faviconImage)
                            .resizable()
                            .frame(width: 18, height: 18) // Size set to 18x18 for favicon
                    } else {
                        Image(systemName: "globe.americas.fill")
                            .resizable()
                            .frame(width: 18, height: 18) // Placeholder icon
                            .font(Font.title.weight(.bold))
                    }
                }
                
                // Spacer between address bar and next button chunk
                ToolbarItem(placement: .primaryAction) {
                    Spacer()
                }
                
                // Share button
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        shareURL(URLString)
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .help("Share this page")
                }
            }
    }

    // Sets up functions for webpage commands
    private func goBack() {
        if webView.canGoBack {
            webView.goBack()
            // Adds extremely slight delay before refreshing page when navigating
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                refresh()
            }
        }
    }

    private func goForward() {
        if webView.canGoForward {
            webView.goForward()
            // Adds extremely slight delay before refreshing page when navigating
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                refresh()
            }
        }
    }

    private func refresh() {
        webView.reload()
    }

    private func shareURL(_ URLString: String) {
        guard let url = URL(string: URLString) else {
            print("Invalid URL")
            return
        }

        let items: [Any] = [url]
        let sharingServicePicker = NSSharingServicePicker(items: items)
        
        sharingServicePicker.show(relativeTo: webView.bounds, of: webView, preferredEdge: .minY)
    }
    
    private func loadURL() {
        let trimmedURLString = URLString.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedURLString.contains(".") {
            // Contains a dot, likely a URL
            if let url = URL(string: addHttpIfNeeded(trimmedURLString)) {
                let request = URLRequest(url: url)
                webView.load(request)
            }
        } else {
            // No dot, treat as search query
            search()
        }
    }

    private func search() {
        guard let searchQuery = URLString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        if let searchURL = URL(string: "https://google.com/search?q=\(searchQuery)") {
            let request = URLRequest(url: searchURL)
            webView.load(request)
        }
    }

    private func addHttpIfNeeded(_ URLString: String) -> String {
        if URLString.hasPrefix("http://") || URLString.hasPrefix("https://") {
            return URLString
        } else {
            return "https://\(URLString)"
        }
    }
}

// I genuinely do not know

struct WebView: NSViewRepresentable {
    let webView: WKWebView
    @Binding var pageTitle: String // Binding for the pageTitle
    @Binding var URLString: String // Binding for the URLString
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
        Coordinator(webView: webView, pageTitle: $pageTitle, URLString: $URLString, faviconImage: $faviconImage)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        let webView: WKWebView
        @Binding var pageTitle: String // Binding for the pageTitle
        @Binding var URLString: String // Binding for the URLString
        @Binding var faviconImage: NSImage? // Binding for the favicon image

        init(webView: WKWebView, pageTitle: Binding<String>, URLString: Binding<String>, faviconImage: Binding<NSImage?>) {
            self.webView = webView
            self._pageTitle = pageTitle
            self._URLString = URLString
            self._faviconImage = faviconImage
        }
        
        // Sets up functions to gather webpage information to display in toolbar

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("document.title") { (result, error) in
                if let title = result as? String {
                    self.pageTitle = title
                    self.URLString = webView.url?.absoluteString ?? ""
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
