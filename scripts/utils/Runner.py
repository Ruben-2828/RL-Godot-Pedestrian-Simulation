
import os
from pathlib import Path
from typing import Collection, Optional

from godot_rl.wrappers.onnx.stable_baselines_export import export_ppo_model_as_onnx
from godot_rl.wrappers.stable_baselines_wrapper import StableBaselinesGodotEnv
from stable_baselines3 import PPO
from stable_baselines3.common.callbacks import CallbackList
from stable_baselines3.common.vec_env import VecMonitor

from scripts.models.Level import Level
from scripts.utils import Constants
from scripts.utils.Callbacks import EndTrainingOnMeanRewardReachedCallback, EndTrainingOnEarlyFailCallback
from scripts.utils.ConfigParser import ConfigParser


class Runner:
    """
    Class used to handle the model training phase.
    To let the entire training work properly, the curriculum list inside godot must be the same as the one specified
    in the config file, with the addition of the retraining environment at the end.
    """

    def __init__(self, config_path: str = Constants.DEFAULT_CONFIG_FILE) -> None:
        """
        Runner constructor, used to set the config file path
        :param config_path: path to the yaml config file.
        """
        self.config_path = config_path
        self.model: Optional[PPO] = None

    def run(self) -> None:
        """
        Method used to run the model training.
        The training is composed of two phases: training and retraining
        During training phase each level is executed once sequentially as specified in the config file. To change
        environment during training phase, the model is saved as .zip and re-loaded from .zip file with the new
        environment. At the end of the execution the zip file will be deleted.
        During retraining phase each level is executed in parallel to re-learn old features the model forgot and
        to maintain every newer feature.
        """

        levels = self.load_levels()

        # Training phase
        for level in levels:
            self.train_level(level)

        # Retraining phase
        self.retraining()

        # Exporting onnx model
        self.handle_onnx_export()

        # Removing tmp model file
        os.remove(Constants.DEFAULT_TMP_MODEL_FILE)

    def load_levels(self) -> Collection[Level]:
        """
        Checks the level config file and if there aren't any errors loads the levels
        """
        config_parser = ConfigParser(self.config_path)
        assert config_parser.validate_curriculum(), "Invalid configuration file"
        return config_parser.get_levels()

    def train_level(self, level: Level) -> None:
        """
        Method that trains the model for the given level. The total timesteps for training is a very high value and
        training is stopped through two different callbacks. The first checks if a mean reward is reached, and the
        second is used to stop execution of the entire training if the training is going too bad.
        :param level: Current level to train the model on
        """

        vec_env, monitor_logs_path = self.create_vec_env(level.name)

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
        self.model.save(Constants.DEFAULT_TMP_MODEL_FILE)

        self.handle_onnx_export()

        # Closing environment
        try:
            print("closing env")
            vec_env.close()
        except Exception as e:
            print("Exception while closing env: ", e)

    def create_vec_env(self, name: str) -> tuple[VecMonitor, str]:
        """
        Method that creates a VecMonitor.
        No exe is passed to the env, so when it is created, it will wait for a connection from a godot client to
        synchronize the model with the godot environment.
        :param name: The name of the environment
        :return: tuple containing the VecMonitor and the monitor logs path of the env
        """

        # Setting up environment
        monitor_logs_path = Constants.DEFAULT_LOGS_PATH + f"{name}_logs/"
        env = StableBaselinesGodotEnv(
            show_window=Constants.SHOW_WINDOW,
        )
        print(f"Running level: {name}")

        return VecMonitor(env, filename=monitor_logs_path + name), monitor_logs_path

    def init_model(self, vec_env: VecMonitor) -> None:
        """
        Method that creates and sets the runner current model. The model is created from scratch.
        :param vec_env: The VecMonitor used to create the model.
        """
        print("Creating new model")
        self.model = PPO(
            "MultiInputPolicy",
            vec_env,
            verbose=0,
            learning_rate=0.0003,
            device='cuda',
            ent_coef=0.0001,
            tensorboard_log=Constants.DEFAULT_TENSORBOARD_LOGS_PATH,
            n_steps=32,
        )

    def load_model(self, vec_env: VecMonitor) -> None:
        """
        Method that loads and sets the runner current model. The model is created using an existing .zip model file.
        :param vec_env: The VecMonitor used to create the model.
        """
        print("Loading model")
        self.model = PPO.load(
            Constants.DEFAULT_TMP_MODEL_FILE,
            vec_env,
            tensorboard_log=Constants.DEFAULT_TENSORBOARD_LOGS_PATH,
            device='cuda',
        )

    def retraining(self) -> None:
        """
        Method that handles the retraining process
        """
        print("Retraining phase")

        # Setting up environment
        vec_env, monitor_logs_path = self.create_vec_env("retraining")

        # Setting up model
        self.load_model(vec_env)

        # Learn and save the model
        self.model.learn(total_timesteps=Constants.DEFAULT_RETRAINING_TIMESTEPS)
        self.model.save(Constants.BASE_PATH + "model_tmp.zip")

        # Closing environment
        try:
            print("closing env")
            vec_env.close()
        except Exception as e:
            print("Exception while closing env: ", e)

    def handle_onnx_export(self) -> None:
        """
        Method used to export the model to ONNX format
        """
        os.makedirs(Path(Constants.DEFAULT_ONNX_EXPORT_PATH).parent, exist_ok=True)

        save_path = Constants.DEFAULT_ONNX_EXPORT_PATH
        i = 1
        while os.path.exists(save_path):
            name, extension = os.path.splitext(save_path)
            save_path = name + "_" + str(i) + extension

        print("Exporting onnx to: " + os.path.abspath(save_path))
        export_ppo_model_as_onnx(self.model, save_path)
