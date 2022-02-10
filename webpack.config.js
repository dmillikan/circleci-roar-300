const path = require("path");
const slsw = require("serverless-webpack");
const CopyPlugin = require("copy-webpack-plugin");

module.exports = {
  mode: slsw.lib.webpack.isLocal ? "development" : "production",
  optimization: {
    minimize: false,
  },
  node: {
    __dirname: false,
  },
  entry: slsw.lib.entries,
  devtool: "source-map",
  output: {
    libraryTarget: "commonjs",
    path: path.join(__dirname, ".webpack"),
    filename: "[name].js",
    sourceMapFilename: "[file].map",
  },
  target: "node",
};
