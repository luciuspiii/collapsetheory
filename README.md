| File                | Purpose                                                                         |
| ------------------- | ------------------------------------------------------------------------------- |
| `CollapseSystem.jl` | Defines `module CollapseSystem`, includes all other `.jl` source files.         |
| `scoring.jl`        | Implements `compute_psi_score`, status classification (STABLE, MODERATE, HIGH). |
| `data_fetch.jl`     | All live API functions: `fetch_borrow_rate_kamino`, `fetch_scores`, etc.        |
| `dashboard.jl`      | Formats and prints terminal dashboards with emojis, timestamps, statuses.       |
| `storage.jl`        | Manages `psi_history`, `borrow_history`, and saving/loading JSON snapshots.     |
| `plotting.jl`       | Contains `plot_score_history`, `plot_psi_vs_borrow`, and time range variants.   |
| `live_loop.jl`      | `run_loop()` function — performs periodic fetch, compute, record, plot.         |
| `utils.jl`          | Any date formatting, numeric normalization, or logging helpers.                 |



