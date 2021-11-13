
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
max_steps_per_episode = 10
eps = np.finfo(np.float32).eps.item()  # Smallest number such that 1.0 + eps != 1.0

num_inputs = 2  # rat's position
num_actions = 9  # move direction
num_hidden = 128

inputs = layers.Input(shape=(num_inputs,))
common = layers.Dense(num_hidden, activation="relu")(inputs)
action = layers.Dense(num_actions, activation="softmax")(common)
critic = layers.Dense(1)(common)

model = keras.Model(inputs=inputs, outputs=[action, critic])

optimizer = keras.optimizers.Adam(learning_rate=0.01)
huber_loss = keras.losses.Huber()
action_probs_history = []
critic_value_history = []
critic_value_allhistory = []
rewards_history = []
running_reward = 0
episode_count = 0

while episode_count < 500:  
    state = [0, 0]
    episode_reward = 0
    with tf.GradientTape() as tape:
        for timestep in range(1, max_steps_per_episode):
            state = tf.convert_to_tensor(state)
            state = tf.expand_dims(state, 0)

            action_probs, critic_value = model(state)
            critic_value_history.append(critic_value[0, 0])
            critic_value_allhistory.append(critic_value[0, 0])

            action = np.random.choice(num_actions, p=np.squeeze(action_probs))
            #print("A0",action_probs)
            action_probs_history.append(tf.math.log(action_probs[0, action]))
            
            reward = np.random.rand()
            state = [trj_data[episode_count,0]/2, trj_data[episode_count,1]/2]
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
        history = zip(action_probs_history, critic_value_history, returns)
        actor_losses = []
        critic_losses = []
        for log_prob, value, ret in history:
            diff = ret - value
            actor_losses.append(-log_prob * diff)  # actor loss

            # The critic must be updated so that it predicts a better estimate of
            # the future rewards.
            critic_losses.append(
                huber_loss(tf.expand_dims(value, 0), tf.expand_dims(ret, 0))
            )

        # Backpropagation
        loss_value = sum(actor_losses) + sum(critic_losses)
        grads = tape.gradient(loss_value, model.trainable_variables)
        optimizer.apply_gradients(zip(grads, model.trainable_variables))

        # Clear the loss and reward history
        action_probs_history.clear()
        critic_value_history.clear()
        rewards_history.clear()

    # Log details
    episode_count += 1
    if episode_count % 100 == 0:
        print("episode",episode_count)

z=np.zeros([100,100])
for i in range(100):
    for j in range(100):
        state = tf.convert_to_tensor([i/20-2.5,j/20-2.5])
        state = tf.expand_dims(state, 0)
        z[i,j] = model(state)[1]

plt.imshow(z)
plt.colorbar () # カラーバーの表示 
plt.xlabel('X')
plt.ylabel('Y')
plt.show()
