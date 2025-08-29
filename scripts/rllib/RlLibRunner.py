
import os
import datetime
import pathlib
from typing import Optional, Any

from godot_rl.core.godot_env import GodotEnv
from godot_rl.wrappers.petting_zoo_wrapper import GDRLPettingZooEnv

import ray
from ray import tune, train
from ray.rllib.algorithms import Algorithm
from ray.rllib.env import ParallelPettingZooEnv
from ray.rllib.policy.policy import PolicySpec

from scripts.models.Level import Level
from scripts.rllib.RlLibCallbacks import RlLibCallback
from scripts.rllib.RlLibWrappers import NumpyObsPZWrapper
from scripts.rllib import RlLibConstants
from scripts.rllib.RlLibConfigParser import RlLibConfigParser


class RlLibRunner:
    """
    Class used to handle the model training phase.
    To let the entire training work properly, the curriculum list inside godot must be the same as the one specified
    in the config file, with the addition of the retraining environment at the end.
    """

    def __init__(
            self,
            curriculum_path: str = RlLibConstants.DEFAULT_CURRICULUM_CONFIG_FILE,
            config_path: str = RlLibConstants.DEFAULT_MODEL_CONFIG_FILE,
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

        self.start_time: Optional[float] = None
        self.env_change_file: Optional[str] = None
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
            log_path = RlLibConstants.DEFAULT_TENSORBOARD_LOGS_PATH + "run_" + str(i) + "/"
            while os.path.exists(log_path):
                i += 1
                log_path = RlLibConstants.DEFAULT_TENSORBOARD_LOGS_PATH + "run_" + str(i) + "/"
        else:
            log_path = RlLibConstants.DEFAULT_TENSORBOARD_LOGS_PATH + self.run_name + "/"

        os.makedirs(log_path, exist_ok=True)
        os.makedirs(log_path + "tensorboard_export", exist_ok=True)
        os.makedirs(log_path + "model", exist_ok=True)
        os.makedirs(log_path + "plots", exist_ok=True)

        self.env_change_file = os.path.abspath(os.path.join(log_path, "EnvironmentChanges.txt"))

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

        env_creator = self.create_env_creator()
        tune.register_env("godot", env_creator)

        ray.init(_temp_dir=os.path.abspath(RlLibConstants.RLLIB_LOGS))

        policy_names = self.set_policy_names()

        self.configs["config"]["callbacks"] = lambda: RlLibCallback(
            levels=self.levels,
            num_workers=self.configs["config"]["num_workers"],
            log_env_change=self.log_env_change,
        )

        tuner = tune.Tuner(
            trainable=self.configs["algorithm"],
            param_space=self.configs["config"],
            run_config=train.RunConfig(
                storage_path=os.path.abspath(RlLibConstants.RLLIB_LOGS),
                stop=self.configs["stop"],
                checkpoint_config=train.CheckpointConfig(checkpoint_frequency=self.configs["checkpoint_frequency"]),
                verbose=0,
            ),
        )
        result = tuner.fit()

        self.log_env_change("End")

        # Exporting onnx model
        self.handle_onnx_export(result, policy_names)

    def load_configs(self) -> None:
        """
        Checks the level config file and if there aren't any errors loads the levels
        """
        config_parser = RlLibConfigParser(self.curriculum_path, self.config_path)

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

        with open(self.env_change_file, "a") as f:
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

    def create_env_creator(self) -> callable:
        def env_creator(env_config):
            index = (env_config.worker_index *
                     self.configs["config"]["num_envs_per_env_runner"] +
                     env_config.vector_index)
            port = index + GodotEnv.DEFAULT_PORT
            seed = index
            base = GDRLPettingZooEnv(
                config=env_config,
                port=port,
                seed=seed,
                show_window=self.configs["config"]["env_config"]["show_window"],
            )
            return ParallelPettingZooEnv(NumpyObsPZWrapper(base))

        return env_creator

    def set_policy_names(self) -> list[str]:
        """
        Method used to get the policy names from a temporary environment and set them in the configs
        :return: list of policy names
        """
        print("Starting a temporary multi-agent env to get the policy names")
        tmp_env = GDRLPettingZooEnv(config=self.configs["config"]["env_config"], show_window=False)
        policy_names = tmp_env.agent_policy_names
        tmp_env.close()

        def policy_mapping_fn(agent_id: int, episode, worker, **kwargs) -> str:
            return policy_names[agent_id]

        self.configs["config"]["multiagent"] = {
            "policies": {policy_name: PolicySpec() for policy_name in policy_names},
            "policy_mapping_fn": policy_mapping_fn,
        }

        return policy_names

    def handle_onnx_export(self, result, policy_names) -> None:
        """
        Method used to export the model to ONNX format
        """
        path = self.run_log_path + RlLibConstants.DEFAULT_ONNX_EXPORT_PATH

        checkpoint = result.get_best_result().checkpoint

        if checkpoint:
            ppo = Algorithm.from_checkpoint(checkpoint)

            for policy_name in set(policy_names):
                ppo.get_policy(policy_name).export_model(f"{path}/{policy_name}_onnx", onnx=12)
                print(
                    f"Saving onnx policy to {pathlib.Path(f'{path}/{policy_name}_onnx').resolve()}"
                )
