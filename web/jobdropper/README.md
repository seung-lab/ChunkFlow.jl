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

## Elastic Beanstalk
setup the AWS Elastic Beanstalk environment, then 
```
eb init --interactive
eb deploy
```
the Docker environment will automatically use the `Dockerfile` and `Dockerrun.aws.json` to envision a EB deployment.

## set environment variables
setup AWS authorization
add these lines in `~/.bashrc` of linux, or `~/.bash_profile` of mac.
```
export AWS_ACCESS_KEY_ID=XXXXXXX
export AWS_SECRET_ACCESS_KEY=XXXXX
export AWS_ACCOUNT_ID=XXXXX 
```

## pack the libraries
```
webpack
google-chrome index.html
```
you can open `index.html` with other mordern browser too.

# Trouble Shooting
## can not find 'webpack'
`npm link webpack`

## /usr/bin/env: ‘node’: No such file or directory
use [old way of nodejs](https://github.com/animetosho/Nyuu/issues/14) 
apt-get install nodejs-legacy 
