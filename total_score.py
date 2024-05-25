from pprint import pprint
import csv

from peewee import *


def get_data_from_view(db, q):    
    query = db.execute_sql(q)
    return query.fetchall()


def write_total_score_to_csv(data):
    with open('total_score.csv', 'w', newline='') as f:
        writer = csv.writer(f, delimiter=';')
        writer.writerow(['inn', 'total_score'])
        writer.writerows(data)



if __name__ == "__main__":


    credentials = {
        "user": 'user',
        "password": 'password',
        "host": 'host',
        "database": 'database',
    }

    db = PostgresqlDatabase(**credentials)
    query = "SELECT * FROM total_score"
    data = get_data_from_view(db, query)
    write_total_score_to_csv(data)




