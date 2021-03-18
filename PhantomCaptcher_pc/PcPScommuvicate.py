from photoshop import PhotoshopConnection


def paste(filename, name, x, y, password='123456'):
    
    # There seem to be a bug on Windows where the path must be using unix separators.
    # https://github.com/cyrildiagne/ar-cutpaste/issues/5
    filename = filename.replace('\\', '/')

    # with PhotoshopConnection(password=password) as conn:
    #     script = open(basename(dirname(__file__)) + '/script.js', 'r').read()
    #     x -= DOC_WIDTH * 0.5 + DOC_OFFSET_X
    #     y -= DOC_HEIGHT * 0.5 + DOC_OFFSET_Y
    #     script += f'pasteImage("{filename}", "{name}", {x}, {y})'
    #     result = conn.execute(script)
    #     print(result)
    #     if result['status'] != 0:
    #         return result
    
    return None



with PhotoshopConnection(password='123456') as conn:
    print('========================================================================')
    info_=conn.get_document_info()
    for layer_ in info_['layers']:
        for index_ in layer_:
            print(f"{index_}:\n\t{layer_[index_]}")
        print('------------------------------------------------------------------------')
    