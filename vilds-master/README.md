## Black box variational inference for state space models

Reference implementation of the algorithms described in the following publications:

>  Y Gao*, E Archer*, L Paninski, J Cunningham (2016). [Linear dynamical neural population models through nonlinear embeddings](http://arxiv.org/abs/1605.08454)

>  E Archer, IM Park, L Buesing, J Cunningham, L Paninski (2015). [Black box variational inference for state space models](http://arxiv.org/abs/1511.07367)

## Tutorial 

An IPython Notebook tutorial is available in the code directory:
> [https://github.com/earcher/vilds/blob/master/code/tutorial.ipynb](https://github.com/earcher/vilds/blob/master/code/tutorial.ipynb)

## Installation
To check out, run `git@github.com:earcher/vilds.git`

The code is written in Python 2. In addition to standard scientific Python libraries (IPython, numpy, matplotlib), the code expects: 

* [Theano](http://deeplearning.net/software/theano/)
* [Lasagne](http://github.com/Lasagne/Lasagne)
* [dill](http://pypi.python.org/pypi/dill)
