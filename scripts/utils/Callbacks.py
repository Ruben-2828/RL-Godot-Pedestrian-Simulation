import numpy as np
from stable_baselines3.common.callbacks import BaseCallback
from stable_baselines3.common.monitor import load_results


class EndTrainingOnMeanRewardReachedCallback(BaseCallback):

    def __init__(self, log_dir: str, mean_reward: float, episodes_for_mean: int = 36, verbose: int = 0):
        super().__init__(verbose)
        self.log_dir = log_dir
        self.mean_reward = mean_reward
        self.episodes_for_mean = episodes_for_mean

    def _on_step(self) -> bool:

        episodes = load_results(self.log_dir)
        if len(episodes) > self.episodes_for_mean:

            mean_reward = np.mean(episodes['r'][-self.episodes_for_mean:])
            if mean_reward > self.mean_reward:
                return False

        return True
