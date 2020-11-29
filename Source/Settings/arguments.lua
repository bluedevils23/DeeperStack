--- Parameters for DeepStack.
--@module arguments

local torch = require 'torch'

torch.setdefaulttensortype('torch.FloatTensor')

local params = {}

--- cache board buckets for faster loading
params.cache_boards = true
--- whether to run on GPU
params.gpu = true
--- list of pot-scaled bet sizes to use in tree, for flop/turn/river.
params.bet_sizing = {{0.5, 1}, {0.5, 1}, {0.5, 1}}
--- server running the ACPC dealer
params.acpc_server = "localhost"
--- server port running the ACPC dealer
params.acpc_server_port = 16177
--- the tensor datatype used for storing DeepStack's internal data
params.Tensor = torch.FloatTensor
--- the directory for data files
params.data_directory = '../Data/'
--- the size of the game's ante/small blind/big blind, in chips
params.ante = 1
params.sb = 10
params.bb = 20
--- the size of each player's stack, in chips
params.stack = 500
--- the number of iterations that DeepStack runs CFR for
params.cfr_iters = 1200
--- the number of preliminary CFR iterations which DeepStack doesn't factor into the average strategy (included in cfr_iters)
params.cfr_skip_iters = 500
--- how many poker situations are solved simultaneously during data generation
params.gen_batch_size = 10
--- how many poker situations are used in each neural net training batch
params.train_batch_size = 500
--- path to the solved poker situation data used to train the neural net
params.data_path = '../Data/TrainSamples/'
--- path to the neural net model
params.model_path = '../Data/Models/'
--- the name of the neural net file
params.value_net_name = 'final'
--- the neural net architecture, use 3 layers by default.
params.net = '{nn.Linear(input_size, 500), nn.BatchNormalization(500), nn.PReLU(), nn.Linear(500, 500), nn.BatchNormalization(500), nn.PReLU(), nn.Linear(500, 500), nn.BatchNormalization(500), nn.PReLU(), nn.Linear(500, output_size)}'
--params.net = '{nn.Linear(input_size, 100), nn.BatchNormalization(100), nn.PReLU(), nn.Linear(100, 100), nn.BatchNormalization(100), nn.PReLU(), nn.Linear(100, 100), nn.BatchNormalization(100), nn.PReLU(), nn.Linear(100, output_size)}'
--- how often to save the model during training
params.save_epoch = 1
--- how many epochs to train for
params.epoch_count = 300
--- how many solved poker situations are generated for use as training examples
params.train_data_count = 80000
--- learning rate for neural net training
params.learning_rate = 0.001
--- how epochs are needed to decrease learning_rate to learning_rate / 10
params.decrease_learning_at_epoch = 200

assert(params.cfr_iters > params.cfr_skip_iters)
if params.gpu then
  require 'cutorch'
  params.Tensor = torch.CudaTensor
end

return params
