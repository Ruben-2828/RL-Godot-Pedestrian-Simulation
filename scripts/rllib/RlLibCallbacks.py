from datetime import datetime
from math import floor, ceil

import numpy as np
from ray.rllib.algorithms.callbacks import DefaultCallbacks


def trimmed_mean(values):
    """
    Calculates the trimmed mean by removing the top and bottom 10% of the values.
    """
    if len(values) < 10:
        return np.mean(values)  # fallback if few values
    trim_range = floor(len(values) / 10)
    trimmed_values = np.sort(values)[trim_range:-trim_range]
    return np.mean(trimmed_values)


class RlLibCallback(DefaultCallbacks):
    """
    RLlib version of the curriculum callback.
    """

    def __init__(self, levels: list, num_workers: int, log_env_change=None):
        super().__init__()
        self.levels = levels
        self.log_env_change = log_env_change
        self.rewards = []
        self.curr_level_idx = 0
        self.num_workers = num_workers
        self.cycle_count = 0

        # Tempo di inizio training
        self.start_time = None

    def on_algorithm_init(self, *, algorithm, **kwargs):
        # Log the start of the first level
        if self.log_env_change:
            self.log_env_change(
                self.levels[self.curr_level_idx].name,
                self.levels[self.curr_level_idx].mean_reward,
                "train",
            )
        print("Running first level:", self.levels[self.curr_level_idx].name)

    def on_episode_end(self, *, episode, base_env, worker, **kwargs):
        self.rewards.append(episode.total_reward)

        num_ep = ceil(self.levels[self.curr_level_idx].episodes_for_mean / self.num_workers)

        if len(self.rewards) >= num_ep:
            mean_reward = trimmed_mean(self.rewards[:num_ep])

            self.cycle_count += 1

            print(f"[Level {self.levels[self.curr_level_idx].name}] | "
                  f"Cycle {self.cycle_count}/{self.levels[self.curr_level_idx].cycles} | "
                  f"Trimmed mean reward: {mean_reward:.1f}")

            if mean_reward > self.levels[self.curr_level_idx].mean_reward:
                self.curr_level_idx += 1
                if self.curr_level_idx < len(self.levels):
                    print(f"Advancing to next level: {self.levels[self.curr_level_idx].name}")
                    self.rewards = []
                    self.cycle_count = 0

                    for env in base_env.get_sub_environments():
                        env.get_sub_environments.godot_env.call("next_level")

                    if self.log_env_change and worker.worker_index == 1:
                        self.log_env_change(
                            self.levels[self.curr_level_idx].name,
                            self.levels[self.curr_level_idx].mean_reward,
                            "train",
                        )
                else:
                    print("Curriculum completed: all levels successfully reached!\n")
                    self.rewards = []
            else:
                if self.cycle_count < self.levels[self.curr_level_idx].cycles:
                    print(f"Mean reward not reached on level {self.levels[self.curr_level_idx].name}, "
                          f"continuing training...")
                else:
                    print(f"Max cycles reached on level {self.levels[self.curr_level_idx].name} "
                          f"without achieving target mean reward.\n")
            del self.rewards[:num_ep]
