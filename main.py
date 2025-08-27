from scripts.utils.Runner import Runner

# Instantiating runner and starting training
runner = Runner(
    config_path="scripts/configs/base_config.yaml",
    curriculum_path="scripts/configs/curriculum/curriculum_group_config.yaml",
    run_name="gruppi/prova1",
)
runner.run()
