
from os.path import splitext


class Level:

    def __init__(self, name: str, mean_reward: float, episodes_for_mean: int, cycles: int):
        self.name = name
        self.mean_reward = mean_reward
        self.episodes_for_mean = episodes_for_mean
        self.cycles = cycles
