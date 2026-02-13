.PHONY: up down lint clean build rebuild initial-load incremental-load clean-up

up:
	docker-compose up -d

build:
	docker-compose build

rebuild:
	docker-compose down
	docker-compose build
	docker-compose up -d

down:
	docker-compose down

lint:
	uv run ruff check . && \
	uv run sqlfluff lint dbt_core/models --dialect snowflake

clean:
	rm -rf dbt_core/target
	rm -rf dbt_core/dbt_packages
	rm -rf dbt_core/logs

initial-load:
	docker-compose exec airflow-scheduler airflow dags trigger retail_full_load

incremental-load:
	docker-compose exec airflow-scheduler airflow dags trigger retail_incremental_load

clean-up:
	docker-compose exec airflow-scheduler airflow dags trigger retail_cleanup