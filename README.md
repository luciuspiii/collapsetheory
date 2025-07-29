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


CollapseSystem/
├── Project.toml
├── Manifest.toml
├── src/
│   ├── CollapseSystem.jl           # Main module entry point
│   ├── scoring.jl                  # Ψ-score computation logic
│   ├── data_fetch.jl               # External API calls (e.g. Kamino, Drift)
│   ├── dashboard.jl                # Terminal display & summary printing
│   ├── storage.jl                  # Historical storage (score, borrow)
│   ├── plotting.jl                 # All plotting utilities (Plots.jl)
│   ├── live_loop.jl                # Live update scheduler / main loop
│   └── utils.jl                    # Helper functions, formatting, status logic
├── test_run.jl                     # Dev script for testing full run
├── run_loop.jl                     # Production execution loop (uses `include(...)`)
├── data/
│   ├── psi_history.json            # Saved Ψ-score time series
│   ├── borrow_history.json         # Borrow rate time series
│   └── config.json                 # Asset list, alert thresholds, etc.
└── plots/
    └── BONK_plot.png              # Saved plots
