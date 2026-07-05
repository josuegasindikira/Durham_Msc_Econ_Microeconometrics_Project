# Job-Retention Schemes and Employment During Covid: Evidence from Albion

## Overview

This repository contains the Stata code and report for a microeconometric analysis of a Covid-era job-retention loan scheme in Albion.

The project studies two main questions:

1. **Which firm characteristics predict participation in the loan scheme?**
2. **What was the causal effect of the scheme on firm employment?**

The analysis combines descriptive statistics, binary-choice models, panel-data estimators, Difference-in-Differences, and matching methods.

## Data

The dataset is a balanced panel of **1,000 firms observed from 2018 to 2020** across two regions:

- **North:** 500 firms
- **South:** 500 firms

In 2020, the job-retention scheme was introduced only in the North. Among northern firms:

- **350 firms received the loan**
- **150 firms did not receive the loan**

Main variables include:

- `loan` — indicator for loan receipt
- `employment` — number of employees
- `leverage` — liabilities relative to assets
- `age` — firm age
- `industry` — industry category
- `state` — regional indicator
- `year` — year
- `id` — firm identifier

> **Data availability:** The dataset was provided for academic coursework and is redistributed in this repository.

## Empirical Strategy

### 1. Descriptive Analysis

The project first compares firms across:

- North vs South
- Treated vs untreated firms in the North
- Treated northern firms vs all untreated firms

Mean-comparison t-tests are used to assess differences in firm characteristics and employment.

### 2. Prediction of Loan Receipt

Loan participation is modelled using:

- Linear Probability Model (LPM)
- Logit
- Probit

The main predictors are:

- leverage
- 2019 employment
- firm age
- industry

Average marginal effects are reported for the nonlinear probability models.

### 3. Panel-Data Estimators

The employment effect of the loan is also examined using:

- Pooled OLS
- Firm Fixed Effects
- First Differences

These estimators provide robustness checks while accounting for part of the unobserved firm heterogeneity.

### 4. Difference-in-Differences

A Difference-in-Differences framework is used to compare changes in employment between treated and untreated firms around the 2020 policy intervention.

### 5. Matching Methods

To address observable selection into treatment, the project applies:

- Nearest-neighbour matching with Mahalanobis distance
- Propensity-score matching based on a Logit model

Matching quality is assessed using balance plots for:

- 2019 employment
- leverage
- firm age

The analysis compares matching based on:

- untreated firms in the North only
- all untreated firms in the sample

### 6. Matching + Difference-in-Differences

The preferred specification combines matching with Difference-in-Differences.

This approach aims to reduce bias from both:

- observable differences in firm characteristics
- common time effects

## Main Findings

The results suggest that loan participation was non-random:

- firms with higher leverage were more likely to receive the loan;
- firms with higher pre-treatment employment were more likely to participate;
- older firms were less likely to participate.

The preferred matching + Difference-in-Differences estimator finds a **positive and statistically significant employment effect of approximately 4.24 jobs per treated firm on average**.

## Figures

The Stata code reproduces the main figures used in the report:

1. Quality of match — Employment
2. Quality of match — Leverage
3. Parallel trends before matching
4. Parallel trends after matching
5. Quality of match — Age
