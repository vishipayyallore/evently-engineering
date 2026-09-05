# S.M.A.R.T. Prompt Framework for GitHub Copilot Coding Agents

**Machine Learning Algorithms from Scratch Edition** - Framework for creating high-quality coding agent instructions aligned with ML algorithm implementation best practices and educational standards.

---

## 🎯 **The S.M.A.R.T. Framework**

Use this framework to create highly effective coding agent instructions:

```text
S - Specific Role Definition (ML Engineer, Algorithm Specialist, Data Scientist, etc.)
M - Mission-Critical Requirements (What must be accomplished with measurable outcomes)
A - Audience-Aware Communication (Team expertise level, mathematical maturity, domain context)
R - Response Format Control (Code structure, algorithm patterns, documentation style)
T - Task-Oriented Constraints (Technology stack, implementation patterns, forbidden actions)
```

---

## 🏛️ **ML Algorithm System Alignment**

When creating prompts, consider:

- **Algorithm Type**: Is this supervised, unsupervised, semi-supervised, or reinforcement learning?
- **Use Case Context**: What task type (classification, regression, clustering, dimensionality reduction)?
- **Implementation Approach**: From-scratch implementation, optimization, or educational demonstration?
- **Template Reusability**: Can this prompt be templated for reuse across similar algorithms?

## 🏗️ **Advanced Problem Statement Template**

Use this enhanced template for coding agent tasks:

```markdown
## ROLE DEFINITION

You are a [Specific Role] specializing in [Technology Stack] with expertise in [Domain Areas]

## MISSION

[Clear, specific objective with measurable outcomes]

## CONTEXT

[Brief overview of current situation and progress made]

## CURRENT STATUS

- **Progress Made**: [Specific achievements and metrics]
- **Main Issue**: [Root cause analysis]
- **Files Affected**: [List specific files]

## REMAINING WORK

### 1. [Priority Task Name] (Priority N)

- **Problem**: [Specific technical issue]
- **Current Error**: [Exact error messages]
- **Solution Approach**: [Concrete implementation steps]
- **Files to Modify**: [Specific file paths]

## TECHNICAL CONSTRAINTS

- **🚨 CRITICAL**: [Non-negotiable requirements]
- **Framework**: [Technology stack requirements]
- **Dependencies**: [Package/version constraints]

## RESPONSE FORMAT REQUIREMENTS

- [Specific code structure expectations]
- [Documentation requirements]
- [Testing requirements]
- [Mathematical correctness verification]

## WHAT NOT TO DO

- ❌ [Explicit forbidden actions with reasoning]

## WHAT TO DO

- ✅ [Explicit required actions with priority]

## SUCCESS CRITERIA

[Measurable outcomes with acceptance criteria]

## QUALITY STANDARDS

- [Code quality requirements]
- [Mathematical correctness expectations]
- [Performance considerations]
- [Educational value standards]
```

## 🎭 **Role-Based Specialization Examples**

### **For ML Algorithm Implementation:**

```markdown
ROLE: You are a Machine Learning Engineer specializing in implementing algorithms from scratch, mathematical foundations, and educational code quality

EXPERTISE FOCUS: Algorithm implementation from first principles, NumPy/SciPy optimization, mathematical correctness, clear documentation

OUTPUT REQUIREMENTS: Production-ready Python code with comprehensive error handling, unit tests with proper test cases, and educational-grade documentation

MANDATORY VALIDATION:
- ✅ `pytest tests/` succeeds with 0 failures
- ✅ Algorithm implementation matches theoretical foundations
- ✅ Code runs without errors on standard datasets
- ✅ Mathematical correctness verified
```

### **For Supervised Learning Algorithms:**

```markdown
ROLE: You are an ML Algorithm Specialist specializing in supervised learning algorithms (classification and regression)

EXPERTISE FOCUS: Linear models, tree-based methods, ensemble methods, evaluation metrics, cross-validation

OUTPUT REQUIREMENTS: From-scratch implementations with proper mathematical foundations, comprehensive docstrings, and educational examples

MANDATORY VALIDATION:
- ✅ Algorithm implementation is mathematically correct
- ✅ Unit tests pass with 0 failures
- ✅ Code follows PEP 8 standards
- ✅ Documentation includes mathematical formulations
```

### **For Unsupervised Learning Algorithms:**

