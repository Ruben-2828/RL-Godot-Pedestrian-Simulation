import numpy as np
from stable_baselines3.common.callbacks import BaseCallback
from stable_baselines3.common.monitor import load_results


class EndTrainingOnMeanRewardReachedCallback(BaseCallback):

    def __init__(self, log_dir: str, mean_reward: float, episodes_for_mean: int):
        super().__init__()
        self.log_dir = log_dir
        self.mean_reward = mean_reward
        self.episodes_for_mean = episodes_for_mean
        self.cycle = 1

    def _on_step(self) -> bool:
        episodes = load_results(self.log_dir)
        if len(episodes) >= (self.episodes_for_mean * self.cycle):

            mean_reward = np.mean(
                episodes['r'].iloc[self.episodes_for_mean * (self.cycle - 1):self.episodes_for_mean * self.cycle]
            )
            self.cycle += 1

            if mean_reward > self.mean_reward:
                return False
        return True


class EndTrainingOnEarlyFailCallback(BaseCallback):

    def __init__(self, log_dir: str, min_mean_reward: float, episodes_for_mean: int, max_cycles: int):
        super().__init__()
        self.log_dir = log_dir
        self.min_mean_reward = min_mean_reward
        self.episodes_for_mean = episodes_for_mean
        self.max_cycles = max_cycles
        self.cycle = 1
        self.no_improvement = 0

    def _on_step(self) -> bool:
        episodes = load_results(self.log_dir)
        if len(episodes) >= (self.episodes_for_mean * self.cycle):
            mean_reward = np.mean(
                episodes['r'].iloc[self.episodes_for_mean * (self.cycle - 1):self.episodes_for_mean * self.cycle]
            )
            self.cycle += 1
            if mean_reward < self.min_mean_reward:
                self.no_improvement += 1
                if self.no_improvement == self.max_cycles:
                    print("Training stopped by early fail")
                    exit()

        return True
