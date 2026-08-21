/* eslint-disable no-undef */

function parseOffHeader(text) {
  var lines = text.split("\n");
  var i = 0;

  // skip to OFF keyword
  while (i < lines.length && lines[i].trim() !== "OFF") i++;
  i++; // skip OFF line

  // skip empty lines
  while (i < lines.length && lines[i].trim() === "") i++;

  var counts = lines[i].trim().split(/\s+/).map(Number);
  return { numVertices: counts[0], numFaces: counts[1] };
}

self.onmessage = async function () {
  try {
    self.postMessage({ progress: "Loading OpenSCAD module..." });
    var mod = await import("/wasm/openscad.js");

    self.postMessage({ progress: "Initializing OpenSCAD WASM..." });
    var instance = await mod.default({
      noInitialRun: true,
      locateFile: function (path) {
        if (path.endsWith(".wasm")) return "/wasm/openscad.wasm";
        return path;
      },
    });

    self.postMessage({ progress: "Downloading assets..." });
    var results = await Promise.all([
      fetch("/scad/pampanet_card.scad").then(function (r) { return r.text(); }),
      fetch("/scad/qr.scad").then(function (r) { return r.text(); }),
      fetch("/fonts/LiberationSans-Bold.ttf").then(function (r) { return r.arrayBuffer(); }),
      fetch("/fonts/fonts.conf").then(function (r) { return r.text(); }),
    ]);

    var scadSrc = results[0];
    var qrSrc = results[1];
    var fontData = results[2];
    var fontsConf = results[3];
    var inlinedScad = scadSrc.replace("include <qr.scad>", qrSrc);

    var fs = instance.FS;
    fs.mkdirTree("/scad");
    fs.mkdirTree("/fonts");
    fs.mkdirTree("/tmp/fontconfig");

    var env = instance.ENV;
    env.HOME = "/tmp";
    env.FONTCONFIG_PATH = "/fonts";
    env.FONTCONFIG_FILE = "/fonts/fonts.conf";
    env.OPENSCAD_FONT_PATH = "/fonts";

    fs.writeFile("/fonts/fonts.conf", fontsConf);
    fs.writeFile("/fonts/LiberationSans-Bold.ttf", new Uint8Array(fontData));
    fs.writeFile("/scad/pampanet_card.scad", inlinedScad);

    self.postMessage({ progress: "Rendering with colors..." });
    instance.callMain([
      "/scad/pampanet_card.scad",
      "--backend=manifold",
      "--export-format=off",
      "-o", "/output.off",
    ]);

    self.postMessage({ progress: "Reading output..." });
    var offText = fs.readFile("/output.off", { encoding: "utf8" });

    self.postMessage({ off: offText });
  } catch (err) {
    self.postMessage({
      error: err instanceof Error ? err.message : String(err),
    });
  }
};
