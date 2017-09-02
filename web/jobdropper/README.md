# Installation
this is a standard [typescript + react + webpack](https://www.typescriptlang.org/docs/handbook/react-&-webpack.html) configuration
```
npm install -g webpack
npm install --save react react-dom @types/react @types/react-dom
npm install --save-dev typescript awesome-typescript-loader source-map-loader
# for hot reload
npm install webpack-dev-server --save-dev
```

# Usage

```
webpack
google-chrome index.html
```
you can open `index.html` with other mordern browser too.

# Trouble Shooting
## can not find 'webpack'
`npm link webpack`
