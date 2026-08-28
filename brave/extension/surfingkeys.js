api.Hints.setCharacters('neiohtsrad');

api.unmap('m');

api.unmap('af');

api.unmap('ab');

api.mapkey("n", "Scroll left",  () => { api.Normal.scroll("left"); });
api.mapkey("e", "Scroll down",  () => { api.Normal.scroll("down"); });
api.mapkey("i", "Scroll up",    () => { api.Normal.scroll("up"); });
api.mapkey("o", "Scroll right", () => { api.Normal.scroll("right"); });

api.mapkey("N", "Go back in history",    () => { history.go(-1); });
api.mapkey("O", "Go forward in history", () => { history.go(1); });

api.mapkey("E", "Next tab",     () => { api.RUNTIME("nextTab"); });
api.mapkey("I", "Previous tab", () => { api.RUNTIME("previousTab"); });

api.mapkey("F", "Open link in new tab", () => { api.Hints.create("", api.Hints.dispatchMouseClick, {tabbed: true, active: true}); })
//api.mapkey("f", "Open link", () => { api.Hints.create("", api.Hints.dispatchMouseClick); });
//api.mapkey("f", "Open link", () => { api.Hints.create("", api.Hints.dispatchMouseClick, {tabbed: false, active: true}); })
api.mapkey("f", "Open link in current tab", () => {
    api.Hints.create("", (element) => {
        // strip the target attribute to prevent forced new tabs/windows
        if (element.hasAttribute('target')) {
            element.removeAttribute('target');
        }
        // now click on the link normally
        api.Hints.dispatchMouseClick(element);
    });
});

api.vmap("_h",  "h");
api.vmap("_j",  "j");
api.vmap("_k",  "k");
api.vmap("_l",  "l");
api.vmap("_e",  "e");

api.vunmap("h");
api.vunmap("j");
api.vunmap("k");
api.vunmap("l");
api.vunmap("e");

api.vmap("n",  "_h");
api.vmap("e",  "_j");
api.vmap("i",  "_k");
api.vmap("o",  "_l");
api.vmap("l",  "_e");
//api.vmap("<ArrowLeft>",  "_h");
//api.vmap("<ArrowDown>",  "_j");
//api.vmap("<ArrowUp>",    "_k");
//api.vmap("<ArrowRight>", "_l");

api.vunmap("_h");
api.vunmap("_j");
api.vunmap("_k");
api.vunmap("_l");
api.vunmap("_e");

api.addSearchAlias('m', 'google-maps', 'https://www.google.com/maps/search/', 's');

api.addSearchAlias('o', 'stackoverflow', 'https://stackoverflow.com/search?q=', 's');

api.mapkey('ss', 'Search current Startpage query on Google', function() {
    // get query string
    let googleUrl = 'https://www.google.com/search?q=' + document.querySelector("#q").value;
    // redirect to Google search page
    window.location.href = googleUrl;
});

if (window.location.host === 'music.youtube.com') {

    api.mapkey('t', 'Focus search bar on YouTube Music', function() {
        // click the search icon to reveal the search bar
        let searchBtn = document.querySelector('ytmusic-search-box button');
        if (searchBtn) {
            searchBtn.click();
            setTimeout(() => {
                let input = document.querySelector('ytmusic-search-box input');
                if (input) {
                    input.focus();
                }
            }, 300); // slight delay to allow DOM to update
        }
    });

    api.mapkey('s', 'Toggle Save/Remove Album in YouTube Music', function() {
        let saveBtn = document.querySelector(
            'button[aria-label="Save to library"],' +
            'button[aria-label="Added to library"],' +
            'button[aria-label="Remove from library"]'
        );

        if (saveBtn) {
            saveBtn.click();
        } else {
            api.Front.showPopup('Save/Remove button not found.');
        }
    });

    api.mapkey('h', 'Go to Home', function() {
        // find all sidebar items
        let items = document.querySelectorAll('tp-yt-paper-item.style-scope.ytmusic-guide-entry-renderer');

        // filter "Home" and click on it
        for (let item of items) {
            let titleElem = item.querySelector('yt-formatted-string.title');
            if (titleElem && titleElem.textContent.trim() === 'Home') {
                item.click();
                return;
            }
        }
        api.Front.showPopup('Home button not found.');
    });

    api.mapkey('l', 'Go to Library', function() {
        // find all sidebar items
        let items = document.querySelectorAll('tp-yt-paper-item.style-scope.ytmusic-guide-entry-renderer');

        // filter "Library" and click on it
        for (let item of items) {
            let titleElem = item.querySelector('yt-formatted-string.title');
            if (titleElem && titleElem.textContent.trim() === 'Library') {
                item.click();
                return;
            }
        }
        api.Front.showPopup('Library button not found.');
    });

}