```markdown
ROLE: You are an ML Algorithm Specialist specializing in unsupervised learning algorithms (clustering and dimensionality reduction)

EXPERTISE FOCUS:
- Clustering algorithms (K-Means, DBSCAN, hierarchical)
- Dimensionality reduction (PCA, t-SNE, UMAP)
- Distance metrics and similarity measures
- Evaluation metrics for unsupervised learning

OUTPUT REQUIREMENTS:
- From-scratch implementations with clear mathematical foundations
- Proper handling of distance calculations
- Visualization examples for clustering results
- Documentation with algorithm theory

MANDATORY VALIDATION:
- ✅ Algorithm implementation matches theoretical foundations
- ✅ Clustering results are visually verifiable
- ✅ Distance metrics are correctly implemented
- ✅ Code is well-documented with mathematical explanations
```

### **For Reinforcement Learning Algorithms:**

```markdown
ROLE: You are an RL Algorithm Specialist specializing in reinforcement learning algorithms and environments

EXPERTISE FOCUS:
- Value-based methods (Q-Learning, DQN)
- Policy-based methods (REINFORCE, Actor-Critic)
- Environment design and simulation
- Reward shaping and exploration strategies

OUTPUT REQUIREMENTS:
- From-scratch RL algorithm implementations
- Environment implementations with proper state/action spaces
- Training loops with proper logging
- Documentation with RL theory and convergence analysis

MANDATORY VALIDATION:
- ✅ RL algorithms converge on test environments
- ✅ Environment implementations are correct
- ✅ Training loops include proper logging
- ✅ Code demonstrates RL concepts clearly
```

## 🚨 **Critical Constraint Guidelines**

### **Framework/Package Versions:**

```markdown
- 🚨 CRITICAL: Use Python 3.12+ ONLY - DO NOT downgrade
- 🚨 CRITICAL: Use NumPy, SciPy, Pandas latest stable versions - DO NOT downgrade
- ❌ DO NOT use scikit-learn for core algorithm logic (only for comparison/validation)
- ❌ DO NOT modify pyproject.toml to downgrade packages
```

### **File Modification Boundaries:**

```markdown
- ❌ DO NOT modify [specific files]
- ✅ ONLY modify [allowed areas]
```

### **Build Requirements:**

```markdown
When implementing algorithms, use: uv sync  (Windows/PowerShell: optionally .venv\Scripts\Activate.ps1; prefer uv run …)
Ensure all code follows project standards (PEP 8 for Python)
All algorithms must be implemented from scratch (no direct library usage for core logic)
```

## ✅ **Effective Instruction Patterns**

### **DO - Be Specific and Explicit:**

- ✅ "Implement Linear Regression from scratch using gradient descent optimization"
- ✅ "Create KMeans clustering algorithm with proper centroid initialization and convergence checking"
- ✅ "Fix the cost function calculation in logistic_regression.py - verify mathematical correctness"

### **DON'T - Be Vague:**

- ❌ "Fix the algorithm"
- ❌ "Make it work"
- ❌ "Update the code"

## 📝 **Constraint Language Examples**

### **Strong Constraint Language That Works:**

```markdown
🚨 ABSOLUTELY DO NOT use scikit-learn's LinearRegression class for the core implementation.

The following packages MUST remain at their current versions:
- numpy: Latest stable version
- scipy: Latest stable version
- pandas: Latest stable version

CRITICAL: Algorithm must be implemented from scratch using only NumPy for numerical operations.
```

### **Weak Language That Doesn't Work:**

```markdown
Please try to maintain Python 3.12+ compatibility
Prefer keeping current package versions
```

## 🎯 **Advanced Prompt Design Patterns**

### **Multi-Layered Prompt Architecture:**

```markdown
SYSTEM LAYER:
You are a [Specialist Role] with expertise in [Technology Stack] and [Domain Expertise].

CONTEXT LAYER:
[Project context, current situation, learning objectives]

TASK LAYER:
[Specific implementation task with clear deliverables]

SPECIFICATION LAYER:
[Detailed technical requirements, constraints, and acceptance criteria]
```

### **Conditional Logic for Complex Scenarios:**

```markdown
LOGIC FRAMEWORK:
IF algorithm_type == "supervised_classification":
THEN approach: Implement from scratch with proper loss function
AND include: Evaluation metrics (accuracy, precision, recall, F1)

ELIF algorithm_type == "unsupervised_clustering":
THEN approach: Implement distance-based clustering with proper initialization
AND include: Visualization of cluster results

ELIF algorithm_type == "reinforcement_learning":
THEN approach: Implement value-based or policy-based method
AND include: Environment simulation and training loop
```

## 📊 **Output Format Control**

### **For Algorithm Implementation Tasks:**

```markdown
OUTPUT REQUIREMENTS:
- From-scratch implementation with comprehensive error handling
- Unit tests with proper test cases
- Type hints for Python
- Comprehensive docstrings with mathematical formulations
- Consistent code style following project conventions (PEP 8)
- Educational examples demonstrating algorithm usage
- Mathematical correctness verification
```

