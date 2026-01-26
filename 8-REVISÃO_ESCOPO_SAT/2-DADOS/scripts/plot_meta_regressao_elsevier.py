"""
Meta-Regression Plot - Elsevier Style
Replicates plot6_metaregressao_ano.png using Python (statsmodels) and Elsevier style.
"""

import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import statsmodels.api as sm

# Elsevier Colors
COLOR_POINT_FILL = "#B3CDE3" # Pastel Blue
COLOR_LINE = "#4D4D4D"
COLOR_BAND = "#E0E0E0"

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    # SAT-only source (built from BibTeX): build_sat_meta_analysis_dataset.py
    input_csv = os.path.join(
        script_dir,
        "..",
        "1-ESTATISTICA",
        "1-RSTUDIO",
        "9-META_ANALISE",
        "dados_meta_analise_sat.csv",
    )
    output_png = os.path.join(script_dir, "..", "..", "2-FIGURAS", "2-EN", "meta_regressao_ano.png")
    
    # Load Data
    df = pd.read_csv(input_csv)
    
    # Filter valid data
    df = df.dropna(subset=["ano", "acuracia", "variancia"])
    # Ensure variances are positive
    df = df[df["variancia"] > 0]
    
    # Variables
    y = df["acuracia"]
    X = df["ano"]
    weights = 1.0 / df["variancia"]
    
    # Prepare X for statsmodels (add constant for intercept)
    X_const = sm.add_constant(X)
    
    # WLS (Weighted Least Squares) - Fixed Effects assumption proxy
    model = sm.WLS(y, X_const, weights=weights)
    results = model.fit()
    
    # Prediction for line
    x_pred = np.linspace(X.min(), X.max(), 100)
    x_pred_const = sm.add_constant(x_pred)
    
    # Get prediction and confidence intervals
    # statsmodels get_prediction().summary_frame() returns mean, mean_se, mean_ci_lower, mean_ci_upper...
    pred = results.get_prediction(x_pred_const)
    pred_df = pred.summary_frame(alpha=0.05)
    
    # Plot
    plt.style.use('default')
    plt.rcParams.update({
        "figure.figsize": (10, 7),
        "figure.dpi": 300,
        "font.family": "serif",
        "font.size": 12,
        "axes.facecolor": "white",
        "axes.edgecolor": "black",
        "axes.spines.top": False,
        "axes.spines.right": False,
    })
    
    fig, ax = plt.subplots()
    
    # Confidence Band
    ax.fill_between(x_pred, pred_df["mean_ci_lower"], pred_df["mean_ci_upper"], 
                    color=COLOR_BAND, alpha=0.5, label="95% CI")
    
    # Regression Line
    ax.plot(x_pred, pred_df["mean"], color=COLOR_LINE, linewidth=2, label="Meta-regression")
    
    # Points (Weighted Bubble Plot)
    # Normalize weights for size (e.g. 20 to 200)
    w_min, w_max = weights.min(), weights.max()
    if np.isclose(w_min, w_max):
        sizes = np.full_like(weights, 60.0, dtype=float)
    else:
        sizes = 20 + (weights - w_min) / (w_max - w_min) * 180
    
    scatter = ax.scatter(X, y, s=sizes, c=COLOR_POINT_FILL, edgecolors='black', linewidth=0.5, alpha=0.9, zorder=3)
    
    # Labels
    ax.set_xlabel("Publication Year")
    ax.set_ylabel("Reported Accuracy (%)")
    ax.set_title("Meta-Regression: Accuracy Trend Over Time")
    
    # Slope info
    slope = results.params["ano"]
    p_value = results.pvalues["ano"]
    text_str = f"Slope: {slope:.3f} (p={p_value:.4f})"
    props = dict(boxstyle='round', facecolor='white', alpha=0.9, edgecolor='lightgray')
    ax.text(0.05, 0.95, text_str, transform=ax.transAxes, fontsize=10,
            verticalalignment='top', bbox=props)

    plt.tight_layout()
    plt.savefig(output_png, dpi=300)
    print(f"Meta-regression saved to {output_png}")

if __name__ == "__main__":
    main()
