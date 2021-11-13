#from test import test
import torch
import torch.optim as optim
import gym
import torch
import torch.nn as nn
import torch.nn.functional as F
from torch.distributions import Categorical
import os
import scipy.io
import numpy as np 
import matplotlib.pyplot as plt


os.environ['KMP_DUPLICATE_LIB_OK']='True'
datax = scipy.io.loadmat("xtrain_hati20.mat")
z_true = scipy.io.loadmat("trj_hati.mat")
trj_data = z_true["xxhati"]
spike_data = datax["yy"]
class ActorCritic(nn.Module):
    def __init__(self):
        super(ActorCritic, self).__init__()
        self.affine = nn.Linear(2, 256)
        self.value_layer = nn.Linear(256, 1)
        
        self.state_values = []
        self.rewards = []

    def forward(self, state):
        state = torch.from_numpy(state).float()
        state = F.relu(self.affine(state))
        state_value = self.value_layer(state)
        self.state_values.append(state_value)
        
        return state_value
    
    def calculateLoss(self, gamma=0.99):
        rewards = []
        dis_reward = 0
        for reward in self.rewards[::-1]:
            dis_reward = reward + gamma * dis_reward
            rewards.insert(0, dis_reward)
                
        # normalizing the rewards:
        rewards = torch.tensor(rewards)
        rewards = (rewards - rewards.mean()) / (rewards.std())
        
        loss = 0
        for value, reward in zip(self.state_values, rewards):
            advantage = reward  - value.item()
            value_loss = F.smooth_l1_loss(value, reward)
            loss += value_loss 
        return loss
    
    def clearMemory(self):
        del self.state_values[:]
        del self.rewards[:]
        
def train():
    gamma = 0.99
    lr = 0.01
    betas = (0.9, 0.999)
    num_inputs = 2 
    
    critic = ActorCritic()
    optimizer = optim.Adam(critic.parameters(), lr=lr, betas=betas)
    print(lr,betas)
    state = np.zeros(num_inputs)
    running_reward = 0
    for i_episode in range(0, 5000):
        state[0] = trj_data[0,0]
        state[1] = trj_data[0,1]
        for t in range(1,500):
            value_est = critic(state)
            if state[0] > 0:
                reward = 1.0
            else:
                reward = 0
            state[0] = trj_data[t,0]
            state[1] = trj_data[t,1]
    
            critic.rewards.append(reward)
                    
        optimizer.zero_grad()
        loss = critic.calculateLoss(gamma)
        loss.backward()
        optimizer.step()        
        critic.clearMemory()
        
        if i_episode % 20 == 0:
            print('Episode {}\tloss: {}'.format(i_episode, loss))
    
    X, Y = np.mgrid[0:12.1:0.1, 0:12.1:0.1]
    X-=6.0
    Y-=6.0
    z=np.zeros([120,120])
    for i in range(120):
        for j in range(120):
            state[0] = -6+ j/10
            state[1] = -i/10+6
            z[i,j] = critic(state)[0]

    fig, ax = plt.subplots()
    im = ax.pcolormesh(X, Y, z, cmap='inferno',vmin=0,vmax=1.1)
    ax.set_xlabel("X")
    ax.set_ylabel("Y")
    cbar = fig.colorbar(im)
    cbar.set_label("Z")
    plt.show()
            
if __name__ == '__main__':
    train()

"""
class ActorCritic(nn.Module):
    def __init__(self):
        super(ActorCritic, self).__init__()
        self.affine = nn.Linear(4, 128)
        
        self.action_layer = nn.Linear(128, 2)
        self.value_layer = nn.Linear(128, 1)
        
        self.logprobs = []
        self.state_values = []
        self.rewards = []

    def forward(self, state):
        state = torch.from_numpy(state).float()
        state = F.relu(self.affine(state))
        
        state_value = self.value_layer(state)
        
        action_probs = F.softmax(self.action_layer(state))
        action_distribution = Categorical(action_probs)
        action = action_distribution.sample()
        
        self.logprobs.append(action_distribution.log_prob(action))
        self.state_values.append(state_value)
        
        return action.item()
    
    def calculateLoss(self, gamma=0.99):
        
        # calculating discounted rewards:
        rewards = []
        dis_reward = 0
        for reward in self.rewards[::-1]:
            dis_reward = reward + gamma * dis_reward
            rewards.insert(0, dis_reward)
                
        # normalizing the rewards:
        rewards = torch.tensor(rewards)
        rewards = (rewards - rewards.mean()) / (rewards.std())
        
        loss = 0
        for logprob, value, reward in zip(self.logprobs, self.state_values, rewards):
            advantage = reward  - value.item()
            action_loss = -logprob * advantage
            value_loss = F.smooth_l1_loss(value, reward)
            loss += (action_loss + value_loss)   
        return loss
    
    def clearMemory(self):
        del self.logprobs[:]
        del self.state_values[:]
        del self.rewards[:]
        
def train():
    render = False
    gamma = 0.99
    lr = 0.02
    betas = (0.9, 0.999)
    random_seed = 543
    
    torch.manual_seed(random_seed)
    
    env = gym.make('CartPole-v0')
    env.seed(random_seed)
    
    policy = ActorCritic()
    optimizer = optim.Adam(policy.parameters(), lr=lr, betas=betas)
    print(lr,betas)
    
    running_reward = 0
    for i_episode in range(0, 100):
        state = env.reset()
        for t in range(1000):
            action = policy(state)
            state, reward, done, _ = env.step(action)
            policy.rewards.append(reward)
            running_reward += reward
            if render and i_episode > 1000:
                env.render()
            if done:
                break
                    
        optimizer.zero_grad()
        loss = policy.calculateLoss(gamma)
        loss.backward()
        optimizer.step()        
        policy.clearMemory()
        
        if running_reward > 4000:
            torch.save(policy.state_dict(), './preTrained/LunarLander_{}_{}_{}.pth'.format(lr, betas[0], betas[1]))
            print("########## Solved! ##########")
            #test(name='LunarLander_{}_{}_{}.pth'.format(lr, betas[0], betas[1]))
            break
        
        if i_episode % 20 == 0:
            running_reward = running_reward/20
            print('Episode {}\tlength: {}\treward: {}'.format(i_episode, t, running_reward))
            running_reward = 0
            
if __name__ == '__main__':
    train()
"""