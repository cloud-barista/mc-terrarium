package readyz

import (
	"sync/atomic"
)

// isSystemReady is declared as an atomic.Value to ensure thread safety.
var isSystemReady atomic.Value

// init function initializes isSystemReady with its default value.
func init() {
	isSystemReady.Store(false) // Initialize as the system is not ready.
}

// IsReady returns the current readiness status of the system.
func IsReady() bool {
	return isSystemReady.Load().(bool)
}

// SetReady sets the readiness status of the system.
func SetReady(ready bool) {
	isSystemReady.Store(ready)
}
