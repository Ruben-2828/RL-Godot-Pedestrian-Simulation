from typing import Collection, Optional

from godot_rl.wrappers.stable_baselines_wrapper import StableBaselinesGodotEnv
from stable_baselines3 import PPO
from stable_baselines3.common.callbacks import CallbackList
from stable_baselines3.common.vec_env import VecMonitor

from scripts.models.level import Level
from scripts.utils import Constants
from scripts.utils.Callbacks import EndTrainingOnMeanRewardReachedCallback, EndTrainingOnEarlyFailCallback
from scripts.utils.config_parser import ConfigParser


class Runner:

    def __init__(self, config_path: str = Constants.DEFAULT_CONFIG_FILE):
        self.config_path = config_path
        self.model: Optional[PPO] = None

    def run(self) -> None:

        levels = self.load_levels()

        for level in levels:

            self.run_level(level)

    def load_levels(self) -> Collection[Level]:
        config_parser = ConfigParser(self.config_path)
        assert config_parser.validate_curriculum(), "Invalid configuration file"
        return config_parser.get_levels()

    def run_level(self, level: Level) -> None:

        print(f"Running level: {level.name}")

        # Setting up environment
        monitor_logs_path = Constants.OUTPUT_PATH + f"tmp_{level.get_name()}/"
        env = StableBaselinesGodotEnv(
            env_path=level.level_file,
            show_window=True,
        )
        vec_env = VecMonitor(env, filename=monitor_logs_path + level.get_name())

        # Setting up model
        if self.model is None:
            self.init_model(vec_env)
        else:
            self.load_model(vec_env)

        # Setting up callbacks to stop training
        mean_reward_callback = EndTrainingOnMeanRewardReachedCallback(monitor_logs_path,
                                                                      level.mean_reward,
                                                                      level.episodes_for_mean)
        early_fail_callback = EndTrainingOnEarlyFailCallback(monitor_logs_path,
                                                             level.mean_reward,
                                                             level.episodes_for_mean,
                                                             level.cycles)
        callback = CallbackList([mean_reward_callback, early_fail_callback])

        # Learn and save the model
        self.model.learn(total_timesteps=Constants.DEFAULT_TIMESTEPS, callback=callback)
        self.model.save(Constants.BASE_PATH + "model_tmp.zip")

        # Closing environment
        try:
            print("closing env")
            vec_env.close()
        except Exception as e:
            print("Exception while closing env: ", e)

    def init_model(self, vec_env: VecMonitor) -> None:
        print("Creating new model")
        self.model = PPO(
            "MultiInputPolicy",
            vec_env,
            verbose=0,
            learning_rate=0.0003,
            device='cuda',
            ent_coef=0.0001,
            tensorboard_log=Constants.OUTPUT_PATH + "logs/sb3",
            n_steps=32,
        )

    def load_model(self, vec_env: VecMonitor) -> None:
        print("Loading model")
        self.model = PPO.load(
            Constants.BASE_PATH + "model_tmp.zip",
            vec_env,
            tensorboard_log=Constants.OUTPUT_PATH + "logs/sb3",
            device='cuda',
        )