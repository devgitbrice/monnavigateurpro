import SwiftUI
import WebKit

#if os(macOS)
struct WebViewWrapper: NSViewRepresentable {
    let tab: Tab
    let onNavigationChange: (URL?, String?) -> Void

    func makeNSView(context: Context) -> WKWebView {
        tab.webView.navigationDelegate = context.coordinator
        tab.webView.uiDelegate = context.coordinator
        return tab.webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(tab: tab, onNavigationChange: onNavigationChange)
    }
}
#else
struct WebViewWrapper: UIViewRepresentable {
    let tab: Tab
    let onNavigationChange: (URL?, String?) -> Void

    func makeUIView(context: Context) -> WKWebView {
        tab.webView.navigationDelegate = context.coordinator
        tab.webView.uiDelegate = context.coordinator
        return tab.webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(tab: tab, onNavigationChange: onNavigationChange)
    }
}
#endif

extension WebViewWrapper {
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let tab: Tab
        let onNavigationChange: (URL?, String?) -> Void
        private var progressObservation: NSKeyValueObservation?
        private var titleObservation: NSKeyValueObservation?
        private var urlObservation: NSKeyValueObservation?
        private var loadingObservation: NSKeyValueObservation?
        private var canGoBackObservation: NSKeyValueObservation?
        private var canGoForwardObservation: NSKeyValueObservation?

        init(tab: Tab, onNavigationChange: @escaping (URL?, String?) -> Void) {
            self.tab = tab
            self.onNavigationChange = onNavigationChange
            super.init()
            setupObservers()
        }

        private func setupObservers() {
            progressObservation = tab.webView.observe(\.estimatedProgress) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.tab.estimatedProgress = webView.estimatedProgress
                }
            }

            titleObservation = tab.webView.observe(\.title) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    if let title = webView.title, !title.isEmpty {
                        self?.tab.title = title
                    }
                }
            }

            urlObservation = tab.webView.observe(\.url) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.tab.url = webView.url
                    self?.onNavigationChange(webView.url, webView.title)
                }
            }

            loadingObservation = tab.webView.observe(\.isLoading) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.tab.isLoading = webView.isLoading
                }
            }

            canGoBackObservation = tab.webView.observe(\.canGoBack) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.tab.canGoBack = webView.canGoBack
                }
            }

            canGoForwardObservation = tab.webView.observe(\.canGoForward) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.tab.canGoForward = webView.canGoForward
                }
            }
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            tab.isLoading = true
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            tab.isLoading = false
            tab.url = webView.url
            if let title = webView.title, !title.isEmpty {
                tab.title = title
            }
            onNavigationChange(webView.url, webView.title)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            tab.isLoading = false
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            tab.isLoading = false
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }
    }
}
