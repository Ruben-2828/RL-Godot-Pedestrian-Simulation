
from typing import Collection

import yaml

from scripts.models.Level import Level
from scripts.utils import Constants


class ConfigParser:
    """
    This class is used to parse and get the configuration for the training from a yaml file.
    """

    def __init__(self, curriculum_configs_path: str, model_configs_path: str) -> None:
        """
        Config parser constructor. Used mainly to set the yaml config file
        :param curriculum_configs_path: path to curriculum config file
        :param model_configs_path: path to model config file
        """
        self.curriculum_config = self.load_file(curriculum_configs_path)
        self.model_config = self.load_file(model_configs_path)

        self.levels = []

    def load_file(self, filepath: str) -> dict:
        """
        Loads the YAML configuration file. Checks if it exists and if it is well formatted
        :param filepath: String containing the path to the YAML configuration file
        :return: Dictionary containing the configuration
        """
        with open(filepath, 'r') as file:
            return yaml.safe_load(file)


    def validate_curriculum(self) -> bool:
        """
        Validates each level in the curriculum from the configuration file.
        Every level will be added to self.levels collection.
        :return: True if the entire curriculum is valid, False otherwise
        """
        curriculum = self.curriculum_config.get('Curriculum', {})
        for level, details in curriculum.items():
            if not self.validate_level(level, details):
                return False
        return True

    def validate_level(self, level_name: str, details: dict) -> bool:
        """
        Validates mean_reward, episode_mean and cycles for a given level.
        If the level is valid, it will be added to the collection of levels self.levels
        :param level_name: Name of the level to validate. It corresponds to the key in the configuration dict
        :param details: Dictionary containing the needed values. It corresponds to the key in the configuration dict
        :return: True if the given level is valid, False otherwise
        """
        # Validate mean_reward
        mean_reward = details.get('mean_reward')
        if not isinstance(mean_reward, float):
            print(f"Error: mean_reward for {level_name} is not a float.")
            return False

        # Validate episode_mean
        episode_mean = details.get('episode_mean')
        if (not isinstance(episode_mean, int)) or episode_mean <= 0:
            print(f"Error: episode_mean for {level_name} is not valid")
            return False

        # Validate cycles
        cycles = details.get('cycles')
        if (not isinstance(episode_mean, int)) or cycles <= 0:
            print(f"Error: cycles for {level_name} is not valid")
            return False

        self.levels.append(Level(level_name, mean_reward, episode_mean, cycles))
        return True

    def get_levels(self) -> Collection[Level]:
        """
        Levels getter. To return the levels the method validate_curriculum() must be called to fill the
        levels' collection.
        :return: Collection of levels of class Level
        """
        return self.levels.copy()

    def validate_config(self) -> bool:
        print(self.model_config)

        if "hyperparameters" not in self.model_config:
            print(f"Error: hyperparameters not find in config file")
            return False

        if "max_steps" not in self.model_config:
            print(f"Error: max_steps not find in config file")
            return False

        return True

    def get_config(self) -> dict:
        return self.model_config.copy()


# Only for debug
if __name__ == '__main__':
    config_parser = ConfigParser(
        "../configs/curriculum_config.yaml",
        "../configs/base_config.yaml",
    )

    if config_parser.validate_curriculum():
        print("Curriculum is valid.")
        print(config_parser.get_levels())
    else:
        print("Curriculum validation failed.")

    if config_parser.validate_config():
        print("Config is valid.")
        print(config_parser.get_config())
    else:
        print("Config validation failed.")


