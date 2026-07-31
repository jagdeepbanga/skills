# Widget Specifications

> **For planning agents**: Copy all relevant information from this file into
> your plan. The implementing agent will only see your plan, not this file.

## What to Include

| Element     | Why the Implementing Agent Needs It |
| ----------- | ----------------------------------- |
| Widget type | Stats, Chart, or Table              |
| Command     | Artisan command to scaffold         |
| Location    | Dashboard or resource page          |
| Data source | Model/query for the widget          |

## Commands

```
php artisan make:filament-widget {Name} --stats-overview --no-interaction
php artisan make:filament-widget {Name} --chart --no-interaction
php artisan make:filament-widget {Name} --table --no-interaction
php artisan make:filament-widget {Name} --resource={Resource} --no-interaction
```

## Widget Types

| Type  | Component                              | Docs                                                            |
| ----- | -------------------------------------- | --------------------------------------------------------------- |
| Stats | `Filament\Widgets\StatsOverviewWidget` | https://filamentphp.com/docs/5.x/widgets/stats-overview         |
| Chart | `Filament\Widgets\ChartWidget`         | https://filamentphp.com/docs/5.x/widgets/charts                 |
| Table | `Filament\Widgets\TableWidget`         | https://filamentphp.com/docs/5.x/widgets/overview#table-widgets |

## Stats Widget Plan Format

```
Widget: OrderStats
  Type: StatsOverviewWidget
  Command: php artisan make:filament-widget OrderStats --stats-overview
  Location: Dashboard

  Stats:
    Stat: Pending Orders
      Value: Order::where('status', 'pending')->count()
      Color: warning
      Icon: Heroicon::Clock

    Stat: Revenue
      Value: Order::sum('total') / 100
      Format: money
      Description: This month
      DescriptionIcon: Heroicon::ArrowTrendingUp
      Color: success
```

## Chart Widget Plan Format

Chart types: line, bar, pie, doughnut, radar, polarArea, scatter, bubble

```
Widget: OrdersChart
  Type: ChartWidget
  Command: php artisan make:filament-widget OrdersChart --chart
  Location: Dashboard
  ChartType: line
  Heading: Orders Over Time
  Color: primary

  Data:
    Model: Order
    Aggregation: count
    Period: perMonth
    Range: startOfYear to endOfYear
```

## Table Widget Plan Format

```
Widget: LatestOrders
  Type: TableWidget
  Command: php artisan make:filament-widget LatestOrders --table
  Location: Dashboard

  Model: Order
  Query: Order::latest()->limit(5)
  Columns: (see [tables.md] for column format)
```

## Resource Page Widgets

```
Widget: CustomerStats
  Type: StatsOverviewWidget
  Command: php artisan make:filament-widget CustomerStats --resource=CustomerResource
  Location: CustomerResource Edit page header
  RecordAccess: $this->record

  Stats:
    Stat: Total Orders
      Value: $this->record->orders()->count()
```

## Configuration

| Property           | Purpose                             |
| ------------------ | ----------------------------------- |
| `$sort`            | Order on dashboard (lower = higher) |
| `$columnSpan`      | Width: 1-12 or 'full'               |
| `$pollingInterval` | '5s', '10s', or null to disable     |

## Don't Write

| Bad (vague)            | Good (specific)                        |
| ---------------------- | -------------------------------------- |
| "Add order statistics" | List each Stat with Value, Color, Icon |
| "Show a chart"         | Specify ChartType, Data source, Period |
