import logging
from os import getenv
from datetime import date
from contextlib import contextmanager

from playhouse.postgres_ext import JSONField
from peewee import *



logger = logging.getLogger(__name__)

credentials = {
    "user": getenv('DB_USER'),
    "password": getenv('DB_PASS'),
    "host": getenv('DB_HOST', 'localhost'),
    "database": getenv('DB_USER', 'postgres'),
}

db = PostgresqlDatabase(**credentials)



class BaseModel(Model):
    class Meta:
        database = db


class ClientActivity(BaseModel):
    inn = TextField()
    type = TextField()
    value = TextField()
    date = DateField()
    call_type = TextField()


class ContactCC(BaseModel):
    name = TextField()
    site = TextField()
    phone_numbers = JSONField()


class Tender(BaseModel):
    kam = TextField(null=True)
    division = TextField(null=True)
    fz = TextField(null=True)
    purchase_name = TextField(null=True)
    lot_name = TextField(null=True)
    format = TextField(null=True)
    nmc = TextField(null=True)
    size = TextField(null=True)
    start_date =  TimestampField(null=True)
    stop_date =  TimestampField(null=True)
    duration = IntegerField(null=True)
    customer_name = TextField(null=True)
    customer_inn = TextField(null=True)
    customer_region = TextField(null=True)


class AKC(BaseModel):
    value = TextField()
    type = TextField()


class Repository:
    def __init__(self, session) -> None:
        self.session = session
        self.check_con()

    def check_con(self):
        try:
            self.session.connect()
        except Exception:        
            logger.error('Не удалось подключиться к БД. Работа скрипта будет завершена.')
            return False
        else:
            return True

    def create_tables(self, list_of_tables):
        with self.session as s:
            try:
                s.create_tables(list_of_tables)
            except Exception as e:
                logger.error(e)

    def add(self, table, row):
        with self.session.atomic():  
            try:
                table.create(**row)
            except Exception as e:
                logger.error(e)

    def load(self, table, rows):
        with self.session.atomic():
            table.insert_many(rows).execute()
 

 
if __name__ == "__main__":
    con = Repository(db)
    con.create_tables([ClientActivity, ContactCC, Tender])
