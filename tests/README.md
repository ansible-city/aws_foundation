# Tests

## Testing on Real AWS Account

In order to run this role against real AWS account you can run

```
# get tmp creds exported to your current shell
$(make aws-sudo PROFILE=profile-name)

# run the role (playbook)
make run
```
