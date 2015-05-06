# -*- coding: utf-8 -*-
"""
Created on Wed Apr 15 16:52:24 2015

compile:
python setup.py build_ext --inplace

@author: jingpeng
"""

from distutils.core import setup
from Cython.Build import cythonize

setup(
  name = 'c_relabel',
  ext_modules = cythonize("c_relabel.pyx"),
)