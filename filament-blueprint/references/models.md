# Model Specifications

> **For planning agents**: Copy all relevant information from this file into
> your plan. The implementing agent will only see your plan, not this file.

Define every model completely so the implementing agent can create migrations
and models without guessing.

## New vs Update

For new models, specify full attributes. For existing models, specify only
changes:

```
## New Model
Model: Order
  Table: orders
  Attributes:
    - id: bigint, primary
    - status: string, required
    ...

## Update Existing Model
Migration: add_tracking_to_orders
  Table: orders
  Add: tracking_number (string, nullable)
  Add: shipped_at (timestamp, nullable)
  Remove: legacy_field
  Modify: status (add 'shipped' to enum)
```

## What to Include

| Element               | Why the Implementing Agent Needs It |
| --------------------- | ----------------------------------- |
| Table name            | For migration                       |
| Attributes with types | For migration columns               |
| Constraints           | For migration modifiers             |
| Relationships         | For model methods                   |
| Traits                | For model traits                    |

## Plan Format

```
Model: Order
  Table: orders
  Attributes:
    - id: bigint, primary
    - user_id: bigint, foreign(users.id), required
    - status: enum(pending|confirmed|shipped|delivered|cancelled), default:pending
    - total_cents: integer, required
    - notes: text, nullable
    - shipped_at: timestamp, nullable
    - created_at: timestamp
    - updated_at: timestamp
    - deleted_at: timestamp, nullable
  Relationships:
    - belongsTo: User via user_id
    - hasMany: OrderItem via order_id
  Traits:
    - SoftDeletes
```

## Attribute Types

| Type                | Use For                    |
| ------------------- | -------------------------- |
| `bigint`            | IDs, foreign keys          |
| `integer`           | Counts, amounts in cents   |
| `string`            | Short text (names, emails) |
| `text`              | Long text                  |
| `boolean`           | True/false                 |
| `timestamp`         | Dates with time            |
| `date`              | Dates without time         |
| `enum(a or b or c)` | Fixed set of values        |
| `json`              | Arrays or objects          |

## Constraints

| Constraint              | Meaning                  |
| ----------------------- | ------------------------ |
| `primary`               | Primary key              |
| `required`              | Not nullable, no default |
| `nullable`              | Can be null              |
| `unique`                | Must be unique           |
| `foreign(table.column)` | Foreign key reference    |
| `default:value`         | Default value            |

## Relationship Format

```
- belongsTo: User via user_id
- hasMany: OrderItem via order_id
- belongsToMany: Product via order_products
- hasOne: Profile via user_id
```

## Soft Deletes

When using soft deletes, you must specify BOTH:

1. The `SoftDeletes` trait in Traits
2. The `deleted_at: timestamp, nullable` attribute

```
Model: Order
  Attributes:
    ...
    - deleted_at: timestamp, nullable
  Traits:
    - SoftDeletes
```

The implementing agent needs both to create the migration column AND add the
trait to the model class. Missing either will cause errors.

## Enums

For enums used in Filament, implement interfaces from
`Filament\Support\Contracts`. Always implement `HasLabel`. Add `HasColor` and
`HasIcon` if displayed as badges.

```
Enum: OrderStatus
  Implements: HasLabel, HasColor, HasIcon
  Cases:
    - pending: label "Pending", color "warning", icon "Heroicon::Clock"
    - confirmed: label "Confirmed", color "success", icon "Heroicon::Check"
    - shipped: label "Shipped", color "info", icon "Heroicon::Truck"
    - cancelled: label "Cancelled", color "danger", icon "Heroicon::XMark"
```

## Don't Write

| Bad (vague)            | Good (specific)                                                  |
| ---------------------- | ---------------------------------------------------------------- |
| "Standard timestamps"  | `created_at: timestamp` and `updated_at: timestamp`              |
| "Foreign key to users" | `user_id: bigint, foreign(users.id), required`                   |
| "Status field"         | `status: enum(pending or confirmed or shipped), default:pending` |
