# Rllib Example for single and multi-agent training for GodotRL with onnx export,
# needs rllib_config.yaml in the same folder or --config_file argument specified to work.

import argparse
import os
import pathlib
from datetime import datetime
from typing import Optional

import time
import ray
import yaml
from ray import train, tune
from ray.rllib.algorithms.algorithm import Algorithm
from ray.rllib.env.wrappers.pettingzoo_env import ParallelPettingZooEnv
from ray.rllib.policy.policy import PolicySpec

from godot_rl.core.godot_env import GodotEnv
from godot_rl.wrappers.petting_zoo_wrapper import GDRLPettingZooEnv
from godot_rl.wrappers.ray_wrapper import RayVectorGodotEnv

import numpy as np
from math import floor, ceil
from ray.rllib.algorithms.callbacks import DefaultCallbacks
from ray.rllib.utils.metrics.metrics_logger import MetricsLogger

from scripts.utils.ConfigParser import ConfigParser


def trimmed_mean(values):
    """
    Calculates the trimmed mean by removing the top and bottom 10% of the values.
    """
    if len(values) < 10:
        return np.mean(values)  # fallback if few values
    trim_range = floor(len(values) / 10)
    trimmed_values = np.sort(values)[trim_range:-trim_range]
    return np.mean(trimmed_values)


class HandleTrainingCombinedCallback(DefaultCallbacks):
    """
    RLlib version of the curriculum callback.
    """

    def __init__(self, levels: list, num_workers: int, log_env_change=None):
        super().__init__()
        self.levels = levels
        self.log_env_change = self.log_env_change_fun #log_env_change
        self.rewards = []
        self.curr_level_idx = 0
        self.num_workers = num_workers
        self.cycle_count = 0

        # Tempo di inizio training
        self.start_time = None

    def on_algorithm_init(self, *, algorithm, **kwargs):
        print("akjsdnaskjdnnsakdjnaskdjnaskjdnaskjdnaksjdn")
        # Log the start of the first level
        if self.log_env_change:
            print("asoidjasodjmasoldkmasoldkasmdolklasmdolasmd")
            self.log_env_change(
                self.levels[self.curr_level_idx].name,
                self.levels[self.curr_level_idx].mean_reward,
                "train",
            )
        print("Running first level:", self.levels[self.curr_level_idx].name)

    def on_episode_end(self, *, episode, base_env, **kwargs):
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

                    if self.log_env_change:
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

    def log_env_change_fun(self, env_name: str, min_score: float = -100, phase: str = '') -> None:
        """
        Method to log information about environment changes. Logs are stored in a csv file in the following format:
        datetime; timestamp; start time (in seconds); env name; score; phase
        :param env_name: name of the current environment
        :param min_score: score to reach during current environment
        :param phase: phase of the training (train, retrain)
        """

        if self.start_time is None:
            self.start_time = datetime.now().timestamp()

        with open("EnvironmentChanges.txt", "a") as f:
            current_time = datetime.now()

            f.write(
                str(current_time) + ';' +
                str(int(current_time.timestamp())) + ';' +
                str(int(current_time.timestamp() - self.start_time)) + ';' +
                env_name + ';' +
                str(min_score) + ';' +
                phase + '\n'
            )
            f.close()


# --- Observation normalization wrappers to ensure numpy arrays are returned ---
def _extract_low_high(space):
    """Extract low/high bounds for the subspace keyed by 'obs' if present."""
    try:
        # gymnasium.spaces.Dict exposes .spaces (dict)
        if hasattr(space, "spaces") and isinstance(space.spaces, dict):
            sub = space.spaces.get("obs")
            if sub is not None and hasattr(sub, "low") and hasattr(sub, "high"):
                return sub.low, sub.high
        # Or the space itself is a Box
        if hasattr(space, "low") and hasattr(space, "high"):
            return space.low, space.high
    except Exception:
        pass
    return None, None


