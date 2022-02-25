# Tensorflow

```sh
docker pull tensorflow/tensorflow


# Start a CPU-only container
$ docker run -it --rm tensorflow/tensorflow bash


# Start a GPU container, using the Python interpreter.
$ docker run -it --rm --runtime=nvidia tensorflow/tensorflow:latest-gpu python

# Run a Jupyter notebook server with your own notebook directory (assumed here to be ~/notebooks). To use it, navigate to localhost:8888 in your browser.

$ docker run -it --rm -v $(realpath ~/notebooks):/tf/notebooks -p 8888:8888 tensorflow/tensorflow:latest-jupyter

```


## BERT Fine-Tuning

```sh
export BERT_DIR=
$ docker run -it --rm -v $(realpath $BERT_DIR):/bert tensorflow/tensorflow python3 
```


```sh
# 下载的预训练模型文件的目录
export BERT_BASE_DIR=/path/to/bert/uncased_L-12_H-768_A-12
# fine-tuning使用的文件目录 (目录包含train.tsv, dev.tsv, test.tsv文件)
export TEXT_DIR=/path/to/text

CUDA_VISIBLE_DEVICES=0 python run_classifier.py \
  --task_name=text \
  --do_train=true \
  --do_eval=true \
  --data_dir=$TEXT_DIR \
  --vocab_file=$BERT_BASE_DIR/vocab.txt \
  --bert_config_file=$BERT_BASE_DIR/bert_config.json \
  --init_checkpoint=$BERT_BASE_DIR/bert_model.ckpt \
  --max_seq_length=128 \
  --train_batch_size=32 \
  --learning_rate=2e-5 \
  --num_train_epochs=3.0 \
  --output_dir=/tmp/text_output/
```

run_classifier.py使用的参数含义在文件开头都有解释，这里就不再赘述了。


如果想利用fine-tuning好的模型来对test数据进行预测，可以参考以下shell脚本

```sh
export BERT_BASE_DIR=/path/to/bert/uncased_L-12_H-768_A-12
export DATA_DIR=/path/to/text
# 前面fine-tuning模型的输出目录
export TRAINED_CLASSIFIER=/tmp/text_output/

python run_classifier.py \
  --task_name=text \
  --do_predict=true \
  --data_dir=$DATA_DIR \
  --vocab_file=$BERT_BASE_DIR/vocab.txt \
  --bert_config_file=$BERT_BASE_DIR/bert_config.json \
  --init_checkpoint=$TRAINED_CLASSIFIER \
  --max_seq_length=128 \
  --output_dir=/tmp/text_output/pred/

```

预测完成后会在/tmp/text_output/pred/目录下生成一个test_results.tsv文件。文件每行代表模型对每个类别预测的分数，对应顺序为TextProcessor中get_labels返回的标签顺序。
