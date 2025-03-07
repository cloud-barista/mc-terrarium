package main

import (
	"fmt"
	"log"

	"github.com/cloud-barista/mc-terrarium/pkg/tofu/tfclient"
)

func main() {
	// Define trace ID and request ID for tracking
	traceID := "example-trace-001"
	requestID := "example-req-001"
	
	fmt.Println("OpenTofu Client Examples")
	fmt.Println("========================")
	
	// Example 1: Basic initialization
	fmt.Println("\n=== Example 1: Initialize a Terraform project ===")
	initExample(traceID, requestID)
	
	// Example 2: Plan with variables
	fmt.Println("\n=== Example 2: Create a plan with variables ===")
	planExample(traceID, requestID)
	
	// Example 3: Apply with auto-approve
	fmt.Println("\n=== Example 3: Apply configuration with auto-approve ===")
	applyExample(traceID, requestID)
	
	// Example 4: Show outputs in JSON format
	fmt.Println("\n=== Example 4: Get outputs in JSON format ===")
	outputExample(traceID, requestID)
	
	// Example 5: Destroy with variables
	fmt.Println("\n=== Example 5: Destroy infrastructure ===")
	destroyExample(traceID, requestID)
	
	// Example 6: Workspace management
	fmt.Println("\n=== Example 6: Workspace management ===")
	workspaceExample(traceID, requestID)
	
	// Example 7: Async command execution
	fmt.Println("\n=== Example 7: Asynchronous command execution ===")
	asyncExample(traceID, requestID)
	
	// Example 8: State management
	fmt.Println("\n=== Example 8: State management ===")
	stateExample(traceID, requestID)
}

// Basic initialization example
func initExample(traceID, requestID string) {
	client := tfclient.NewClient(traceID, requestID)
	
	// Set working directory
	client.SetChdir("./terraform-project")
	
	// Initialize with backend reconfiguration and upgrade
	result, err := client.Init().Reconfigure().Upgrade().Exec()
	
	if err != nil {
		log.Printf("Error executing init: %v", err)
		return
	}
	
	fmt.Println("Init result:", result)
}

// Plan example with variables
func planExample(traceID, requestID string) {
	client := tfclient.NewClient(traceID, requestID)
	
	// Set working directory
	client.SetChdir("./terraform-project")
	
	// Create plan with variables and output to a file
	result, err := client.Plan().
		SetVar("instance_count", "2").
		SetVar("region", "us-west-2").
		SetVarFile("env/prod.tfvars").
		SetOut("tfplan").
		NoColor().
		Exec()
	
	if err != nil {
		log.Printf("Error executing plan: %v", err)
		return
	}
	
	fmt.Println("Plan result:", result)
}

// Apply example with auto-approve
func applyExample(traceID, requestID string) {
	client := tfclient.NewClient(traceID, requestID)
	
	// Set working directory
	client.SetChdir("./terraform-project")
	
	// Apply with auto-approve and parallelism settings
	result, err := client.Apply().
		Auto().
		Parallelism(10).
		SetVarFile("env/prod.tfvars").
		Exec()
	
	if err != nil {
		log.Printf("Error executing apply: %v", err)
		return
	}
	
	fmt.Println("Apply result:", result)
}

// Output example with JSON format
func outputExample(traceID, requestID string) {
	client := tfclient.NewClient(traceID, requestID)
	
	// Set working directory
	client.SetChdir("./terraform-project")
	
	// Get specific output in JSON format
	result, err := client.Output().
		Json().
		SetArg("instance_ips").
		Exec()
	
	if err != nil {
		log.Printf("Error getting outputs: %v", err)
		return
	}
	
	fmt.Println("Output result:", result)
}

// Destroy example
func destroyExample(traceID, requestID string) {
	client := tfclient.NewClient(traceID, requestID)
	
	// Set working directory
	client.SetChdir("./terraform-project")
	
	// Destroy with auto-approve
	result, err := client.Destroy().
		Auto().
		SetVarFile("env/prod.tfvars").
		Exec()
	
	if err != nil {
		log.Printf("Error executing destroy: %v", err)
		return
	}
	
	fmt.Println("Destroy result:", result)
}

