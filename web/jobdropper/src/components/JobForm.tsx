import * as React from "react";
// import * as MUI from 'material-ui';
import getMuiTheme from 'material-ui/styles/getMuiTheme';
import {MuiThemeProvider, lightBaseTheme} from 'material-ui/styles';
import RaisedButton from 'material-ui/RaisedButton';
import TextField from 'material-ui/TextField';
import DropDownMenu from 'material-ui/DropDownMenu';
import MenuItem from 'material-ui/MenuItem';

const lightMuiTheme = getMuiTheme(lightBaseTheme);

const style = {
  margin: 12,
};

export class JobForm extends React.Component <any, any> {
    constructor(props: any) {
        super(props);
        this.state = {
            queue: 'chunkflow-inference',
            taskTemplate: 'task template',
            start: [1,2,3],
            gridSize: [1,2,3]
        };
        this.handleTaskTemplateChange = this.handleTaskTemplateChange.bind(this);
        this.handleStartChange = this.handleStartChange.bind(this);
        this.handleSubmit = this.handleSubmit.bind(this);
    }
    handleQueueChange(event: any, index: number, value: string) {
        alert('queue name: ' + value);
        this.setState({queue: {value}});
    }
    handleTaskTemplateChange(event: any) {
        this.setState({taskTemplate: event.target.taskTemplate});
    }
    handleStartChange(event: any) {
        this.setState({start: event.target.start});
    }
    handleSubmit(event: any) {
        alert('A task was submitted: ' + this.state.taskTemplate);
        alert('the start coordinate: ' + this.state.start);
        alert('the queue: ' + this.state.queue);
        event.preventDefault();
    }

    render(){
        return (
            <MuiThemeProvider muiTheme={lightMuiTheme}>
            <div>
                AWS Queue Name: <br/>
                <DropDownMenu value={this.state.queue} onChange={this.handleQueueChange}>
                    <MenuItem value={"chunkflow-inference"} primaryText="chunkflow-inference"/>
                    <MenuItem value={"chunkflow-ingest"} primaryText="chunkflow-ingest"/>
                </DropDownMenu><br/>
                <TextField hintText="task template"
                    floatingLabelText={this.state.taskTemplate}
                    multiLine={true}
                    onChange={this.handleTaskTemplateChange}
                /><br/>
                <RaisedButton onClick = {this.handleSubmit}
                    label="Submit Tasks" primary={true} style={style}/>
            </div>
            </MuiThemeProvider>
        );
    }
}
