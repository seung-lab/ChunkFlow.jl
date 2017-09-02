import * as React from "react";

/*interface JobDropperProps { job: string }*/

export class JobForm extends React.Component <any, any> {
    constructor(props: any) {
        super(props);
        this.state = {value: 'state_value'};
        this.handleChange = this.handleChange.bind(this);
        this.handleSubmit = this.handleSubmit.bind(this);
    }
    handleChange(event: any) {
        this.setState({value: event.target.value});
    }
    handleSubmit(event: any) {
        alert('A name was submitted: ' + this.state.value);
        event.preventDefault();
    }

    render(){
        return (
            <form onSubmit={this.handleSubmit}>
                <label>
                    ChunkFlow Task:
                    < input type="text" value={this.state.value} onChange={this.handleChange} />
                </label>
                <input type="submit" value="SubmitMe"/>
            </form>
        );
    }
}

export class JobDropper extends React.Component<{},{}> {
    render(){
        const name = "job dropper";
        return (
            <div>
                < JobForm />
                Hello, {name}!
                <button onClick={() => alert("Hello")}>
                    Click me
                </button>
            </div>
        );
    }
}
