import os
import pathlib
from typing import Callable

from stable_baselines3 import PPO
from stable_baselines3.common.vec_env.vec_monitor import VecMonitor
from stable_baselines3.common.callbacks import EvalCallback, StopTrainingOnNoModelImprovement

from godot_rl.core.utils import can_import
from godot_rl.wrappers.onnx.stable_baselines_export import export_ppo_model_as_onnx
from godot_rl.wrappers.stable_baselines_wrapper import StableBaselinesGodotEnv


def close_env(env):
    try:
        print("closing env")
        env.close()
    except Exception as e:
        print("Exception while closing env: ", e)


# LR schedule code snippet from:
# https://stable-baselines3.readthedocs.io/en/master/guide/examples.html#learning-rate-schedule
def linear_schedule(initial_value: float) -> Callable[[float], float]:
    """
    Linear learning rate schedule.

    :param initial_value: Initial learning rate.
    :return: schedule that computes
      current learning rate depending on remaining progress
    """

    def func(progress_remaining: float) -> float:
        """
        Progress will decrease from 1 (beginning) to 0.

        :param progress_remaining:
        :return: current learning rate
        """
        return progress_remaining * initial_value

    return func

'''
if args.resume_model_path is None:
    model: PPO = PPO(
        "MultiInputPolicy",
        env,
        ent_coef=0.0001,
        verbose=2,
        n_steps=32,
        tensorboard_log=args.experiment_dir,
        learning_rate=0.003,
        batch_size=512,
        n_epochs=3,
        device='auto'
    )
else:
    path_zip = pathlib.Path(args.resume_model_path)
    print("Loading model: " + os.path.abspath(path_zip))
    model = PPO.load(path_zip, env=env, tensorboard_log=args.experiment_dir)

if args.inference:
    obs = env.reset()
    for i in range(args.timesteps):
        action, _state = model.predict(obs, deterministic=True)
        obs, reward, done, info = env.step(action)
else:
    learn_arguments = dict(total_timesteps=args.timesteps, tb_log_name=args.experiment_name)
    if args.save_checkpoint_frequency:
        print("Checkpoint saving enabled. Checkpoints will be saved to: " + abs_path_checkpoint)
        checkpoint_callback = CheckpointCallback(
            save_freq=(args.save_checkpoint_frequency // env.num_envs),
            save_path=path_checkpoint,
            name_prefix=args.experiment_name,
        )
        learn_arguments["callback"] = checkpoint_callback
    try:
        model.learn(**learn_arguments)
    except KeyboardInterrupt:
        print(
            """Training interrupted by user. Will save if --save_model_path was
            used and/or export if --onnx_export_path was used."""
        )
'''



if __name__ == "__main__":
    
    training_env = StableBaselinesGodotEnv(
        show_window=True,
    )
    training_vec_env = VecMonitor(training_env)
    #stop_train_callback = StopTrainingOnNoModelImprovement(max_no_improvement_evals=3, min_evals=5, verbose=1)
    #eval_callback = EvalCallback(VecMonitor(training_vec_env), eval_freq=1000, callback_after_eval=stop_train_callback, verbose=1)

    model = PPO(
        "MultiInputPolicy", 
        training_vec_env, 
        verbose=1,
        learning_rate=0.0003,
        device='auto',
        ent_coef=0.0001,
        tensorboard_log="logs/sb3",
        n_steps=32,
    )
    model.learn(total_timesteps=60_000)
    model.save("tr.zip")

    close_env(training_vec_env)

    retraining_env = StableBaselinesGodotEnv(
        show_window=True,
    )
    retraining_vec_env = VecMonitor(retraining_env)
    #stop_train_callback = StopTrainingOnNoModelImprovement(max_no_improvement_evals=3, min_evals=5, verbose=1)
    #eval_callback = EvalCallback(retraining_vec_env, eval_freq=1000, callback_after_eval=stop_train_callback, verbose=1)

    model = PPO.load("tr.zip", retraining_vec_env, tensorboard_log="logs/sb3",)
    model.learn(total_timesteps=20_000)
    model.save("re.zip")

    close_env(retraining_vec_env)
    '''
    consolidation_env = StableBaselinesGodotEnv(
        show_window=True,
    )
    consolidation_vec_env = VecMonitor(consolidation_env)
    stop_train_callback = StopTrainingOnNoModelImprovement(max_no_improvement_evals=3, min_evals=5, verbose=1)
    eval_callback = EvalCallback(consolidation_vec_env, eval_freq=1000, callback_after_eval=stop_train_callback, verbose=1)

    model = PPO.load("re.zip", consolidation_vec_env)
    model.learn(total_timesteps=1_000_000_000, callback=eval_callback)

    close_env(consolidation_vec_env)
    '''
