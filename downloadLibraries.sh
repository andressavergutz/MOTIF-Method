#!/bin/bash
sudo apt-get install python-numpy python-scipy python-matplotlib ipython python-pandas python-sympy python-nose
pip install -U scikit-learn
python verifyLibraries.py
