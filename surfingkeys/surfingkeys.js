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

api.vunmap("_h");
api.vunmap("_j");
api.vunmap("_k");
api.vunmap("_l");

api.addSearchAlias('m', 'google-maps', 'https://www.google.com/maps/search/', 's');

api.addSearchAlias('o', 'stackoverflow', 'https://stackoverflow.com/search?q=', 's');
api.unmapallexcept([], /localhost/);
