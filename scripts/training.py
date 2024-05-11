import os

from typing import Optional, Collection

from godot_rl.wrappers.stable_baselines_wrapper import StableBaselinesGodotEnv
from stable_baselines3 import PPO
from stable_baselines3.common.callbacks import CallbackList
from stable_baselines3.common.vec_env.vec_monitor import VecMonitor

from scripts.utils import Constants
from scripts.utils.Callbacks import EndTrainingOnMeanRewardReachedCallback, EndTrainingOnEarlyFailCallback
from scripts.utils.ConfigParser import ConfigParser


def close_env(environment):
    try:
        print("closing env")
        environment.close()
    except Exception as e:
        print("Exception while closing env: ", e)


if __name__ == "__main__":

    config_parser = ConfigParser(Constants.DEFAULT_CONFIG_PATH + "config.yaml")
    assert config_parser.validate_curriculum(), "Invalid configuration file"
    levels = config_parser.get_levels()

    model: Optional[PPO] = None

    for level in levels:

        monitor_logs_path = Constants.OUTPUT_PATH + f"tmp_{level.name}/"

        env = StableBaselinesGodotEnv(
            env_path=level.level_file,
            show_window=True,
        )
        vec_env = VecMonitor(env, filename=monitor_logs_path + level.name)

        if model is None:
            print("Creating new model")
            model = PPO(
                "MultiInputPolicy",
                vec_env,
                verbose=0,
                learning_rate=0.0003,
                device='cuda',
                ent_coef=0.0001,
                tensorboard_log=Constants.OUTPUT_PATH + "logs/sb3",
                n_steps=32,
            )
        else:
            print("Loading model")
            model = PPO.load(
                Constants.BASE_PATH + "model_tmp.zip",
                vec_env,
                tensorboard_log=Constants.OUTPUT_PATH + "logs/sb3",
                device='cuda',
            )

        mean_reward_callback = EndTrainingOnMeanRewardReachedCallback(monitor_logs_path,
                                                                      level.mean_reward,
                                                                      level.episodes_for_mean)
        early_fail_callback = EndTrainingOnEarlyFailCallback(monitor_logs_path,
                                                             level.mean_reward,
                                                             level.episodes_for_mean,
                                                             level.cycles)
        callback = CallbackList([mean_reward_callback, early_fail_callback])

        model.learn(total_timesteps=Constants.DEFAULT_TIMESTEPS, callback=callback)
        model.save(Constants.BASE_PATH + "model_tmp.zip")
        close_env(env)

    os.remove(Constants.BASE_PATH + "model_tmp.zip")
