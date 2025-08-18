from scripts.utils.Runner import Runner

# Instantiating runner and starting training
runner = Runner(
    config_path="scripts/configs/base_config.yaml",
    curriculum_path="scripts/configs/curriculum/curriculum_config.yaml",
    run_name="test_archi/test_2",
)
runner.run()