// unmap the default "yy" behavior to prevent conflicts
api.unmap('yy');

// map "yy" to our custom URL cleaner function
api.mapkey('yy', 'Copy current page URL (Cleaned for AliExpress)', function() {
    let currentUrl = window.location.href;

    try {
        let urlObj = new URL(currentUrl);
        // check if we are on an AliExpress domain
        if (urlObj.hostname.endsWith("aliexpress.com")) {
            // change any subdomain (like "pt.") to "www."
            urlObj.hostname = "www.aliexpress.com";
            // remove all tracking and query parameters (everything after "?")
            urlObj.search = "";
            // update the URL string with our clean version
            currentUrl = urlObj.toString();
        }
    } catch(e) {
        // if URL parsing fails, we gracefully fall back to the raw URL
        console.error("Surfingkeys: URL parsing error", e);
    }
    // copy the final string to the clipboard
    api.Clipboard.write(currentUrl);
    // show a visual banner confirming what was copied
    api.Front.showBanner("Copied: " + currentUrl);
});

// map ",p" to open local PDF.js via Python proxy
api.mapkey(',p', 'Open Arxiv paper in local PDF.js', function() {
    const currentUrl = window.location.href;
    // match the arxiv ID from the /abs/ URL
    const arxivRegex = /arxiv\.org\/abs\/([^/?#]+)/;
    const match = currentUrl.match(arxivRegex);

    if (match && match[1]) {
        const paperId = match[1];
        const pdfUrl = `https://arxiv.org/pdf/${paperId}.pdf`;
        // tell the Python server to fetch the PDF
        const proxyUrl = `http://localhost:8080/proxy?url=${encodeURIComponent(pdfUrl)}`;
        // tell the local viewer to open the proxied URL
        const finalUrl = `http://localhost:8080/web/viewer.html?file=${encodeURIComponent(proxyUrl)}`;
        api.tabOpenLink(finalUrl);
    } else {
        api.Front.showBanner("Not on an Arxiv /abs/ page!");
    }
}, {domain: /arxiv\.org/i});

// map "gA" to open arXiv pages (abstract or PDF) in the HTML ar5iv version
api.mapkey('gA', 'Read arXiv paper in HTML (ar5iv)', function() {
    let url = window.location.href;
    // swap arxiv.org for ar5iv.org
    let htmlUrl = url.replace("arxiv.org", "ar5iv.org");
    // if in a PDF page, also change "/pdf/" to "/abs/" so the HTML loads correctly
    htmlUrl = htmlUrl.replace("/pdf/", "/abs/").replace(".pdf", "");
    // open in current tab
    window.location.href = htmlUrl
    // open in a new tab
    //api.tabOpenLink(htmlUrl);
}, {domain: /arxiv\.org/i});

if (window.location.hostname.includes('campinas.com.br')) {
    const unblockCopy = () => {
        // force CSS to allow text selection and mouse events everywhere
        let style = document.createElement('style');
        style.innerHTML = '* { user-select: text !important; -webkit-user-select: text !important; pointer-events: auto !important; }';
        document.documentElement.appendChild(style);
        // intercept and stop anti-copy event listeners in the capture phase
        const events = ['copy', 'contextmenu', 'selectstart', 'dragstart', 'cut', 'paste'];
        events.forEach(event => {
            document.addEventListener(event, e => e.stopPropagation(), true);
        });
    };
    // run immediately, and run again once the DOM is fully loaded in case the site applies restrictions late
    unblockCopy();
    document.addEventListener('DOMContentLoaded', unblockCopy);
}

// map <Alt-t> to toggle Dark Mode in local PDF.js
api.mapkey('<Alt-t>', 'Toggle PDF Dark Mode', function() {
    let styleId = 'pdfjs-dark-mode';
    let existingStyle = document.getElementById(styleId);

    // if dark mode is active, remove the CSS (switch to light)
    if (existingStyle) {
        existingStyle.remove();
        api.Front.showBanner("PDF Light Mode");
    }
    // if dark mode is inactive, inject the CSS (switch to dark)
    else {
        let style = document.createElement('style');
        style.id = styleId;
        style.innerHTML = `
            /* invert the actual PDF canvas and text, then fix the color hues */
            .pdfViewer .page {
                filter: invert(100%) hue-rotate(180deg) !important;
            }
            /* darken the gray backdrop behind the pages */
            body, #viewerContainer {
                background-color: #121212 !important;
            }
            /* (optional) slightly dim the paper to reduce eye strain */
            .pdfViewer .page canvas {
                opacity: 0.9 !important;
            }
        `;
        document.head.appendChild(style);
        api.Front.showBanner("PDF Dark Mode");
    }
}, {domain: /localhost/i});

// tag the window title when on the local PDF.js viewer
if (window.location.href.includes("localhost:8080/web/viewer.html")) {
    const modifyTitle = () => {
        if (document.title && !document.title.includes("[pdfjs]")) {
            document.title = "[pdfjs] " + document.title;
        }
    };
    // run immediately
    modifyTitle();
    // PDF.js changes the title dynamically when the PDF loads, so keep tracking it
    const titleNode = document.querySelector('title');
    if (titleNode) {
        new MutationObserver(modifyTitle).observe(titleNode, { childList: true });
    }
}

api.mapkey('b', 'Bookmarks Omnibar', () => {
    const tag = "[omnibar_bookmarks] ";

    if (!document.title.startsWith(tag)) document.title = tag + document.title;
    api.Front.openOmnibar({type: "Bookmarks"});

    clearInterval(window.skbTimer);
    let opened = false, wait = 0;

    window.skbTimer = setInterval(() => {
        let el = document.activeElement;

        // if the Surfingkeys anonymous DIV has focus:
        if (el && el.tagName === 'DIV' && el.shadowRoot) {
            opened = true; wait = 0;
            if (!document.title.startsWith(tag)) document.title = tag + document.title.replace(tag, '');
        }
        // if focus is lost (closed) or it fails to load after 2 seconds:
        else if (opened || ++wait > 40) {
            document.title = document.title.replace(tag, '');
            clearInterval(window.skbTimer);
        }
    }, 50);
});

settings.theme = `
    /* Main Background & Text */
    .sk_theme {
        background: #1a1b26 !important;
        color: #a9b1d6 !important;
    }

    /* Omnibar Input Area */
    .sk_theme input {
        color: #c0caf5 !important;
    }
    #sk_omnibarSearchArea {
        border-bottom: 1px solid #292e42 !important;
    }

    /* Search Results List */
    .sk_theme #sk_omnibarSearchResult ul li:nth-child(odd) {
        background: #16161e !important;
    }
    .sk_theme #sk_omnibarSearchResult ul li.focused {
        background: #283457 !important;
        border-radius: 4px !important;
    }

    /* Result Text Styling */
    .sk_theme .title {
        color: #c0caf5 !important;
    }
    .sk_theme .url {
        color: #7aa2f7 !important;
    }
    /* Hide folder paths, timestamps, and the star icon */
    .sk_theme .omnibar_folder,
    .sk_theme .omnibar_timestamp,
    .sk_theme #sk_omnibarSearchResult .icon {
        display: none !important;
    }
    .sk_theme .omnibar_highlight {
        color: #e0af68 !important;
    }

    /* Hints (Link Markers) */
    #sk_hints > div {
        background: #e0af68 !important;
        color: #1a1b26 !important;
        border: 1px solid #e0af68 !important;
        font-weight: bold !important;
    }

    /* Popup / Banners */
    #sk_banner, #sk_keystroke {
        background: #1a1b26 !important;
        color: #a9b1d6 !important;
        border: 1px solid #292e42 !important;
    }
`;

//api.unmapAllExcept([], /localhost/);

api.unmap("c", /youtube.com/);

settings.blocklistPattern = /localhost:5000\d\/lab/;
