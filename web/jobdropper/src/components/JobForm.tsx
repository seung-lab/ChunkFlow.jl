import * as React from "react";


export class JobForm extends React.Component <any, any> {
    constructor(props: any) {
        super(props);
        this.state = {
            taskTemplate: 'task template',
            start: [1,2,3],
            gridSize: [1,2,3]
        };
        this.handleTaskTemplateChange = this.handleTaskTemplateChange.bind(this);
        this.handleStartChange = this.handleStartChange.bind(this);
        this.handleSubmit = this.handleSubmit.bind(this);
    }
    handleTaskTemplateChange(event: any) {
        this.setState({taskTemplate: event.target.taskTemplate});
    }
    handleStartChange(event: any) {
        this.setState({start: event.target.start})
    }
    handleSubmit(event: any) {
        alert('A task was submitted: ' + this.state.taskTemplate);
        alert('the start coordinate: ' + this.state.start);
        event.preventDefault();
    }

    render(){
        return (
            <form onSubmit={this.handleSubmit}>
                <label>
                    <h1>ChunkFlow Task Definition and Submition</h1>
                    <p>
                    AWS SQS queue name:
                    <select>
                        <option value="chunkflow-inference">chunkflow-inference</option>
                    </select>
                    </p>
                    < input type="text" value={this.state.start} onChange={this.handleStartChange} />
                    <p>
                    <textarea name='textarea' value={this.state.taskTemplate} onChange={this.handleTaskTemplateChange}/>
                    </p>
                </label>
                <p>
                <input type="submit" value="Submit Tasks" onSubmit={this.handleSubmit}/>
                </p>
            </form>
        );
    }
}
