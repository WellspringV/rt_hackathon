import pandas as pd

from orm import db, Repository, ClientActivity, ContactCC, Tender, AKC
from downloader import DownloadManager
from szunpack import SZUnpack



def clean_list(lst):
        return [x for x in lst if pd.notnull(x)]




if __name__ == "__main__":
    url = 'https://contestfiles.storage.yandexcloud.net/companies/76b19c3f3c417fc4f9623ba4d00cbde8/data.7z?roistat_visit=1390266'
    filename = 'data.7z'

    DLoader = DownloadManager(url)
    DLoader.download()

    Unpack = SZUnpack('data.7z')
    Unpack.unpack_archive()
    Unpack.remove_archive()


    DB_con = Repository(db)
    DB_con.create_tables([ClientActivity, ContactCC, Tender, AKC])


    # =========================================== CONTACT CC ======================================================================================================== #

    df_cc = pd.read_excel('data//Contact_CC.xlsx')
    df_cc.rename(columns={"Unnamed: 0": "id", "наименование": "name", "сайт": "site"}, inplace=True)
    df_cc = df_cc.assign(phone_numbers=lambda x: x[['телефон', 'телефон.1', 'телефон.2']].apply(lambda row: [row['телефон'], row['телефон.1'], row['телефон.2']], axis=1))
    df_cc = df_cc.drop(columns=['телефон', 'телефон.1', 'телефон.2'])
    df_cc['phone_numbers'] = df_cc['phone_numbers'].apply(clean_list)
    data_list_cc = df_cc.to_dict('records')

    for row in data_list_cc:        
        DB_con.add(ContactCC, row)
    # =============================================================================================================================================================== #
 


    

    # =============== START HADRCODE BLOCK  ===================== #
    df = pd.read_excel('data//tender.xlsx')
    df = df.rename(columns = {
        'Ответственный пользователь': 'kam',
        'Подразделение 2-го уровня': 'division',
        'Тип закупки (ФЗ)': 'fz',
        'Наименование закупки': 'purchase_name',
        'Наименование лота': 'lot_name',
        'Способ проведения закупки': 'format',
        'НМЦ закупки': 'nmc',
        'Дата начала приёма заявок': 'start_date',
        'Дата окончания приёма заявок': 'stop_date',
        'Длительность этапа (дней)': 'duration',        
        'Наименование заказчика': 'customer_name',
        'ИНН заказчика': 'customer_inn',
        'Регион заказчика': 'customer_region',
    })

    # Где статус?

    # true_keys = [key for key in vars(Tender).keys() if not key.startswith('_')]     
    # df = df.rename(columns=dict(zip(df.columns, true_keys)))
    
    data_list = df.to_dict('records')
    for row in data_list:
        DB_con.add(Tender, row)
    # =============== END HADRCODE BLOCK  ===================== #



   
   # ============================== AKC  ================================== #
    second_sheet_df = pd.read_excel('data//tender.xlsx', sheet_name='АКЦ')
    f = second_sheet_df.rename(columns = {'Значение': 'value', 'Тип': 'type'})  
    data_list = f.to_dict('records')
    for row in data_list:
        DB_con.add(AKC, row)
   # ====================================================================== #



   # =========================================== BIG DATA ======================================================================================================== #    
    chunk_size = 10000
    chunks = pd.read_csv('data/BigData.csv', encoding='utf-8', encoding_errors='ignore', delimiter=';', chunksize=chunk_size)    
    for chunk in chunks:
        data_list_bd = chunk.to_dict('records')
        DB_con.load(ClientActivity, data_list_bd)
   # ============================================================================================================================================================= #
