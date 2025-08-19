# Review Pull Request

<!-- ABOUTME: Conducts complete PR reviews against issue requirements and best practices -->

<!-- ABOUTME: Analyzes code quality, tests, documentation, and implementation standards -->

Pull Request: $ARGUMENTS

## Task

I'll carefully review this pull request against issue requirements and good coding practices.

I will:

1. **Auto-detect tracking system** - Determine if GitHub PR (gh CLI) or Linear-linked PR (linear-cli)
2. **Read the pull request** to understand changes, scope, and implementation approach
3. **Find related issue/ticket** for acceptance criteria and original requirements
4. **Ensure latest code context** - pull changes and verify working directory state
5. **Review project documentation** - check `docs/`, `spec.md`, `requirements.md`, `CLAUDE.md` for standards
6. **Analyze implementation quality** - code structure, patterns, maintainability
7. **Verify test coverage** - ensure complete testing of new functionality
8. **Check style compliance** - validate against project guidelines from `CLAUDE.md`
9. **Assess scope adherence** - confirm changes are minimal and focused on requirements
10. **Determine review action** - check if self-authored (comment) vs external (formal review)
11. **Submit structured feedback** - provide actionable recommendations

## Auto-Detection Logic

The command automatically detects the issue tracking context:

- **GitHub PRs**: Uses `gh` CLI to fetch PR and linked issue details
- **Linear-linked PRs**: Searches PR description for Linear ticket references, uses `linear-cli`
- **Manual Override**: Use `--github` or `--linear` flags to force specific system

## Review Framework

### **Requirements Alignment**

- **Acceptance Criteria Coverage**: Verify all issue requirements are met
- **Scope Boundaries**: Ensure no scope creep beyond original ticket
- **Edge Case Handling**: Confirm robust error handling and input validation

### **Code Quality Assessment**

- **Architecture Consistency**: Follows established patterns from codebase
- **Code Organization**: Single Responsibility Principle, DRY compliance
- **Documentation**: Adequate comments for complex logic, API changes documented
- **Performance Considerations**: No obvious bottlenecks or inefficient algorithms

### **Test Coverage Verification**

- **TDD Compliance**: Tests written first, implementation follows
- **Coverage Completeness**: All new functionality has corresponding tests
- **Error Scenarios**: Edge cases and failure modes are tested
- **Integration Testing**: Changes work correctly with existing system

### **Implementation Standards**

- **Branch Management**: Clean commit history, appropriate branch naming
- **Change Minimalism**: Smallest necessary changes to achieve requirements
- **Backwards Compatibility**: No breaking changes without explicit justification
- **Security Review**: Input validation, no credentials exposure

## Review Output Structure

### **📋 Requirements Coverage**

- ✅ All acceptance criteria met
- ⚠️ Partial implementation notes
- ❌ Missing functionality

### **🔍 Code Quality**

- Architecture adherence
- Pattern consistency
- Documentation completeness
- Performance implications

### **🧪 Test Assessment**

- Coverage verification
- TDD compliance check
- Edge case testing
- Integration validation

### **📝 Final Recommendation**

- **Approve**: Ready for merge
- **Request Changes**: Specific issues to address
- **Comment**: Self-authored PR feedback

## Command Reference

### GitHub Flow

```bash
# View PR with full details
gh pr view <number> --json title,body,author,commits,files,comments,reviews

# Get diff and file changes
gh pr diff <number>

# View related GitHub issue
gh issue view <number> --json title,body,labels,assignees

# List all PRs for context
gh pr list --state all --json number,title,author,createdAt,updatedAt

# Submit review (if not self-authored)
gh pr review <number> --approve|--request-changes|--comment
```

### Linear Integration

```bash
# View all issues for context
linear-cli issues

# View specific Linear issue
linear-cli issue <team-id>

# Search for issues referenced in PR
linear-cli issues --filter "description contains '<pr-reference>'"
```

## Review Quality Standards

**For Self-Authored PRs:**

- Leave detailed comments explaining approach and decisions
- Document any technical debt or future improvement opportunities
- Call out areas where feedback would be valuable

**For External PRs:**

- Provide constructive, specific feedback
- Include code examples for suggested improvements
- Balance thoroughness with practicality
- Focus on maintainability and requirements adherence
