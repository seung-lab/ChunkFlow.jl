import * as React from "react";
import * as ReactDOM from "react-dom";

import { JobDropper } from "./components/JobDropper"

import { } from 'dotenv/config';

document.title = "ChunkFlow"
ReactDOM.render(
    <JobDropper />,
    document.getElementById("example")
);

/* this is for react hot reload
if (module.hot) {
    module.host.accept('./components/JobDropper.ts', ()=>{
        const NextJobDropper = require('./components/JobDropper.ts').default;
        ReactDOM.render(<NextJobDropper />, document.getElementById('example'));
    })
}
*/
