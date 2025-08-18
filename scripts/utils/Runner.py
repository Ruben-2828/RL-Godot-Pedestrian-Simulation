
import os
import datetime
from typing import Optional, Any

from godot_rl.wrappers.onnx.stable_baselines_export import export_ppo_model_as_onnx
from godot_rl.wrappers.stable_baselines_wrapper import StableBaselinesGodotEnv
from stable_baselines3 import PPO
from stable_baselines3.common.vec_env import VecMonitor

from scripts.models.Level import Level
from scripts.utils import Constants
from scripts.utils.Callbacks import HandleTrainingCombinedCallback
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
            run_name: str = None,
    ) -> None:
        """
        Runner constructor, used to set the config file path
        :param curriculum_path: path to the yaml curriculum config file
        :param config_path: path to the yaml config file
        """
        self.curriculum_path = curriculum_path
        self.config_path = config_path
        self.run_name: str = run_name

        self.model: Optional[PPO] = None
        self.start_time: Optional[float] = None
        self.run_log_path: str = self.create_run_log_path()
        self.levels: list[Level] = []
        self.configs: Optional[dict[str, Any]] = None


    def create_run_log_path(self) -> str:
        """
        Creates the current run log directory and the needed subdirectories.
        :return: string containing the created log directory
        """
        if self.run_name is None:
            i = 1
            log_path = Constants.DEFAULT_TENSORBOARD_LOGS_PATH + "run_" + str(i) + "/"
            while os.path.exists(log_path):
                i += 1
                log_path = Constants.DEFAULT_TENSORBOARD_LOGS_PATH + "run_" + str(i) + "/"
        else:
            log_path = Constants.DEFAULT_TENSORBOARD_LOGS_PATH + self.run_name + "/"

        os.makedirs(log_path, exist_ok=True)
        os.makedirs(log_path + "tensorboard_export", exist_ok=True)
        os.makedirs(log_path + "model", exist_ok=True)
        os.makedirs(log_path + "plots", exist_ok=True)

        return log_path

    def run(self) -> None:
        """
        Method used to run the model training.
        During training phase each level is executed once sequentially as specified in the config file. To change
        level during training phase, a callback is used to call a method inside the godot environment that will
        switch the current level to the next one.
        """

        self.load_configs()

        self.log_settings()

        vec_env, monitor_logs_path = self.create_vec_env("aggregated_level")

        callback = HandleTrainingCombinedCallback(
            monitor_logs_path,
            self.levels,
            self.log_env_change,
        )

        self.init_model(vec_env)

        self.model.learn(
            total_timesteps=self.configs['max_steps'],
            callback=callback,
            tb_log_name=Constants.DEFAULT_TENSORBOARD_LOGS_FILE,
            reset_num_timesteps=True,
        )

        self.log_env_change("End")

        vec_env.close()

        # Exporting onnx model
        self.handle_onnx_export()

        # Show tensorboard command to see results
        print("\nTo see tensorboard logs run the following command:")
        path = os.path.abspath(self.run_log_path)
        print("tensorboard --logdir " + path)


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
        An exe file is used to run 10 instances of the environment in parallel.
        :param name: The name of the environment
        :return: tuple containing the VecMonitor and the monitor logs path of the env
        """

        # Setting up environment
        monitor_logs_path = Constants.DEFAULT_LOGS_PATH + f"{name}_logs/"
        env = StableBaselinesGodotEnv(
            env_path=Constants.GODOT_ENV_PATH,
            n_parallel=Constants.GODOT_ENV_INSTANCES_COUNT,
        )
        return VecMonitor(env, filename=monitor_logs_path + name), monitor_logs_path

    def init_model(self, vec_env: VecMonitor) -> None:
        """
        Method that creates and sets the model.
        :param vec_env: The VecMonitor used to create the model.
        """
        print("Creating new model")
        self.model = PPO(
            "MultiInputPolicy",
            vec_env,
            tensorboard_log=self.run_log_path,
            **self.configs['hyperparameters'],
        )

    def handle_onnx_export(self) -> None:
        """
        Method used to export the model to ONNX format
        """
        path = self.run_log_path + Constants.DEFAULT_ONNX_EXPORT_PATH

        print("Exporting onnx to: " + os.path.abspath(path))
        export_ppo_model_as_onnx(self.model, path)
