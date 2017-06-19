
## Produce tasks using the web console (recommended)

directly visit [web console](http://130.211.134.112:5555/)


### find help

    julia taskproducer.jl -h

### produce some tasks

    julia taskproducer.jl -t pinky.5.reomnify.json -a pinky-omni -o 10241,16385,4003 -s 1536,1536,0 -g 17,16,1


> make sure that the `Message Retention Period` in your SQS queue is longer than your computation time. The default is 4 days and the maximum is 14 days.

> make sure that the `Default Visibility Timeout` is longer than the computation time of one task, so the task will not be done twice.

