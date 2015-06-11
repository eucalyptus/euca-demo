# Test AWS CLI with Eucalyptus Regions

### Overview
You must first setup AWS CLI to access the Eucalyptus region endpoints, described in a
separate procedure.

This page contains statements which can be used to test various aspects of the AWS CLI
against both AWS and Euca Regions. It assumes you have setup your ~/.aws/config and
~/.aws/credentials files appropriately, and have set your AWS_DEFAULT_PROFILE environment
variable to the appropriate profile.

### Unsorted
This section contains various statements which are useful but which have not been formally
sorted and documented for this page. Initially, it will act as a holding area for every
statement I try.

1. Test query language to restrict results
    This pulls the instance name and run-time state and formats as a table.

    ```bash
    aws ec2 describe-instances --query 'Reservations[].Instances[].[Tags[?Key==`Name`] | [0].Value, State.Name]' \
                               --output table
    ```
