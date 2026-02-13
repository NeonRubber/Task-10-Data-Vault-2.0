import logging
import requests
from airflow.models import Variable
from utils.constants import TG_TOKEN_VAR, TG_CHAT_ID_VAR



SUCCESS_IMAGES = ["https://media.tenor.com/g9EDqXL6Pd0AAAAe/cat-like.png"]
FAILURE_IMAGES = ["https://media.tenor.com/fjk1rI5fZxYAAAAe/siren-borzoi-siren-dog.png"]

def send_telegram_notification(context, status):
    # Send Telegram notification using Airflow Variables
    try:
        # Fetch variables inside the function to avoid DB hits during parsing
        tg_token = Variable.get(TG_TOKEN_VAR, default_var=None)
        tg_chat_id = Variable.get(TG_CHAT_ID_VAR, default_var=None)

        # Check for tokens
        if not tg_token or not tg_chat_id:
            raise ValueError("Telegram Token or Chat ID not found in Airflow Variables!")

        # 1 Preparing the data
        dag_id = str(context.get('dag').dag_id)
        task_id = str(context.get('task_instance').task_id)
        exec_date = str(context.get('execution_date'))[:19]

        # 2 Selecting status and image
        if status == "SUCCESS":
            label = "✅ SUCCESSFUL"
            img = SUCCESS_IMAGES[0]
        else:
            label = "🔴 FAILED"
            img = FAILURE_IMAGES[0]

        # 3 Formatting the text
        caption = (
            f"{label}\n"
            f"DAG: {dag_id}\n"
            f"Task: {task_id}\n"
            f"Time: {exec_date}"
        )

        # 4 Sending the request
        url = f"https://api.telegram.org/bot{tg_token}/sendPhoto"
        payload = {
            "chat_id": tg_chat_id,
            "photo": img,
            "caption": caption
        }

        logging.info(f"!!! Sending Telegram Notification via Variables for {task_id}...")
        
        response = requests.post(url, json=payload, timeout=10)
        
        if response.status_code != 200:
            logging.error(f"!!! TELEGRAM ERROR: {response.text}")
        
        response.raise_for_status()
        
    except Exception as e:
        logging.error(f"!!! CALLBACK FAILED: {str(e)}")

def send_telegram_success(context):
    send_telegram_notification(context, "SUCCESS")

def send_telegram_failure(context):
    send_telegram_notification(context, "FAILURE")