// Workspace management example
func workspaceExample(traceID, requestID string) {
	client := tfclient.NewClient(traceID, requestID)
	
	// Set working directory
	client.SetChdir("./terraform-project")
	
	// List workspaces
	listResult, err := client.Workspace().SetArg("list").Exec()
	if err != nil {
		log.Printf("Error listing workspaces: %v", err)
	} else {
		fmt.Println("Workspace list:", listResult)
	}
	
	// Create new workspace
	newResult, err := client.Workspace().
		SetArgs("new", "dev-environment").
		Exec()
	
	if err != nil {
		log.Printf("Error creating workspace: %v", err)
	} else {
		fmt.Println("New workspace result:", newResult)
	}
	
	// Select workspace
	selectResult, err := client.Workspace().
		SetArgs("select", "dev-environment").
		Exec()
	
	if err != nil {
		log.Printf("Error selecting workspace: %v", err)
	} else {
		fmt.Println("Workspace select result:", selectResult)
	}
}

// Async command execution example
func asyncExample(traceID, requestID string) {
	client := tfclient.NewClient(traceID, requestID)
	
	// Set working directory
	client.SetChdir("./terraform-project")
	
	// Run plan asynchronously
	jobID, err := client.Plan().
		SetVarFile("env/prod.tfvars").
		Async(true).
		Exec()
	
	if err != nil {
		log.Printf("Error starting async plan: %v", err)
		return
	}
	
	fmt.Println("Async job started with ID:", jobID)
	fmt.Println("You can now poll for the results using this ID")
}

// State management example
func stateExample(traceID, requestID string) {
	client := tfclient.NewClient(traceID, requestID)
	
	// Set working directory
	client.SetChdir("./terraform-project")
	
	// List all resources in state
	fmt.Println("Listing all resources in state:")
	listResult, err := client.State().List().Exec()
	if err != nil {
		log.Printf("Error listing state resources: %v", err)
	} else {
		fmt.Println(listResult)
	}
	
	// Show details of a specific resource
	fmt.Println("\nShowing details of a specific resource:")
	showResult, err := client.State().Show("aws_instance.example").Exec()
	if err != nil {
		log.Printf("Error showing state resource: %v", err)
	} else {
		fmt.Println(showResult)
	}
	
	// Move a resource in state
	fmt.Println("\nMoving a resource in state:")
	moveResult, err := client.State().Move(
		"aws_instance.example", 
		"aws_instance.web",
	).Exec()
	if err != nil {
		log.Printf("Error moving state resource: %v", err)
	} else {
		fmt.Println(moveResult)
	}
	
	// Remove a resource from state
	fmt.Println("\nRemoving a resource from state:")
	rmResult, err := client.State().Remove("aws_security_group.obsolete").Exec()
	if err != nil {
		log.Printf("Error removing state resource: %v", err)
	} else {
		fmt.Println(rmResult)
	}
	
	// Pull remote state
	fmt.Println("\nPulling remote state:")
	pullResult, err := client.State().Pull().WithStateOut("./terraform.tfstate").Exec()
	if err != nil {
		log.Printf("Error pulling state: %v", err)
	} else {
		fmt.Println(pullResult)
	}
	
	// List resources with filter
	fmt.Println("\nListing resources with filter:")
	filteredResult, err := client.State().List().WithFilter("aws_instance.*").Exec()
	if err != nil {
		log.Printf("Error listing filtered resources: %v", err)
	} else {
		fmt.Println(filteredResult)
	}
	
	// Replace provider in state
	fmt.Println("\nReplacing provider in state:")
	replaceResult, err := client.State().ReplaceProvider(
		"registry.terraform.io/hashicorp/aws",
		"registry.terraform.io/hashicorp/aws-custom",
	).Exec()
	if err != nil {
		log.Printf("Error replacing provider: %v", err)
	} else {
		fmt.Println(replaceResult)
	}
}
