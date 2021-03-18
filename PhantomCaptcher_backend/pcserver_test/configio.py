import configparser

def getValue(session_name,value_name):
    conf = configparser.ConfigParser()
    return [item[1] for item in conf.items(session_name) if item[0]==value_name][0]