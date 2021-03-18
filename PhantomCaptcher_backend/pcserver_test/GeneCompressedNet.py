import torch
from PIL import Image
import numpy as np
from torchvision import datasets, models, transforms
import os
import glob
from models import DoveNetG

transformsC = transforms.Compose([transforms.Resize((512, 512)), transforms.ToTensor(), transforms.Normalize((0.5, 0.5, 0.5), (0.5, 0.5, 0.5))])
transformsG = transforms.Compose([transforms.Resize((512, 512)), transforms.ToTensor(), transforms.Normalize((0.5, ), (0.5, ))])

# model_dir = '/content/drive/MyDrive/TibaMe/Phantom Captcher/DoveNet/saved_models/latest_net_G.pth'
model_dir = 'pth/DoveNetG.pth'


print("Loading GeneCompressedNet...")

net = DoveNetG()
# model = init_net(model, gpu_ids=[0])
net.load_state_dict(torch.load(model_dir))

def run(img_,mask_):
  # width, height = img_.size
  height,width = img_.size



  transformsC = transforms.Compose([transforms.Resize((width, height)), transforms.ToTensor(), transforms.Normalize((0.5, 0.5, 0.5), (0.5, 0.5, 0.5))])
  transformsG = transforms.Compose([transforms.Resize((width, height)), transforms.ToTensor(), transforms.Normalize((0.5, ), (0.5, ))])


  img_ = transformsC(img_)
  mask_ = transformsG(mask_)
  inputs = torch.cat([img_,mask_],0)
  inputs = torch.unsqueeze(inputs, 0)
  with torch.no_grad():
    output = net(inputs)
  im_numpy = output.data[0].cpu().float().numpy()
  im_numpy = (np.transpose(im_numpy, (1, 2, 0)) + 1) / 2.0 * 255.0
  im_numpy = im_numpy.astype(np.uint8)
  im = Image.fromarray(im_numpy).resize((width, height)).convert("RGB")
  return im

