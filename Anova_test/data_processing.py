import pandas as pd
import numpy as np
import os
import re

files_name = [x for x in os.listdir('DATADATA1/') if x.endswith('txt')]

#%%

files = [pd.read_csv('DATADATA1/' + x, sep='\t') for x in files_name]

#%%

files_withoutExt = [x.split('.')[0] for x in files_name]

film = [''.join(re.findall('[a-z]', x)) for x in files_withoutExt]

subtitle = [''.join(re.findall('[A-Z]', x)) for x in files_withoutExt]

print(film)

#%%

files = dict(zip(files_name, files))

#%%




#%%


