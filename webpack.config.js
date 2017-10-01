var webpack = require('webpack');
var path = require('path');

var BUILD_DIR = path.resolve(__dirname, 'assets/js/');
var APP_DIR = path.resolve(__dirname, '_client/src');

var config = {
  entry: APP_DIR + '/events.jsx',
  output: {
    path: BUILD_DIR,
    filename: 'events.js'
  },
  module: {
    loaders: [
      {
        test: /\.jsx?$/,
        loader: "babel-loader",
        include : APP_DIR,
        query: { presets: ["es2015", "react"] }
      }
    ]
  },
  exclude: /node_modules/
};

module.exports = config; 
