
class Level:
    """
    Class used to store level information. The level itself isn't stored in python, but the model synchronize with
    the godot env to train. This class only contains the information needed to stop training on a certain level.
    """

    def __init__(self, name: str, mean_reward: float, episodes_for_mean: int, cycles: int):
        """
        Level constructor.
        :param name: Level name.
        :param mean_reward: Mean reward threshold to reach to step to next level.
        :param episodes_for_mean: Episodes used to calculate mean reward.
        :param cycles: Number of cycles after which the execution is stopped if the threshold is not reached.
        """
        self.name = name
        self.mean_reward = mean_reward
        self.episodes_for_mean = episodes_for_mean
        self.cycles = cycles
