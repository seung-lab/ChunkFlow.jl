import * as React from "react";
import * as ReactDOM from "react-dom";

import { JobDropper } from "./components/JobDropper"

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
