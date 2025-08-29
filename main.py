from scripts.utils.Runner import Runner

# Instantiating runner and starting training
runner = Runner(
    config_path="scripts/configs/sensitivity_studies/current_best.yaml",
    curriculum_path="scripts/configs/curriculum/multiagent_config.yaml",
    run_name="test_test/test_narrowdoor_in_fondo",
)
runner.run()
