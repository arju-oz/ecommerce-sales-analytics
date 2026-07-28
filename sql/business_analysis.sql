USE ecommerce_analytics;
-- ==========================================================================================================================================
-- Q1: Revenue & Category Performance
-- Which product categories drive the most revenue, and are there 
-- categories with high sales but poor reviews (a hidden risk)?
-- ==========================================================================================================================================
SELECT 
    ct.product_category_name_english AS category,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(AVG(rev.review_score), 2) AS avg_review_score,
    COUNT(oi.order_id) AS total_orders
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN category_translation ct ON p.product_category_name = ct.product_category_name
LEFT JOIN order_reviews rev ON oi.order_id = rev.order_id
GROUP BY category
ORDER BY total_revenue DESC
LIMIT 15;

-- ==========================================================================================================================================
-- Q2: Customer Purchase Behavior
-- What proportion of customers are one-time vs repeat buyers, and how 
-- much revenue does each segment contribute?
-- ==========================================================================================================================================
SELECT 
    buyer_type,
    COUNT(*) AS number_of_customers,
    ROUND(SUM(customer_revenue), 2) AS total_revenue
FROM (
    SELECT 
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(oi.price) AS customer_revenue,
        CASE 
            WHEN COUNT(DISTINCT o.order_id) = 1 THEN 'One-time buyer'
            ELSE 'Repeat buyer'
        END AS buyer_type
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id
) AS customer_summary
GROUP BY buyer_type;

-- ==========================================================================================================================================
-- Q3: Delivery Performance & Satisfaction
-- Does delivery speed correlate with review scores, and which states 
-- have the worst delivery performance?
-- ==========================================================================================================================================
SELECT 
    c.customer_state,
    ROUND(AVG(o.delivery_delay_days), 2) AS avg_delivery_delay,
    ROUND(AVG(r.review_score), 2) AS avg_review_score,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.delivery_delay_days IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_delivery_delay DESC
LIMIT 10;

-- ==========================================================================================================================================
-- Q4: Payment Behavior
-- Which payment methods and installment patterns are most common, and 
-- do certain payment types correlate with order value?
-- ==========================================================================================================================================
SELECT 
    payment_type,
    COUNT(*) AS total_transactions,
    ROUND(AVG(payment_installments), 2) AS avg_installments,
    ROUND(AVG(payment_value), 2) AS avg_payment_value,
    ROUND(SUM(payment_value), 2) AS total_payment_value
FROM order_payments
GROUP BY payment_type
ORDER BY total_transactions DESC;

-- ==========================================================================================================================================
-- Q5: Seller Performance & Marketplace Health
-- Are a small number of sellers responsible for a large share of revenue?
-- ==========================================================================================================================================
SELECT 
    s.seller_id,
    s.seller_state,
    ROUND(SUM(oi.price), 2) AS seller_revenue,
    COUNT(DISTINCT oi.order_id) AS total_orders
FROM order_items oi
JOIN sellers s ON oi.seller_id = s.seller_id
GROUP BY s.seller_id, s.seller_state
ORDER BY seller_revenue DESC
LIMIT 10;

-- =========================================================================================================================================
-- Q6: RFM Customer Segmentation
-- Who are the most valuable customers based on Recency, Frequency, 
-- and Monetary value?
-- =========================================================================================================================================
SELECT 
    c.customer_unique_id,
    DATEDIFF('2018-10-17', MAX(o.order_purchase_timestamp)) AS recency_days,
    COUNT(DISTINCT o.order_id) AS frequency,
    ROUND(SUM(oi.price), 2) AS monetary
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_unique_id;

-- Step 2: Score each customer 1-5 on R, F, M-----------------------------------------------------------------------------------------------
SELECT 
    customer_unique_id,
    recency_days,
    frequency,
    monetary,
    NTILE(5) OVER (ORDER BY recency_days DESC) AS recency_score,
    NTILE(5) OVER (ORDER BY frequency ASC) AS frequency_score,
    NTILE(5) OVER (ORDER BY monetary ASC) AS monetary_score
FROM (
    SELECT 
        c.customer_unique_id,
        DATEDIFF('2018-10-17', MAX(o.order_purchase_timestamp)) AS recency_days,
        COUNT(DISTINCT o.order_id) AS frequency,
        ROUND(SUM(oi.price), 2) AS monetary
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id
) AS rfm_base;

-- Q6: RFM Segmentation — Final: Combine scores into named segments--------------------------------------------------------------------------
SELECT 
    customer_unique_id,
    recency_score,
    frequency_score,
    monetary_score,
    (recency_score + frequency_score + monetary_score) AS rfm_total,
    CASE 
        WHEN (recency_score + frequency_score + monetary_score) >= 12 THEN 'Champions'
        WHEN (recency_score + frequency_score + monetary_score) >= 9 THEN 'Loyal Customers'
        WHEN (recency_score + frequency_score + monetary_score) >= 6 THEN 'Potential Loyalists'
        WHEN (recency_score + frequency_score + monetary_score) >= 4 THEN 'At Risk'
        ELSE 'Lost'
    END AS customer_segment
FROM (
    SELECT 
        customer_unique_id,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS recency_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS frequency_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS monetary_score
    FROM (
        SELECT 
            c.customer_unique_id,
            DATEDIFF('2018-10-17', MAX(o.order_purchase_timestamp)) AS recency_days,
            COUNT(DISTINCT o.order_id) AS frequency,
            ROUND(SUM(oi.price), 2) AS monetary
        FROM customers c
        JOIN orders o ON c.customer_id = o.customer_id
        JOIN order_items oi ON o.order_id = oi.order_id
        GROUP BY c.customer_unique_id
    ) AS rfm_base
) AS rfm_scored;

-- Q6: RFM Segment Summary -----------------------------------------------------------------------------------------------------------------
SELECT 
    customer_segment,
    COUNT(*) AS num_customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_customers
FROM (
    SELECT 
        customer_unique_id,
        CASE 
            WHEN (recency_score + frequency_score + monetary_score) >= 12 THEN 'Champions'
            WHEN (recency_score + frequency_score + monetary_score) >= 9 THEN 'Loyal Customers'
            WHEN (recency_score + frequency_score + monetary_score) >= 6 THEN 'Potential Loyalists'
            WHEN (recency_score + frequency_score + monetary_score) >= 4 THEN 'At Risk'
            ELSE 'Lost'
        END AS customer_segment
    FROM (
        SELECT 
            customer_unique_id,
            NTILE(5) OVER (ORDER BY recency_days DESC) AS recency_score,
            NTILE(5) OVER (ORDER BY frequency ASC) AS frequency_score,
            NTILE(5) OVER (ORDER BY monetary ASC) AS monetary_score
        FROM (
            SELECT 
                c.customer_unique_id,
                DATEDIFF('2018-10-17', MAX(o.order_purchase_timestamp)) AS recency_days,
                COUNT(DISTINCT o.order_id) AS frequency,
                ROUND(SUM(oi.price), 2) AS monetary
            FROM customers c
            JOIN orders o ON c.customer_id = o.customer_id
            JOIN order_items oi ON o.order_id = oi.order_id
            GROUP BY c.customer_unique_id
        ) AS rfm_base
    ) AS rfm_scored
) AS segments
GROUP BY customer_segment
ORDER BY num_customers DESC;