var webpack = require('webpack');
//var process = require('process')
//const Dotenv = require('dotenv-webpack')

module.exports = {
    entry: [
        "./src/index.tsx"
    ],
    output: {
        filename: "bundle.js",
        path: __dirname + "/dist"
    },

    // Enable sourcemaps for debugging webpack's output.
    devtool: "source-map", // "dev" should be faster

    resolve: {
        // Add '.ts' and '.tsx' as resolvable extensions.
        extensions: [".ts", ".tsx", ".js", ".json"]
    },

    module: {
        rules: [
            // All files with a '.ts' or '.tsx' extension will be handled by 'awesome-typescript-loader'.
            { test: /\.tsx?$/, loader: "awesome-typescript-loader" },

            // All output '.js' files will have any sourcemaps re-processed by 'source-map-loader'.
            { enforce: "pre", test: /\.js$/, loader: "source-map-loader" }
        ]
    },
    devServer: {
        host: "127.0.0.1",
        inline:true,
        port: 80
    },

    // When importing a module whose path matches one of the following, just
    // assume a corresponding global variable exists and use that instead.
    // This is important because it allows us to avoid bundling all of our
    // dependencies, which allows browsers to cache those libraries between builds.
    externals: {
        "react": "React",
        "react-dom": "ReactDOM"
    }/*,
    plugins: [
        new Dotenv({
            path: './.env',
            safe:true
        })
    ]*/
};

// new webpack.EnvironmentPlugin(['AWS_REGION'])
//console.log(process.env.AWS_REGION);
//new webpack.DefinePlugin({
//    'process.env': {
//        'AWS_REGION': JSON.stringify(process.env.AWS_REGION)
//    }
//})
/*
new webpack.DefinePlugin({
    //AWS_REGION: JSON.stringify(process.env.AWS_REGION)
    AWS_REGION: JSON.stringify('us-east-1')
})*/

