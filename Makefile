.PHONY: up down lint clean

up:
	docker-compose up -d

down:
	docker-compose down

lint:
	uv run ruff check .
	uv run sqlfluff lint dbt_core/models

clean:
	rm -rf dbt_core/target
	rm -rf dbt_core/dbt_packages
	rm -rf dbt_core/logs

initial-load:
	docker-compose exec airflow-scheduler airflow dags trigger retail_full_load

clean-up:
	docker-compose exec airflow-scheduler airflow dags trigger retail_cleanup