### **For ML Workflow Tasks:**

```markdown
OUTPUT REQUIREMENTS:
- Data preprocessing pipelines with proper validation
- Model evaluation with cross-validation
- Hyperparameter tuning with proper search strategies
- Visualization of results and learning curves
- Documentation with best practices
```

## 🎯 **Success Indicators**

### **Agent is working correctly when:**

- ✅ It acknowledges constraints explicitly
- ✅ It asks clarifying questions about mathematical foundations
- ✅ It maintains from-scratch implementation approach
- ✅ It focuses on algorithm correctness, not just functionality
- ✅ It provides detailed progress updates
- ✅ It includes proper mathematical documentation

### **Agent needs restart when:**

- ❌ It immediately uses library implementations for core logic
- ❌ It ignores mathematical correctness requirements
- ❌ It ignores explicit constraints
- ❌ It breaks from-scratch implementation principle
- ❌ It takes overly broad approach to simple problems

## 🔄 **Agent Restart Protocol**

### **When to restart the coding agent:**

- Agent uses library implementations instead of from-scratch code
- Agent breaks mathematical correctness
- Agent modifies forbidden files
- Agent ignores explicit constraints
- Agent takes wrong implementation approach

### **How to restart:**

1. Close current pull request
2. Create new pull request with more explicit constraints
3. Include specific examples of what went wrong
4. Add stronger constraint language

## 🏗️ **ML Algorithm Implementation Patterns**

When implementing algorithms, apply these patterns:

### **Pattern: From-Scratch Implementation**

```markdown
IMPLEMENTATION PATTERN: From-Scratch Algorithm Implementation

REQUIREMENTS:
- Core algorithm logic implemented from first principles
- Use NumPy/SciPy only for numerical operations (not algorithm logic)
- Mathematical foundations clearly documented
- Proper initialization and convergence checking
- Educational examples demonstrating usage

QUALITY GATES:
✅ Algorithm implementation matches theoretical foundations
✅ No direct library usage for core algorithm logic
✅ Mathematical correctness verified
✅ Code is well-documented with theory
✅ Unit tests validate correctness
```

### **Pattern: Algorithm Evaluation**

```markdown
EVALUATION PATTERN: Comprehensive Algorithm Testing

CHARACTERISTICS:
- Unit tests for individual components
- Integration tests for full algorithm
- Comparison with reference implementations (for validation)
- Performance benchmarking
- Visualization of results

IMPLEMENTATION REQUIREMENTS:
- Test on standard datasets
- Compare results with theoretical expectations
- Visualize algorithm behavior
- Document performance characteristics
- Include edge case handling

QUALITY GATES:
✅ All unit tests pass
✅ Algorithm produces expected results
✅ Performance is reasonable
✅ Edge cases are handled
✅ Results are reproducible
```

## 📋 **Universal PR Success Template**

Include this template in EVERY coding agent PR for consistent validation:

```markdown
## 🎯 MANDATORY SUCCESS CRITERIA (NON-NEGOTIABLE)

### Algorithm Implementation Requirements
```powershell
# MUST PASS: Algorithm tests with zero failures
python -m pytest tests/ -v
# Expected Result: "passed" with 0 failures
```

### Code Quality Requirements

```powershell
# MUST PASS: Code quality checks
# Use Ruff as the primary lint/format tool
uv run ruff check src/
# Optionally: `uv run ruff format src/` to auto-format before checking
# Expected Result: No errors
```

### Mathematical Correctness

```powershell
# MUST VERIFY: Algorithm implementation matches theoretical foundations
# Review mathematical formulations in docstrings
# Verify cost functions, update rules, etc.
```

## 📋 FINAL CHECKLIST

Before marking this PR ready for review:

- [ ] ✅ Algorithm tests pass with 0 failures
- [ ] ✅ Code quality checks pass
- [ ] ✅ Algorithm implemented from scratch (no library usage for core logic)
- [ ] ✅ Mathematical correctness verified
- [ ] ✅ All original issues resolved completely
- [ ] ✅ Documentation includes mathematical foundations
- [ ] ✅ Educational examples provided

**CRITICAL**: Do not mark this PR as ready for review until ALL validations pass successfully.
```

## 🚀 **ML Algorithms from Scratch-Specific S.M.A.R.T. Example**

