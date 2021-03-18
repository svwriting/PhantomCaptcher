

import DBcontrol

# print(DBcontrol.GetAllAccount())
# print(DBcontrol.GetAccountInfo('user_test','user_test'))

# print(DBcontrol.GetAllImgInfo())
# print(DBcontrol.GetImgInfo('img_userid','user_test'))


# DBcontrol.DeleteImg(f'user_pic/fitin_test.png')
# DBcontrol.DeleteImgsByID('user_test-20210220-221340-781170')
a=DBcontrol.GetUserIP('user_test')
print(a)