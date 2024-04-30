# RL-Godot-Pedestrian-Simulation

## Curriculum–Based Reinforcement Learning for Pedestrian Simulation

#### Tenderini Ruben 
#### Falbo andrea 

## Table of Contents

### 1. [Objective](#objective)
### 2. [Contents](#contents)
### 3. [Tools](#tools)
### 4. [Setup](#setup)
### 5. [Usage](#usage)
### 6. [Codebase](#codebase)
### 7  [Collaborate](#collaborate)

## Objective

The goal of this project is to apply reinforcement learning (RL) to the domain of pedestrian simulation, traditionally 
dominated by agent-based models where pedestrian decisions are scripted manually. 
This involves developing a robust RL framework that trains an agent to optimize behaviors through a reward system 
designed to encapsulate goal orientation, basic proxemics, and way-finding strategies. 

Our approach includes creating a progressively challenging curriculum to aid the agent in acquiring complex pedestrian 
behaviors such as orientation, walking, and interacting with other pedestrians in a simulated environment. 

The framework leverages Godot and Godot-RL-Agents for implementing and testing the simulation.

## Contents

_coming soon..._

## Tools

The main tools and methodologies used to conduct this study are provided below:

### Godot Engine
[Godot Engine](https://godotengine.org/) is an open-source game engine used for the development of 2D and 3D games. Godot provides a flexible and powerful environment for game development and simulation tasks, such as the one undertaken in this project.

### Godot-RL-Agents
[Godot-RL-Agents](https://github.com/edbeeching/godot_rl_agents) is a plugin for the Godot Engine designed to integrate reinforcement learning algorithms directly into game environments. This tool allows for real-time interaction and learning in complex simulated environments.

### Stable Baselines 3

[**Stable Baselines 3**](https://github.com/DLR-RM/stable-baselines3) is a reinforcement learning library in Python, 
developed by OpenAI.
It provides a set of stable and reliable RL algorithm implementations, designed to be easily
accessible and usable by developers. 

## Setup

### Windows

Here's the setup for Windows:

#### Open the project on Godot
1. **Install Godot**: You can download and install Godot from [here](https://godotengine.org/download/windows/)!

2. **Clone this repository**: Clone this repository 
    ```
    https://github.com/Ruben-2828/RL-Godot-Pedestrian-Simulation.git
    ```
3. **Launch Godot**: Extract the files and run the Godot exe. The godot engine will open

4. **Import Project**: In the launcher, press Import and find the repository. Then press Import & Edit. 
Now the project should be open!

#### Enable RL to Godot

1. **Install Anaconda**: We recommend installing anaconda to have a complete and integrated environment. You can do it 
from [here](https://www.anaconda.com/download)!

2. **Create an environment**: Open Anaconda Prompt and create an environment with python 3.8:
    ```
    conda create --name myenv python=3.8
    ```
3. **Activate the environment**: After creating the environment, you need to activate it using the following command:
    ```
    conda activate myenv
    ```
4. **Install the dependencies**: You can install the dependencies of this project using this following commands:
    ```
    pip install godot-rl
    ```
    ```
    pip install stable-baselines
    ```
#### Run the project
1. **Activate RL-Agents**: Enable rl-agents using this command from Anaconda Prompt:
    ```
    gdrl
    ```
2. **Press Run**: From Godot, press F5 or the Run command to run the project!

Every time you need to run the project, you will have to run these two commands.

### Linux

_coming soon..._

## Usage

For a detailed understanding of how this project was developed and to explore all its features and uses, please refer 
to the `documentation` file in the doc folder.

## Codebase
To have a better understanding of the location of the files within the repository, we recommend reading this section.
All folders and files that are not included here are not relevant to this project.

* docs: This folder includes concise summaries about Godot and Godot-RL-Agents, as well as a comprehensive documentation on Godot-RL-Pedestrian-Simulation. It provides detailed descriptions of all the system features.
* environments: This folder contains all files related to the environments, such as levels, their corresponding code, and the level manager.
  * levels: This folder contains all the levels, i.e. all the rooms that can be inserted into the curriculum
  * levels_scripts: This folder contains all the corresponding code to the level 
* materials: This folder contains materials relating to the elements that furnish the rooms.
* models: This folder holds all the training files that are saved for later use during the testing phase. It serves as a dedicated storage area to ensure seamless access and organization of training data required for model evaluation.
* objects: This folder contains individual objects placed within a scene
  * basic: This folder contains the basic objects to compose a room, i.e. targets, walls, floor ecc...
  * composed: This folder contains all composed objects, like room hallway, intersection
  * pedestrian: This folder contains all information relating to the pedestrian
* scripts: This folder contains all the python scripts related to the project
* testing_scene: This folder contains files relating to the testing phase
* training_scene: This folder contains files relating to the training phase

## Collaborate

If you encounter any errors or have suggestions for improvements, we welcome collaboration and feedback from the 
community. You can contribute by:

* Reporting Issues: If you come across any bugs or issues, please submit them through GitHub's issue tracker for this project repository.

* Pull Requests: Feel free to submit pull requests with fixes, enhancements, or new features. We appreciate any contributions that improve the project.

Collaboration is essential for the continued development and improvement of this project. Let's work together to make it even better!