```markdown
ROLE: You are a Machine Learning Engineer specializing in implementing algorithms from scratch, mathematical foundations, and educational code quality

MISSION: Implement Linear Regression algorithm from scratch in the ML Algorithms from Scratch repository - a comprehensive learning workspace for understanding ML algorithms from first principles using Python, NumPy, and educational best practices

AUDIENCE: Learning community with expertise in:
- Python programming and NumPy
- Basic machine learning concepts
- Mathematical foundations (linear algebra, calculus)
- Algorithm implementation patterns

RESPONSE FORMAT:
- From-scratch implementation with comprehensive error handling
- Type hints and comprehensive docstrings
- Unit tests for algorithm correctness
- Educational documentation with mathematical foundations
- Proper from-scratch implementation (no scikit-learn for core logic)

TASK CONSTRAINTS:
- 🚨 CRITICAL: Implement from scratch using only NumPy for numerical operations
- 🚨 CRITICAL: Verify mathematical correctness of implementation
- Architecture: Algorithm class → Training method → Prediction method → Evaluation
- Quality Standards: Zero test failures, mathematical correctness, PEP 8 compliance
- Technology Stack: Python 3.12+, NumPy, SciPy, Pandas, Matplotlib
```

## 📚 **Best Practices Summary**

1. **Be Specific**: Define exact roles, technologies, and constraints
2. **Set Clear Boundaries**: Use strong constraint language
3. **Define Success**: Include measurable outcomes and validation steps
4. **Control Output**: Specify exactly what format and quality you expect
5. **Plan for Failure**: Include restart protocols and troubleshooting
6. **Validate Everything**: Always include build and test requirements
7. **Document Thoroughly**: Ensure all decisions and constraints are recorded
8. **Align with Educational Goals**: Reference from-scratch implementation principles
9. **Enable Learning**: Include mathematical foundations and theory
10. **Progressive Complexity**: Scale scope to learning objectives

---

## ⚡ **Quick Reference Checklist**

Use this checklist before submitting any coding agent task:

### **Role Definition**

- [ ] Specific role/expertise clearly stated
- [ ] Technology stack and frameworks identified
- [ ] Expected audience knowledge level documented
- [ ] Domain context provided

### **Task Clarity**

- [ ] Mission and objectives clearly defined
- [ ] Success criteria are measurable
- [ ] Scope is appropriately sized
- [ ] Priority and sequencing defined

### **Technical Requirements**

- [ ] Framework and version constraints specified
- [ ] Implementation patterns identified (from-scratch)
- [ ] Dependencies listed explicitly
- [ ] Mathematical foundations documented

### **Constraints & Boundaries**

- [ ] Forbidden actions explicitly listed (❌)
- [ ] Required actions explicitly listed (✅)
- [ ] File modification boundaries defined
- [ ] Implementation decision constraints included

### **Quality & Validation**

- [ ] Code quality standards specified (PEP 8)
- [ ] Build/test requirements included
- [ ] Mathematical correctness expectations defined
- [ ] Educational value considerations addressed

### **Algorithm Implementation Specifics**

- [ ] From-scratch implementation requirements specified
- [ ] Mathematical foundations documented
- [ ] Evaluation approach included
- [ ] Educational examples required

### **Output Expectations**

- [ ] Code format and style specified
- [ ] Documentation requirements defined
- [ ] Testing approach specified
- [ ] Mathematical correctness verification included

---

## 📋 **FINAL VALIDATION CHECKLIST**

Before submitting ANY coding agent PR or task completion:

- [ ] ✅ All technical constraints acknowledged
- [ ] ✅ Success criteria clearly measurable
- [ ] ✅ Algorithm tests pass without errors/failures
- [ ] ✅ Code quality checks pass
- [ ] ✅ No forbidden files modified
- [ ] ✅ From-scratch implementation principles applied correctly
- [ ] ✅ Mathematical correctness verified
- [ ] ✅ Documentation is complete and accurate
- [ ] ✅ Code review readiness criteria met

---

## 🎓 **ML Algorithms System Integration**

Align your coding agent tasks with ML Algorithms from Scratch best practices:

### **For Algorithm Implementation Development:**

- Focus on from-scratch implementation using NumPy
- Demonstrate proper mathematical foundations
- Include cost functions and optimization methods
- Show proper error handling and validation

### **For ML Workflow Development:**

- Use proper data preprocessing patterns
- Implement cross-validation correctly
- Include hyperparameter tuning strategies
- Demonstrate proper model evaluation

### **For Educational Content Creation:**

- Create clear algorithm explanations
- Document mathematical foundations
- Include visualizations and examples
- Provide learning objectives and outcomes

This framework ensures consistent, high-quality results from GitHub Copilot coding agents while preventing common issues and maintaining educational standards aligned with ML algorithm implementation best practices and from-scratch implementation principles.
