### cuDNN

######################################################################
# - [NVCC :: CUDA Toolkit Documentation](https://docs.nvidia.com/cuda/cuda-compiler-driver-nvcc/index.html)
# - DNN で使われる基本的な機能をまとめた CUDA ライブラリ
# - フレームワークごとに CUDA のコードを書くムダを無くしている
# - NVIDIA 自身が最適化しているので性能的にも良いものを手軽に作れる
######################################################################

if [ -e "/usr/local/cuda/bin" ]; then
    export PATH="/usr/local/cuda/bin:$PATH"
fi

if [ -e "/usr/local/cuda/lib64" ]; then
    export LD_LIBRARY_PATH="/usr/local/cuda/lib64:$LD_LIBRARY_PATH"
fi

if [ -e "/usr/lib/wsl/lib" ]; then
    export LD_LIBRARY_PATH="/usr/lib/wsl/lib:$LD_LIBRARY_PATH"
fi
