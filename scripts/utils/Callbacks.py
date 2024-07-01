
from math import floor

import numpy as np
from pandas import Series
from stable_baselines3.common.callbacks import BaseCallback
from stable_baselines3.common.monitor import load_results


class EndTrainingOnMeanRewardReachedCallback(BaseCallback):
    """
    Callback used to stop training if the trimmed mean reward is greater than a certain threshold.
    The trimmed mean reward is calculated removing the top and bottom 10% of the values, to eliminate outliers.
    """

    def __init__(self, log_dir: str, mean_reward: float, episodes_for_mean: int):
        """
        Callback constructor
        :param log_dir: Log file to get the reward from. Must be a VecMonitor log file.
        :param mean_reward: Mean reward threshold to reach to stop training current level.
        :param episodes_for_mean: Number of episodes used to calculate the mean reward.
        """
        super().__init__()

        self.log_dir = log_dir
        self.mean_reward = mean_reward
        self.episodes_for_mean = episodes_for_mean
        self.cycle = 1

    def _on_step(self) -> bool:
        """
        Callback method to decide whether to stop or continue execution.
        :return: True to continue execution, False to stop execution
        """
        # print("Cycle: ", self.cycle)
        episodes = load_results(self.log_dir)
        if len(episodes) >= (self.episodes_for_mean * self.cycle):

            mean_reward = trimmed_mean(
                episodes['r'].iloc[self.episodes_for_mean * (self.cycle - 1) : self.episodes_for_mean * self.cycle]
            )
            self.cycle += 1

            if mean_reward > self.mean_reward:
                return False
        return True


class EndTrainingOnEarlyFailCallback(BaseCallback):
    """
    Callback to decide whether to stop or continue training on minimum mean reward reached or on early fail.
    The entire execution will stop if the model cant reach the trimmed mean reward threshold after a certain number of
    episodes. The trimmed mean reward is calculated removing the top and bottom 10% of the values, to eliminate outliers.
    """

    def __init__(self, log_dir: str, min_mean_reward: float, episodes_for_mean: int, max_cycles: int):
        """
        Callback constructor
        :param log_dir: Log file to get the reward from. Must be a VecMonitor log file.
        :param min_mean_reward: Mean reward threshold to reach to continue execution.
        :param episodes_for_mean: Number of episodes used to calculate the mean reward.
        :param max_cycles: Number of cycles after which the execution is stopped if the threshold is not reached.
        """
        super().__init__()
        self.log_dir = log_dir
        self.min_mean_reward = min_mean_reward
        self.episodes_for_mean = episodes_for_mean
        self.max_cycles = max_cycles
        self.cycle = 1
        self.no_improvement = 0

    def _on_step(self) -> bool:
        """
        Callback method to decide whether to stop or continue execution.
        :return: True to continue execution, False to stop execution
        """
        episodes = load_results(self.log_dir)
        if len(episodes) >= (self.episodes_for_mean * self.cycle):

            mean_reward = trimmed_mean(
                episodes['r'].iloc[self.episodes_for_mean * (self.cycle - 1):self.episodes_for_mean * self.cycle]
            )
            self.cycle += 1

            if mean_reward < self.min_mean_reward:
                self.no_improvement += 1
                if self.no_improvement == self.max_cycles:
                    print("Training stopped by early fail")
                    exit()

        return True


class EndTrainingCombinedCallback(BaseCallback):
    """
    Callback to stop the entire execution when the model cant train good enough.

    The current level will be stopped if the trimmed mean reward is greater than the set threshold.
    The entire execution will stop if the model cant reach the trimmed mean reward threshold after a certain number of
    episodes.

    The trimmed mean reward is calculated removing the top and bottom 10% of the values, to eliminate outliers.
    """

    def __init__(self, log_dir: str, min_mean_reward: float, episodes_for_mean: int, max_cycles: int):
        """
        Callback constructor
        :param log_dir: Log file to get the reward from. Must be a VecMonitor log file.
        :param min_mean_reward: Mean reward threshold to reach to continue execution.
        :param episodes_for_mean: Number of episodes used to calculate the mean reward.
        :param max_cycles: Number of cycles after which the execution is stopped if the threshold is not reached.
        """
        super().__init__()
        self.log_dir = log_dir
        self.min_mean_reward = min_mean_reward
        self.episodes_for_mean = episodes_for_mean
        self.max_cycles = max_cycles
        self.cycle = 1
        self.no_improvement = 0

    def _on_step(self) -> bool:
        """
        Callback method to decide whether to stop or continue execution.
        :return: True to continue execution, False to stop execution
        """
        episodes = load_results(self.log_dir)
        if len(episodes) >= (self.episodes_for_mean * self.cycle):

            mean_reward = trimmed_mean(
                episodes['r'].iloc[self.episodes_for_mean * (self.cycle - 1):self.episodes_for_mean * self.cycle]
            )
            self.cycle += 1

            if mean_reward > self.min_mean_reward:
                return False

            self.no_improvement += 1
            if self.no_improvement == self.max_cycles:
                print("Training stopped by early fail")
                exit()

        return True


def trimmed_mean(values: Series) -> float:

    trim_range: int = floor(len(values) / 10)
    trimmed_values = values.sort_values().iloc[trim_range:-trim_range]

    return np.mean(trimmed_values)


