api.Hints.setCharacters('neiohtsrad');

api.map("_h",  "h");
api.map("_j",  "j");
api.map("_k",  "k");
api.map("_l",  "l");
api.map("_S",  "S");
api.map("_D",  "D");
api.map("_E",  "E");
api.map("_R",  "R");
api.map("_I",  "I");
api.map("_af", "af");

api.unmap("h");
api.unmap("j");
api.unmap("k");
api.unmap("l");
api.unmap("S");
api.unmap("D");
api.unmap("E");
api.unmap("R");
api.unmap("I");
api.unmap("af");

api.map("n", "_h");
api.map("e", "_j");
api.map("i", "_k");
api.map("o", "_l");

api.map("N", "_S");
api.map("O", "_D");

api.map("E", "_R");
api.map("I", "_E");

api.map("F", "_af");

api.unmap("_h");
api.unmap("_j");
api.unmap("_k");
api.unmap("_l");
api.unmap("_S");
api.unmap("_D");
api.unmap("_E");
api.unmap("_R");
api.unmap("_I");

api.unmapAllExcept([], /localhost/);
