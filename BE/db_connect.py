import configparser
import os
import psycopg2
from psycopg2 import Error

def connect_to_postgres():
    # Tạo đối tượng parser
    config = configparser.ConfigParser()
    config.read('config.ini')
    if 'database' not in config:
        print("Lỗi: Section 'database' không tồn tại trong file config.ini.")
        return None
        
    db_host = config['database'].get('host')
    db_user = config['database'].get('user')
    db_password = config['database'].get('password')
    dbname = config['database'].get('db_name') 
    conn = None
    try:
        conn = psycopg2.connect(
            dbname=dbname,  
            user=db_user,
            password=db_password,
            host=db_host
        )
        print("Connected to the database successfully")
        return conn
    except Error as e:
        print(f"Error connecting to the database: {e}")
        return None

# Example usage
# if __name__ == '__main__':
#     conn = connect_to_postgres()
#     if conn:
#         conn.close()
#         print("Đã đóng kết nối.")

