{% macro drop_existing_constraints(table_ref, constraint_type) %}
  {#
    Queries Snowflake for existing constraints on a table and drops them.
    constraint_type: "PRIMARY KEY" or "FOREIGN KEY"
  #}
  {% if constraint_type == "PRIMARY KEY" %}
    {% set show_query = "SHOW PRIMARY KEYS IN TABLE " ~ table_ref %}
  {% else %}
    {% set show_query = "SHOW IMPORTED KEYS IN TABLE " ~ table_ref %}
  {% endif %}

  {% do log("show_query=" ~ show_query, true) %}
  {% set result = run_query(show_query) %}
  {% set ns = namespace(names=[]) %}
  {% for row in result.rows %}
    {% if constraint_type == "PRIMARY KEY" %}
      {% set name = row["constraint_name"] %}
    {% else %}
      {% set name = row["fk_name"] %}
    {% endif %}
    {% if name and name not in ns.names %}
      {% set ns.names = ns.names + [name] %}
    {% endif %}
  {% endfor %}

  {% for name in ns.names %}
    {% set drop_stmt = "ALTER TABLE " ~ table_ref ~ " DROP CONSTRAINT \"" ~ name ~ "\"" %}
    {% do log("drop_stmt=" ~ drop_stmt, true) %}
    {% do run_query(drop_stmt) %}
    {{ log("Dropped " ~ constraint_type ~ ": " ~ name ~ " from " ~ table_ref, info=True) }}
  {% endfor %}
{% endmacro %}


{% macro add_constraints() %}

  {% set customers = ref('customers') %}
  {% set orders = ref('orders') %}
  {% set order_items = ref('order_items') %}
  {% set products = ref('products') %}
  {% set locations = ref('locations') %}
  {% set supplies = ref('supplies') %}

  {% set tables = [customers, orders, order_items, products, locations, supplies] %}

  {# Drop all FKs across all tables first, then all PKs #}
  {% for t in tables %}
    {{ drop_existing_constraints(t, "FOREIGN KEY") }}
  {% endfor %}
  {% for t in tables %}
    {{ drop_existing_constraints(t, "PRIMARY KEY") }}
  {% endfor %}

  {# Add PKs #}
  {% set pk_statements = [
    "ALTER TABLE " ~ customers ~ " ADD CONSTRAINT pk_customers PRIMARY KEY (customer_id);",
    "ALTER TABLE " ~ orders ~ " ADD CONSTRAINT pk_orders PRIMARY KEY (order_id);",
    "ALTER TABLE " ~ order_items ~ " ADD CONSTRAINT pk_order_items PRIMARY KEY (order_item_id);",
    "ALTER TABLE " ~ products ~ " ADD CONSTRAINT pk_products PRIMARY KEY (product_id);",
    "ALTER TABLE " ~ locations ~ " ADD CONSTRAINT pk_locations PRIMARY KEY (location_id);",
    "ALTER TABLE " ~ supplies ~ " ADD CONSTRAINT pk_supplies PRIMARY KEY (supply_uuid);",
  ] %}

  {% for stmt in pk_statements %}
    {% do run_query(stmt) %}
    {{ log("Applied: " ~ stmt, info=True) }}
  {% endfor %}

  {# Add FKs #}
  {% set fk_statements = [
    "ALTER TABLE " ~ orders ~ " ADD CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES " ~ customers ~ "(customer_id);",
    "ALTER TABLE " ~ orders ~ " ADD CONSTRAINT fk_orders_location FOREIGN KEY (location_id) REFERENCES " ~ locations ~ "(location_id);",
    "ALTER TABLE " ~ order_items ~ " ADD CONSTRAINT fk_order_items_order FOREIGN KEY (order_id) REFERENCES " ~ orders ~ "(order_id);",
    "ALTER TABLE " ~ supplies ~ " ADD CONSTRAINT fk_supplies_product FOREIGN KEY (product_id) REFERENCES " ~ products ~ "(product_id);",
  ] %}

  {% for stmt in fk_statements %}
    {% do run_query(stmt) %}
    {{ log("Applied: " ~ stmt, info=True) }}
  {% endfor %}

{% endmacro %}
