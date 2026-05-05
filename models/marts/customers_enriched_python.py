import polars as pl


def model(dbt, session):
    dbt.config(materialized="table")

    # Reference the upstream dim_customers model
    dim_customers = dbt.ref("dim_customers")

    # Convert to Polars DataFrame
    pdf = dim_customers.pl()

    # Categorize customers by email provider
    def categorize_email(email):
        if not email:
            return "Unknown"
        try:
            domain = email.split("@")[1]
            if "gmail" in domain:
                return "Gmail"
            elif "yahoo" in domain:
                return "Yahoo"
            elif "hotmail" in domain or "outlook" in domain:
                return "Microsoft"
            else:
                return "Other"
        except Exception:
            return "Unknown"

    # Apply using Polars map_elements
    pdf = pdf.with_columns(
        pl.col("email").map_elements(
            categorize_email, return_dtype=pl.String
        ).alias("email_provider")
    )

    return pdf