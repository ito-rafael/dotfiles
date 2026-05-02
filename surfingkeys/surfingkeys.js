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

api.mapkey("f", "Open link", () => { api.Hints.create("", api.Hints.dispatchMouseClick, {tabbed: false, active: true}); })
api.mapkey("F", "Open link in new tab", () => { api.Hints.create("", api.Hints.dispatchMouseClick, {tabbed: true, active: true}); })

api.vmap("_h",  "h");
api.vmap("_j",  "j");
api.vmap("_k",  "k");
api.vmap("_l",  "l");

api.vunmap("h");
api.vunmap("j");
api.vunmap("k");
api.vunmap("l");

api.vmap("n",  "_h");
api.vmap("e",  "_j");
api.vmap("i",  "_k");
api.vmap("o",  "_l");
//api.vmap("<ArrowLeft>",  "_h");
//api.vmap("<ArrowDown>",  "_j");
//api.vmap("<ArrowUp>",    "_k");
//api.vmap("<ArrowRight>", "_l");

api.vunmap("_h");
api.vunmap("_j");
api.vunmap("_k");
api.vunmap("_l");

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
            Front.showPopup('Save/Remove button not found.');
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
        Front.showPopup('Home button not found.');
    });
api.unmapallexcept([], /localhost/);
