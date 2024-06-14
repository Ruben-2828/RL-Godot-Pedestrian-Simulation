from scripts.utils.Runner import Runner

# Instantiating runner and starting training
runner = Runner(config_path="scripts/configs/current_best_256_256_128.yaml",
                curriculum_path="scripts/configs/high_density_config.yaml",
                run_name="high_density/hd_no_retr_call")
runner.run()
