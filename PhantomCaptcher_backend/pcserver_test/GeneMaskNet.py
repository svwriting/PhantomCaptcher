
#----------------- in BASNet ------------------
# import sys
# sys.path.append("..")
# sys.path.insert(0, 'BASNet')
from data_loader import RescaleT
from data_loader import ToTensorLab

from models import BASNet
from models import U2Net
from models import U2NetP
from models import U2Net_full # 理論上=U2Net
from models import U2Net_lite # 理論上=U2NetP
#--------------------------------------------------

from skimage import io, transform
import torch
import torchvision
from torch.autograd import Variable
import torch.nn as nn
import torch.nn.functional as F
from torch.utils.data import Dataset, DataLoader
from torchvision import transforms

from torch.utils.data import Dataset, DataLoader

import numpy as np
from PIL import Image


# model_dir = './BASNet/saved_models/basnet_bsi/basnet.pth'
# model_dir ='/content/drive/MyDrive/TibaMe/Phantom Captcher/BASNet/saved_models/basnet_bsi/basnet.pth'

# model_dir ='/content/drive/MyDrive/TibaMe/Phantom Captcher/U-2-Net/saved_models/u2net/u2net.pth'
model_dir ='pth/U2Net.pth'


print("Loading GeneMaskNet...")

#net = BASNet(3, 1)
# net = U2Net(3, 1)
#net = U2NetP(3, 1)
net = U2Net_full()
#net = U2Net_lite()

net.load_state_dict(torch.load(model_dir))
if torch.cuda.is_available():
    net.cuda()
net.eval()


def normPRED(d):
    ma = torch.max(d)
    mi = torch.min(d)
    dn = (d - mi) / (ma - mi)
    return dn


def preprocess(image):
    label_3 = np.zeros(image.shape)
    label = np.zeros(label_3.shape[0:2])

    if (3 == len(label_3.shape)):
        label = label_3[:, :, 0]
    elif (2 == len(label_3.shape)):
        label = label_3

    if (3 == len(image.shape) and 2 == len(label.shape)):
        label = label[:, :, np.newaxis]
    elif (2 == len(image.shape) and 2 == len(label.shape)):
        image = image[:, :, np.newaxis]
        label = label[:, :, np.newaxis]

    transform = transforms.Compose([RescaleT(256), ToTensorLab(flag=0)])
    sample = transform({'image': image, 'label': label})

    return sample


def run(img):
    torch.cuda.empty_cache()

    sample = preprocess(img)
    inputs_test = sample['image'].unsqueeze(0)
    inputs_test = inputs_test.type(torch.FloatTensor)

    if torch.cuda.is_available():
        inputs_test = Variable(inputs_test.cuda())
    else:
        inputs_test = Variable(inputs_test)

    # d1, d2, d3, d4, d5, d6, d7, d8 = net(inputs_test)
    try:
      d1, _, _, _, _, _, _, _ = net(inputs_test)
    except:
      d1 = net(inputs_test)

    # Normalization.
    # pred = d1[:,0,:,:]
    pred = d1[:][0][:][:]
    predict = normPRED(pred)

    # Convert to PIL Image
    predict = predict.squeeze()
    predict_np = predict.cpu().data.numpy()
    im = Image.fromarray(predict_np * 255).convert('RGB')

    # Cleanup.
    # del d1, d2, d3, d4, d5, d6, d7, d8
    del d1

    return im
