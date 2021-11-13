import gym
import numpy as np
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers
import scipy.io
import matplotlib.pyplot as plt

datax = scipy.io.loadmat("xtrain_hati20.mat")
z_true = scipy.io.loadmat("trj_hati.mat")
trj_data = z_true["xxhati"]
spike_data = datax["yy"] 

gamma = 0.99  # Discount factor for past rewards
max_steps_per_episode = 500
eps = np.finfo(np.float32).eps.item()  # Smallest number such that 1.0 + eps != 1.0

num_inputs = 2  # rat's position
num_hidden1 = 64
num_hidden2 = 32

inputs = layers.Input(shape=(num_inputs,))
hidden1 = layers.Dense(num_hidden1, activation="relu")(inputs)
hidden2 = layers.Dense(num_hidden2, activation="relu")(hidden1)
critic = layers.Dense(1)(hidden2)

model = keras.Model(inputs=inputs, outputs=[critic])

optimizer = keras.optimizers.Adam(learning_rate=0.001)
huber_loss = keras.losses.Huber()
critic_value_history = []
critic_value_allhistory = []
rewards_history = []
running_reward = 0
episode_count = 0

while episode_count < 200:  
    #state =  [trj_data[max_steps_per_episode*episode_count,0], trj_data[max_steps_per_episode*episode_count,1]]
    state =  [trj_data[0,0], trj_data[0,1]]
    with tf.GradientTape() as tape:
        for timestep in range(1, max_steps_per_episode):
            state = tf.convert_to_tensor(state)
            state = tf.expand_dims(state, 0)

            critic_value = model(state)
            critic_value_history.append(critic_value[0, 0])
        
            state = [trj_data[timestep,0], trj_data[timestep,1]]
            if trj_data[timestep-1,0] < 0:
                reward = 1#np.random.rand()
            else:
                reward = -1
            rewards_history.append(reward)

        # Calculate expected value from rewards
        # - At each timestep what was the total reward received after that timestep
        # - Rewards in the past are discounted by multiplying them with gamma
        # - These are the labels for our critic
        returns = []
        discounted_sum = 0
        for r in rewards_history[::-1]:
            discounted_sum = r + gamma * discounted_sum
            returns.insert(0, discounted_sum)

        # Normalize
        returns = np.array(returns)
        returns = (returns - np.mean(returns)) / (np.std(returns) + eps)
        returns = returns.tolist()

        # Calculating loss values to update our network
        history = zip(critic_value_history, returns)
        critic_losses = []
        for value, ret in history:
            critic_losses.append(
                huber_loss(tf.expand_dims(value, 0), tf.expand_dims(ret, 0))
            )

        # Backpropagation
        loss_value = sum(critic_losses)
    grads = tape.gradient(loss_value, model.trainable_variables)
    for i in range(1):
        optimizer.apply_gradients(zip(grads, model.trainable_variables))

    # Clear the loss and reward history
    critic_value_history.clear()
    rewards_history.clear()

    # Log details
    episode_count += 1
    if episode_count % 100 == 0:
        print("episode",episode_count)

