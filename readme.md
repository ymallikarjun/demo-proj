
# maersk-solution

Scenario 1:

As the code is already migrated to Azure Repos. Now create a Build pipeline to build, test and package the code.

In Azure DevOps, navigate to your respective Organization -> Project.

Do a Sanity check, if the repo in intact post migration from TFS.

Solution:

1.	Create a new Build (CI) pipeline.
2.	Build Project automatically on check in to Master branch.
3.	In the Pipeline build-test.yaml add a step to build your .Net application and then add a step to run tests and code coverage.
4.	Fail a build if test step fail. Also, a notification mail if build passes/fails.



Steps:
1.	Navigate to Pipelines tab on the Azure DevOps project. Add New Pipeline
2.	Choose your source for the code. Here select Azure Repos Git.
3.	Select Project template to be .NET Core.

4.	Modify the build pipeline as per your requirement.

Find the attached .yaml for build configuration.


1)	The build should trigger as soon as anyone in the dev team checks in code to master branch. 


trigger:
- master

2) There will be test projects which will create and maintained in the solution along the Web and API. The trigger should build all the 3 projects - Web, API and test. 


The build should not be successful if any test fails. 

Modify the build pipeline as per your requirement.

Find the attached azure-pipelines.yaml for build configuration.


steps:
- script: dotnet build --configuration $(buildConfiguration)
  displayName: 'dotnet build $(buildConfiguration)'
  
- task: DotNetCoreCLI@2
  inputs:
    command: 'test'
    projects: '**/*Tests/*.csproj'
    arguments: '--logger trx --results-directory $(Agent.TempDir)'
    testRunTitle: 'Running test'

- task: PublishTestResults@2
  inputs:
    testRunner: VSTest
    testResultsFiles: '**/*.trx'
    failOnStandardError: 'true'
    failTaskOnFailedTests: 'true' //failing tasks if tests fail


3)	The deployment of code and artifacts should be automated to Dev environment. 

**•	Create a New Release Pipeline 
•	Select artifact source as from: Build Stage and select your Build pipeline.
•	Add 3 stages for deployment. 
•	Select IIS Deployment type.**

4.Upon successful deployment to the Dev environment, deployment should be easily promoted to QA and Prod through automated process.
**Set Pre-Deployment Trigger to ‘After Stage’ and select DEV**

5) The deployments to QA and Prod should be enabled with Approvals from approvers only.
**Set Pre deployment Approvals and Approver for QA and PROD Stage**



Scenario 2:

 Q2 - SCENARIO 
Macro Life, a healthcare company has recently setup the entire Network and Infrastructure on Azure. 
The infrastructure has different components such as Virtual N/W, Subnets, NIC, IPs, NSG etc. 
The IT team currently has developed PowerShell scripts to deploy each component where all the properties of each resource is set using PowerShell commands. 
The business has realized that the PowerShell scripts are growing over period of time and difficult to handover when new admin onboards in the IT. 
The IT team has now decided to move to Terraform based deployment of all resources to Azure. 
All the passwords are stored in a Azure Service known as key Vault. The deployments needs to be automated using Azure DevOps using IaC(Infrastructure as Code). 
1. List the tools you will to create and store the Terraform templates. 
VS Code to write config files.
Push config files to git after testing

2.Explain the process and steps to create automated deployment pipeline. 

	Make sure  Terraform folder is there in the repo.
push main.tf to Git.
	Build you CI pipeline
	In addition to the application build, we need to publish terraform files to build artifacts so that it will be available in CD pipeline. So we have added Copy files task to copy Terraform file to Artifacts directory.

3. Create a sample Terraform template you will use to deploy Below services: 
	Vnet 
	2 Subnet 
	NSG to open port 80 and 443 
	1 Window VM in each subnet 
	1 Storage account 

Shared via Git


**
Case 2: Assumption key vault exists in Azure**

Create service principal to access resources of azure 
$ az ad sp create-for-rbac -n mysp

Note down appId, password , tenand Id of the output

Goto->key vault ->  + Access Policy and select above ‘mysp’ service principal.

Select Permission to be ‘Get’ and ‘List’. Create Access Policy.

Now in Azure DevOps Add a service connection to Azure using existing service principal.

In Release pipeline the release definition for Dev stage has a Azure Key Vault task.
 
This task downloads Secrets from an Azure Key Vault. You will need to point to the subscription and the Azure Key Vault resource to get the secrets.

At runtime, Azure Pipelines will fetch the latest values of the secrets and set them as task variables which can be consumed.

Add ‘Replace Tokens in Terraform ‘ task. Set target files to **/*.tf  and Token Prefix an suffix to ‘__’. Note this is used in main.tf.


