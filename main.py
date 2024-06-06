from scripts.utils.Runner import Runner

# Instantiating runner and starting training
runner = Runner(config_path="scripts/configs/base_config_no_retr.yaml", run_name="base_config_no_retr")
runner.run()
