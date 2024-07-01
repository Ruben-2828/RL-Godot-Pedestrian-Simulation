from scripts.utils.Runner import Runner

# Instantiating runner and starting training
runner = Runner(
    config_path="scripts/configs/sensitivity_studies/net_256_128_64.yaml",
    curriculum_path="scripts/configs/curriculum/curriculum_config.yaml",
    run_name="sensitivity_studies/net_256_128_64",
)
runner.run()
