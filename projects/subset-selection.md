---
title: Subset Selection
description: Review of Methods for Subset Selection
permalink: /projects/subset-selection
---

# Review and Comparison of Subset Selection Methods for Linear Regression

### Abstract

Many applications of regression modeling benefit from sparse parameter estimates, making the best subset selection problem a desired, although difficult, solution, which has been approximated by popular heuristics such as the Lasso.

My work presents results of extensive experiments comparing four methods for subset selection in linear regression, namely the Lasso, relaxed Lasso, a discrete first-order method presented and a mixed integer programming formulation of the best subset selection problem.

Both statistical performance and support recovery are evaluated, across different dimensionalities, noise levels, sparsity patterns and correlation factors, leading to the following main insights:

1. The Lasso yields good statistical performance in noisy settings
2. The relaxed Lasso performs well across a variety of scenarios, both in terms of statistical accuracy as well as support recovery
3. Best subset selection and the above-mentioned discrete first-order method provide the best support recovery, specially in high dimensional settings.
4. The discrete first-order method can give the same results as an MIP solution and may prove useful in other applications beyond linear regression

### Code

The code employed in this project can be found in [my github](https://github.com/miguelfmc/subset-selection).
