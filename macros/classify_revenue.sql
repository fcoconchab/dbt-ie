{% macro classify_revenue(amount_col, low_threshold=100, high_threshold=500) %}

    case
        when {{ amount_col }} >= {{ high_threshold }} then 'high'
        when {{ amount_col }} >= {{ low_threshold }}  then 'medium'
        else                                               'low'
    end

{% endmacro %}