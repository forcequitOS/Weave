// Designed with ❤️ and 🤖 by Ctrl.
// Made specifically for your Mac. Try Weave Touch for your iPhone and iPad!

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

// Initializes BrowserView's variables for basic setup
struct BrowserView: View {
    @State private var webView = WKWebView()
    @State private var URLString = ""
    @State private var pageTitle = "Weave"
    @State private var faviconImage: NSImage?
    @State private var userAgent: String = {
        // All this stuff is to automatically fetch 3 key values to automatically build a user agent, the WebKit version, Safari version (based on current OS), and a default user agent given by WKWebView.
        let defaultUserAgent = WKWebView().value(forKey: "userAgent")
        let sysVersion = ProcessInfo.processInfo.operatingSystemVersion
        var safariVersion = "\(sysVersion.majorVersion + 3).\(sysVersion.minorVersion).\(sysVersion.patchVersion)"
        var webKitVersion = ""
        if let userAgentString = defaultUserAgent as? String {
            if let startIndex = userAgentString.range(of: "AppleWebKit/")?.upperBound {
                let versionSubstring = userAgentString[startIndex...]
                if let endIndex = versionSubstring.firstIndex(of: " ") ?? versionSubstring.firstIndex(of: "/") {
                    webKitVersion = String(versionSubstring[..<endIndex])
                }
            }
        }
        return "\(defaultUserAgent ?? "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/621.4.20 (KHTML, like Gecko) Weave/FallbackUserAgent") Version/\(safariVersion) Safari/\(webKitVersion)"
    }()
    
    var body: some View {
        WebView(webView: webView, pageTitle: $pageTitle, URLString: $URLString, faviconImage: $faviconImage, userAgent: $userAgent)
            .onAppear {
                print(userAgent)
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
            .toolbar (id:"toolbar"){
                
                // Back button (cmd + ←)
                ToolbarItem(id:"back", placement: .navigation) {
                    Button(action: goBack) {
                        Label("Back", systemImage: "chevron.left")
                    }
                    .help("Go back")
                    .keyboardShortcut(.leftArrow, modifiers: [.command])
                    .disabled(!webView.canGoBack)
                }
                
                // Forward button (cmd + →)
                ToolbarItem(id:"forward", placement: .navigation) {
                    Button(action: goForward) {
                        Label("Forward", systemImage: "chevron.right")
                    }
                    .help("Go forward")
                    .keyboardShortcut(.rightArrow, modifiers: [.command])
                    .disabled(!webView.canGoForward)
                }
                
                // Address Bar
                ToolbarItem(id:"address", placement: .status) {
                    TextField("Search or enter URL", text: $URLString, onCommit: loadURL)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 500) // Set a fixed width
                        .multilineTextAlignment(.center)
                        .lineLimit(1) // Limit to 1 line
                        .truncationMode(.tail) // Truncates at the end
                        .onAppear {
                            self.URLString = webView.url?.absoluteString ?? ""
                        }
                        .help("Enter a URL or search term")
                }
                
                // Refresh button (cmd + r)
                ToolbarItem(id:"refresh", placement: .navigation) {
                    Button(action: refresh) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .help("Refresh this page")
                    .keyboardShortcut("r", modifiers: [.command])
                }
                
                // Favicon display, wrapped in an HStack to avoid a stupid SwiftUI bug
                ToolbarItem(id:"favicon", placement: .navigation) {
                    HStack {
                        if let faviconImage = faviconImage {
                            // Site favicon
                            Image(nsImage: faviconImage)
                                .resizable()
                                .frame(width: 18, height: 18)
                        } else {
                            // Placeholder favicon
                            Image(systemName: "globe.americas.fill")
                                .resizable()
                                .frame(width: 18, height: 18)
                                .font(Font.title.weight(.bold))
                                    }
                                }
                            }
                
                // Spacer between address bar and Share button chunk
                ToolbarItem(id:"spacer", placement: .primaryAction) {
                    Spacer()
                }
                
                // Download button (cmd + s)
                ToolbarItem(id: "download", placement: .primaryAction, showsByDefault: false) {
                    Button(action: downloadPage) {
                        Label("Download Page", systemImage: "square.and.arrow.down")
                    }
                    .help("Download page source")
                    .keyboardShortcut("s", modifiers: [.command])
                }
                
                // Copy link button (cmd + shift + c)
                ToolbarItem(id:"copy", placement: .primaryAction, showsByDefault: false) {
                    Button(action: {
                        copyURL()
                    }) {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .help("Copy current URL to clipboard")
                    .keyboardShortcut("c", modifiers: [.command, .shift])
                }
                
                // Share button (cmd + shift + s)
                ToolbarItem(id:"share", placement: .primaryAction) {
                    Button(action: {
                        shareURL(URLString)
                    }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .help("Share this page")
                    .keyboardShortcut("s", modifiers: [.command, .shift])
                }
            }
    }

    // Sets up functions for webpage commands
    // Copies URL to clipboard
    private func copyURL() {
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(URLString, forType: .string)
    }
    
    // Goes back a page and then refreshes (to load new title and favicon data)
    private func goBack() {
        if webView.canGoBack {
            webView.goBack()
            // Adds extremely slight delay before refreshing page when navigating
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                refresh()
            }
        }
    }

    // Goes forward a page and then refreshes (to load new title and favicon data)
    private func goForward() {
        if webView.canGoForward {
            webView.goForward()
            // Adds extremely slight delay before refreshing page when navigating
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                refresh()
            }
        }
    }

