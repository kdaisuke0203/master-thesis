import sys
import torch  
import gym
import numpy as np  
import torch.nn as nn
import torch.optim as optim
import torch.nn.functional as F
from torch.autograd import Variable
import matplotlib.pyplot as plt
import pandas as pd
import os
import scipy.io
os.environ['KMP_DUPLICATE_LIB_OK']='True'

datax = scipy.io.loadmat("xtrain_hati20.mat")
z_true = scipy.io.loadmat("trj_hati.mat")
trj_data = z_true["xxhati"]
spike_data = datax["yy"]

hidden_size = 256
learning_rate = 3e-4

GAMMA = 0.99
num_steps = 300
max_episodes = 30

class ActorCritic(nn.Module):
    def __init__(self, num_inputs, num_actions, hidden_size, learning_rate=3e-4):
        super(ActorCritic, self).__init__()

        self.num_actions = num_actions

        self.actor_linear1 = nn.Linear(num_inputs, hidden_size)
        self.actor_linear2 = nn.Linear(hidden_size, num_actions)
    
    def forward(self, state):
        state = Variable(torch.from_numpy(state).float().unsqueeze(0))
        
        policy_dist = F.relu(self.actor_linear1(state))
        policy_dist = F.softmax(self.actor_linear2(policy_dist), dim=1)

        return policy_dist

def a2c():
    num_inputs = 2
    num_outputs = 1
    
    actor_critic = ActorCritic(num_inputs, num_outputs, hidden_size)
    ac_optimizer = optim.Adam(actor_critic.parameters(), lr=learning_rate)

    all_lengths = []
    average_lengths = []
    all_rewards = []
    entropy_term = 0
    state = np.zeros(num_inputs)
    new_state = np.zeros(num_inputs)
    for episode in range(max_episodes):
        log_probs = []
        values = []
        rewards = []

        state[0] = trj_data[0,0]
        state[1] = trj_data[0,1]
        for steps in range(num_steps):
            policy_dist = actor_critic.forward(state)

            dist = policy_dist.detach().numpy() 

            action = np.random.choice(num_outputs, p=np.squeeze(dist))
            log_prob = torch.log(policy_dist.squeeze(0)[action])
            entropy = -np.sum(np.mean(dist) * np.log(dist))
            new_state[0] = trj_data[steps,0]
            new_state[1] = trj_data[steps,1]
            reward = 1

            rewards.append(reward)
            entropy_term += entropy
            state = new_state
            
            if steps == num_steps-1:
                all_rewards.append(np.sum(rewards))
                all_lengths.append(steps)
                average_lengths.append(np.mean(all_lengths[-10:]))
                if episode % 10 == 0:                    
                    sys.stdout.write("episode: {}, reward: {}, total length: {}, average length: {} \n".format(episode, np.sum(rewards), steps, average_lengths[-1]))
                break
        
        
        critic_loss = (-log_prob).mean()

        ac_optimizer.zero_grad()
        critic_loss.backward()
        ac_optimizer.step()

    plt.plot(all_lengths)
    plt.plot(average_lengths)
    plt.xlabel('Episode')
    plt.ylabel('Episode length')
    plt.show()
    
if __name__ == "__main__":
    a2c()  