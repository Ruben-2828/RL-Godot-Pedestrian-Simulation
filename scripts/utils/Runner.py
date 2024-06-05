
import os
import datetime
from pathlib import Path
from typing import Collection, Optional, Any

from godot_rl.wrappers.onnx.stable_baselines_export import export_ppo_model_as_onnx
from godot_rl.wrappers.stable_baselines_wrapper import StableBaselinesGodotEnv
from stable_baselines3 import PPO
from stable_baselines3.common.callbacks import CallbackList
from stable_baselines3.common.vec_env import VecMonitor

from scripts.models.Level import Level
from scripts.utils import Constants
from scripts.utils.Callbacks import EndTrainingOnMeanRewardReachedCallback, EndTrainingOnEarlyFailCallback, \
    EndTrainingCombinedCallback
from scripts.utils.ConfigParser import ConfigParser


class Runner:
    """
    Class used to handle the model training phase.
    To let the entire training work properly, the curriculum list inside godot must be the same as the one specified
    in the config file, with the addition of the retraining environment at the end.
    """

    def __init__(
            self,
            curriculum_path: str = Constants.DEFAULT_CURRICULUM_CONFIG_FILE,
            config_path: str = Constants.DEFAULT_MODEL_CONFIG_FILE,
    ) -> None:
        """
        Runner constructor, used to set the config file path
        :param curriculum_path: path to the yaml curriculum config file
        :param config_path: path to the yaml config file
        """
        self.curriculum_path = curriculum_path
        self.config_path = config_path
        self.model: Optional[PPO] = None
        self.start_time: Optional[float] = None
        self.run_log_path: str = self.create_run_log_path()
        self.levels: Collection[Level] = []
        self.configs: Optional[dict[str, Any]] = None

    def create_run_log_path(self) -> str:
        i = 1
        log_path = Constants.DEFAULT_TENSORBOARD_LOGS_PATH + "run_" + str(i) + "/"
        while os.path.exists(log_path):
            i += 1
            log_path = Constants.DEFAULT_TENSORBOARD_LOGS_PATH + "run_" + str(i) + "/"

        os.makedirs(log_path, exist_ok=True)
        os.makedirs(log_path + "tensorboard_export", exist_ok=True)
        os.makedirs(log_path + "model", exist_ok=True)
        os.makedirs(log_path + "plots", exist_ok=True)

        return log_path

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

        self.load_configs()

        # Training phase
        for level in self.levels:
            self.train_level(level)

        # Retraining phase
        self.retraining()

        self.log_env_change("End")

        # Exporting onnx model
        self.handle_onnx_export()

        # Show tensorboad command to see results
        print("To see tensorboard logs run the following command:")
        path = os.path.abspath(self.run_log_path)
        print("tensorboard --logdir " + path)

        # Log used settings
        self.log_settings()

        # Removing tmp model file
        os.remove(Constants.DEFAULT_TMP_MODEL_FILE)

    def load_configs(self) -> None:
        """
        Checks the level config file and if there aren't any errors loads the levels
        """
        config_parser = ConfigParser(self.curriculum_path, self.config_path)

        assert config_parser.validate_curriculum(), "Invalid curriculum configuration file"
        self.levels = config_parser.get_levels()

        assert config_parser.validate_config(), "Invalid model configuration file"
        self.configs = config_parser.get_config()

    def log_settings(self) -> None:
        """
        Save a file inside the current run directory with the path to curriculum and config files
        """
        with open(self.run_log_path + "run_configs.txt", "w") as f:
            f.write(f"Curriculum settings: {self.curriculum_path}\n")
            f.write(f"Model settings: {self.config_path}")
        f.close()

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
            reset_num_timesteps = True
        else:
            self.load_model(vec_env)
            reset_num_timesteps = False

        # Setting up callbacks to stop training
        # mean_reward_callback = EndTrainingOnMeanRewardReachedCallback(monitor_logs_path,
        #                                                               level.mean_reward,
        #                                                               level.episodes_for_mean)
        # early_fail_callback = EndTrainingOnEarlyFailCallback(monitor_logs_path,
        #                                                      level.mean_reward,
        #                                                      level.episodes_for_mean,
        #                                                      level.cycles)
        # callback = CallbackList([mean_reward_callback, early_fail_callback])

        callback = EndTrainingCombinedCallback(
            monitor_logs_path,
            level.mean_reward,
            level.episodes_for_mean,
            level.cycles
        )

        self.log_env_change(level.name, level.mean_reward, "train")

        # Learn and save the model
        self.model.learn(
            total_timesteps=self.configs['max_steps'],
            callback=callback,
            tb_log_name=Constants.DEFAULT_TENSORBOARD_LOGS_FILE,
            reset_num_timesteps=reset_num_timesteps,
        )
        self.model.save(Constants.DEFAULT_TMP_MODEL_FILE)

        # Closing environment
        try:
            print("closing env")
            vec_env.close()
        except Exception as e:
            print("Exception while closing env: ", e)

    def log_env_change(self, env_name: str, min_score: float = -100, phase: str = '') -> None:
        """
        Method to log information about environment changes. Logs are stored in a csv file in the following format:
        datetime; timestamp; start time (in seconds); env name; score; phase
        :param env_name: name of the current environment
        :param min_score: score to reach during current environment
        :param phase: phase of the training (train, retrain)
        """

        if self.start_time is None:
            self.start_time = datetime.datetime.now().timestamp()

        with open(self.run_log_path + "EnvironmentChanges.txt", "a") as f:
            current_time = datetime.datetime.now()

            f.write(
                str(current_time) + ';' +
                str(int(current_time.timestamp())) + ';' +
                str(int(current_time.timestamp() - self.start_time)) + ';' +
                env_name + ';' +
                str(min_score) + ';' +
                phase + '\n'
            )
            f.close()

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
            tensorboard_log=self.run_log_path,
            **self.configs['hyperparameters'],
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
            tensorboard_log=self.run_log_path,
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

        self.log_env_change("Retraining", phase="retrain")

        # Learn and save the model
        self.model.learn(
            total_timesteps=Constants.DEFAULT_RETRAINING_TIMESTEPS,
            tb_log_name=Constants.DEFAULT_TENSORBOARD_LOGS_FILE,
            reset_num_timesteps=False
        )

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
        path = self.run_log_path + Constants.DEFAULT_ONNX_EXPORT_PATH

        print("Exporting onnx to: " + os.path.abspath(path))
        export_ppo_model_as_onnx(self.model, path)
