#!/usr/bin/env python
 
from distutils.core import setup
from Cython.Build import cythonize
from distutils.extension import Extension
 
# compile command: python setup.py build_ext --inplace
 

setup(ext_modules = cythonize(Extension(
           "unique",
           sources=["unique_segid.pyx", "makeUnique.cpp"],
           language="c++",                        
      )))