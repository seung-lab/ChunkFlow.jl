import * as React from "react";
import {JobForm} from "./JobForm"

export class JobDropper extends React.Component<{},{}> {
    render(){
        const name = "job dropper";
        return (
            <div>
                < JobForm />
            </div>
        );
    }
}