def _to_numpy_obs(obs, low=None, high=None):
    """
    Ensure observations match RLlib's expected structure: Dict('obs' -> np.ndarray).
    Converts any Python list at obs['obs'] to a numpy float32 array. Leaves other
    structures untouched.
    """
    if isinstance(obs, dict) and "obs" in obs:
        value = obs["obs"]
        if isinstance(value, list):
            obs = dict(obs)
            obs["obs"] = np.asarray(value, dtype=np.float32)
        elif isinstance(value, np.ndarray) and value.dtype != np.float32:
            obs = dict(obs)
            obs["obs"] = value.astype(np.float32, copy=False)
        # Clip to space if provided
        if low is not None and high is not None:
            obs = dict(obs)
            obs_arr = np.asarray(obs["obs"], dtype=np.float32)
            try:
                obs_arr = np.clip(obs_arr, low, high)
            except Exception:
                # Fallback to scalar clip if broadcasting fails
                obs_arr = np.clip(obs_arr, -1.0, 1.0)
            obs["obs"] = obs_arr
    return obs


class NumpyObsGymWrapper:
    """
    Minimal gymnasium-style wrapper that converts dict observations containing
    Python lists into numpy arrays under key 'obs'.
    """

    def __init__(self, base_env):
        self.base_env = base_env

        # Expose typical attributes used by RLlib
        self.observation_space = getattr(base_env, "observation_space", None)
        self.action_space = getattr(base_env, "action_space", None)
        self.num_envs = getattr(base_env, "num_envs", None)
        self._low, self._high = _extract_low_high(self.observation_space)

    def reset(self, *args, **kwargs):
        result = self.base_env.reset(*args, **kwargs)
        # Support gymnasium API: (obs, info)
        if isinstance(result, tuple) and len(result) == 2:
            obs, info = result
            return _to_numpy_obs(obs, self._low, self._high), info
        # Fallback to old gym API
        return _to_numpy_obs(result, self._low, self._high)

    def step(self, action):
        obs, reward, terminated, truncated, info = self.base_env.step(action)
        return _to_numpy_obs(obs, self._low, self._high), reward, terminated, truncated, info

    def close(self):
        return self.base_env.close()

    def __getattr__(self, item):
        # Delegate everything else
        return getattr(self.base_env, item)


