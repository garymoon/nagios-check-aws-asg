nagios-check-aws-asg
====================

A nagios check for monitoring the status of an AutoScaling group

Usage
-----
    Usage: check_aws_asg [options]
            --groups group[,group]       which ASG do you wish to report on?
            --stack stack                which stack do you wish to report on?
            --tags tag,[tag]             which tag(s) do you wish to report on?
        -k, --key key                    specify your AWS key ID
        -s, --secret secret              specify your AWS secret
            --debug                      enable debug mode
            --region region              which region do you wish to report on?
        -h, --help                       help

Configuration
-------------

    define command{
      command_name  check_aws_asg
      command_line  $USER1$/check_aws_asg.rb --stack '$ARG1$' --tags '$ARG2$' --key '$ARG3$' --secret '$ARG4$' --region '$ARG5$'
      }
    
    define service{
      use                             generic-service
      host_name                       aws
      service_description             WWW ASG
      check_command                   check_aws_asg!<%= @aws_cfn_stack %>!WWWFleet!<%= @aws_nagios_key %>!<%= @aws_nagios_secret %>!<%= @aws_region_code %>
      check_interval                  5
      retry_interval                  1
      first_notification_delay        30
    }


Notes:
* For our purposes, it checks only for the ReplaceSuspended process. You may want something different.
* The default region is us-west-2 (Oregon)