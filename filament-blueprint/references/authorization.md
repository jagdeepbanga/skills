# Authorization Specifications

> **For planning agents**: Copy all relevant information from this file into
> your plan. The implementing agent will only see your plan, not this file.

Describe access control in plain English so the implementing agent knows exactly
what logic to write.

## When Policies Are Needed

Not every resource needs a policy. Decide based on requirements:

| Scenario                             | What to Specify                          |
| ------------------------------------ | ---------------------------------------- |
| All authenticated users can access   | `Authorization: All authenticated users` |
| Only certain roles can access        | Policy with role checks                  |
| Users can only see their own records | Policy with ownership checks             |
| Different permissions per action     | Policy with ability-specific logic       |
| No restrictions (public panel)       | `Authorization: None (public)`           |

## What to Include (When Using a Policy)

| Element        | Why the Implementing Agent Needs It |
| -------------- | ----------------------------------- |
| Policy class   | So they create the right file       |
| Each ability   | So they write all required methods  |
| Logic for each | So they write correct conditions    |

## Policy Location

Pattern: `App\Policies\{Model}Policy`

Docs: https://filamentphp.com/docs/5.x/resources/overview#authorization

## Plan Format: No Restrictions

```
Resource: PostResource
  Authorization: All authenticated users
```

## Plan Format: With Policy

```
Resource: OrderResource
  Policy: App\Policies\OrderPolicy

  Abilities:
    viewAny: user has 'view orders' permission
    view: user owns the order (user_id matches) OR has 'view all orders' permission
    create: user has 'create orders' permission
    update: user owns the order AND order status is not 'shipped' AND not 'completed'
    delete: user has 'delete orders' permission AND order status is 'pending'
    deleteAny: user has 'delete orders' permission
    restore: user has 'manage orders' permission
    forceDelete: user has 'super-admin' role
```

## How to Describe Abilities

Be specific about:

- **Permission checks**: "user has '{permission-name}' permission"
- **Role checks**: "user has '{role-name}' role"
- **Ownership**: "user owns the record (user_id matches)" or "user owns the
  order"
- **Record state**: "status is 'pending'" or "status is not 'shipped'"
- **Combinations**: use AND, OR to combine

## Action Authorization

For custom actions, specify inline:

```
Action: Approve
  Authorization: user has 'approve orders' permission AND order status is 'pending'
```

## Field Visibility

When fields should be hidden from some users:

```
Field Visibility:
  cost_price: only visible to users with 'view costs' permission
  internal_notes: only visible to users with 'admin' role
  commission: only visible when user owns the record
```

## Don't Write

| Bad (vague)           | Good (specific)                                                   |
| --------------------- | ----------------------------------------------------------------- |
| "Check if authorized" | "user has 'view orders' permission"                               |
| "Only owners"         | "user owns the order (user_id matches)"                           |
| "Admins only"         | "user has 'admin' role"                                           |
| "When allowed"        | "order status is 'pending' AND user has 'edit orders' permission" |
