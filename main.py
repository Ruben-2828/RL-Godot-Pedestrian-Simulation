from scripts.utils.Runner import Runner

# Instantiating runner and starting training
runner = Runner(config_path="scripts/configs/current_best.yaml",
                curriculum_path="scripts/configs/bottleneck_config.yaml",
                run_name="bottleneck")
runner.run()