class NumpyObsPZWrapper:
    """
    Minimal PettingZoo ParallelEnv-style wrapper that converts each agent's
    observation dict so that obs['obs'] is a numpy array.
    """

    def __init__(self, base_env):
        self.base_env = base_env

        # Expose observation/action spaces mapping if present
        self.observation_spaces = getattr(base_env, "observation_spaces", None)
        self.action_spaces = getattr(base_env, "action_spaces", None)

    def reset(self, *args, **kwargs):
        observations, info = self.base_env.reset(*args, **kwargs)
        observations = {
            aid: _to_numpy_obs(
                ob,
                *_extract_low_high(self.observation_spaces[
                                       aid]) if self.observation_spaces is not None and aid in self.observation_spaces else (
                None, None),
            )
            for aid, ob in observations.items()
        }
        return observations, info

    def step(self, actions):
        observations, rewards, terminations, truncations, infos = self.base_env.step(actions)
        observations = {
            aid: _to_numpy_obs(
                ob,
                *_extract_low_high(self.observation_spaces[
                                       aid]) if self.observation_spaces is not None and aid in self.observation_spaces else (
                None, None),
            )
            for aid, ob in observations.items()
        }
        return observations, rewards, terminations, truncations, infos

    def close(self):
        return self.base_env.close()

    def __getattr__(self, item):
        return getattr(self.base_env, item)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(allow_abbrev=False)
    parser.add_argument("--config_file", default="rllib_config.yaml", type=str, help="The yaml config file")
    parser.add_argument("--restore", default=None, type=str, help="the location of a checkpoint to restore from")
    parser.add_argument(
        "--experiment_dir",
        default="logs/rllib",
        type=str,
        help="The name of the the experiment directory, used to store logs.",
    )
    args, extras = parser.parse_known_args()

    # Get config from file
    with open(args.config_file) as f:
        exp = yaml.safe_load(f)

    is_multiagent = exp["env_is_multiagent"]

    # Register env
    env_name = "godot"
    env_wrapper = None


    def env_creator(env_config):
        index = env_config.worker_index * exp["config"]["num_envs_per_env_runner"] + env_config.vector_index
        port = index + GodotEnv.DEFAULT_PORT
        seed = index
        if is_multiagent:
            base = GDRLPettingZooEnv(
                config=env_config,
                port=port,
                seed=seed,
                show_window=False #(True if env_config.worker_index == 1 else False)
            )
            return ParallelPettingZooEnv(NumpyObsPZWrapper(base))
        else:
            base = RayVectorGodotEnv(config=env_config, port=port, seed=seed)
            return NumpyObsGymWrapper(base)


    tune.register_env(env_name, env_creator)

    policy_names = None
    num_envs = None
    tmp_env = None

    if is_multiagent:  # Make temp env to get info needed for multi-agent training config
        print("Starting a temporary multi-agent env to get the policy names")
        tmp_env = GDRLPettingZooEnv(config=exp["config"]["env_config"], show_window=False)
        policy_names = tmp_env.agent_policy_names
        print("Policy names for each Agent (AIController) set in the Godot Environment", policy_names)
    else:  # Make temp env to get info needed for setting num_workers training config
        print(
            "Starting a temporary env to get the number of envs and auto-set the num_envs_per_env_runner config value")
        tmp_env = GodotEnv(env_path=exp["config"]["env_config"]["env_path"], show_window=False)
        num_envs = tmp_env.num_envs

    tmp_env.close()


    def policy_mapping_fn(agent_id: int, episode, worker, **kwargs) -> str:
        return policy_names[agent_id]


    ray.init(_temp_dir=os.path.abspath(args.experiment_dir))

    if is_multiagent:
        exp["config"]["multiagent"] = {
            "policies": {policy_name: PolicySpec() for policy_name in policy_names},
            "policy_mapping_fn": policy_mapping_fn,
        }
    else:
        exp["config"]["num_envs_per_env_runner"] = num_envs

    config_parser = ConfigParser("../scripts/configs/curriculum/multiagent_config.yaml",
                                 "../scripts/configs/sensitivity_studies/current_best.yaml")

    assert config_parser.validate_curriculum(), "Invalid curriculum configuration file"
    levels = config_parser.get_levels()

    exp["config"]["callbacks"] = lambda: HandleTrainingCombinedCallback(
        levels=levels,
        num_workers=exp["config"]["num_workers"]
    )

    tuner = None
    if not args.restore:
        tuner = tune.Tuner(
            trainable=exp["algorithm"],
            param_space=exp["config"],
            run_config=train.RunConfig(
                storage_path=os.path.abspath(args.experiment_dir),
                stop=exp["stop"],
                checkpoint_config=train.CheckpointConfig(checkpoint_frequency=exp["checkpoint_frequency"]),
                verbose=1,
            ),
        )
    else:
        tuner = tune.Tuner.restore(
            trainable=exp["algorithm"],
            path=args.restore,
            resume_unfinished=True,
        )
    result = tuner.fit()

    # Onnx export after training if a checkpoint was saved
    checkpoint = result.get_best_result().checkpoint

    if checkpoint:
        result_path = result.get_best_result().path
        ppo = Algorithm.from_checkpoint(checkpoint)
        if is_multiagent:
            for policy_name in set(policy_names):
                ppo.get_policy(policy_name).export_model(f"{result_path}/onnx_export/{policy_name}_onnx", onnx=12)
                print(
                    f"Saving onnx policy to {pathlib.Path(f'{result_path}/onnx_export/{policy_name}_onnx').resolve()}"
                )
        else:
            ppo.get_policy().export_model(f"{result_path}/onnx_export/single_agent_policy_onnx", onnx=12)
            print(
                f"Saving onnx policy to {pathlib.Path(f'{result_path}/onnx_export/single_agent_policy_onnx').resolve()}"
            )