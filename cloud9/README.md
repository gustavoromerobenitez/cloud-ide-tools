# Cloud9 Environment Set Up Notes

[https://console.aws.amazon.com/cloud9/](https://console.aws.amazon.com/cloud9/)

* The time on the Cloud9 VMs is UTC
* By default, the VMs come with a 10GB storage volume, and it does not seem possible to use a custom VM type
* The instances always have a public IP although it is possible to create instances which don't have any exposed ports
 and have the Cloud9 service connect to them via Systems Manager
* A t2.small vm type seems enough to run the Springboot Petclinic application with a MySQL or Postgres backend running on Docker.
* Choose a region close to you to enhance response times.

## Setting up access to Cloud9 environments

[Documentation](https://docs.aws.amazon.com/cloud9/latest/user-guide/setup.html)

* Create two AWS IAM Groups: One for AWS Cloud9 Administrators and another one for Cloud9 Users.
* Add the role `AWSCloud9Administrator` to the administrators group.
  * Add IAM Users to the administrators group.
* For the 'regular users' group, choose either:
  * The role `AWSCloud9User` if they will be allowed to create their own environments.
  * The role `AWSCloud9EnvironmentMember` if users can only be invited to use [Shared Environments](https://docs.aws.amazon.com/cloud9/latest/user-guide/share-environment.html).
* Add IAM users to the regular users group.
  
### Shared Environments

* Create environments as an AWS Cloud9 Admnistrator: [Web Console](https://docs.aws.amazon.com/cloud9/latest/user-guide/create-environment-main.html#create-environment-console) / [CLI](https://docs.aws.amazon.com/cloud9/latest/user-guide/create-environment-main.html#create-environment-code).
    
* Share the environment with specific users: [Web Console](https://docs.aws.amazon.com/cloud9/latest/user-guide/share-environment.html#share-environment-invite-user) / [CLI](https://docs.aws.amazon.com/cloud9/latest/user-guide/share-environment.html#share-environment-admin-user).

* Cloud9 Users can access their environments via a direct link to the IDE or by logging into the AWS Console and navigating to Cloud9.
  * Select the correct region to show available environments
  * Shared environment appear under 'Environments shared with me'  
 
## Resizing EC2 Volumes on Cloud9 instances

[AWS Cloud Moving Environments Documentation](https://docs.aws.amazon.com/cloud9/latest/user-guide/move-environment.html)

* Modify volume size of the instance in the EC2 web console.
  
 * Wait until volume is in the OPTIMIZATION stage before continuing with the next steps.

* Open the Cloud9 environment and follow these steps:

  * Find out which partition needs resizing after the volume was resized:

    `lsblk`

  * Resize partition to use all the available space in the volume, i.e:
  
    `sudo growpart /dev/xvda 1`

  * Find out filesystem type:
    
    `sudo df -hT`
    
  * Resize a mounted filesystem, i.e for XFS:

    `sudo xfs_growfs -d /`
    
  * Verify that the filesystem now uses all the available space in the partition:

    `sudo df -hT`

