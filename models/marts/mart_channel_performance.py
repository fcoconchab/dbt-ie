def model(dbt, session):

    # --- CONFIGURATION ---
    # Tell dbt to store this as a physical table (not a view)
    dbt.config(materialized="table")

    # --- INPUT ---
    # Read stg_website_sessions using ref() — same as SQL, just Python syntax
    sessions = dbt.ref("stg_website_sessions")

    # Convert to a Pandas DataFrame so we can work with it in Python
    df = sessions.df()

    # --- TRANSFORMATION ---
    # Group by source and device_type, then calculate all metrics at once
    result = (
        df.groupby(["source", "device_type"])
        .agg(
            total_sessions=("session_id", "count"),              # count rows
            conversions=("converted", "sum"),                    # sum of 1s = count of conversions
            avg_page_views=("page_views", "mean"),               # average pages viewed
            avg_duration_seconds=("session_duration_seconds", "mean"),  # average time on site
            bounces=("is_bounce", "sum"),                        # count of bounced sessions
        )
        .reset_index()  # turn the groupby keys back into regular columns
    )

    # --- CALCULATED COLUMNS ---
    # bounce_rate: what % of sessions left immediately
    result["bounce_rate"] = result["bounces"] / result["total_sessions"] * 100

    # conversion_rate: what % of sessions resulted in a purchase
    result["conversion_rate"] = result["conversions"] / result["total_sessions"] * 100

    # channel_quality: classify the channel based on conversion rate
    def classify_quality(rate):
        if rate >= 10:
            return "high_performing"
        elif rate >= 5:
            return "average"
        else:
            return "low_performing"

    result["channel_quality"] = result["conversion_rate"].apply(classify_quality)

    # --- CLEANUP ---
    # Drop the intermediate 'bounces' column — we only needed it to calculate bounce_rate
    result = result.drop(columns=["bounces"])

    # Fix data types so DuckDB can read them correctly
    # DuckDB doesn't recognize Python's native 'str' type — convert explicitly by column name
    # (more reliable than checking dtype, which varies by Pandas version)
    result["source"] = result["source"].astype("string")
    result["device_type"] = result["device_type"].astype("string")
    result["channel_quality"] = result["channel_quality"].astype("string")

    # --- OUTPUT ---
    # Return the final dataframe — dbt will write it to DuckDB as a table
    return result