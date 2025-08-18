from math import floor
from typing import Callable

import numpy as np
from pandas import Series
from stable_baselines3.common.callbacks import BaseCallback
from stable_baselines3.common.monitor import load_results

from scripts.models.Level import Level


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
                episodes['r'].iloc[self.episodes_for_mean * (self.cycle - 1): self.episodes_for_mean * self.cycle]
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

    def __init__(self, log_dir: str, min_mean_reward: float, episodes_for_mean: int, max_cycles: int,
                 log_level_change: Callable):
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
        self.log_level_change = log_level_change

        self.log_level_change()

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


class HandleTrainingCombinedCallback(BaseCallback):
    """
    Callback to handle the training of multiple levels in a curriculum.

    It has three main functionalities:
    1. It switches to the next level when the mean reward of the current level is greater than the set threshold.
    2. It stops the training if the model can't reach the mean reward threshold after a certain number of cycles.
    3. It logs the environment change when switching levels.

    Mean reward is calculated by removing the top and bottom 10% of the values, to eliminate outliers.
    """

    def __init__(self, log_dir: str, levels: list[Level], log_env_change: Callable = None):
        """
        Callback constructor
        :param log_dir: Log file to get the reward from. Must be a VecMonitor log file.
        :param levels: List of Level objects specified in the curriculum.
        """
        super().__init__()
        self.log_dir = log_dir
        self.levels = levels
        self.log_env_change = log_env_change
        self.cycle = 1
        self.no_improvement = 0

        self.past_episodes_count = 0
        self.curr_level_idx = 0

    def _on_training_start(self) -> None:
        """
        Callback method called at the start of training.
        It logs the start of the first level.
        """
        if self.log_env_change:
            self.log_env_change(
                self.levels[self.curr_level_idx].name,
                self.levels[self.curr_level_idx].mean_reward,
                "train",
            )

        print("Running first level:", self.levels[self.curr_level_idx].name)

    def _on_step(self) -> bool:
        """
        Callback method to decide whether to stop or continue execution.
        If the mean reward of the current level is greater than the set threshold, it switches to the next level.
        If the model can't reach the mean reward threshold after a certain number of cycles, it stops the training.
        :return: True to continue execution, False to stop execution
        """
        episodes = load_results(self.log_dir)
        if len(episodes) - self.past_episodes_count >= (
                self.levels[self.curr_level_idx].episodes_for_mean * self.cycle):

            mean_reward = trimmed_mean(
                episodes['r'].iloc[
                    self.levels[self.curr_level_idx].episodes_for_mean * (self.cycle - 1) + self.past_episodes_count:
                    self.levels[self.curr_level_idx].episodes_for_mean * self.cycle + self.past_episodes_count
                ]
            )
            self.cycle += 1

            self.no_improvement += 1
            if self.no_improvement == self.levels[self.curr_level_idx].cycles:
                print("Training stopped by early fail")
                exit()

            if mean_reward > self.levels[self.curr_level_idx].mean_reward:
                self.curr_level_idx += 1
                if self.curr_level_idx >= len(self.levels):
                    print("Training finished successfully")
                    return False

                print("Running next level:", self.levels[self.curr_level_idx].name)

                self.no_improvement = 0
                self.cycle = 1
                self.past_episodes_count = len(episodes)
                for e in self.training_env.envs:
                    e.call("next_level")

                if self.log_env_change:
                    self.log_env_change(
                        self.levels[self.curr_level_idx].name,
                        self.levels[self.curr_level_idx].mean_reward,
                        "train",
                    )

        return True


def trimmed_mean(values: Series) -> float:
    """
    Calculates the trimmed mean by removing the top and bottom 10% of the values.
    :param values: Series of values to calculate the trimmed mean from.
    :return: Float containing the trimmed mean of the values.
    """
    trim_range: int = floor(len(values) / 10)
    trimmed_values = values.sort_values().iloc[trim_range:-trim_range]

    return np.mean(trimmed_values)
