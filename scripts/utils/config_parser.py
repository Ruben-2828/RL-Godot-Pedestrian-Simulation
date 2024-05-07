from typing import Collection

import yaml
import os

from scripts.models.level import Level
from scripts.utils import Constants


class ConfigParser:
    def __init__(self, filepath: str):

        self.config = self.load_config(filepath)
        self.levels = []
    def load_config(self, filepath: str) -> dict:
        """Loads the YAML configuration file."""
        try:
            with open(filepath, 'r') as file:
                return yaml.safe_load(file)
        except FileNotFoundError:
            print(f"Error: File not found {filepath}")
            return {}
        except yaml.YAMLError as exc:
            print(f"Error in configuration file: {exc}")
            return {}

    def validate_curriculum(self) -> bool:
        """Validates each level in the curriculum from the configuration file."""
        curriculum = self.config.get('Curriculum', {})
        for level, details in curriculum.items():
            if not self.validate_level(level, details):
                return False
        return True

    def validate_level(self, level_name: str, details: dict) -> bool:
        """Validates file_name, mean_reward, episode_mean and cycles for a given level."""
        # Validate file_name
        file_name = details.get('file_name')
        if not os.path.exists(file_name):
            print(f"Warning: {file_name} for {level_name} does not exist.")
            return False

        # Validate mean_reward
        mean_reward = details.get('mean_reward')
        if not isinstance(mean_reward, float):
            print(f"Warning: mean_reward for {level_name} is not a float.")
            return False

        # Validate episode_mean
        episode_mean = details.get('episode_mean')
        if not isinstance(episode_mean, int) or episode_mean <= 0:
            print(f"Warning: episode_mean for {level_name} is not valid")
            return False

        # Validate cycles
        cycles = details.get('cycles')
        if not isinstance(episode_mean, int) or cycles <= 0:
            print(f"Warning: cycles for {level_name} is not valid")
            return False

        self.levels.append(Level(level_name, file_name, mean_reward, episode_mean, cycles))
        return True

    def get_levels(self) -> Collection[Level]:
        return self.levels


if __name__ == '__main__':
    config_parser = ConfigParser(Constants.DEFAULT_CONFIG_FILE)
    if config_parser.validate_curriculum():
        print("Curriculum is valid.")
        print(config_parser.get_levels())
    else:
        print("Curriculum validation failed.")
