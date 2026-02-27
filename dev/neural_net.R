# 1. Install and load the package
# install.packages("neuralnet")
# https://writings.stephenwolfram.com/2023/02/what-is-chatgpt-doing-and-why-does-it-work/
# Beyond Basic Training
library(neuralnet)

n_training <- 1000

hidden_fun <- function(values) {
  sapply(values, function(x) {
    if (x < -0.3) {
      -1
    } else if (x >= -0.3 & x < 0.4) {
      1
    } else {
      0
    }
  })
}

plot(seq(-1, 1, 0.1), hidden_fun(seq(-1, 1, 0.1)))

# 2. Generate synthetic data (Learning y = sin(x))
set.seed(123)
inputs <- runif(n_training, min = -1, max = 1)
training_data <- data.frame(
  input = inputs,
  output = hidden_fun(inputs)
)

plot(training_data)

generate_random_weights <- function(
  inputs,
  hidden_vector,
  outputs,
  min = -1,
  max = 1
) {
  # Combine all layers into one architecture vector
  # e.g., c(1, 5, 1) for 1 input, 5 hidden, 1 output
  layers <- c(inputs, hidden_vector, outputs)

  weights_list <- list()

  # Loop through layers to create weight matrices
  for (i in 1:(length(layers) - 1)) {
    rows <- layers[i] + 1 # Previous layer + 1 for Bias
    cols <- layers[i + 1] # Current layer nodes

    # Create the matrix with random values
    weights_list[[i]] <- matrix(
      runif(rows * cols, min, max),
      nrow = rows,
      ncol = cols
    )
  }

  return(weights_list)
}

# 3. Build and train a 3-layer network
# hidden = 5 creates one hidden layer with 5 neurons
# linear.output = TRUE is used for regression (predicting continuous values)
model <- neuralnet(
  output ~ input,
  data = training_data,
  hidden = c(4, 3),
  stepmax = 1000,
  linear.output = TRUE
)

model$weights <- list(generate_random_weights(1, c(4, 3), 1))

# 4. Visualize the network
# plot(model)

# set.seed(321)
test_inputs <- data.frame(input = runif(100, min = -1, max = 1))

# 5. Test the model
prediction <- predict(model, test_inputs)
result <- cbind(
  test_inputs$input,
  prediction,
  actual = hidden_fun(test_inputs$input)
)

plot(result[, 1:2])
