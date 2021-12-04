import numpy as np
import matplotlib.pyplot as plt


def lorenz(x, y, z, s=10, r=28, b=8/3):
    '''
    Given:
       x, y, z: a point of interest in three dimensional space
       s, r, b: parameters defining the lorenz attractor
    Returns:
       x_dot, y_dot, z_dot: values of the lorenz attractor's partial
           derivatives at the point x, y, z
    '''
    x_dot = s*(y - x)
    y_dot = r*x - y - x*z
    z_dot = x*y - b*z
    return x_dot, y_dot, z_dot

def sample_traj_lorenz(T = 100,speed_up = 4,initial_offset = 10000):

    dt = 0.006
    num_steps = speed_up*T+initial_offset -1

    # Need one more for the initial values
    traj = np.zeros((num_steps + 1,3))

    # Set initial values
    traj[0,0], traj[0,1], traj[0,2] = tuple([np.random.randn(1).tolist()[0] for i in range(3)])

    # Step through "time", calculating the partial derivatives at the current point
    # and using them to estimate the next point
    for i in range(num_steps):
        x_dot, y_dot, z_dot = lorenz(traj[i,0], traj[i,1], traj[i,2])
        traj[i+1,0] = traj[i,0] + (x_dot * dt)
        traj[i+1,1] = traj[i,1] + (y_dot * dt)
        traj[i+1,2] = traj[i,2] + (z_dot * dt)
    
    # Initial Offset to make sure sample are intependant:
    traj = traj[initial_offset:]
    # Speed Up trajectory:
    traj = traj[::speed_up,:]
    
    return traj
