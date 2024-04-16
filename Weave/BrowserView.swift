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
        return "\(defaultUserAgent ?? "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/621.4.20 (KHTML, like Gecko) Weave/Fallback") Version/\(safariVersion) Safari/\(webKitVersion)"
    }()
    
    // Creates a view to make the translucency effect for the window
    struct VisualEffectView: NSViewRepresentable {
        func makeNSView(context: Context) -> NSVisualEffectView {
            let effectView = NSVisualEffectView()
            effectView.state = .active
            return effectView
        }
        func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        }
    }
    
    // Primary view
    var body: some View {
        // Sets the opacity for the window (72.5% by default, 70% and 80% also work well here)
        let windowOpacity = 0.725
        // Variable binding initialization
        WebView(webView: webView, pageTitle: $pageTitle, URLString: $URLString, faviconImage: $faviconImage, userAgent: $userAgent)
        // Everything to load at app start
            .onAppear {
                // Sets accent color variables to use in CSS
                let sysAccent = NSColor.systemAccentColor.hexString
                let sysAccentDim = NSColor.systemAccentColor.blended(withFraction: 1.4, of: .black)!.hexString
                let sysAccentBright = NSColor.systemAccentColor.blended(withFraction: 0.4, of: .white)!.hexString
                // CSS Stylesheet injection for text and color styling
                let styleSheet = """
                    var style = document.createElement('style');
                    style.innerHTML = `
                    * {
                        font-family: -apple-system !important;
                        letter-spacing: 0px !important;
                    }
                
                    a {
                        color:\(sysAccent);
                        text-decoration: none !important;
                        text-decoration-color: \(sysAccent);
                        transition: 0.15s !important;
                        font-weight: 500;
                    }
                    
                    a:visited {
                        text-decoration: none !important;
                        text-decoration-color: \(sysAccentDim);
                        color:\(sysAccentDim);
                        transition: 0.25s !important;
                    }
                
                    a:link {
                        text-decoration: none !important;
                        transition: 0.25s !important;
                    }
                
                    a:hover, a:active {
                        text-decoration: none !important;
                        text-decoration-color: \(sysAccentBright);
                        color: \(sysAccentBright);
                        transition: 0.15s !important;
                        font-weight: 600;
                    }
                
                    button, input[type="button"], input[type="submit"] {
                        font-weight: 500;
                        transition: 0.15s !important;
                    }
                
                    button:hover, input[type="button"]:hover, input[type="submit"]:hover {
                        font-weight: 600;
                        transition: 0.15s !important;
                    }

                    h1 {
                        font-weight: 800 !important;
                    }
                
                    h2 {
                        font-weight: 700 !important;
                    }
                
                    h3, h4, h5, h6 {
                        font-weight: 600 !important;
                    }
                
                    sub {
                        font-weight: 300 !important;
                    }
                    `;
                    document.head.appendChild(style);
                """

                // Injecting a simple adblocker with CSS and JS, a bit more advanced than the old one.
                let adBlockerScript = """
                function findAdsInDocument() {
                    const adIDs = ["Ad","RadAd","bbccom","hbBHeaderSpon","hiddenHeaderSpon","navbar_adcode","pagelet_adbox","rightAds","rightcolumn_adcode","tracker_advertorial","adbrite","dclkAds","konaLayer","a.kLink span[id^='preLoadWrap'][class='preLoadWrap']","div[id='tooltipbox'][class^='itxt']","div[id='google_ads_div']","embed[flashvars*='AdID']","iframe[src*='clicksor.com']","img[src*='clicksor.com']","ispan#ab_pointer","#A9AdsMiddleBoxTop","#A9AdsOutOfStockWidgetTop","#A9AdsServicesWidgetTop","#Ad2","#Ad3Left","#Ad3Right","#AdBar1","#AdContainerTop","#AdHeader","#AdRectangle","#AdShowcase_F1","#AdSky23","#AdSkyscraper","#AdSponsor_SF","#AdTargetControl1_iframe","#Ad_Block","#Ad_Center1","#Ad_Top","#Adrectangle","#AdsContent","#AdsWrap","#AdvertMPU23b","#Advertorial","#BannerAdvert","#BigBoxAd","#CompanyDetailsNarrowGoogleAdsPresentationControl","#CompanyDetailsWideGoogleAdsPresentationControl","#ContentAd","#ContentAd1","#ContentAd2","#FP_Ad","#FooterAd","#FooterAdContainer","#HEADERAD","#HeaderAdsBlock","#HeroAd","#HomeAd1","#HouseAd","#Journal_Ad_125","#Journal_Ad_300","#LeftAdF1","#LeftAdF2","#PageLeaderAd","#RightSponsoredAd","#SectionAd300-250","#SidebarAdContainer","#SkyAd","#SponsoredAd","#TOP_ADROW","#TopAdPos","#VM-MPU-adspace","#VM-header-adwrap","#XEadLeaderboard","#XEadSkyscraper","#ad-160x600","#ad-250x300","#ad-300x250","#ad-300x250Div","#ad-728","#ad-banner","#ad-bottom","#ad-bottom-wrapper","#ad-footer","#ad-footprint-160x600","#ad-front-footer","#ad-front-sponsoredlinks","#ad-halfpage","#ad-label","#ad-leaderboard","#ad-leaderboard-bottom","#ad-leaderboard-top","#ad-left","#ad-lrec","#ad-medium-rectangle","#ad-middlethree","#ad-middletwo","#ad-module","#ad-mpu","#ad-placard","#ad-rectangle","#ad-righttop","#ad-side-text","#ad-skyscraper","#ad-space","#ad-splash","#ad-target","#ad-teaser","#ad-top","#ad-tower","#ad-typ1","#ad-wrap-right","#ad-wrapper1","#ad-yahoo-simple","#ad125BL","#ad125BR","#ad125TL","#ad125TR","#ad125x125","#ad160x600","#ad160x600right","#ad1Sp","#ad2Sp","#ad3","#ad300","#ad300-250","#ad300X250","#ad300x150","#ad300x250","#ad300x250Module","#ad300x60","#ad336","#ad375x85","#ad526x250","#ad600","#ad7","#ad728Wrapper","#adB","#adBadges","#adBanner120x600","#adBannerTable","#adBannerTop","#adBar","#adBlock125","#adBlocks","#adFps","#adFrame","#adHCM","#adHeader","#adHov01","#adHov02","#adHov03","#adHov04","#adHov05","#adImg","#adKona","#adLREC","#adLargeRectangle","#adLeaderboard","#adMPU","#adMRec","#adNewsRight1","#adNewsRight2","#adNewsRight3","#adRectangle","#adResult2","#adRight","#adSky","#adSky3"];

                    const allElements = [...document.querySelectorAll('*')];
                    const adElements = allElements.filter(element => {
                        const id = element.id || '';
                        const classes = element.className || '';
                        return adIDs.some(adID => {
                            const regex = new RegExp(`(^|\\s)${adID}(\\s|$)`, 'i');
                            return regex.test(id) || regex.test(classes);
                        });
                    });

                    const css = adElements.map(element => `#${element.id} { display: none !important; }`).join('\n');

                    const style = document.createElement('style');
                    style.type = 'text/css';
                    style.appendChild(document.createTextNode(css));

                    document.head.appendChild(style);
                }
                """
                
                // Actually injects scripts into webview
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
                
                // New tab button (cmd + t)
                ToolbarItem(id: "newTab", placement: .primaryAction) {
                    Button(action: newTab) {
                        Label("New Tab", systemImage: "plus")
                    }
                    .help("Open a new tab")
                    .keyboardShortcut("t", modifiers: [.command])
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
            .opacity(windowOpacity) // Sets window opacity based on windowOpacity variable declared earlier (This also allows for wallpaper tinting!)
            .background(VisualEffectView().ignoresSafeArea()) // Uses the VisualEffectView created earlier for translucent web view
    }

    // Sets up functions for webpage commands
    // Spawns a new tab within same window
    private func newTab() {
        if let currentWindow = NSApp.keyWindow,
           let windowController = currentWindow.windowController {
            windowController.newWindowForTab(nil)
            if let newWindow = NSApp.keyWindow,
               currentWindow != newWindow {
                currentWindow.addTabbedWindow(newWindow, ordered: .above)
            }
        }
    }
    
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
