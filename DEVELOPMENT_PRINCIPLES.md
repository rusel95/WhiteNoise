# Development Principles and Patterns Reference

This document serves as a comprehensive guide for all development practices in the WhiteNoise project. All new features and modifications must adhere to these principles.

## Core Principles Checklist

### SOLID Principles ✓
- [ ] **Single Responsibility Principle (SRP)**: Each class/module has one reason to change
- [ ] **Open/Closed Principle (OCP)**: Open for extension, closed for modification
- [ ] **Liskov Substitution Principle (LSP)**: Subtypes must be substitutable for base types
- [ ] **Interface Segregation Principle (ISP)**: No client forced to depend on unused methods
- [ ] **Dependency Inversion Principle (DIP)**: Depend on abstractions, not concretions

### DRY Principle ✓
- [ ] No duplicate code across modules
- [ ] Common functionality extracted into reusable components
- [ ] Shared behavior implemented via extensions
- [ ] Constants centralized in appropriate locations

### Code Quality Checks ✓
- [ ] No force unwrapping (`!`) in Swift
- [ ] No unnecessary `DispatchQueue.main.async` calls
- [ ] All UI updates marked with `@MainActor`
- [ ] No magic numbers - use named constants
- [ ] Classes under 200 lines
- [ ] Methods under 30 lines
- [ ] No dead code
- [ ] No primitive obsession

## Architecture Patterns

### MVVM (Model-View-ViewModel) - Primary Pattern
**When to use**: Default for all UI components
**Implementation checklist**:
- [ ] View contains only UI logic
- [ ] ViewModel contains business logic and state
- [ ] Model is pure data structure
- [ ] Proper use of `@StateObject`, `@ObservedObject`, `@Published`
- [ ] No business logic in Views

### Factory Pattern
**When to use**: Creating objects with complex initialization
**Implementation checklist**:
- [ ] Factory method returns protocol type, not concrete type
- [ ] Easy to add new types without modifying factory
- [ ] Clear naming convention (e.g., `createSound()`)

### Repository Pattern
**When to use**: Abstracting data access
**Implementation checklist**:
- [ ] Protocol defines data access methods
- [ ] Implementation details hidden from consumers
- [ ] Supports multiple data sources if needed

### Coordinator Pattern
**When to use**: Complex navigation flows
**Implementation checklist**:
- [ ] Navigation logic separated from Views
- [ ] ViewModels don't know about navigation
- [ ] Clear parent-child coordinator relationships

## Design Patterns Usage Guide

### Observer Pattern
**Implementation**: Use Combine's `@Published` properties
```swift
@Published var isPlaying: Bool = false
```

### Delegate Pattern
**When to use**: Callbacks between components (UIKit legacy)
**Prefer**: Combine publishers or async/await in new code

### Dependency Injection
**Always use** for:
- [ ] Services (audio, timer, persistence)
- [ ] ViewModels in Views
- [ ] External dependencies in ViewModels

### Protocol-Oriented Programming
**Prefer over inheritance**:
- [ ] Define capabilities via protocols
- [ ] Use protocol extensions for default implementations
- [ ] Composition over inheritance

## iOS-Specific Best Practices

### SwiftUI Guidelines
- [ ] Use `@StateObject` for owned objects
- [ ] Use `@ObservedObject` for injected objects
- [ ] Avoid massive Views - extract components
- [ ] Use ViewModifiers for reusable styling

### Combine Framework
- [ ] Prefer Combine over callbacks
- [ ] Properly cancel subscriptions
- [ ] Use operators to transform data
- [ ] Handle errors appropriately

### Concurrency
- [ ] Use async/await for asynchronous code
- [ ] Mark UI updates with `@MainActor`
- [ ] Avoid blocking main thread
- [ ] Proper task cancellation

## Pre-Implementation Checklist

Before implementing any feature:
1. [ ] Identify which patterns apply
2. [ ] Check SOLID compliance
3. [ ] Plan for testability
4. [ ] Consider edge cases
5. [ ] Review existing code for reusability

## Post-Implementation Review

After implementing a feature:
1. [ ] Verify SOLID principles adherence
2. [ ] Check for code smells
3. [ ] Ensure no force unwrapping
4. [ ] Confirm proper thread safety
5. [ ] Validate pattern implementation
6. [ ] Review for DRY violations
7. [ ] Check class/method sizes
8. [ ] Ensure proper error handling

## Common Anti-Patterns to Avoid

### Massive View Controller/ViewModel
- Keep under 200 lines
- Extract logic into services
- Use composition

### Singleton Abuse
- Use dependency injection instead
- Only for truly global state
- Make thread-safe if necessary

### Pyramid of Doom
- Use early returns
- Extract complex conditions
- Leverage Swift's guard statements

### Stringly-Typed Code
- Use enums for fixed sets
- Create proper types
- Avoid string-based APIs

## Testing Principles

### Unit Testing
- [ ] Test ViewModels independently
- [ ] Mock dependencies via protocols
- [ ] Test edge cases
- [ ] Maintain high coverage for business logic

### UI Testing
- [ ] Test critical user flows
- [ ] Use accessibility identifiers
- [ ] Keep tests maintainable

## Documentation Standards

### Code Comments
- Explain "why", not "what"
- Document complex algorithms
- Use Swift documentation comments for public APIs

### Method Naming
- Clear, descriptive names
- Follow Swift naming conventions
- Avoid abbreviations

## Performance Considerations

- [ ] Profile before optimizing
- [ ] Lazy loading where appropriate
- [ ] Efficient collection operations
- [ ] Proper memory management

---

**Remember**: This document should be reviewed before and after implementing any feature. It serves as both a guide and a checklist to ensure code quality and consistency.