    // Simply reloads webView
    private func refresh() {
        webView.reload()
    }

    // Shares URL with macOS default Share Sheet
    private func shareURL(_ URLString: String) {
        guard let url = URL(string: URLString) else {
            print("Invalid URL")
            return
        }

        let items: [Any] = [url]
        let sharingServicePicker = NSSharingServicePicker(items: items)
        
        sharingServicePicker.show(relativeTo: webView.bounds, of: webView, preferredEdge: .minY)
    }
    
    // Checks if URL is valid, if it is, it loads, if it isn't, it does not
    private func loadURL() {
        let trimmedURLString = URLString.trimmingCharacters(in: .whitespacesAndNewlines)
        // Finds final dot in string
        if let lastDotIndex = trimmedURLString.lastIndex(of: ".") {
            let afterLastDotIndex = trimmedURLString.index(after: lastDotIndex)
            // Check if there are characters following the last period
            if afterLastDotIndex < trimmedURLString.endIndex {
                // Characters following the last period, so assume it's a domain
                if let url = URL(string: addHTTPIfNeeded(trimmedURLString)) {
                    let request = URLRequest(url: url)
                    webView.load(request)
                    return
                }
            }
        }
        // No more than 1 character following final period, likely a search query
        search()
    }


    // Function to search with Google
    private func search() {
        guard let searchQuery = URLString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        if let searchURL = URL(string: "https://google.com/search?q=\(searchQuery)") {
            let request = URLRequest(url: searchURL)
            webView.load(request)
        }
    }

    // Adds https:// to URLs that don't have it
    private func addHTTPIfNeeded(_ URLString: String) -> String {
        if URLString.hasPrefix("http://") || URLString.hasPrefix("https://") {
            return URLString
        } else {
            return "https://\(URLString)"
        }
    }

    // Downloads HTML file of page source to ~/Downloads folder
    private func downloadPage() {
        webView.evaluateJavaScript("document.URL") { (result, error) in
            if let urlString = result as? String, let url = URL(string: urlString) {
                let downloadTask = URLSession.shared.downloadTask(with: url) { (location, response, error) in
                    guard let location = location else { return }
                    let documentsPath = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
                    let destinationURL = documentsPath.appendingPathComponent(response?.suggestedFilename ?? url.lastPathComponent)

                    do {
                        try FileManager.default.moveItem(at: location, to: destinationURL)
                        print("File downloaded successfully: \(destinationURL.absoluteString)")
                    } catch {
                        print("Error saving file: \(error)")
                    }
                }
                downloadTask.resume()
            }
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
