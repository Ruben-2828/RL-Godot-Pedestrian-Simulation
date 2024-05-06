
from os.path import splitext


class Level:

    def __init__(self, level_file: str, mean_reward: float, episodes_for_mean: int = 36):
        self.mean_reward = mean_reward
        self.level_file = level_file
        self.episodes_for_mean = episodes_for_mean

    def get_name(self) -> str:
        return splitext(self.level_file)[0]
