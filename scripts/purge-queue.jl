run(`aws sqs purge-queue --queue-url https://sqs.us-east-1.amazonaws.com/098703261575/$(ARGS[1])`)
