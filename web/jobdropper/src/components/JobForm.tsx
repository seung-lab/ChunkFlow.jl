import * as React from "react";
import getMuiTheme from 'material-ui/styles/getMuiTheme';
import {MuiThemeProvider, lightBaseTheme} from 'material-ui/styles';
import RaisedButton from 'material-ui/RaisedButton';
import TextField from 'material-ui/TextField';
import SelectField from 'material-ui/SelectField';
import MenuItem from 'material-ui/MenuItem';
import Divider from 'material-ui/Divider';

import {TaskTemplate} from './TaskTemplate';
import {AWSSQS} from './SQS';
//import {AWSBatch} from './Batch';

const lightMuiTheme = getMuiTheme(lightBaseTheme);

const SQS_QUEUE_NAME = 'chunkflow-inference';
//const JOB_QUEUE_NAME = 'LowPriorityBatchCloudformationJobqueue';

const styles = {
  button: {
      margin: 12,
      width: '60%'
  },
  h3: {
      marginTop: 20,
      fontWeight: 400,
  },
  pre: {overflow: 'hidden'},
  textField: {width: '80%'}
};

export class JobForm extends React.Component <any, any> {
    constructor(props: any) {
        super(props);
        this.state = {
            sqs: new AWSSQS(SQS_QUEUE_NAME),
            //batch: new AWSBatch(JOB_QUEUE_NAME, SQS_QUEUE_NAME),
            taskTemplate: new TaskTemplate(),
            start: {
                x: 1,
                y: 1,
                z: 1
            },
            stride: {
                x: 0,
                y: 0,
                z: 0
            },
            gridSize: {
                x: 1,
                y: 1,
                z: 1
            }
        };
        this.handleTaskTemplateChange = this.handleTaskTemplateChange.bind(this);
        this.handleQueueChange = this.handleQueueChange.bind(this);
        this.handleStartXChange = this.handleStartXChange.bind(this);
        this.handleStartYChange = this.handleStartYChange.bind(this);
        this.handleStartZChange = this.handleStartZChange.bind(this);
        this.handleStrideXChange = this.handleStrideXChange.bind(this);
        this.handleStrideYChange = this.handleStrideYChange.bind(this);
        this.handleStrideZChange = this.handleStrideZChange.bind(this);
        this.handleGridSizeXChange = this.handleGridSizeXChange.bind(this);
        this.handleGridSizeYChange = this.handleGridSizeYChange.bind(this);
        this.handleGridSizeZChange = this.handleGridSizeZChange.bind(this);
        this.handleSubmit = this.handleSubmit.bind(this);
    }
    handleQueueChange(event: any, index: number, newValue: string) {
        console.log("set queue name: "+ newValue);
        this.state.sqs.set_queue_name(newValue);
        this.setState({sqs: this.state.sqs});
    }
    handleTaskTemplateChange(event: any, newValue: string) {
        this.setState({taskTemplate: this.state.taskTemplate.parse(newValue)});
    }
    handleStartXChange(event: any) {
        this.setState({start: {
            x: event.target.value,
            y: this.state.start.y,
            z: this.state.start.z
        }});
    }
    handleStartYChange(event: any){
        this.setState({start: {
            x: this.state.start.x,
            y: event.target.value,
            z: this.state.start.z
        }})
    }
    handleStartZChange(event: any) {
        this.setState({start: {
            x: this.state.start.x,
            y: this.state.start.y,
            z: event.target.value
        }})
    }
    handleStrideXChange(event: any) {
        this.setState({stride: {
            x: event.target.value,
            y: this.state.stride.y,
            z: this.state.stride.z
        }})
    }
    handleStrideYChange(event: any) {
        this.setState({stride: {
            y: event.target.value,
            x: this.state.stride.x,
            z: this.state.stride.z
        }})
    }
    handleStrideZChange(event: any) {
        this.setState({stride: {
            z: event.target.value,
            x: this.state.stride.x,
            y: this.state.stride.y
        }})
    }
    handleGridSizeXChange(event: any) {
        this.setState({gridSize: {
            x: event.target.value,
            y: this.state.gridSize.y,
            z: this.state.gridSize.z
        }})
    }
    handleGridSizeYChange(event: any) {
        this.setState({gridSize: {
            y: event.target.value,
            x: this.state.gridSize.x,
            z: this.state.gridSize.z
        }})
    }
    handleGridSizeZChange(event: any) {
        this.setState({gridSize: {
            z: event.target.value,
            x: this.state.gridSize.x,
            y: this.state.gridSize.y
        }})
    }
    handleSubmit(event: any) {
        event.preventDefault();
        for(let gz: number=0; gz<this.state.gridSize.z; gz++) {
            for(let gy: number=0; gy<this.state.gridSize.y; gy++) {
                for(let gx: number=0; gx<this.state.gridSize.x; gx++){
                    // build a task message
                    let message: string = this.state.taskTemplate.stringify( [
                        this.state.start.x,
                        this.state.start.y,
                        this.state.start.z
                    ] );
                    this.state.sqs.send(message);
                    //this.state.batch.submit_job();
                }
            }
        }
    }

    render(){
        return (
            <MuiThemeProvider muiTheme={lightMuiTheme}>
            <div>
                <h3>Current Settings</h3>
                <pre>
                    start: {JSON.stringify(this.state.start)}<br/>
                    stride: {JSON.stringify(this.state.stride)}<br/>
                    gridSize: {JSON.stringify(this.state.gridSize)}<br/>
                    taskTemplate: {this.state.taskTemplate.stringify()}<br/>
                    queue name: {this.state.sqs.get_queue_name()}
                </pre>
                <SelectField floatingLabelText="queue name in AWS SQS"
                    value={this.state.sqs.get_queue_name()} onChange={this.handleQueueChange}>
                    <MenuItem value={"chunkflow-inference"} primaryText="chunkflow-inference"/>
                    <MenuItem value={"chunkflow-ingest"} primaryText="chunkflow-ingest"/>
                </SelectField>
                <pre>
                start       (x,y,z):
                <input type='number' defaultValue={this.state.start.x} onChange={this.handleStartXChange}/>
                <input type='number' defaultValue={this.state.start.y} onChange={this.handleStartYChange}/>
                <input type='number' defaultValue={this.state.start.z} onChange={this.handleStartZChange}/><br/>
                stride      (x,y,z):
                <input type='number' defaultValue={this.state.stride.x} onChange={this.handleStrideXChange}/>
                <input type='number' defaultValue={this.state.stride.y} onChange={this.handleStrideYChange}/>
                <input type='number' defaultValue={this.state.stride.z} onChange={this.handleStrideZChange}/><br/>
                grid size   (x,y,z):
                <input type='number' defaultValue={this.state.gridSize.x} onChange={this.handleGridSizeXChange}/>
                <input type='number' defaultValue={this.state.gridSize.y} onChange={this.handleGridSizeYChange}/>
                <input type='number' defaultValue={this.state.gridSize.z} onChange={this.handleGridSizeZChange}/><br/>
                </pre>
                <TextField hintText="task template formatted as JSON text"
                    value={this.state.taskTemplate.stringify()}
                    style={styles.textField}
                    floatingLabelText="task template"
                    multiLine={true}
                    rowsMax={20}
                    onChange={this.handleTaskTemplateChange}
                /><br/>
                <RaisedButton onClick = {this.handleSubmit}
                    label="Submit Tasks" primary={true} style={styles.button}/>
            </div>
            </MuiThemeProvider>
        );
    }
}
