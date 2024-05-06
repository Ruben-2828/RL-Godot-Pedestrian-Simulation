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
        device='cuda',
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
